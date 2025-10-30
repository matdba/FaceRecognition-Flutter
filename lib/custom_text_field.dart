import 'package:facerecognition_flutter/app/app_colors.dart';
import 'package:facerecognition_flutter/custom_text_editing_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class CustomTextField extends StatelessWidget {
  final CustomTextEditingController textEditingController;
  final TextInputType keyboardType;
  final bool hasButton;
  final bool enabled;
  final int length;
  final List<TextInputFormatter>? textInputFormatter;
  final int minLines;
  final bool isSeRagham;
  final IconData prefixIcon;
  final bool hidden;
  final bool englishNumber;
  final bool hasCounter;

  const CustomTextField({
    super.key,
    required this.keyboardType,
    required this.textEditingController,
    required this.prefixIcon,
    required this.length,
    this.hasButton = false,
    this.enabled = true,
    this.textInputFormatter,
    this.minLines = 1,
    this.isSeRagham = false,
    this.hidden = false,
    this.englishNumber = false,
    this.hasCounter = true,
  });

  @override
  Widget build(BuildContext context) {
    textEditingController.setEmptyStatus();
    return Obx(
      () => Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            textEditingController.errorText.value = '';
          }
        },
        child: SizedBox(
          height: 80,
          child: TextFormField(
            keyboardType: keyboardType,
            readOnly: !enabled,
            enableInteractiveSelection: enabled,
            maxLength: length,
            inputFormatters: textInputFormatter,
            canRequestFocus: enabled,
            minLines: minLines,
            maxLines: minLines,
            controller: textEditingController.controller,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              fontFamily: !englishNumber ? 'SansFaNum' : null,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            cursorColor: AppColors.primaryLight,
            decoration: InputDecoration(
              isCollapsed: true,
              labelText: textEditingController.fieldName,
              isDense: true,
              fillColor: enabled ? AppColors.white : AppColors.tertiary.withValues(alpha: .2),
              filled: true,
              // hintText: textEditingController.fieldName,
              hintStyle: const TextStyle(
                fontFamily: 'Sans',
                fontSize: 14,
                color: AppColors.black,
                fontWeight: FontWeight.w500,
              ),
              errorMaxLines: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.tertiary,
                fontWeight: FontWeight.normal,
              ),
              errorText: textEditingController.errorText.value != '' ? textEditingController.errorText.value : null,
              errorStyle: const TextStyle(
                fontSize: 11,
                color: Colors.redAccent,
                fontFamily: 'Sans',
                fontWeight: FontWeight.w500,
              ),
              // counter: hasCounter ? null : const Text(''),
              counter: null,
              counterStyle: const TextStyle(
                fontSize: 0,
                color: AppColors.black,
                fontFamily: 'SansFaNum',
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.only(top: 16, bottom: 16, left: 32, right: 0),
              // contentPadding: const EdgeInsets.zero,
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade50, width: 0),
                borderRadius: BorderRadius.circular(30),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.tertiary.withValues(alpha: .2), width: 1),
                borderRadius: BorderRadius.circular(30),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
                borderRadius: BorderRadius.circular(30),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                borderRadius: BorderRadius.circular(30),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
                borderRadius: BorderRadius.circular(30),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      prefixIcon,
                      size: 24,
                      color: AppColors.tertiary,
                    ),
                    // const SizedBox(width: 12),
                    // Container(
                    //   height: 32,
                    //   width: 1,
                    //   color: AppColors.tertiary.withOpacity(.3),
                    // )
                  ],
                ),
              ),
              // suffixIcon: textEditingController.controller.text.length == length
              //     ? Row(
              //         mainAxisSize: MainAxisSize.min,
              //         mainAxisAlignment: MainAxisAlignment.end,
              //         children: [
              //           Container(
              //             height: 16,
              //             width: 16,
              //             decoration: BoxDecoration(
              //               color: Colors.greenAccent.shade400,
              //               borderRadius: BorderRadius.circular(8),
              //             ),
              //             child: Icon(
              //               SolarIconsBold.checkCircle,
              //               size: 12,
              //             ),
              //           ),
              //           const SizedBox(width: 8),
              //         ],
              //       )
              //     : const const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }
}
