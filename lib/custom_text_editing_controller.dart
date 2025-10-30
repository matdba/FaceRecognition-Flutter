import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persian_number_utility/persian_number_utility.dart';

enum TextFieldType { def, phoneNumber, password, text }

enum TextFieldButtonType { clear, hide }

class CustomTextEditingController {
  TextEditingController controller = TextEditingController();
  TextFieldType textFieldType;
  TextFieldButtonType textFieldButtonType;

  RxString errorText = ''.obs;
  RxBool isEmpty = true.obs;
  RxBool isHidden = false.obs;

  bool textFieldButtonTypeAlwaysOn;
  bool exactCharAllowed;
  String fieldName;
  int minimumAllowedChar;

  CustomTextEditingController({
    required this.fieldName,
    this.textFieldType = TextFieldType.def,
    this.textFieldButtonType = TextFieldButtonType.clear,
    this.textFieldButtonTypeAlwaysOn = false,
    this.minimumAllowedChar = 1,
    this.exactCharAllowed = false,
  }) : isHidden = textFieldButtonTypeAlwaysOn.obs;

  void setEmptyStatus() {
    isEmpty(controller.text.isEmpty);
  }

  bool hasError() {
    return errorText.value.isNotEmpty;
  }

  bool isValid() {
    return errorText.value.isEmpty;
  }

  void validateText() {
    switch (textFieldType) {
      case TextFieldType.phoneNumber:
        if (controller.text.isEmpty) {
          errorText('$fieldName نمی تواند خالی باشد');
        } else if (controller.text.length < 11) {
          errorText('$fieldName باید ۱۱ رقمی باشد');
        } else if (!controller.text.isValidIranianMobileNumber()) {
          errorText('$fieldName وارد شده صحیح نیست');
        } else {
          errorText('');
        }

      default:
        if (controller.text.isEmpty) {
          errorText('$fieldName نمی تواند خالی باشد');
        } else if (controller.text.length < minimumAllowedChar) {
          if (exactCharAllowed) {
            errorText('$fieldName باید $minimumAllowedChar ${int.tryParse(controller.text) != null ? "رقمی" : "کاراکتری"} باشد');
          } else {
            errorText(
                '$fieldName نمی تواند کمتر از $minimumAllowedChar ${int.tryParse(controller.text) != null ? "رقم" : "کاراکتر"} باشد');
          }
        } else {
          errorText('');
        }
    }
  }
}
