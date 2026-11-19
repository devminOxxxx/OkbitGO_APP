import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_storage_service.dart';

class EventProvider extends ChangeNotifier {
  final EventStorageService _storageService;
  List<Event> _events = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  EventProvider(this._storageService);

  List<Event> get events => _events;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 초기 이벤트 데이터 로드
  Future<void> fetchEvents() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 로컬 저장소에서 먼저 로드
      _events = await _storageService.getLocalEvents();
      notifyListeners();

      // Firestore와 동기화
      _events = await _storageService.syncEvents();
      _isInitialized = true;
    } catch (e) {
      _error = '이벤트를 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 특정 날짜의 이벤트 가져오기
  List<Event> getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events.where((event) {
      final eventStart =
          DateTime(event.start.year, event.start.month, event.start.day);
      final eventEnd = DateTime(event.end.year, event.end.month, event.end.day);

      // 이벤트 시작일부터 종료일까지의 모든 날짜에 이벤트 표시
      return (normalizedDay.isAtSameMomentAs(eventStart) ||
              normalizedDay.isAfter(eventStart)) &&
          (normalizedDay.isAtSameMomentAs(eventEnd) ||
              normalizedDay.isBefore(eventEnd));
    }).toList();
  }

  // 이벤트 추가
  Future<void> addEvent(Event event) async {
    try {
      _events.add(event);
      notifyListeners();

      // 로컬 저장소에 저장
      await _storageService.saveLocalEvents(_events);

      // Firestore에 저장
      await _storageService.saveFirestoreEvent(event);
    } catch (e) {
      _error = '이벤트를 추가하는 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 이벤트 업데이트
  Future<void> updateEvent(Event updatedEvent) async {
    try {
      final index = _events.indexWhere((e) => e.id == updatedEvent.id);
      if (index != -1) {
        _events[index] = updatedEvent;
        notifyListeners();

        // 로컬 저장소에 저장
        await _storageService.saveLocalEvents(_events);

        // Firestore에 저장
        await _storageService.saveFirestoreEvent(updatedEvent);
      }
    } catch (e) {
      _error = '이벤트를 업데이트하는 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 이벤트 삭제
  Future<void> deleteEvent(String eventId) async {
    try {
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();

      // 로컬 저장소에 저장
      await _storageService.saveLocalEvents(_events);

      // Firestore에서 삭제
      await _storageService.deleteFirestoreEvent(eventId);
    } catch (e) {
      _error = '이벤트를 삭제하는 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }

  // 새 이벤트 ID 생성
  String generateEventId() {
    return _storageService.generateEventId();
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
