import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';

class MealStorageService {
  static const String _mealKey = 'meal_data';
  static const String _lastUpdateKey = 'meal_last_update';

  final SharedPreferences _prefs;

  MealStorageService(this._prefs);

  static Future<MealStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return MealStorageService(prefs);
  }

  // 메뉴 텍스트 정리를 위한 메서드
  String _cleanMenuText(String text) {
    return text
        .replaceAll(RegExp(r'\[.*?\]'), '') // 대괄호와 그 안의 내용 제거
        .replaceAll(RegExp(r'\s+'), ' ') // 연속된 공백을 하나로
        .trim(); // 앞뒤 공백 제거
  }

  Future<void> saveMeals(List<Meal> meals) async {
    try {
      final mealJsonList = meals
          .map((meal) => {
                'date': meal.date,
                'calorie': meal.calorie,
                'menu': meal.menu.map(_cleanMenuText).join('\n'),
              })
          .toList();

      final jsonString = jsonEncode(mealJsonList);
      final success = await _prefs.setString(_mealKey, jsonString);
      if (success) {
        await _prefs.setString(
            _lastUpdateKey, DateTime.now().toIso8601String());
      } else {}
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Meal>> getMeals() async {
    try {
      final mealJsonString = _prefs.getString(_mealKey);
      if (mealJsonString == null) {
        return [];
      }

      final mealJsonList = jsonDecode(mealJsonString) as List;
      final meals = mealJsonList
          .map((json) {
            try {
              final date = json['date']?.toString() ?? '';
              final calorie = json['calorie']?.toString() ?? '';
              final menuStr = json['menu']?.toString() ?? '';

              if (date.isEmpty) {
                return null;
              }

              final menuList = menuStr.isEmpty
                  ? <String>[]
                  : menuStr
                      .split('\n')
                      .map(_cleanMenuText)
                      .where((item) => item.isNotEmpty)
                      .toList();

              return Meal(
                date: date,
                calorie: calorie,
                menu: menuList,
              );
            } catch (e) {
              // 급식 데이터 파싱 오류 발생
              return null;
            }
          })
          .whereType<Meal>()
          .toList();

      return meals;
    } catch (e) {
      return [];
    }
  }

  Future<DateTime?> getLastUpdateTime() async {
    try {
      final lastUpdate = _prefs.getString(_lastUpdateKey);
      return lastUpdate != null ? DateTime.parse(lastUpdate) : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> needsUpdate() async {
    try {
      final lastUpdate = await getLastUpdateTime();
      if (lastUpdate == null) {
        return true;
      }

      final now = DateTime.now();
      final needsUpdate = now.difference(lastUpdate).inHours >= 24;
      return needsUpdate;
    } catch (e) {
      return true;
    }
  }

  Future<void> clearMeals() async {
    try {
      await _prefs.remove(_mealKey);
      await _prefs.remove(_lastUpdateKey);
    } catch (e) {
      rethrow;
    }
  }
}
