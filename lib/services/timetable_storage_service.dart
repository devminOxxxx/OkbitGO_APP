import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timetable.dart';

class TimeTableStorageService {
  static const String _timeTableKey = 'timetable_data';
  static const String _lastUpdateKey = 'timetable_last_update';
  static const String _customTimeTableKey = 'custom_timetable_data';

  final SharedPreferences _prefs;

  TimeTableStorageService(this._prefs);

  static Future<TimeTableStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeTableStorageService(prefs);
  }

  // 시간표 데이터 저장
  Future<void> saveTimeTable(TimeTable timeTable) async {
    try {
      final jsonData = jsonEncode(timeTable.toJson());
      await _prefs.setString(_timeTableKey, jsonData);
      await _prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());

      // 개인 맞춤 시간표도 저장 (기본 시간표를 처음 불러올 때)
      final customKey =
          _getCustomTimeTableKey(timeTable.grade, timeTable.classNum);
      if (!_prefs.containsKey(customKey)) {
        await _prefs.setString(customKey, jsonData);
      }
    } catch (e) {
      throw Exception('시간표 데이터 저장 실패: $e');
    }
  }

  // 개인 맞춤 시간표 저장
  Future<void> saveCustomTimeTable(TimeTable timeTable) async {
    try {
      final jsonData = jsonEncode(timeTable.toJson());
      final customKey =
          _getCustomTimeTableKey(timeTable.grade, timeTable.classNum);
      await _prefs.setString(customKey, jsonData);
    } catch (e) {
      throw Exception('개인 맞춤 시간표 데이터 저장 실패: $e');
    }
  }

  // 개인 맞춤 시간표 키 생성
  String _getCustomTimeTableKey(String grade, String classNum) {
    return '${_customTimeTableKey}_${grade}_$classNum';
  }

  // 저장된 시간표 데이터 가져오기 (개인 맞춤 시간표 우선)
  Future<TimeTable?> getTimeTable() async {
    try {
      // 기본 시간표 데이터 가져오기
      final String? jsonData = _prefs.getString(_timeTableKey);
      if (jsonData == null) {
        return null;
      }

      final data = jsonDecode(jsonData);
      final timeTable = TimeTable.fromJson(data);

      // 개인 맞춤 시간표가 있는지 확인
      final customKey =
          _getCustomTimeTableKey(timeTable.grade, timeTable.classNum);
      final String? customJsonData = _prefs.getString(customKey);

      if (customJsonData != null) {
        // 개인 맞춤 시간표 반환
        final customData = jsonDecode(customJsonData);
        return TimeTable.fromJson(customData);
      }

      // 개인 맞춤 시간표가 없으면 기본 시간표 반환
      return timeTable;
    } catch (e) {
      return null;
    }
  }

  // 특정 학년/반의 개인 맞춤 시간표 가져오기
  Future<TimeTable?> getCustomTimeTable(String grade, String classNum) async {
    try {
      final customKey = _getCustomTimeTableKey(grade, classNum);
      final String? customJsonData = _prefs.getString(customKey);

      if (customJsonData != null) {
        final customData = jsonDecode(customJsonData);
        return TimeTable.fromJson(customData);
      }

      // 개인 맞춤 시간표가 없으면 기본 시간표 확인
      final String? jsonData = _prefs.getString(_timeTableKey);
      if (jsonData != null) {
        final data = jsonDecode(jsonData);
        final timeTable = TimeTable.fromJson(data);

        // 요청한 학년/반과 일치하는지 확인
        if (timeTable.grade == grade && timeTable.classNum == classNum) {
          return timeTable;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // 마지막 업데이트 시간 확인
  Future<DateTime?> getLastUpdateTime() async {
    final lastUpdate = _prefs.getString(_lastUpdateKey);
    return lastUpdate != null ? DateTime.parse(lastUpdate) : null;
  }

  // 업데이트가 필요한지 확인 (하루에 한 번)
  Future<bool> needsUpdate() async {
    final lastUpdate = await getLastUpdateTime();
    if (lastUpdate == null) {
      return true;
    }

    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    // 하루가 지났거나 다른 날짜인 경우 업데이트
    if (difference.inDays > 0 ||
        lastUpdate.day != now.day ||
        lastUpdate.month != now.month ||
        lastUpdate.year != now.year) {
      return true;
    }

    return false;
  }

  // 저장된 데이터 삭제
  Future<void> clearTimeTable() async {
    try {
      await _prefs.remove(_timeTableKey);
      await _prefs.remove(_lastUpdateKey);
    } catch (e) {
      throw Exception('시간표 데이터 삭제 실패: $e');
    }
  }

  // 개인 맞춤 시간표 데이터 삭제
  Future<void> clearCustomTimeTable(String grade, String classNum) async {
    try {
      final customKey = _getCustomTimeTableKey(grade, classNum);
      await _prefs.remove(customKey);
    } catch (e) {
      throw Exception('개인 맞춤 시간표 데이터 삭제 실패: $e');
    }
  }
}
