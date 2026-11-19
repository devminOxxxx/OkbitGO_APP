import 'package:flutter/material.dart';
import '../models/timetable.dart';
import '../services/timetable_service.dart';
import '../services/timetable_storage_service.dart';

class TimeTableProvider with ChangeNotifier {
  final TimeTableService _timeTableService;
  final TimeTableStorageService _storageService;
  TimeTable? _timeTable;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  String? _message;
  String _grade = '3';
  String _classNum = '6';
  String? _userId;

  TimeTableProvider(this._timeTableService, this._storageService) {
    // 초기화를 지연시켜서 사용자 정보가 설정된 후에 실행되도록 함
    // _initializeTimeTable();
  }

  void _initializeTimeTable() async {
    try {
      _isLoading = true;
      _message = '로컬 저장소에서 시간표 데이터를 불러오는 중...';
      notifyListeners();

      // 로컬 저장소에서 데이터 로드
      final localData = await _storageService.getTimeTable();
      if (localData != null) {
        _timeTable = localData;
        _grade = localData.grade;
        _classNum = localData.classNum;
        _message = '로컬 저장소에서 시간표 데이터 로드 완료';
        notifyListeners();
      }

      // 업데이트가 필요한지 확인
      if (await _storageService.needsUpdate()) {
        await fetchTimeTable(forceRefresh: true);
      } else {
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _message = '시간표 초기화 중 오류가 발생했습니다.';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Getters
  TimeTable? get timeTable => _timeTable;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get message => _message;
  String get grade => _grade;
  String get classNum => _classNum;
  String? get userId => _userId;

  // Setters
  void setGrade(String grade) {
    print('🔧 학년 설정 시도: $_grade → $grade');
    if (_grade != grade) {
      _grade = grade;
      print('✅ 학년 설정 완료: $_grade');
      notifyListeners();
    } else {
      print('⚠️ 학년 동일하여 변경하지 않음: $_grade');
    }
  }

  void setClassNum(String classNum) {
    print('🔧 반 설정 시도: $_classNum → $classNum');
    if (_classNum != classNum) {
      _classNum = classNum;
      print('✅ 반 설정 완료: $_classNum');
      notifyListeners();
    } else {
      print('⚠️ 반 동일하여 변경하지 않음: $_classNum');
    }
  }

  void setUserId(String? userId) {
    print('🔧 사용자 ID 설정: $_userId → $userId');
    _userId = userId;
    print('✅ 사용자 ID 설정 완료: $_userId');
  }

  void clearError() {
    _error = null;
    _message = null;
    notifyListeners();
  }

  // 시간표 데이터 가져오기
  Future<void> fetchTimeTable({bool forceRefresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      _message = '시간표를 불러오는 중입니다...';
      notifyListeners();

      // 1. 개인 맞춤 시간표 확인
      final customTimeTable =
          await _storageService.getCustomTimeTable(_grade, _classNum);
      if (customTimeTable != null && !forceRefresh) {
        _timeTable = customTimeTable;
        _isLoading = false;
        _isInitialized = true;
        _message = '개인 맞춤 시간표를 불러왔습니다.';
        notifyListeners();
        return;
      }

      // 2. API에서 새로운 데이터 가져오기
      _message = '나이스 API에서 시간표 데이터를 가져오는 중...';
      notifyListeners();

      print('🚀 나이스 API 호출: 학년=${_grade}, 반=${_classNum}, 사용자ID=${_userId}');
      final newTimeTable = await _timeTableService.fetchTimeTable(
        grade: _grade,
        classNum: _classNum,
        userId: _userId,
      );
      print(
          '✅ 나이스 API 응답: ${newTimeTable.grade}학년 ${newTimeTable.classNum}반 시간표');

      // 3. 로컬 저장소에 저장
      _message = '시간표를 저장하는 중...';
      notifyListeners();
      await _storageService.saveTimeTable(newTimeTable);

      // 4. 상태 업데이트
      _timeTable = newTimeTable;
      _isInitialized = true;

      // 기본 시간표인지 확인
      bool isDefaultTimeTable = _isDefaultTimeTable(newTimeTable);
      if (isDefaultTimeTable) {
        _message = '나이스 API에서 시간표를 가져오지 못해 기본 시간표를 표시합니다.';
      } else {
        _message = '나이스 API에서 시간표를 성공적으로 불러왔습니다.';
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _message = '시간표를 불러오는데 실패했습니다: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 기본 시간표인지 확인하는 메서드
  bool _isDefaultTimeTable(TimeTable timeTable) {
    // 기본 시간표의 첫 번째 과목이 '국어'인지 확인
    if (timeTable.subjects.isNotEmpty &&
        timeTable.subjects[0].isNotEmpty &&
        timeTable.subjects[0][0] == '국어') {
      return true;
    }
    return false;
  }

  // 시간표 데이터 삭제
  Future<void> clearTimeTable() async {
    await _storageService.clearTimeTable();
    _timeTable = null;
    notifyListeners();
  }

  // 시간표 데이터 업데이트 (개인 맞춤)
  Future<void> updateTimeTable(TimeTable timeTable) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 시간표 데이터 업데이트
      _timeTable = timeTable;

      // 개인 맞춤 시간표로 저장
      await _storageService.saveCustomTimeTable(timeTable);

      // 사용자 ID가 있으면 Firestore에도 저장
      if (_userId != null) {
        await _timeTableService.saveCustomTimeTable(_userId!, timeTable);
      }

      _isLoading = false;
      _isInitialized = true;
      _message = '시간표가 업데이트되었습니다.';
      notifyListeners();
    } catch (e) {
      _error = '시간표 업데이트 중 오류가 발생했습니다: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // 과목 수정
  Future<void> updateSubject(int periodIndex, int dayIndex, String newSubject,
      String newTeacher) async {
    if (_timeTable == null) return;

    try {
      final subjects = List<List<String>>.from(_timeTable!.subjects);

      // 인덱스 범위 확인
      if (periodIndex < 0 || periodIndex >= subjects.length) {
        _error = '유효하지 않은 교시입니다: ${periodIndex + 1}';
        notifyListeners();
        return;
      }

      if (dayIndex < 0 || dayIndex >= subjects[periodIndex].length) {
        _error = '유효하지 않은 요일입니다: ${dayIndex + 1}';
        notifyListeners();
        return;
      }

      // 과목명과 교사명 결합
      String updatedSubject = newSubject;
      if (newTeacher.isNotEmpty) {
        updatedSubject = '$newSubject\n$newTeacher';
      }

      // 시간표 업데이트
      subjects[periodIndex][dayIndex] = updatedSubject;

      // 새 시간표 생성
      final updatedTimeTable = TimeTable(
        grade: _timeTable!.grade,
        classNum: _timeTable!.classNum,
        subjects: subjects,
        periods: _timeTable!.periods,
        weekdays: _timeTable!.weekdays,
        startTime: _timeTable!.startTime,
      );

      // 시간표 업데이트
      await updateTimeTable(updatedTimeTable);
    } catch (e) {
      _error = '과목 업데이트 중 오류가 발생했습니다: $e';
      notifyListeners();
    }
  }
}
