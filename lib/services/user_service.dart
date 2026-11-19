import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

import '../config/database_config.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 로그인한 사용자 정보 가져오기
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('UserService: 로그인된 사용자가 없습니다.');
        return null;
      }

      debugPrint('UserService: 현재 사용자 ID - ${currentUser.uid}');
      return await getUserById(currentUser.uid);
    } catch (e) {
      debugPrint('UserService: 사용자 정보 가져오기 오류 - $e');
      throw Exception('사용자 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 사용자 ID로 사용자 정보 가져오기
  Future<UserModel> getUserById(String userId) async {
    try {
      debugPrint('UserService: 사용자 정보 조회 시작 - $userId');
      final docSnapshot = await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        debugPrint('UserService: Firestore에서 사용자 정보 찾음');
        final data = docSnapshot.data() as Map<String, dynamic>;
        return _processUserData(data, userId);
      } else {
        debugPrint('UserService: Firestore에 사용자 정보가 없음, 새 사용자 생성');
        return await _createNewUser(userId);
      }
    } catch (e) {
      debugPrint('UserService: 사용자 정보 가져오기 오류 - $e');
      throw Exception('사용자 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 이메일로 사용자 정보 가져오기
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      debugPrint('UserService: 이메일로 사용자 정보 조회 시작 - $email');
      final querySnapshot = await _firestore
          .collection(DatabaseConfig.usersCollection)
          .where(DatabaseConfig.emailField, isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        debugPrint('UserService: 이메일로 사용자 정보 찾음');
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return _processUserData(data, doc.id);
      } else {
        debugPrint('UserService: 해당 이메일의 사용자 정보가 없음');
        return null;
      }
    } catch (e) {
      debugPrint('UserService: 이메일로 사용자 정보 가져오기 오류 - $e');
      throw Exception('사용자 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 새 사용자 생성
  Future<UserModel> _createNewUser(String userId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('인증된 사용자가 없습니다.');
      }

      final newUser = UserModel(
        id: userId,
        email: currentUser.email ?? '',
        name: currentUser.displayName ?? '사용자',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notificationSettings: DatabaseConfig.defaultNotificationSettings,
        photoUrl: currentUser.photoURL,
        school: DatabaseConfig.defaultSchool,
        grade: '',
        classNumber: '',
        studentNumber: '',
        isAdmin: DatabaseConfig.defaultIsAdmin,
        theme: DatabaseConfig.defaultTheme,
        allergies: const [],
      );

      debugPrint('UserService: 새 사용자 정보 Firestore에 저장');
      await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(userId)
          .set(newUser.toJson());
      return newUser;
    } catch (e) {
      debugPrint('UserService: 새 사용자 생성 오류 - $e');
      throw Exception('새 사용자 생성에 실패했습니다: $e');
    }
  }

  // Firestore 데이터 처리
  UserModel _processUserData(Map<String, dynamic> data, String userId) {
    try {
      return UserModel(
        id: userId,
        email: data[DatabaseConfig.emailField] ?? '',
        name: data[DatabaseConfig.nameField] ?? '사용자',
        photoUrl: data[DatabaseConfig.photoUrlField],
        school:
            data[DatabaseConfig.schoolField] ?? DatabaseConfig.defaultSchool,
        grade: _parseStringField(data[DatabaseConfig.gradeField]),
        classNumber: _parseStringField(data[DatabaseConfig.classNumberField]),
        studentNumber:
            _parseStringField(data[DatabaseConfig.studentNumberField]),
        isAdmin:
            data[DatabaseConfig.isAdminField] ?? DatabaseConfig.defaultIsAdmin,
        notificationSettings: Map<String, dynamic>.from(
          data[DatabaseConfig.notificationSettingsField] ??
              DatabaseConfig.defaultNotificationSettings,
        ),
        createdAt: _parseTimestamp(data[DatabaseConfig.createdAtField]),
        updatedAt: _parseTimestamp(data[DatabaseConfig.updatedAtField]),
        theme: data[DatabaseConfig.themeField] ?? DatabaseConfig.defaultTheme,
        allergies: List<String>.from(data[DatabaseConfig.allergiesField] ?? []),
        additionalInfoCompleted:
            data[DatabaseConfig.additionalInfoCompletedField] ??
                DatabaseConfig.defaultAdditionalInfoCompleted,
        isTemporaryEmail: data[DatabaseConfig.isTemporaryEmailField] ??
            DatabaseConfig.defaultIsTemporaryEmail,
      );
    } catch (e) {
      debugPrint('UserService: 사용자 데이터 처리 오류 - $e');
      throw Exception('사용자 데이터 처리에 실패했습니다: $e');
    }
  }

  // 필드 값을 안전하게 String으로 변환
  String? _parseStringField(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }

  // Timestamp 파싱 헬퍼
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now();
  }

  // 사용자 정보 업데이트
  Future<void> updateUser(UserModel user) async {
    try {
      debugPrint('UserService: 사용자 정보 업데이트 시작 - ${user.id}');
      final Map<String, dynamic> updateData = {
        DatabaseConfig.nameField: user.name,
        DatabaseConfig.emailField: user.email,
        if (user.photoUrl != null) DatabaseConfig.photoUrlField: user.photoUrl,
        if (user.school != null) DatabaseConfig.schoolField: user.school,
        if (user.grade != null) DatabaseConfig.gradeField: user.grade,
        if (user.classNumber != null)
          DatabaseConfig.classNumberField: user.classNumber,
        if (user.studentNumber != null)
          DatabaseConfig.studentNumberField: user.studentNumber,
        DatabaseConfig.isAdminField: user.isAdmin,
        DatabaseConfig.notificationSettingsField: user.notificationSettings,
        DatabaseConfig.themeField: user.theme,
        DatabaseConfig.allergiesField: user.allergies,
        DatabaseConfig.updatedAtField: Timestamp.fromDate(user.updatedAt),
      };

      await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(user.id)
          .update(updateData);
      debugPrint('UserService: 사용자 정보 업데이트 완료');
    } catch (e) {
      debugPrint('UserService: 사용자 정보 업데이트 오류 - $e');
      throw Exception('사용자 정보 업데이트에 실패했습니다: $e');
    }
  }

  // 사용자 계정 삭제
  Future<void> deleteUser(String userId) async {
    try {
      debugPrint('UserService: 사용자 계정 삭제 시작 - $userId');
      await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(userId)
          .delete();
      debugPrint('UserService: 사용자 계정 삭제 완료');
    } catch (e) {
      debugPrint('UserService: 사용자 계정 삭제 오류 - $e');
      throw Exception('사용자 계정 삭제에 실패했습니다: $e');
    }
  }

  // 알레르기 정보 업데이트
  Future<bool> updateAllergies(String userId, List<String> allergies) async {
    if (userId == 'anonymous') {
      debugPrint('UserService: 익명 사용자, 로컬에서만 업데이트');
      return true;
    }

    try {
      debugPrint('UserService: 알레르기 정보 업데이트 시작 - $userId');
      await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(userId)
          .update({
        DatabaseConfig.allergiesField: allergies,
        DatabaseConfig.updatedAtField: Timestamp.now(),
      });
      debugPrint('UserService: 알레르기 정보 업데이트 완료');
      return true;
    } catch (e) {
      debugPrint('UserService: 알레르기 정보 업데이트 오류 - $e');
      return false;
    }
  }

  // 알림 설정 업데이트
  Future<bool> updateNotificationSettings(
      String userId, Map<String, bool> settings) async {
    if (userId == 'anonymous') {
      debugPrint('UserService: 익명 사용자, 로컬에서만 업데이트');
      return true;
    }

    try {
      debugPrint('UserService: 알림 설정 업데이트 시작 - $userId');
      await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(userId)
          .update({
        DatabaseConfig.notificationSettingsField: settings,
        DatabaseConfig.updatedAtField: Timestamp.now(),
      });
      debugPrint('UserService: 알림 설정 업데이트 완료');
      return true;
    } catch (e) {
      debugPrint('UserService: 알림 설정 업데이트 오류 - $e');
      return false;
    }
  }

  // 테마 설정 업데이트
  Future<bool> updateThemeSettings(String userId, String theme) async {
    if (userId == 'anonymous') {
      debugPrint('UserService: 익명 사용자, 로컬에서만 업데이트');
      return true;
    }

    try {
      debugPrint('UserService: 테마 설정 업데이트 시작 - $userId');
      await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(userId)
          .update({
        DatabaseConfig.themeField: theme,
        DatabaseConfig.updatedAtField: Timestamp.now(),
      });
      debugPrint('UserService: 테마 설정 업데이트 완료');
      return true;
    } catch (e) {
      debugPrint('UserService: 테마 설정 업데이트 오류 - $e');
      return false;
    }
  }

  // 모든 사용자 리스트 가져오기 (관리자용)
  Future<List<UserModel>> getAllUsers() async {
    try {
      debugPrint('UserService: 모든 사용자 리스트 조회 시작');
      final QuerySnapshot querySnapshot = await _firestore
          .collection(DatabaseConfig.usersCollection)
          .orderBy(DatabaseConfig.createdAtField, descending: true)
          .limit(DatabaseConfig.queryLimit)
          .get();

      final List<UserModel> users = [];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final user = _processUserData(data, doc.id);
          users.add(user);
        } catch (e) {
          debugPrint('UserService: 사용자 데이터 처리 오류 - ${doc.id}: $e');
        }
      }

      debugPrint('UserService: 전체 사용자 수 - ${users.length}');
      return users;
    } catch (e) {
      debugPrint('UserService: 사용자 리스트 조회 오류 - $e');
      throw Exception('사용자 리스트 조회에 실패했습니다: $e');
    }
  }

  // 사용자 통계 조회 (관리자용)
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      debugPrint('UserService: 사용자 통계 조회 시작');
      final QuerySnapshot querySnapshot =
          await _firestore.collection(DatabaseConfig.usersCollection).get();

      final List<UserModel> users = [];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final user = _processUserData(data, doc.id);
          users.add(user);
        } catch (e) {
          debugPrint('UserService: 사용자 데이터 처리 오류 - ${doc.id}: $e');
        }
      }

      // 통계 계산
      final totalUsers = users.length;
      final Map<String, int> gradeCount = {};
      final Map<String, int> classCount = {};
      int activeUsers = 0;
      int newUsersToday = 0;

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      for (final user in users) {
        // 학년별 통계
        if (user.grade != null && user.grade!.isNotEmpty) {
          gradeCount[user.grade!] = (gradeCount[user.grade!] ?? 0) + 1;
        }

        // 반별 통계
        if (user.classNumber != null && user.classNumber!.isNotEmpty) {
          classCount[user.classNumber!] =
              (classCount[user.classNumber!] ?? 0) + 1;
        }

        // 활성 사용자 (최근 30일 내 업데이트)
        if (user.updatedAt.isAfter(today.subtract(const Duration(days: 30)))) {
          activeUsers++;
        }

        // 오늘 가입한 사용자
        if (user.createdAt.isAfter(todayStart)) {
          newUsersToday++;
        }
      }

      final stats = {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'newUsersToday': newUsersToday,
        'gradeCount': gradeCount,
        'classCount': classCount,
      };

      debugPrint('UserService: 사용자 통계 조회 완료 - $stats');
      return stats;
    } catch (e) {
      debugPrint('UserService: 사용자 통계 조회 오류 - $e');
      throw Exception('사용자 통계 조회에 실패했습니다: $e');
    }
  }

  // 관리자가 사용자 정보 업데이트
  Future<void> updateUserByAdmin(
      String userId, Map<String, dynamic> updateData) async {
    try {
      debugPrint('UserService: 관리자가 사용자 정보 업데이트 시작 - $userId');

      await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(userId)
          .update(updateData);

      debugPrint('UserService: 관리자가 사용자 정보 업데이트 완료');
    } catch (e) {
      debugPrint('UserService: 관리자 사용자 정보 업데이트 오류 - $e');
      throw Exception('사용자 정보 업데이트에 실패했습니다: $e');
    }
  }

  // 사용자 차단
  Future<void> blockUser(String userId) async {
    try {
      debugPrint('UserService: 사용자 차단 시작 - $userId');

      await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(userId)
          .update({
        DatabaseConfig.isBlockedField: true,
        DatabaseConfig.blockedAtField: FieldValue.serverTimestamp(),
      });

      debugPrint('UserService: 사용자 차단 완료');
    } catch (e) {
      debugPrint('UserService: 사용자 차단 오류 - $e');
      throw Exception('사용자 차단에 실패했습니다: $e');
    }
  }

  // 사용자 차단 해제
  Future<void> unblockUser(String userId) async {
    try {
      debugPrint('UserService: 사용자 차단 해제 시작 - $userId');

      await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(userId)
          .update({
        DatabaseConfig.isBlockedField: false,
        DatabaseConfig.blockedAtField: null,
      });

      debugPrint('UserService: 사용자 차단 해제 완료');
    } catch (e) {
      debugPrint('UserService: 사용자 차단 해제 오류 - $e');
      throw Exception('사용자 차단 해제에 실패했습니다: $e');
    }
  }

  // 사용자 데이터 삭제 (탈퇴 처리)
  Future<void> deleteUserData(String userId) async {
    try {
      debugPrint('UserService: 사용자 데이터 삭제 시작 - $userId');

      // 먼저 사용자 정보를 deleted_users 컬렉션에 백업
      final userDoc = await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        userData['deletedAt'] = FieldValue.serverTimestamp();
        userData['originalUserId'] = userId;

        await _firestore
            .collection(DatabaseConfig.deletedUsersCollection)
            .doc(userId)
            .set(userData);
      }

      // 원본 사용자 데이터 삭제
      await _firestore
          .collection(DatabaseConfig.usersCollection)
          .doc(userId)
          .delete();

      debugPrint('UserService: 사용자 데이터 삭제 완료');
    } catch (e) {
      debugPrint('UserService: 사용자 데이터 삭제 오류 - $e');
      throw Exception('사용자 데이터 삭제에 실패했습니다: $e');
    }
  }

  // 사용자 복구
  Future<void> restoreUser(String userId) async {
    try {
      debugPrint('UserService: 사용자 복구 시작 - $userId');

      // deleted_users에서 사용자 정보 가져오기
      final deletedUserDoc = await _firestore
          .collection(DatabaseConfig.deletedUsersCollection)
          .doc(userId)
          .get();

      if (deletedUserDoc.exists) {
        final userData = deletedUserDoc.data() as Map<String, dynamic>;

        // 복구 관련 필드 제거
        userData.remove('deletedAt');
        userData.remove('originalUserId');

        // 원본 컬렉션에 복구
        await _firestore
            .collection(DatabaseConfig.usersCollection)
            .doc(userId)
            .set(userData);

        // deleted_users에서 제거
        await _firestore
            .collection(DatabaseConfig.deletedUsersCollection)
            .doc(userId)
            .delete();
      }

      debugPrint('UserService: 사용자 복구 완료');
    } catch (e) {
      debugPrint('UserService: 사용자 복구 오류 - $e');
      throw Exception('사용자 복구에 실패했습니다: $e');
    }
  }

  // 차단된 사용자 목록 가져오기
  Future<List<UserModel>> getBlockedUsers() async {
    try {
      debugPrint('UserService: 차단된 사용자 목록 조회 시작');

      final querySnapshot = await _firestore
          .collection(DatabaseConfig.usersCollection)
          .where(DatabaseConfig.isBlockedField, isEqualTo: true)
          .get();

      final blockedUsers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _processUserData(data, doc.id);
      }).toList();

      debugPrint('UserService: 차단된 사용자 ${blockedUsers.length}명 조회 완료');
      return blockedUsers;
    } catch (e) {
      debugPrint('UserService: 차단된 사용자 목록 조회 오류 - $e');
      throw Exception('차단된 사용자 목록 조회에 실패했습니다: $e');
    }
  }

  // 삭제된 사용자 목록 가져오기
  Future<List<UserModel>> getDeletedUsers() async {
    try {
      debugPrint('UserService: 삭제된 사용자 목록 조회 시작');

      final querySnapshot = await _firestore
          .collection(DatabaseConfig.deletedUsersCollection)
          .get();

      final deletedUsers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return _processUserData(data, doc.id);
      }).toList();

      debugPrint('UserService: 삭제된 사용자 ${deletedUsers.length}명 조회 완료');
      return deletedUsers;
    } catch (e) {
      debugPrint('UserService: 삭제된 사용자 목록 조회 오류 - $e');
      throw Exception('삭제된 사용자 목록 조회에 실패했습니다: $e');
    }
  }

  // 온라인 사용자 수 조회
  Future<int> getOnlineUsersCount() async {
    try {
      debugPrint('UserService: 온라인 사용자 수 조회 시작');

      // 최근 5분 이내 활동한 사용자를 온라인으로 간주
      final fiveMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 5));

      final querySnapshot = await _firestore
          .collection(DatabaseConfig.usersCollection)
          .where(DatabaseConfig.lastActiveField,
              isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .get();

      final onlineCount = querySnapshot.docs.length;
      debugPrint('UserService: 온라인 사용자 수 조회 완료 - $onlineCount명');
      return onlineCount;
    } catch (e) {
      debugPrint('UserService: 온라인 사용자 수 조회 오류 - $e');
      throw Exception('온라인 사용자 수 조회에 실패했습니다: $e');
    }
  }
}
