import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/user_migration_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  final UserService _userService = UserService();
  final UserMigrationService _migrationService = UserMigrationService();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 사용자 정보 로드
  Future<void> loadUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('사용자 정보 로드 시작: $userId');

      // 사용자 데이터 마이그레이션 실행
      await _migrationService.migrateUserFields();

      _user = await _userService.getUserById(userId);
      debugPrint('사용자 정보 로드 완료: ${_user?.name}');
      debugPrint('사용자 학년: ${_user?.grade}');
      debugPrint('사용자 반: ${_user?.classNumber}');
      debugPrint('사용자 학번: ${_user?.studentNumber}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('사용자 정보 로드 오류: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 사용자 정보 업데이트
  Future<void> updateUser({
    String? name,
    String? email,
    String? photoUrl,
    String? school,
    String? grade,
    String? classNumber,
    String? studentNumber,
    bool? isAdmin,
    Map<String, dynamic>? notificationSettings,
    List<String>? allergies,
  }) async {
    if (_user == null) {
      debugPrint('사용자 정보 업데이트 실패: 사용자 정보가 없습니다.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('사용자 정보 업데이트 시작');
      final updatedUser = _user!.copyWith(
        name: name,
        email: email,
        photoUrl: photoUrl,
        school: school,
        grade: grade,
        classNumber: classNumber,
        studentNumber: studentNumber,
        isAdmin: isAdmin,
        notificationSettings: notificationSettings,
        allergies: allergies,
        updatedAt: DateTime.now(),
      );

      await _userService.updateUser(updatedUser);
      _user = updatedUser;
      debugPrint('사용자 정보 업데이트 완료');
    } catch (e) {
      debugPrint('사용자 정보 업데이트 오류: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로그인 상태 확인 및 사용자 정보 로드
  Future<void> checkAuthState() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugPrint('로그인 상태 확인: 로그인됨 (${currentUser.uid})');
      await loadUser(currentUser.uid);
    } else {
      debugPrint('로그인 상태 확인: 로그인되지 않음');
      _user = null;
      notifyListeners();
    }
  }

  // 사용자 정보 새로고침
  Future<void> refreshUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await loadUser(currentUser.uid);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    debugPrint('로그아웃 완료');
    notifyListeners();
  }

  // 사용자 계정 삭제
  Future<void> deleteAccount() async {
    if (_user == null) {
      debugPrint('계정 삭제 실패: 사용자 정보가 없습니다.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('계정 삭제 시작');
      await _userService.deleteUser(_user!.id);
      await FirebaseAuth.instance.currentUser?.delete();
      _user = null;
      debugPrint('계정 삭제 완료');
    } catch (e) {
      debugPrint('계정 삭제 오류: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
