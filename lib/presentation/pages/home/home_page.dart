import 'package:facerecognition_flutter/facedetectionview.dart';
import 'package:facerecognition_flutter/personview.dart';
import 'package:facerecognition_flutter/presentation/controllers/home/home_controller.dart';
import 'package:facerecognition_flutter/settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        title: const Text(
          'تایمند',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      label: const Text(
                        'افزودن',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        backgroundColor: Colors.blueAccent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                      ),
                      onPressed: controller.enrollPerson,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      label: const Text(
                        'شناسایی',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(
                        Icons.person_search,
                        color: Colors.white,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        backgroundColor: Colors.blueAccent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FaceRecognitionView(
                              personList: controller.personList,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      label: const Text(
                        'تنظیمات',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        backgroundColor: Colors.blueAccent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  children: [
                    PersonView(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Visibility(
                          visible: controller.visibleWarning,
                          child: Container(
                            width: double.infinity,
                            height: 40,
                            color: Colors.redAccent,
                            child: Center(
                              child: Text(
                                controller.warningState,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
