import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:facerecognition_flutter/app/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class SmileDetectionView extends StatefulWidget {
  const SmileDetectionView({super.key});

  @override
  State<StatefulWidget> createState() => SmileDetectionViewState();
}

class SmileDetectionViewState extends State<SmileDetectionView> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _smiling = false;
  bool _loading = true;
  int _cameraIndex = -1;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initializeDetector();
    _initializeCamera();
  }

  void _initializeDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        performanceMode: FaceDetectorMode.accurate, // Try accurate mode instead of fast
        minFaceSize: 0.15, // Increase minimum face size for better detection
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      // Find front camera
      for (var i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == CameraLensDirection.front) {
          _cameraIndex = i;
          break;
        }
      }

      // If no front camera found, use the first available camera
      if (_cameraIndex == -1) {
        _cameraIndex = 0;
      }

      await _startLiveFeed();
    } catch (e) {
      log('Error initializing camera: $e');
    }
  }

  Future<void> _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high, // Try higher resolution
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21 // For Android
          : ImageFormatGroup.bgra8888, // For iOS
    );

    try {
      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      log('Error starting camera stream: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = _getInputImage(image);
      if (inputImage == null) return;

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        // Log information about the face
        log('Face detected! Count: ${faces.length}');
        final face = faces.first;
        final smileProb = face.smilingProbability ?? 0.0;
        log('Smile probability: $smileProb');

        if (mounted) {
          setState(() {
            _smiling = smileProb > 0.6;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _smiling = false;
          });
        }
        log('No faces detected');
      }
    } catch (e) {
      log('Face detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _getInputImage(CameraImage image) {
    if (_cameraController == null) return null;

    // Get the camera rotation
    final camera = _cameras[_cameraIndex];
    final rotation = InputImageRotationValue.fromRawValue(
      Platform.isAndroid ? _cameraController!.description.sensorOrientation : 0,
    );

    if (rotation == null) return null;

    // Handle different image formats for Android and iOS
    if (Platform.isAndroid) {
      final bytes = _concatenatePlanes(image.planes);
      final format = InputImageFormat.nv21;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } else if (Platform.isIOS) {
      final format = InputImageFormat.bgra8888;

      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }

    return null;
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Face Recognition'),
          toolbarHeight: 70,
          centerTitle: true,
        ),
        body: Stack(
          children: <Widget>[
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_cameraController != null && _cameraController!.value.isInitialized)
              Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize!.height,
                      height: _cameraController!.value.previewSize!.width,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Apply transform to un-mirror the front camera
                          Transform(
                            alignment: Alignment.center,
                            // This matrix flips the image horizontally to remove the mirror effect
                            transform: Matrix4.identity()..scale(-1.0, 1.0),
                            child: CameraPreview(_cameraController!),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              const Center(child: Text('Camera unavailable')),

            // Face detection status display
            Container(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 85,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tertiary.withAlpha(128),
                      blurRadius: 1,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _smiling ? 'لبخند تشخیص داده شد' : 'در حال شناسایی',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                        fontFamily: 'Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
