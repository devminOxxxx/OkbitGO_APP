import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../config/database_config.dart';

class EventStorageService {
  static const String _localStorageKey = 'user_events';
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Uuid _uuid = const Uuid();

  EventStorageService._(this._prefs, this._firestore, this._auth);

  static Future<EventStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    return EventStorageService._(prefs, firestore, auth);
  }

  // 로컬 저장소에서 이벤트 가져오기
  Future<List<Event>> getLocalEvents() async {
    final String? eventsJson = _prefs.getString(_localStorageKey);
    if (eventsJson == null) {
      return [];
    }

    try {
      final List<dynamic> decodedList = jsonDecode(eventsJson);
      return decodedList
          .map((item) => Event.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 로컬 저장소에 이벤트 저장
  Future<void> saveLocalEvents(List<Event> events) async {
    final List<Map<String, dynamic>> encodedList =
        events.map((event) => event.toMap()).toList();
    await _prefs.setString(_localStorageKey, jsonEncode(encodedList));
  }

  // Firestore에서 사용자 이벤트 가져오기
  Future<List<Event>> getFirestoreEvents() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final QuerySnapshot snapshot = await _firestore
          .collection(DatabaseConfig.eventsCollection)
          .where(DatabaseConfig.userIdField, isEqualTo: user.uid)
          .get();

      return snapshot.docs
          .map((doc) => Event.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Firestore에 이벤트 저장
  Future<void> saveFirestoreEvent(Event event) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      await _firestore
          .collection(DatabaseConfig.eventsCollection)
          .doc(event.id)
          .set(event.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Firestore에서 이벤트 삭제
  Future<void> deleteFirestoreEvent(String eventId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      await _firestore
          .collection(DatabaseConfig.eventsCollection)
          .doc(eventId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // 새 이벤트 ID 생성
  String generateEventId() {
    return _uuid.v4();
  }

  // 현재 사용자 ID 가져오기
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // 모든 이벤트 동기화 (로컬 + Firestore)
  Future<List<Event>> syncEvents() async {
    try {
      final List<Event> localEvents = await getLocalEvents();
      final List<Event> firestoreEvents = await getFirestoreEvents();

      // 로컬에만 있는 이벤트를 Firestore에 업로드
      for (final event in localEvents) {
        if (!firestoreEvents.any((e) => e.id == event.id)) {
          await saveFirestoreEvent(event);
        }
      }

      // 최신 Firestore 이벤트 가져오기
      final List<Event> updatedFirestoreEvents = await getFirestoreEvents();

      // 로컬 저장소 업데이트
      await saveLocalEvents(updatedFirestoreEvents);

      return updatedFirestoreEvents;
    } catch (e) {
      // 오류 발생 시 로컬 이벤트 반환
      return await getLocalEvents();
    }
  }
}
