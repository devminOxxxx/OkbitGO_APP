import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class CustomSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 다크모드에서는 흰색 배경, 라이트모드에서는 검은색 배경
    final bgColor = backgroundColor ??
        (isDarkMode ? kLightBackgroundColor : kLightTextColor);
    final txtColor =
        textColor ?? (isDarkMode ? kLightTextColor : kLightBackgroundColor);

    final snackBar = SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(
          vertical: kPaddingMedium,
          horizontal: kPaddingLarge,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(kBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: txtColor,
                  fontSize: kFontSizeXLarge,
                  fontWeight: kFontWeightMedium,
                  fontFamily: kDefaultFontFamily,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: const EdgeInsets.all(kPaddingLarge),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      duration: duration,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      duration: duration,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      duration: duration,
    );
  }
}
