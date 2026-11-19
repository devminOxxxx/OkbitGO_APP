import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dday.dart';
import '../config/database_config.dart';

class DDayStorageService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SharedPreferences _prefs;

  DDayStorageService(this._firestore, this._auth, this._prefs);

  // 싱글톤 인스턴스 생성을 위한 팩토리 메서드
  static Future<DDayStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DDayStorageService(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
      prefs,
    );
  }

  // 현재 사용자 ID 가져오기
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // 새 디데이 ID 생성
  String generateDDayId() {
    return _firestore.collection(DatabaseConfig.ddaysCollection).doc().id;
  }

  // 로컬 저장소에서 디데이 목록 가져오기
  Future<List<DDay>> getLocalDDays() async {
    try {
      final userId = getCurrentUserId() ?? 'anonymous';
      final String? ddaysJson = _prefs.getString('ddays_$userId');

      if (ddaysJson == null) {
        return [];
      }

      final List<dynamic> ddaysList = json.decode(ddaysJson);
      return ddaysList.map((item) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        return DDay(
          id: map['id'],
          title: map['title'],
          date: DateTime.parse(map['date']),
          userId: map['userId'],
          isCompleted: map['isCompleted'] ?? false,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // 로컬 저장소에 디데이 목록 저장
  Future<void> saveLocalDDays(List<DDay> ddays) async {
    try {
      final userId = getCurrentUserId() ?? 'anonymous';
      final List<Map<String, dynamic>> ddaysList = ddays.map((dday) {
        return {
          'id': dday.id,
          'title': dday.title,
          'date': dday.date.toIso8601String(),
          'userId': dday.userId,
          'isCompleted': dday.isCompleted,
        };
      }).toList();

      await _prefs.setString('ddays_$userId', json.encode(ddaysList));
    } catch (e) {}
  }

  // Firestore에서 디데이 목록 가져오기
  Future<List<DDay>> getFirestoreDDays() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection(DatabaseConfig.ddaysCollection)
          .where(DatabaseConfig.userIdField, isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) {
        return DDay.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Firestore에 디데이 저장
  Future<void> saveFirestoreDDay(DDay dday) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return;
      }

      await _firestore
          .collection(DatabaseConfig.ddaysCollection)
          .doc(dday.id)
          .set(dday.toMap());
    } catch (e) {}
  }

  // Firestore에서 디데이 삭제
  Future<void> deleteFirestoreDDay(String ddayId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return;
      }

      await _firestore
          .collection(DatabaseConfig.ddaysCollection)
          .doc(ddayId)
          .delete();
    } catch (e) {}
  }

  // 로컬 저장소와 Firestore 동기화
  Future<List<DDay>> syncDDays() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return await getLocalDDays();
      }

      final localDDays = await getLocalDDays();
      final firestoreDDays = await getFirestoreDDays();

      // 로컬에만 있는 디데이를 Firestore에 저장
      for (final dday in localDDays) {
        if (!firestoreDDays.any((d) => d.id == dday.id)) {
          await saveFirestoreDDay(dday);
        }
      }

      // Firestore의 디데이로 로컬 디데이 업데이트
      final mergedDDays = [...firestoreDDays];

      // 로컬에 저장
      await saveLocalDDays(mergedDDays);

      return mergedDDays;
    } catch (e) {
      return await getLocalDDays();
    }
  }
}
