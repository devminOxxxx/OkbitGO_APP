import 'package:flutter/material.dart';
import '../models/timer_model.dart';
import '../models/timer_record.dart';
import '../services/timer_storage_service.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';

class TimerProvider extends ChangeNotifier {
  final TimerStorageService _storageService;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // 타이머 상태
  final Map<String, bool> _isRunning = {
    '공부': false,
    '운동': false,
    '취미': false,
    '기타': false,
  };

  final Map<String, int> _durations = {
    '공부': 0,
    '운동': 0,
    '취미': 0,
    '기타': 0,
  };

  final Map<String, Timer?> _timers = {
    '공부': null,
    '운동': null,
    '취미': null,
    '기타': null,
  };

  // 선택된 카테고리와 타이머 설정
  String _selectedCategory = '공부';
  int _targetDuration = 30 * 60 * 1000; // 30분을 밀리초로 변환
  int _remainingDuration = 30 * 60 * 1000;
  Timer? _countdownTimer;
  bool _isCountdownRunning = false;

  // 데이터 로딩 상태
  bool _isLoading = false;
  String? _error;

  // 랭킹 데이터
  List<DailyTimerSummary> _dailySummaries = [];

  List<TimerRecord> _records = [];
  final _uuid = Uuid();
  String _userId = ''; // 사용자 ID

  // 캐싱 관련 변수
  DateTime _lastSyncTime = DateTime.now();
  bool _needsSync = false;
  Timer? _syncTimer;

  // 배치 처리를 위한 변수
  final List<TimerRecord> _pendingRecords = [];
  final int _batchSize = 10;
  final Duration _batchInterval = const Duration(seconds: 30);
  Timer? _batchTimer;

  TimerProvider(this._storageService) {
    loadTimerRecords();
    _setupSyncTimer();
    _setupBatchTimer();
  }

  // Getters
  Map<String, int> get durations => _durations;
  String get selectedCategory => _selectedCategory;
  int get targetDuration => _targetDuration;
  int get remainingDuration => _remainingDuration;
  bool get isCountdownRunning => _isCountdownRunning;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DailyTimerSummary> get dailySummaries => _dailySummaries;
  Map<String, bool> get isRunning => _isRunning;
  List<TimerRecord> get records => _records;

  // 사용자 ID 설정
  void setUserId(String userId) {
    _userId = userId;
    loadTimerRecords();
  }

  // 주기적인 동기화 타이머 설정
  void _setupSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_needsSync) {
        _syncWithFirebase();
      }
    });
  }

  // 배치 처리 타이머 설정
  void _setupBatchTimer() {
    _batchTimer = Timer.periodic(_batchInterval, (timer) {
      _processPendingRecords();
    });
  }

  // Firebase와 동기화
  Future<void> _syncWithFirebase() async {
    if (!_needsSync || _userId.isEmpty) return;

    try {
      // 마지막 동기화 이후의 레코드만 가져오기
      final snapshot = await _database
          .child('timer_records')
          .orderByChild('userId')
          .equalTo(_userId)
          .startAt(_lastSyncTime.millisecondsSinceEpoch)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        final List<TimerRecord> newRecords = [];

        data.forEach((key, value) {
          final record =
              TimerRecord.fromFirebase(Map<String, dynamic>.from(value), key);
          if (!_records.any((r) => r.id == record.id)) {
            newRecords.add(record);
          }
        });

        if (newRecords.isNotEmpty) {
          _records.addAll(newRecords);
          await _storageService.saveRecords(_records);
          notifyListeners();
        }
      }

      _lastSyncTime = DateTime.now();
      _needsSync = false;
    } catch (e) {
      _error = '데이터 동기화에 실패했습니다: $e';
      notifyListeners();
    }
  }

  // 보류 중인 레코드 처리 (배치 처리)
  Future<void> _processPendingRecords() async {
    if (_pendingRecords.isEmpty) return;

    try {
      final batch = _pendingRecords.take(_batchSize).toList();
      _pendingRecords.removeRange(
          0,
          batch.length > _pendingRecords.length
              ? _pendingRecords.length
              : batch.length);

      // Firebase에 배치로 저장
      final updates = <String, dynamic>{};
      for (final record in batch) {
        final recordRef = _database.child('timer_records').push();
        final recordId = recordRef.key!;
        final recordWithId = record.copyWith(id: recordId);
        updates['/timer_records/$recordId'] = recordWithId.toJson();
      }

      await _database.update(updates);

      // 로컬 저장소에도 저장
      _records.addAll(batch);
      await _storageService.saveRecords(_records);

      // 일일 요약 데이터 업데이트
      await _updateDailySummaries();

      notifyListeners();
    } catch (e) {
      _error = '배치 처리에 실패했습니다: $e';
      notifyListeners();
    }
  }

  // 데이터 로딩
  Future<void> loadTimerRecords() async {
    if (_userId.isEmpty) return;

    _setLoading(true);
    try {
      // 로컬 저장소에서 레코드 로드
      _records = await _storageService.getTimerRecords();

      // Firebase에서 최신 데이터 로드
      try {
        final snapshot = await _database
            .child('timer_records')
            .orderByChild('userId')
            .equalTo(_userId)
            .get();

        if (snapshot.exists) {
          final Map<dynamic, dynamic> data =
              snapshot.value as Map<dynamic, dynamic>;
          final List<TimerRecord> firebaseRecords = [];

          data.forEach((key, value) {
            try {
              final record = TimerRecord.fromFirebase(
                  Map<String, dynamic>.from(value), key);
              firebaseRecords.add(record);
            } catch (e) {
              debugPrint('레코드 파싱 오류: $e');
            }
          });

          // 로컬 데이터와 병합
          final Map<String, TimerRecord> recordMap = {};

          // 로컬 레코드 추가
          for (final record in _records) {
            recordMap[record.id] = record;
          }

          // Firebase 레코드 추가 (중복 시 덮어쓰기)
          for (final record in firebaseRecords) {
            recordMap[record.id] = record;
          }

          _records = recordMap.values.toList();
          await _storageService.saveRecords(_records);
        }
      } catch (e) {
        debugPrint('Firebase 데이터 로드 오류: $e');
        // Firebase 로드 실패 시 로컬 데이터만 사용
      }

      // 오늘의 타이머 데이터 계산
      await _loadData();

      _error = null;
    } catch (e) {
      _error = '타이머 데이터를 불러오는 중 오류가 발생했습니다: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  // 데이터 로딩
  Future<void> _loadData() async {
    _setLoading(true);
    try {
      // 오늘의 타이머 데이터 로드
      final today = DateTime.now();
      final dailyTotals = await _getDailyTotalsByCategory(today);

      // 카테고리별 시간 설정
      for (final category in _durations.keys) {
        _durations[category] = dailyTotals[category] ?? 0;
      }

      // 일일 요약 데이터 로드
      _dailySummaries = await _getDailySummaries();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 카테고리 선택
  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // 타이머 목표 시간 설정 (밀리초 단위)
  void setTargetDuration(int duration) {
    _targetDuration = duration;
    if (!_isCountdownRunning) {
      _remainingDuration = duration;
    }
    notifyListeners();
  }

  // 카운트다운 타이머 시작
  void startTimer() {
    if (_isCountdownRunning) return;

    _isCountdownRunning = true;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingDuration > 0) {
        _remainingDuration = _remainingDuration - 1000; // 1초 = 1000 밀리초
        _durations[_selectedCategory] =
            (_durations[_selectedCategory] ?? 0) + 1000;
        notifyListeners();
      } else {
        stopTimer();
      }
    });

    _isRunning[_selectedCategory] = true;
    notifyListeners();
  }

  // 카운트다운 타이머 정지
  void stopTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isCountdownRunning = false;
    _isRunning[_selectedCategory] = false;

    // 타이머 기록 저장
    _saveTimerRecord();

    notifyListeners();
  }

  // 타이머 리셋
  void resetTimer() {
    stopTimer();
    _remainingDuration = _targetDuration;
    notifyListeners();
  }

  // 타이머 기록 저장
  Future<void> _saveTimerRecord() async {
    if ((_durations[_selectedCategory] ?? 0) > 0 && _userId.isNotEmpty) {
      try {
        final record = TimerRecord(
          id: _uuid.v4(),
          category: _selectedCategory,
          duration: _durations[_selectedCategory] ?? 0,
          date: DateTime.now(),
          userId: _userId,
        );

        // 보류 중인 레코드에 추가 (배치 처리를 위해)
        _pendingRecords.add(record);

        // 즉시 로컬에 저장
        _records.add(record);
        await _storageService.saveRecords(_records);

        // 일일 요약 데이터 업데이트
        await _updateDailySummary(record);

        // 동기화 필요 표시
        _needsSync = true;

        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
      }
    }
  }

  // 데이터 새로고침
  Future<void> refreshData() async {
    await _loadData();
    _syncWithFirebase();
  }

  // 특정 카테고리의 타이머 기록 가져오기
  List<TimerRecord> getRecordsByCategory(String category) {
    return _records.where((record) => record.category == category).toList();
  }

  // 타이머 기록 추가하기
  Future<void> addTimerRecord({
    required String category,
    required int duration,
    List<int> laps = const [],
  }) async {
    if (_userId.isEmpty) {
      _error = '사용자 ID가 설정되지 않았습니다.';
      notifyListeners();
      return;
    }

    final record = TimerRecord(
      id: _uuid.v4(),
      category: category,
      duration: duration,
      date: DateTime.now(),
      userId: _userId,
      laps: laps,
    );

    try {
      // 보류 중인 레코드에 추가 (배치 처리를 위해)
      _pendingRecords.add(record);

      // 즉시 로컬에 저장
      _records.add(record);
      await _storageService.saveRecords(_records);

      // 일일 요약 데이터 업데이트
      await _updateDailySummary(record);

      // 동기화 필요 표시
      _needsSync = true;

      notifyListeners();
    } catch (e) {
      _error = '타이머 기록을 저장하는데 실패했습니다: $e';
      notifyListeners();
    }
  }

  // 타이머 기록 업데이트하기
  Future<void> updateTimerRecord(TimerRecord updatedRecord) async {
    try {
      // Firebase에 업데이트
      if (_userId.isNotEmpty) {
        await _database
            .child('timer_records')
            .child(updatedRecord.id)
            .update(updatedRecord.toJson());
      }

      // 로컬 저장소에 업데이트
      final index =
          _records.indexWhere((record) => record.id == updatedRecord.id);
      if (index != -1) {
        _records[index] = updatedRecord;
        await _storageService.saveRecords(_records);

        // 일일 요약 데이터 업데이트
        await _updateDailySummaries();

        notifyListeners();
      }
    } catch (e) {
      _error = '타이머 기록을 업데이트하는데 실패했습니다: $e';
      notifyListeners();
    }
  }

  // 타이머 기록 삭제하기
  Future<void> deleteTimerRecord(String id) async {
    try {
      // Firebase에서 삭제
      if (_userId.isNotEmpty) {
        await _database.child('timer_records').child(id).remove();
      }

      // 로컬 저장소에서 삭제
      _records.removeWhere((record) => record.id == id);
      await _storageService.saveRecords(_records);

      // 일일 요약 데이터 업데이트
      await _updateDailySummaries();

      notifyListeners();
    } catch (e) {
      _error = '타이머 기록을 삭제하는데 실패했습니다: $e';
      notifyListeners();
    }
  }

  // 오늘의 총 시간 계산하기 (밀리초 단위)
  int getTotalDurationToday(String category) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _records
        .where((record) =>
            record.category == category &&
            DateTime(record.date.year, record.date.month, record.date.day)
                .isAtSameMomentAs(today) &&
            record.userId == _userId)
        .fold<int>(0, (int sum, record) => sum + record.duration);
  }

  // 일일 요약 데이터 업데이트
  Future<void> _updateDailySummary(TimerRecord record) async {
    try {
      final dateKey =
          '${record.date.year}-${record.date.month}-${record.date.day}';

      // Firebase에 업데이트
      if (_userId.isNotEmpty) {
        final summaryRef = _database
            .child('daily_summaries')
            .child(record.userId)
            .child(dateKey)
            .child(record.category);

        final snapshot = await summaryRef.get();

        if (snapshot.exists) {
          // 기존 요약 데이터 업데이트
          final currentTotal = (snapshot.value
                  as Map<dynamic, dynamic>)['totalDuration'] as int? ??
              0;
          await summaryRef.update({
            'totalDuration': currentTotal + record.duration,
          });
        } else {
          // 새 요약 데이터 추가
          await summaryRef.set({
            'userId': record.userId,
            'category': record.category,
            'totalDuration': record.duration,
            'date': record.date.millisecondsSinceEpoch,
          });
        }
      }

      // 로컬 요약 데이터 업데이트
      final summaries = await _storageService.getDailySummaries();
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

      await _storageService.saveDailySummaries(summaries);
      _dailySummaries = summaries;
    } catch (e) {
      _error = '일일 요약 데이터를 업데이트하는데 실패했습니다: $e';
    }
  }

  // 모든 일일 요약 데이터 업데이트
  Future<void> _updateDailySummaries() async {
    try {
      // 레코드를 날짜, 사용자 ID, 카테고리별로 그룹화하여 합산
      final Map<String, Map<String, Map<String, int>>> dailyTotals = {};

      for (final record in _records) {
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

      // 로컬 저장소에 저장
      await _storageService.saveDailySummaries(summaries);
      _dailySummaries = summaries;

      // Firebase에 저장 (사용자 ID가 있는 경우)
      if (_userId.isNotEmpty) {
        // 기존 데이터 삭제
        await _database.child('daily_summaries').child(_userId).remove();

        // 새 데이터 저장
        final updates = <String, dynamic>{};

        dailyTotals.forEach((dateKey, userMap) {
          final parts = dateKey.split('-');
          final date = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

          userMap.forEach((userId, categoryMap) {
            if (userId == _userId) {
              categoryMap.forEach((category, totalDuration) {
                updates['/daily_summaries/$userId/$dateKey/$category'] = {
                  'userId': userId,
                  'category': category,
                  'totalDuration': totalDuration,
                  'date': date.millisecondsSinceEpoch,
                };
              });
            }
          });
        });

        if (updates.isNotEmpty) {
          await _database.update(updates);
        }
      }
    } catch (e) {
      _error = '일일 요약 데이터를 업데이트하는데 실패했습니다: $e';
    }
  }

  // 일일 요약 데이터 가져오기
  Future<List<DailyTimerSummary>> _getDailySummaries() async {
    try {
      final List<DailyTimerSummary> summaries = [];
      final Map<String, Map<String, int>> dailyData = {};

      // 최근 7일 데이터만 계산
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      for (final record in _records) {
        if (record.userId == _userId && record.date.isAfter(sevenDaysAgo)) {
          final dateStr =
              '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';

          dailyData[dateStr] ??= {
            '공부': 0,
            '운동': 0,
            '취미': 0,
            '기타': 0,
          };

          dailyData[dateStr]![record.category] =
              (dailyData[dateStr]![record.category] ?? 0) + record.duration;
        }
      }

      dailyData.forEach((date, categoryData) {
        final parts = date.split('-');
        final dateObj = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

        summaries.add(DailyTimerSummary(
          userId: _userId,
          category: '공부',
          totalDuration: categoryData['공부'] ?? 0,
          date: dateObj,
        ));

        summaries.add(DailyTimerSummary(
          userId: _userId,
          category: '운동',
          totalDuration: categoryData['운동'] ?? 0,
          date: dateObj,
        ));

        summaries.add(DailyTimerSummary(
          userId: _userId,
          category: '취미',
          totalDuration: categoryData['취미'] ?? 0,
          date: dateObj,
        ));

        summaries.add(DailyTimerSummary(
          userId: _userId,
          category: '기타',
          totalDuration: categoryData['기타'] ?? 0,
          date: dateObj,
        ));
      });

      // 날짜순으로 정렬
      summaries.sort((a, b) => a.date.compareTo(b.date));

      return summaries;
    } catch (e) {
      debugPrint('일일 요약 데이터 계산 오류: $e');
      return [];
    }
  }

  // 카테고리별 오늘의 총 시간 가져오기
  Future<Map<String, int>> _getDailyTotalsByCategory(DateTime date) async {
    try {
      final Map<String, int> result = {
        '공부': 0,
        '운동': 0,
        '취미': 0,
        '기타': 0,
      };

      if (_records.isEmpty) return result;

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      for (final record in _records) {
        if (record.userId == _userId &&
            record.date.isAfter(startOfDay) &&
            record.date.isBefore(endOfDay)) {
          result[record.category] =
              (result[record.category] ?? 0) + record.duration;
        }
      }

      return result;
    } catch (e) {
      debugPrint('일일 총계 계산 오류: $e');
      return {
        '공부': 0,
        '운동': 0,
        '취미': 0,
        '기타': 0,
      };
    }
  }

  @override
  void dispose() {
    // 모든 타이머 정리
    _countdownTimer?.cancel();
    for (final timer in _timers.values) {
      timer?.cancel();
    }
    _syncTimer?.cancel();
    _batchTimer?.cancel();

    // 보류 중인 레코드 처리
    if (_pendingRecords.isNotEmpty) {
      _processPendingRecords();
    }

    super.dispose();
  }
}
