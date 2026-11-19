import 'package:flutter/material.dart';
import 'constants.dart';

enum ThemeType {
  dark,
  light,
  system,
}

class AppTheme {
  static ThemeData get darkTheme => getDarkTheme();

  static ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBackgroundColor,
      primaryColor: kAccentColor,
      fontFamily: kDefaultFontFamily,
      colorScheme: const ColorScheme.dark(
        primary: kAccentColor,
        secondary: Colors.blueAccent,
        surface: kSurfaceColor,
        error: Colors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: kTextColor,
          fontSize: kFontSizeXXLarge,
          fontWeight: kFontWeightSemiBold,
          fontFamily: kDefaultFontFamily,
        ),
        iconTheme: IconThemeData(color: kTextColor),
      ),
      cardTheme: const CardTheme(
        color: kSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kBorderRadius)),
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: kTextColor,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontFamily: kDefaultFontFamily),
        unselectedLabelStyle: TextStyle(fontFamily: kDefaultFontFamily),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kSurfaceColor,
        selectedItemColor: kAccentColor,
        unselectedItemColor: Colors.grey,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: kTextColor, fontFamily: kDefaultFontFamily),
        bodyMedium:
            TextStyle(color: kTextColor, fontFamily: kDefaultFontFamily),
        bodySmall: TextStyle(
            color: kTextSecondaryColor, fontFamily: kDefaultFontFamily),
        titleLarge: TextStyle(
            color: kTextColor,
            fontWeight: kFontWeightBold,
            fontFamily: kDefaultFontFamily),
        titleMedium: TextStyle(
            color: kTextColor,
            fontWeight: kFontWeightBold,
            fontFamily: kDefaultFontFamily),
        titleSmall: TextStyle(
            color: kTextColor,
            fontWeight: kFontWeightBold,
            fontFamily: kDefaultFontFamily),
      ),
      dividerTheme: const DividerThemeData(
        color: kBorderColor,
        thickness: kBorderWidthRegular,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(
            color: kTextSecondaryColor, fontFamily: kDefaultFontFamily),
        hintStyle: TextStyle(
            color: kTextSecondaryColor, fontFamily: kDefaultFontFamily),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: kAccentColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: kTextColor,
          backgroundColor: kAccentColor,
          textStyle: const TextStyle(
            color: kTextColor,
            fontWeight: kFontWeightBold,
            fontFamily: kDefaultFontFamily,
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: kSurfaceColor,
        titleTextStyle: TextStyle(
          color: kTextColor,
          fontSize: kFontSizeXXXLarge,
          fontWeight: kFontWeightBold,
          fontFamily: kDefaultFontFamily,
        ),
        contentTextStyle: TextStyle(
          color: kTextSecondaryColor,
          fontSize: kFontSizeRegular,
          fontFamily: kDefaultFontFamily,
        ),
      ),
    );
  }

  static ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: kLightBackgroundColor,
      primaryColor: kAccentColor,
      fontFamily: kDefaultFontFamily,
      colorScheme: const ColorScheme.light(
        primary: kAccentColor,
        secondary: Colors.blueAccent,
        surface: kLightBackgroundColor,
        error: Colors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kLightBackgroundColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: kLightTextColor,
          fontSize: kFontSizeXXLarge,
          fontWeight: kFontWeightSemiBold,
          fontFamily: kDefaultFontFamily,
        ),
        iconTheme: IconThemeData(color: kLightTextColor),
      ),
      cardTheme: const CardTheme(
        color: kLightBackgroundColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kBorderRadius)),
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: kAccentColor,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontFamily: kDefaultFontFamily),
        unselectedLabelStyle: TextStyle(fontFamily: kDefaultFontFamily),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kLightBackgroundColor,
        selectedItemColor: kAccentColor,
        unselectedItemColor: Colors.grey,
      ),
      textTheme: const TextTheme(
        bodyLarge:
            TextStyle(color: kLightTextColor, fontFamily: kDefaultFontFamily),
        bodyMedium:
            TextStyle(color: kLightTextColor, fontFamily: kDefaultFontFamily),
        bodySmall: TextStyle(
            color: kLightTextSecondaryColor, fontFamily: kDefaultFontFamily),
        titleLarge: TextStyle(
            color: kLightTextColor,
            fontWeight: kFontWeightBold,
            fontFamily: kDefaultFontFamily),
        titleMedium: TextStyle(
            color: kLightTextColor,
            fontWeight: kFontWeightBold,
            fontFamily: kDefaultFontFamily),
        titleSmall: TextStyle(
            color: kLightTextColor,
            fontWeight: kFontWeightBold,
            fontFamily: kDefaultFontFamily),
      ),
      dividerTheme: const DividerThemeData(
        color: kLightBorderColor,
        thickness: kBorderWidthRegular,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(
            color: kLightTextSecondaryColor, fontFamily: kDefaultFontFamily),
        hintStyle: TextStyle(
            color: kLightTextSecondaryColor, fontFamily: kDefaultFontFamily),
        border: OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black26),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: kAccentColor),
        ),
      ),
      canvasColor: kLightBackgroundColor,
      highlightColor: kAccentColor.withValues(alpha: 0.1),
      splashColor: kAccentColor.withValues(alpha: 0.1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: kLightBackgroundColor,
          backgroundColor: kAccentColor,
          textStyle: const TextStyle(
            color: kLightBackgroundColor,
            fontWeight: kFontWeightBold,
            fontFamily: kDefaultFontFamily,
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: kLightBackgroundColor,
        titleTextStyle: TextStyle(
          color: kLightTextColor,
          fontSize: kFontSizeXXXLarge,
          fontWeight: kFontWeightBold,
          fontFamily: kDefaultFontFamily,
        ),
        contentTextStyle: TextStyle(
          color: kLightTextSecondaryColor,
          fontSize: kFontSizeRegular,
          fontFamily: kDefaultFontFamily,
        ),
      ),
    );
  }
}
