import 'package:flutter/material.dart';
import '../models/dday.dart';
import '../services/dday_storage_service.dart';

class DDayProvider extends ChangeNotifier {
  final DDayStorageService _storageService;
  List<DDay> _ddays = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  DDayProvider(this._storageService) {
    _initializeDDays();
  }

  List<DDay> get ddays => _ddays;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 초기화 메서드 추가
  Future<void> _initializeDDays() async {
    if (!_isInitialized) {
      await fetchDDays();
    }
  }

  // 초기 디데이 데이터 로드
  Future<void> fetchDDays() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 로컬 저장소에서 먼저 로드
      _ddays = await _storageService.getLocalDDays();

      // Firestore와 동기화
      _ddays = await _storageService.syncDDays();
      _isInitialized = true;
    } catch (e) {
      _error = '디데이를 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 디데이 추가
  Future<void> addDDay(DDay dday) async {
    try {
      _ddays.add(dday);
      notifyListeners();

      // 로컬 저장소에 저장
      await _storageService.saveLocalDDays(_ddays);

      // Firestore에 저장
      await _storageService.saveFirestoreDDay(dday);
    } catch (e) {
      _error = '디데이를 추가하는 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 디데이 업데이트
  Future<void> updateDDay(DDay updatedDDay) async {
    try {
      final index = _ddays.indexWhere((d) => d.id == updatedDDay.id);
      if (index != -1) {
        _ddays[index] = updatedDDay;
        notifyListeners();

        // 로컬 저장소에 저장
        await _storageService.saveLocalDDays(_ddays);

        // Firestore에 저장
        await _storageService.saveFirestoreDDay(updatedDDay);
      }
    } catch (e) {
      _error = '디데이를 업데이트하는 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 디데이 삭제
  Future<void> deleteDDay(String ddayId) async {
    try {
      _ddays.removeWhere((d) => d.id == ddayId);
      notifyListeners();

      // 로컬 저장소에 저장
      await _storageService.saveLocalDDays(_ddays);

      // Firestore에서 삭제
      await _storageService.deleteFirestoreDDay(ddayId);
    } catch (e) {
      _error = '디데이를 삭제하는 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 디데이 완료 상태 토글
  Future<void> toggleDDayCompletion(String ddayId) async {
    try {
      final index = _ddays.indexWhere((d) => d.id == ddayId);
      if (index != -1) {
        final dday = _ddays[index];
        final updatedDDay = dday.copyWith(isCompleted: !dday.isCompleted);

        _ddays[index] = updatedDDay;
        notifyListeners();

        // 로컬 저장소에 저장
        await _storageService.saveLocalDDays(_ddays);

        // Firestore에 저장
        await _storageService.saveFirestoreDDay(updatedDDay);
      }
    } catch (e) {
      _error = '디데이 상태를 변경하는 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 새 디데이 ID 생성
  String generateDDayId() {
    return _storageService.generateDDayId();
  }

  // 현재 사용자 ID 가져오기
  String? getCurrentUserId() {
    return _storageService.getCurrentUserId() ?? 'anonymous';
  }

  // 오류 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
