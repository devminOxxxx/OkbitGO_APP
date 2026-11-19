import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timer_record.dart';
import '../models/timer_model.dart';

class TimerStorageService {
  static const String _timerRecordsKey = 'timer_records';
  static const String _dailySummariesKey = 'daily_summaries';
  final SharedPreferences _prefs;

  TimerStorageService._(this._prefs);

  static Future<TimerStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TimerStorageService._(prefs);
  }

  // 모든 타이머 기록 불러오기
  Future<List<TimerRecord>> getTimerRecords() async {
    final recordsJson = _prefs.getStringList(_timerRecordsKey) ?? [];
    return recordsJson
        .map((json) => TimerRecord.fromJson(jsonDecode(json)))
        .toList();
  }

  // 특정 카테고리의 타이머 기록 불러오기
  Future<List<TimerRecord>> getTimerRecordsByCategory(String category) async {
    final records = await getTimerRecords();
    return records.where((record) => record.category == category).toList();
  }

  // 타이머 기록 저장하기
  Future<void> saveTimerRecord(TimerRecord record) async {
    final records = await getTimerRecords();
    records.add(record);
    await saveRecords(records);

    // 일일 요약 데이터 업데이트
    await _updateDailySummary(record);
  }

  // 모든 타이머 기록 저장하기
  Future<void> saveRecords(List<TimerRecord> records) async {
    final recordsJson =
        records.map((record) => jsonEncode(record.toJson())).toList();
    await _prefs.setStringList(_timerRecordsKey, recordsJson);
  }

  // 타이머 기록 업데이트하기
  Future<void> updateTimerRecord(TimerRecord updatedRecord) async {
    final records = await getTimerRecords();
    final index = records.indexWhere((record) => record.id == updatedRecord.id);

    if (index != -1) {
      records[index] = updatedRecord;
      await saveRecords(records);

      // 일일 요약 데이터 업데이트
      await _updateDailySummaries();
    }
  }

  // 타이머 기록 삭제하기
  Future<void> deleteTimerRecord(String id) async {
    final records = await getTimerRecords();
    records.removeWhere((record) => record.id == id);
    await saveRecords(records);

    // 일일 요약 데이터 업데이트
    await _updateDailySummaries();
  }

  // 일일 요약 데이터 업데이트
  Future<void> _updateDailySummary(TimerRecord record) async {
    final summaries = await getDailySummaries();
    final today =
        DateTime(record.date.year, record.date.month, record.date.day);

    // 해당 날짜와 카테고리의 요약 데이터 찾기
    final index = summaries.indexWhere((summary) =>
        summary.category == record.category &&
        DateTime(summary.date.year, summary.date.month, summary.date.day)
            .isAtSameMomentAs(today) &&
        summary.userId == record.userId);

    if (index != -1) {
      // 기존 요약 데이터 업데이트
      final existingSummary = summaries[index];
      summaries[index] = existingSummary.copyWith(
        totalDuration: existingSummary.totalDuration + record.duration,
      );
    } else {
      // 새 요약 데이터 추가
      summaries.add(DailyTimerSummary(
        userId: record.userId,
        category: record.category,
        totalDuration: record.duration,
        date: today,
      ));
    }

    await saveDailySummaries(summaries);
  }

  // 모든 일일 요약 데이터 업데이트
  Future<void> _updateDailySummaries() async {
    final records = await getTimerRecords();
    final Map<String, Map<String, Map<String, int>>> dailyTotals = {};

    // 레코드를 날짜, 사용자 ID, 카테고리별로 그룹화하여 합산
    for (final record in records) {
      final dateKey =
          '${record.date.year}-${record.date.month}-${record.date.day}';

      dailyTotals[dateKey] ??= {};
      dailyTotals[dateKey]![record.userId] ??= {};
      dailyTotals[dateKey]![record.userId]![record.category] ??= 0;
      dailyTotals[dateKey]![record.userId]![record.category] =
          (dailyTotals[dateKey]![record.userId]![record.category] ?? 0) +
              record.duration;
    }

    // 일일 요약 데이터 생성
    final List<DailyTimerSummary> summaries = [];

    dailyTotals.forEach((dateKey, userMap) {
      final parts = dateKey.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      userMap.forEach((userId, categoryMap) {
        categoryMap.forEach((category, totalDuration) {
          summaries.add(DailyTimerSummary(
            userId: userId,
            category: category,
            totalDuration: totalDuration,
            date: date,
          ));
        });
      });
    });

    await saveDailySummaries(summaries);
  }

  // 일일 요약 데이터 저장
  Future<void> saveDailySummaries(List<DailyTimerSummary> summaries) async {
    final summariesJson =
        summaries.map((summary) => jsonEncode(summary.toJson())).toList();
    await _prefs.setStringList(_dailySummariesKey, summariesJson);
  }

  // 일일 요약 데이터 불러오기
  Future<List<DailyTimerSummary>> getDailySummaries() async {
    final summariesJson = _prefs.getStringList(_dailySummariesKey) ?? [];
    return summariesJson
        .map((json) => DailyTimerSummary.fromJson(jsonDecode(json)))
        .toList();
  }

  // 특정 날짜의 카테고리별 총 시간 가져오기
  Future<Map<String, int>> getDailyTotalsByCategory(DateTime date,
      {String? userId}) async {
    final summaries = await getDailySummaries();
    final targetDate = DateTime(date.year, date.month, date.day);

    final Map<String, int> result = {
      '공부': 0,
      '운동': 0,
      '취미': 0,
      '기타': 0,
    };

    for (final summary in summaries) {
      final summaryDate =
          DateTime(summary.date.year, summary.date.month, summary.date.day);

      if (summaryDate.isAtSameMomentAs(targetDate) &&
          (userId == null || summary.userId == userId)) {
        result[summary.category] =
            (result[summary.category] ?? 0) + summary.totalDuration;
      }
    }

    return result;
  }

  // 캐시 지우기
  Future<void> clearCache() async {
    await _prefs.remove(_timerRecordsKey);
    await _prefs.remove(_dailySummariesKey);
  }
}
