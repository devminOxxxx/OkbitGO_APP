import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/social_auth_service.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SocialAuthService _socialAuthService = SocialAuthService();
  User? _user;

  NotificationProvider? _notificationProvider;

  User? get user => _user;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // NotificationProvider 설정
  void setNotificationProvider(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
  }

  Future<void> _onAuthStateChanged(User? user) async {
    final wasLoggedIn = _user != null;
    _user = user;

    // 로그인 시 환영 알림 생성 (새로운 알림 모델 사용) - 비활성화
    /*
    if (!wasLoggedIn && _user != null && _notificationProvider != null) {
      final userName =
          _user!.displayName ?? _user!.email?.split('@')[0] ?? '사용자';

      await _notificationProvider!.addNotification(
        title: '환영합니다! 👋',
        message: '안녕하세요 $userName님, 옥빛GO!에 오신 것을 환영합니다.',
        type: 'welcome',
        priority: NotificationPriority.normal,
        metadata: {
          'user_id': _user!.uid,
          'is_new_user': false,
          'login_time': DateTime.now().toIso8601String(),
          'user_name': userName,
        },
      );
    }
    */

    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _socialAuthService.signOut();
  }

  // 비밀번호 변경 메서드
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    if (_user == null || _user!.email == null) {
      throw Exception('로그인된 사용자가 없습니다');
    }

    try {
      // 현재 비밀번호로 재인증
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      await _user!.reauthenticateWithCredential(credential);

      // 비밀번호 변경
      await _user!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw Exception('현재 비밀번호가 일치하지 않습니다');
        case 'weak-password':
          throw Exception('새 비밀번호가 너무 약합니다');
        case 'requires-recent-login':
          throw Exception('보안을 위해 다시 로그인해주세요');
        default:
          throw Exception('비밀번호 변경 실패: ${e.message}');
      }
    } catch (e) {
      throw Exception('비밀번호 변경 중 오류가 발생했습니다: $e');
    }
  }

  // 계정 삭제 메서드
  Future<void> deleteAccount(String password) async {
    if (_user == null || _user!.email == null) {
      throw Exception('로그인된 사용자가 없습니다');
    }

    try {
      // 비밀번호로 재인증
      AuthCredential credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );
      await _user!.reauthenticateWithCredential(credential);

      // 계정 삭제
      await _user!.delete();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw Exception('비밀번호가 일치하지 않습니다');
        case 'requires-recent-login':
          throw Exception('보안을 위해 다시 로그인해주세요');
        default:
          throw Exception('계정 삭제 실패: ${e.message}');
      }
    } catch (e) {
      throw Exception('계정 삭제 중 오류가 발생했습니다: $e');
    }
  }
}
