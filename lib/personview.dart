import 'package:facerecognition_flutter/presentation/controllers/home/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PersonView extends StatelessWidget {
  const PersonView({super.key});

  deletePerson(String identifier) async {
    Get.find<HomeController>().deletePerson(identifier);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListView.builder(
        itemCount: Get.find<HomeController>().personList.length,
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(
            height: 75,
            child: Card(
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28.0),
                    child: Image.memory(
                      Get.find<HomeController>().personList[index].faceJpg,
                      width: 56,
                      height: 56,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(Get.find<HomeController>().personList[index].name),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => deletePerson(Get.find<HomeController>().personList[index].identifier),
                  ),
                  const SizedBox(width: 8)
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
