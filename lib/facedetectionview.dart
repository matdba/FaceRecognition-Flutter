import 'dart:async';
import 'dart:io';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:facerecognition_flutter/app/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facesdk_plugin/facedetection_interface.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facesdk_plugin/facesdk_plugin.dart';
import 'person.dart';

// ignore: must_be_immutable
class FaceRecognitionView extends StatefulWidget {
  final List<Person> personList;
  FaceDetectionViewController? faceDetectionViewController;

  FaceRecognitionView({super.key, required this.personList});

  @override
  State<StatefulWidget> createState() => FaceRecognitionViewState();
}

class FaceRecognitionViewState extends State<FaceRecognitionView> {
  dynamic _faces;
  double _livenessThreshold = 0;
  double _identifyThreshold = 0;
  bool _recognized = false;
  String _identifiedName = "";
  String _identifiedSimilarity = "";
  String _identifiedLiveness = "";
  String _identifiedYaw = "";
  String _identifiedRoll = "";
  String _identifiedPitch = "";
  // ignore: prefer_typing_uninitialized_variables
  var _identifiedFace;
  // ignore: prefer_typing_uninitialized_variables
  var _enrolledFace;
  final _facesdkPlugin = FacesdkPlugin();
  FaceDetectionViewController? faceDetectionViewController;

  @override
  void initState() {
    super.initState();

    loadSettings();
    _initializeDetector();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? livenessThreshold = prefs.getString("liveness_threshold");
    String? identifyThreshold = prefs.getString("identify_threshold");
    setState(() {
      _livenessThreshold = double.parse(livenessThreshold ?? "0.7");
      _identifyThreshold = double.parse(identifyThreshold ?? "0.8");
    });
  }

  Future<void> faceRecognitionStart() async {
    final prefs = await SharedPreferences.getInstance();
    var cameraLens = prefs.getInt("camera_lens");

    setState(() {
      _faces = null;
      _recognized = false;
    });

    await faceDetectionViewController?.startCamera(cameraLens ?? 1);
  }

  Future<bool> onFaceDetected(faces) async {
    if (_recognized == true) {
      return false;
    }

    if (!mounted) return false;

    setState(() {
      _faces = faces;
    });

    bool recognized = false;
    double maxSimilarity = -1;
    String maxSimilarityName = "";
    double maxLiveness = -1;
    double maxYaw = -1;
    double maxRoll = -1;
    double maxPitch = -1;
    // ignore: prefer_typing_uninitialized_variables
    var enrolledFace, identifedFace;
    if (faces.length > 0) {
      var face = faces[0];
      for (var person in widget.personList) {
        double similarity = await _facesdkPlugin.similarityCalculation(face['templates'], person.templates) ?? -1;
        if (maxSimilarity < similarity) {
          maxSimilarity = similarity;
          maxSimilarityName = person.name;
          maxLiveness = face['liveness'];
          maxYaw = face['yaw'];
          maxRoll = face['roll'];
          maxPitch = face['pitch'];
          identifedFace = face['faceJpg'];
          enrolledFace = person.faceJpg;
        }
      }

      if (maxSimilarity > _identifyThreshold && maxLiveness > _livenessThreshold) {
        recognized = true;
      }
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return false;
      setState(() {
        _recognized = recognized;
        _identifiedName = maxSimilarityName;
        _identifiedSimilarity = maxSimilarity.toString();
        _identifiedLiveness = maxLiveness.toString();
        _identifiedYaw = maxYaw.toString();
        _identifiedRoll = maxRoll.toString();
        _identifiedPitch = maxPitch.toString();
        _enrolledFace = enrolledFace;
        _identifiedFace = identifedFace;
      });
      if (recognized) {
        faceDetectionViewController?.stopCamera();
        _initializeCamera();
        setState(() {
          _faces = null;
        });
      }
    });

    return recognized;
  }

  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _smiling = false;
  bool _loading = true;
  int _cameraIndex = -1;
  List<CameraDescription> _cameras = [];

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
        faceDetectionViewController?.stopCamera();
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
            !_recognized
                ? FaceDetectionView(faceRecognitionViewState: this)
                : _loading
                    ? Center(child: CircularProgressIndicator())
                    : Center(
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
                      ),

            // SizedBox(
            //   width: double.infinity,
            //   height: double.infinity,
            //   child: CustomPaint(
            //     painter: FacePainter(faces: _faces, livenessThreshold: _livenessThreshold),
            //   ),
            // ),
            Visibility(
              visible: true,
              child: Container(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  height: 85,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiary.withValues(alpha: .5),
                        blurRadius: 1,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          // _enrolledFace != null
                          //     ? Column(
                          //         children: [
                          //           ClipRRect(
                          //             borderRadius: BorderRadius.circular(8.0),
                          //             child: Image.memory(
                          //               _enrolledFace,
                          //               width: 160,
                          //               height: 160,
                          //             ),
                          //           ),
                          //           const SizedBox(
                          //             height: 5,
                          //           ),
                          //           const Text('Enrolled')
                          //         ],
                          //       )
                          //     : const SizedBox(height: 1),
                          // _identifiedFace != null
                          //     ? Column(
                          //         children: [
                          //           ClipRRect(
                          //             borderRadius: BorderRadius.circular(8.0),
                          //             child: Image.memory(
                          //               _identifiedFace,
                          //               width: 160,
                          //               height: 160,
                          //             ),
                          //           ),
                          //           const SizedBox(
                          //             height: 5,
                          //           ),
                          //           const Text('Identified')
                          //         ],
                          //       )
                          //     : const SizedBox(height: 1)
                        ],
                      ),
                      Text(
                        _smiling
                            ? 'لبخند تشخیص داده شد'
                            : _recognized
                                ? 'خوش آمدید $_identifiedName'
                                : 'در حال شناسایی',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                          fontFamily: 'Sans',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _recognized && !_smiling
                          ? Text(
                              'لطفا لبخند بزنید',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.black,
                                fontFamily: 'Sans',
                              ),
                            )
                          : const SizedBox(),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // Row(
                      //   children: [
                      //     const SizedBox(
                      //       width: 16,
                      //     ),
                      //     Text(
                      //       'Similarity: $_identifiedSimilarity',
                      //       style: const TextStyle(fontSize: 18),
                      //     )
                      //   ],
                      // ),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // Row(
                      //   children: [
                      //     const SizedBox(
                      //       width: 16,
                      //     ),
                      //     Text(
                      //       'Liveness score: $_identifiedLiveness',
                      //       style: const TextStyle(fontSize: 18),
                      //     )
                      //   ],
                      // ),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // Row(
                      //   children: [
                      //     const SizedBox(
                      //       width: 16,
                      //     ),
                      //     Text(
                      //       'Yaw: $_identifiedYaw',
                      //       style: const TextStyle(fontSize: 18),
                      //     )
                      //   ],
                      // ),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // Row(
                      //   children: [
                      //     const SizedBox(
                      //       width: 16,
                      //     ),
                      //     Text(
                      //       'Roll: $_identifiedRoll',
                      //       style: const TextStyle(fontSize: 18),
                      //     )
                      //   ],
                      // ),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // Row(
                      //   children: [
                      //     const SizedBox(
                      //       width: 16,
                      //     ),
                      //     Text(
                      //       'Pitch: $_identifiedPitch',
                      //       style: const TextStyle(fontSize: 18),
                      //     )
                      //   ],
                      // ),
                      // const SizedBox(height: 16),
                      // ElevatedButton(
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      //   ),
                      //   onPressed: () => faceRecognitionStart(),
                      //   child: const Text('Try again'),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaceDetectionView extends StatefulWidget implements FaceDetectionInterface {
  FaceRecognitionViewState faceRecognitionViewState;

  FaceDetectionView({super.key, required this.faceRecognitionViewState});

  @override
  Future<void> onFaceDetected(faces) async {
    await faceRecognitionViewState.onFaceDetected(faces);
  }

  @override
  State<StatefulWidget> createState() => _FaceDetectionViewState();
}

class _FaceDetectionViewState extends State<FaceDetectionView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'facedetectionview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else {
      return UiKitView(
        viewType: 'facedetectionview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
  }

  void _onPlatformViewCreated(int id) async {
    final prefs = await SharedPreferences.getInstance();
    var cameraLens = prefs.getInt("camera_lens");

    widget.faceRecognitionViewState.faceDetectionViewController = FaceDetectionViewController(id, widget);

    await widget.faceRecognitionViewState.faceDetectionViewController?.initHandler();

    int? livenessLevel = prefs.getInt("liveness_level");
    await widget.faceRecognitionViewState._facesdkPlugin.setParam({'check_liveness_level': livenessLevel ?? 0});

    await widget.faceRecognitionViewState.faceDetectionViewController?.startCamera(cameraLens ?? 1);
  }
}

class FacePainter extends CustomPainter {
  dynamic faces;
  double livenessThreshold;
  FacePainter({required this.faces, required this.livenessThreshold});

  @override
  void paint(Canvas canvas, Size size) {
    if (faces != null) {
      var paint = Paint();
      paint.color = const Color.fromARGB(0xff, 0xff, 0, 0);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;

      for (var face in faces) {
        double xScale = face['frameWidth'] / size.width;
        double yScale = face['frameHeight'] / size.height;

        String title = "";
        Color color = const Color.fromARGB(0xff, 0xff, 0, 0);
        if (face['liveness'] < livenessThreshold) {
          color = const Color.fromARGB(0xff, 0xff, 0, 0);
          title = "Spoof" + face['liveness'].toString();
        } else {
          color = const Color.fromARGB(0xff, 0, 0xff, 0);
          title = "Real " + face['liveness'].toString();
        }

        TextSpan span = TextSpan(style: TextStyle(color: color, fontSize: 20), text: title);
        TextPainter tp = TextPainter(text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(face['x1'] / xScale, face['y1'] / yScale - 30));

        paint.color = color;
        canvas.drawRect(
            Offset(face['x1'] / xScale, face['y1'] / yScale) &
                Size((face['x2'] - face['x1']) / xScale, (face['y2'] - face['y1']) / yScale),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
