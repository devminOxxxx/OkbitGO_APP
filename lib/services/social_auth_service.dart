import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:okbit_go_app/utils/logger_util.dart';
import 'package:okbit_go_app/config/secrets.dart';

class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 현재 로그인 상태 확인
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // 카카오 로그인 (Firebase Custom Token 방식)
  Future<UserCredential?> signInWithKakao() async {
    try {
      // 카카오톡 실행 가능 여부 확인
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } on PlatformException catch (e) {
          // 사용자가 카카오톡 로그인을 취소한 경우
          if (e.code == 'CANCELED') {
            LoggerUtil.info('카카오톡 로그인이 취소되었습니다.');
            return null;
          }
          // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인 시도
          LoggerUtil.info('카카오톡 로그인 실패, 카카오계정으로 로그인 시도: ${e.message}');
          await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        // 카카오톡이 설치되어 있지 않은 경우, 카카오계정으로 로그인
        LoggerUtil.info('카카오톡이 설치되어 있지 않아 카카오계정으로 로그인 시도');
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 개발 모드 사용
      return await _signInWithKakaoDevMode();
    } on PlatformException catch (e) {
      LoggerUtil.error('카카오 로그인 플랫폼 오류: ${e.code}', e.message);
      if (e.code == 'CANCELED') {
        return null; // 사용자가 취소한 경우
      }
      throw Exception('카카오 로그인에 실패했습니다: ${e.message}');
    } catch (error) {
      LoggerUtil.error('카카오 로그인 오류', error);
      throw Exception('카카오 로그인에 실패했습니다. 다시 시도해주세요.');
    }
  }

  // 개발 모드용 카카오 로그인 (서버 없이 테스트)
  Future<UserCredential?> _signInWithKakaoDevMode() async {
    try {
      // 카카오 사용자 정보 가져오기
      final kakaoUser = await kakao.UserApi.instance.me();
      LoggerUtil.info('개발 모드: 카카오 로그인 성공 - ${kakaoUser.id}');

      // 이메일 처리 (없으면 임시 이메일 생성)
      final email = kakaoUser.kakaoAccount?.email;
      String userEmail;
      bool isTemporaryEmail = false;

      if (email == null || email.isEmpty) {
        userEmail = 'kakao_${kakaoUser.id}@temp.okbit.com';
        isTemporaryEmail = true;
        LoggerUtil.info('개발 모드: 임시 이메일 생성 - $userEmail');
      } else {
        userEmail = email;
      }

      // 임시 비밀번호 생성 (패턴은 로컬 secrets.dart에만 둠)
      final password = Secrets.kakaoDevPasswordTemplate.replaceAll(
        '{id}',
        kakaoUser.id.toString(),
      );

      try {
        // 기존 계정으로 로그인 시도
        LoggerUtil.info('개발 모드: Firebase 기존 계정 로그인 시도');
        final credential = await _auth.signInWithEmailAndPassword(
          email: userEmail,
          password: password,
        );

        // 로그인 성공 시 Firestore 정보 업데이트
        if (credential.user != null) {
          await _saveUserToFirestore(
            credential.user!.uid,
            kakaoUser.kakaoAccount?.profile?.nickname ?? '',
            userEmail,
            'kakao',
            kakaoUser.id.toString(),
            isTemporaryEmail: isTemporaryEmail,
          );
        }

        return credential;
      } catch (e) {
        // 계정이 없으면 새로 생성
        LoggerUtil.info('개발 모드: 새 계정 생성');
        final credential = await _auth.createUserWithEmailAndPassword(
          email: userEmail,
          password: password,
        );

        // Firestore에 사용자 정보 저장 (기본 정보만)
        if (credential.user != null) {
          await _saveUserToFirestore(
            credential.user!.uid,
            kakaoUser.kakaoAccount?.profile?.nickname ?? '',
            userEmail,
            'kakao',
            kakaoUser.id.toString(),
            isTemporaryEmail: isTemporaryEmail,
          );
        }

        return credential;
      }
    } catch (error) {
      LoggerUtil.error('개발 모드 카카오 로그인 오류', error);
      throw Exception('개발 모드 로그인에 실패했습니다: $error');
    }
  }

  // 애플 로그인 (디버깅 버전)
  Future<UserCredential?> signInWithApple() async {
    dynamic appleCredential;
    OAuthCredential? oauthCredential;
    UserCredential? credential;

    try {
      LoggerUtil.info('=== 애플 로그인 시작 ===');

      // 1단계: 기기 지원 확인
      LoggerUtil.info('1단계: 기기 지원 확인 중...');
      final isAvailable = await SignInWithApple.isAvailable();
      LoggerUtil.info('애플 로그인 사용 가능 여부: $isAvailable');

      if (!isAvailable) {
        LoggerUtil.error('애플 로그인을 지원하지 않는 기기입니다');
        throw PlatformException(
          code: 'APPLE_SIGN_IN_NOT_AVAILABLE',
          message: '이 기기에서는 애플 로그인을 사용할 수 없습니다.',
        );
      }
      LoggerUtil.info('✅ 1단계 완료: 기기 지원 확인');

      // 2단계: Nonce 생성
      LoggerUtil.info('2단계: Nonce 생성 중...');
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      LoggerUtil.info('Nonce 생성 완료: ${rawNonce.substring(0, 10)}...');
      LoggerUtil.info('✅ 2단계 완료: Nonce 생성');

      // 3단계: 애플 자격 증명 요청
      LoggerUtil.info('3단계: 애플 자격 증명 요청 중...');

      try {
        appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          // Android에서 필요한 추가 설정
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.okbit.service',
            redirectUri: Uri.parse(
              'https://okbit-go-app.firebaseapp.com/__/auth/handler',
            ),
          ),
          nonce: nonce,
        );

        LoggerUtil.info('애플 자격 증명 획득 완료');
        LoggerUtil.info(
            'Identity Token 존재: ${appleCredential.identityToken != null}');
        LoggerUtil.info(
            'Authorization Code 존재: ${appleCredential.authorizationCode != null}');
        LoggerUtil.info('Email 존재: ${appleCredential.email != null}');
        LoggerUtil.info('Given Name: ${appleCredential.givenName}');
        LoggerUtil.info('Family Name: ${appleCredential.familyName}');

        // identityToken이 없으면 로그인 실패
        if (appleCredential.identityToken == null) {
          LoggerUtil.error('애플 로그인 실패: identityToken이 null입니다');
          throw Exception('Apple 로그인에 실패했습니다. 다시 시도해주세요.');
        }

        LoggerUtil.info('✅ 3단계 완료: 애플 자격 증명 획득');
      } catch (e) {
        LoggerUtil.error('3단계 실패: 애플 자격 증명 요청 중 오류', e);
        rethrow;
      }

      // 4단계: Firebase OAuth 자격 증명 생성
      LoggerUtil.info('4단계: Firebase OAuth 자격 증명 생성 중...');

      try {
        oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential!.identityToken!,
          accessToken: appleCredential.authorizationCode,
          rawNonce: rawNonce,
        );
        LoggerUtil.info('✅ 4단계 완료: Firebase OAuth 자격 증명 생성');
      } catch (e) {
        LoggerUtil.error('4단계 실패: Firebase OAuth 자격 증명 생성 중 오류', e);
        rethrow;
      }

      // 5단계: Firebase 로그인
      LoggerUtil.info('5단계: Firebase 로그인 중...');

      try {
        credential = await _auth.signInWithCredential(oauthCredential!);
        LoggerUtil.info('Firebase 로그인 성공: ${credential.user?.uid}');
        LoggerUtil.info('✅ 5단계 완료: Firebase 로그인');
      } catch (e) {
        LoggerUtil.error('5단계 실패: Firebase 로그인 중 오류', e);
        rethrow;
      }

      // 6단계: 사용자 정보 처리 및 저장
      LoggerUtil.info('6단계: 사용자 정보 처리 및 저장 중...');

      if (credential!.user != null) {
        // 애플은 첫 로그인 시에만 이름 정보를 제공
        String displayName = credential.user?.displayName ?? '';

        // 이름 정보가 있으면 사용
        if (appleCredential!.givenName != null &&
            appleCredential.familyName != null) {
          displayName =
              '${appleCredential.familyName}${appleCredential.givenName}';
          LoggerUtil.info('애플에서 제공한 이름 사용: $displayName');
        }

        // 이메일 정보가 있으면 사용
        String email = credential.user?.email ?? '';
        bool isTemporaryEmail = false;

        if (appleCredential.email != null &&
            appleCredential.email!.isNotEmpty) {
          email = appleCredential.email!;
          LoggerUtil.info('애플에서 제공한 이메일 사용: $email');
        } else if (email.isEmpty) {
          // 애플에서 이메일을 제공하지 않은 경우 임시 이메일 생성
          email = 'apple_${credential.user!.uid}@temp.okbit.com';
          isTemporaryEmail = true;
          LoggerUtil.info('애플 로그인: 임시 이메일 생성 - $email');
        }

        // 사용자 정보 저장
        await _saveUserToFirestore(
          credential.user!.uid,
          displayName,
          email,
          'apple',
          credential.user!.uid,
          isTemporaryEmail: isTemporaryEmail,
        );

        LoggerUtil.info('✅ 6단계 완료: 사용자 정보 저장');
      }

      LoggerUtil.info('=== 애플 로그인 완료 ===');
      return credential;
    } on PlatformException catch (e) {
      LoggerUtil.error('애플 로그인 플랫폼 오류: ${e.code}', e.message);
      LoggerUtil.error('플랫폼 오류 상세: ${e.details}');

      if (e.code == 'CANCELED') {
        LoggerUtil.info('사용자가 애플 로그인을 취소했습니다');
        return null; // 사용자가 취소한 경우
      }

      // 구체적인 플랫폼 오류 메시지
      String errorMessage = '애플 로그인에 실패했습니다.';
      if (e.code == 'APPLE_SIGN_IN_NOT_AVAILABLE') {
        errorMessage = '이 기기에서는 Apple 로그인을 사용할 수 없습니다.';
      } else if (e.code == 'SIGN_IN_CANCELLED') {
        errorMessage = '로그인이 취소되었습니다.';
      } else if (e.code == 'SIGN_IN_FAILED') {
        errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
      }

      throw Exception(errorMessage);
    } catch (error) {
      LoggerUtil.error('애플 로그인 일반 오류', error);
      LoggerUtil.error('오류 타입: ${error.runtimeType}');
      LoggerUtil.error('오류 메시지: $error');

      String errorMessage = '애플 로그인에 실패했습니다. 다시 시도해주세요.';

      if (error.toString().contains('network')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      } else if (error.toString().contains('timeout')) {
        errorMessage = '요청 시간이 초과되었습니다. 다시 시도해주세요.';
      }

      throw Exception(errorMessage);
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      // Firebase 로그아웃
      await _auth.signOut();

      // 카카오 로그아웃 (카카오로 로그인한 경우)
      try {
        await kakao.UserApi.instance.logout();
        LoggerUtil.info('카카오 로그아웃 성공');
      } catch (e) {
        // 카카오 로그아웃 실패는 무시 (Firebase 로그아웃이 성공하면 됨)
        LoggerUtil.warning('카카오 로그아웃 실패 (무시됨): $e');
      }

      LoggerUtil.info('로그아웃 성공');
    } catch (e) {
      LoggerUtil.error('로그아웃 오류', e);
      throw Exception('로그아웃에 실패했습니다.');
    }
  }

  // 보안을 위한 nonce 생성
  String _generateNonce() {
    const length = 32;
    final random = List<int>.generate(
        length, (_) => DateTime.now().millisecondsSinceEpoch % 256);
    return base64Url.encode(random);
  }

  // nonce의 SHA-256 해시 생성
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Firestore에 사용자 정보 저장
  Future<void> _saveUserToFirestore(
    String uid,
    String name,
    String email,
    String provider,
    String providerId, {
    bool isTemporaryEmail = false,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'provider': provider,
        'providerId': providerId,
        'isTemporaryEmail': isTemporaryEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      LoggerUtil.info('사용자 정보 Firestore에 저장 성공: $uid');
    } catch (e) {
      LoggerUtil.error('사용자 정보 저장 오류', e);
      throw Exception('사용자 정보 저장에 실패했습니다.');
    }
  }

  // 사용자가 추가 정보를 이미 입력했는지 확인
  Future<bool> hasAdditionalInfo(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data != null &&
            data['grade'] != null &&
            data['classNumber'] != null &&
            data['studentNumber'] != null;
      }
      return false;
    } catch (e) {
      LoggerUtil.error('추가 정보 확인 오류', e);
      return false;
    }
  }

  // 사용자 추가 정보 저장
  Future<void> saveAdditionalInfo(
    String uid,
    int grade,
    int classNumber,
    int number,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'grade': grade.toString(),
        'classNumber': classNumber.toString(),
        'studentNumber': number.toString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      LoggerUtil.info('사용자 추가 정보 저장 성공: $uid');
    } catch (e) {
      LoggerUtil.error('사용자 추가 정보 저장 오류', e);
      throw Exception('추가 정보 저장에 실패했습니다.');
    }
  }
}
