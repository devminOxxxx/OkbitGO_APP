import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: kPaddingLarge),
        backgroundColor: backgroundColor ?? kLightBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kSmallBorderRadius),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? kLightTextColor,
          fontFamily: kDefaultFontFamily,
        ),
      ),
    );
  }
}
