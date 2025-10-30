// ignore_for_file: implementation_imports
import 'package:facerecognition_flutter/app/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DialogWidget extends StatelessWidget {
  const DialogWidget({
    super.key,
    required this.title,
    required this.buttonTitle,
    this.cancelButtonText = 'لغو',
    required this.iconColor,
    required this.buttonColor,
    this.buttonTextColor = Colors.black,
    this.hideCancelButton = false,
    required this.icon,
    required this.loading,
    this.content,
    required this.onPressed,
  });

  final String title;
  final String buttonTitle;
  final String cancelButtonText;
  final Color iconColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final IconData icon;
  final bool loading;
  final Widget? content;
  final VoidCallback onPressed;
  final bool hideCancelButton;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                transform: Matrix4.translationValues(0, -24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          width: 3,
                          color: AppColors.background,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 40,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                transform: Matrix4.translationValues(0, -12, 0),
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (content != null) content!,
              if (content != null) const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  if (!hideCancelButton)
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: AppColors.tertiary.withValues(alpha: .1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.tertiary.withValues(alpha: .1),
                              blurRadius: 1,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: IconButton(
                          style: IconButton.styleFrom(
                            highlightColor: AppColors.primary.withValues(alpha: .2),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            Get.back();
                          },
                          icon: Text(
                            cancelButtonText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!hideCancelButton) const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: buttonColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.tertiary.withValues(alpha: .1),
                            blurRadius: 1,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: IconButton(
                        style: IconButton.styleFrom(
                          highlightColor: buttonColor.withValues(alpha: .2),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          onPressed();
                        },
                        icon: Text(
                          buttonTitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: buttonTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
