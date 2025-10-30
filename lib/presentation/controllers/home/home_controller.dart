import 'dart:io' show Platform;
import 'dart:developer';

import 'package:facerecognition_flutter/app/app_colors.dart';
import 'package:facerecognition_flutter/custom_text_editing_controller.dart';
import 'package:facerecognition_flutter/custom_text_field.dart';
import 'package:facerecognition_flutter/dialog_widget.dart';
import 'package:facerecognition_flutter/person.dart';
import 'package:facerecognition_flutter/settings.dart';
import 'package:facesdk_plugin/facesdk_plugin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';

class HomeController extends GetxController {
  var nameTextEditingController = CustomTextEditingController(fieldName: 'نام', textFieldType: TextFieldType.text);
  String warningState = "";
  bool visibleWarning = false;

  final _facesdkPlugin = FacesdkPlugin();
  // final String title;
  var personList = RxList<Person>();

  @override
  void onInit() async {
    super.onInit();
    int facepluginState = -1;

    try {
      if (Platform.isAndroid) {
        await _facesdkPlugin
            .setActivation("j63rQnZifPT82LEDGFa+wzorKx+M55JQlNr+S0bFfvMULrNYt+UEWIsa11V/Wk1bU9Srti0/FQqp"
                "UczeCxFtiEcABmZGuTzNd27XnwXHUSIMaFOkrpNyNE4MHb7HBm5kU/0J/SAMfybICCWyFajuZ4fL"
                "agozJV5DPKj22oFVaueWMjO/9fMvcps4u1AIiHH2rjP4mEYfiAE8nhHBa1Ou3u/WkXj6jdDafyJo"
                "AFtQHYJYKDU+hcbtCZ3P1f8y1JB5JxOf92ItK4euAt6/OFG9jGfKpo/Fs2mAgwxH3HoWMLJQ16Iy"
                "u2K6boMyDxRQtBJFTiktuJ+ltlay+dVqIi3Jpg==")
            .then((value) => facepluginState = value ?? -1);
      } else {
        await _facesdkPlugin
            .setActivation("nWsdDhTp12Ay5yAm4cHGqx2rfEv0U+Wyq/tDPopH2yz6RqyKmRU+eovPeDcAp3T3IJJYm2LbPSEz"
                "+e+YlQ4hz+1n8BNlh2gHo+UTVll40OEWkZ0VyxkhszsKN+3UIdNXGaQ6QL0lQunTwfamWuDNx7Ss"
                "efK/3IojqJAF0Bv7spdll3sfhE1IO/m7OyDcrbl5hkT9pFhFA/iCGARcCuCLk4A6r3mLkK57be4r"
                "T52DKtyutnu0PDTzPeaOVZRJdF0eifYXNvhE41CLGiAWwfjqOQOHfKdunXMDqF17s+LFLWwkeNAD"
                "PKMT+F/kRCjnTcC8WPX3bgNzyUBGsFw9fcneKA==")
            .then((value) => facepluginState = value ?? -1);
      }

      if (facepluginState == 0) {
        await _facesdkPlugin.init().then((value) => facepluginState = value ?? -1);
      }
    } catch (e) {}

    personList.value = await loadAllPersons();
    await SettingsPageState.initSettings();

    final prefs = await SharedPreferences.getInstance();
    int? livenessLevel = prefs.getInt("liveness_level");

    try {
      await _facesdkPlugin.setParam({'check_liveness_level': livenessLevel ?? 0});
    } catch (e) {}

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    // if (!mounted) return;

    if (facepluginState == -1) {
      warningState = "Invalid license!";
      visibleWarning = true;
    } else if (facepluginState == -2) {
      warningState = "License expired!";
      visibleWarning = true;
    } else if (facepluginState == -3) {
      warningState = "Invalid license!";
      visibleWarning = true;
    } else if (facepluginState == -4) {
      warningState = "No activated!";
      visibleWarning = true;
    } else if (facepluginState == -5) {
      warningState = "Init error!";
      visibleWarning = true;
    }

    warningState = warningState;
    visibleWarning = visibleWarning;
  }

  Future<Database> createDB() async {
    final database = openDatabase(
      join(await getDatabasesPath(), 'person.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE person(name text, identifier text, faceJpg blob, templates blob)',
        );
      },
      version: 1,
    );

    return database;
  }

  Future<List<Person>> loadAllPersons() async {
    final db = await createDB();

    final List<Map<String, dynamic>> maps = await db.query('person');

    log('maps length: ${maps.length}');

    return List.generate(maps.length, (i) {
      return Person.fromMap(maps[i]);
    });
  }

  Future<int> insertPerson(Person person) async {
    final db = await createDB();

    int id = await db.insert(
      'person',
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    log('NEW ID: $id');

    personList.add(person);
    return id;
  }

  Future<void> deleteAllPerson() async {
    final db = await createDB();
    await db.delete('person');

    personList.clear();

    Fluttertoast.showToast(
      msg: "All person deleted!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> deletePerson(String identifier) async {
    final db = await createDB();
    await db.delete('person', where: 'identifier=?', whereArgs: [identifier]);

    personList.removeWhere((person) => person.identifier == identifier);

    Fluttertoast.showToast(
        msg: "Person removed!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  Future enrollPerson() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      var rotatedImage = await FlutterExifRotation.rotateImage(path: image.path);

      final faces = await _facesdkPlugin.extractFaces(rotatedImage.path);

      Get.bottomSheet(
        backgroundColor: AppColors.background,
        DialogWidget(
          title: 'نام شخص',
          buttonTitle: 'افزودن',
          iconColor: AppColors.primaryLight,
          buttonColor: AppColors.primaryLight,
          icon: SolarIconsOutline.userPlus,
          loading: false,
          content: CustomTextField(
            textEditingController: nameTextEditingController,
            keyboardType: TextInputType.text,
            prefixIcon: SolarIconsOutline.user,
            length: 30,
          ),
          onPressed: () {
            for (var face in faces) {
              Person person = Person(
                identifier: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameTextEditingController.controller.text.trim(),
                faceJpg: face['faceJpg'],
                templates: face['templates'],
              );
              insertPerson(person);
              Get.back();
            }
            if (faces.length == 0) {
              Fluttertoast.showToast(
                  msg: "No face detected!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
            } else {
              Fluttertoast.showToast(
                  msg: "Person enrolled!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
            }
          },
        ),
      );
    } catch (e) {
      return;
    }
  }
}
