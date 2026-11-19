import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeType _themeType = ThemeType.system;
  ThemeData _themeData = AppTheme.getDarkTheme();
  bool _isDarkMode = true;

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeType get themeType => _themeType;
  ThemeData get themeData => _themeData;
  bool get isDarkMode => _isDarkMode;

  // 테마 설정 불러오기
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_preference') ?? 'system';

    switch (themeString) {
      case 'dark':
        setTheme(ThemeType.dark);
        break;
      case 'light':
        setTheme(ThemeType.light);
        break;
      case 'system':
      default:
        setTheme(ThemeType.system);
        break;
    }
  }

  // 테마 설정 저장
  Future<void> _saveThemePreference(ThemeType themeType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_preference', themeType.name);
  }

  // 시스템 테마 확인
  bool _getSystemTheme() {
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  // 테마 설정
  void setTheme(ThemeType themeType) {
    _themeType = themeType;

    switch (themeType) {
      case ThemeType.dark:
        _themeData = AppTheme.getDarkTheme();
        _isDarkMode = true;
        break;
      case ThemeType.light:
        _themeData = AppTheme.getLightTheme();
        _isDarkMode = false;
        break;
      case ThemeType.system:
        final isDark = _getSystemTheme();
        _themeData =
            isDark ? AppTheme.getDarkTheme() : AppTheme.getLightTheme();
        _isDarkMode = isDark;
        break;
    }

    _saveThemePreference(themeType);
    notifyListeners();
  }
}
