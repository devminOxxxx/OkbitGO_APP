import 'package:flutter/material.dart';
import 'package:okbit_go_app/utils/constants.dart';
import 'package:okbit_go_app/routes.dart';
import 'package:okbit_go_app/services/social_auth_service.dart';
import 'package:okbit_go_app/utils/logger_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SocialAuthService _authService = SocialAuthService();

  @override
  void initState() {
    super.initState();
    // 화면이 빌드된 후 로그인 상태 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLoginStatus();
    });
  }

  // 로그인 상태 확인
  void checkLoginStatus() async {
    try {
      LoggerUtil.info('스플래시 화면: 로그인 상태 확인 시작');

      // 스플래시 화면 표시를 위해 2초 대기
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // SocialAuthService를 사용하여 로그인 상태 확인
      final isLoggedIn = _authService.isLoggedIn();
      LoggerUtil.info('스플래시 화면: 로그인 상태 - $isLoggedIn');

      if (isLoggedIn) {
        // 로그인되어 있으면 추가 정보 완료 여부 확인
        LoggerUtil.info('스플래시 화면: 로그인 확인됨, 추가 정보 확인');

        // Firestore에서 추가 정보 완료 여부 확인
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          final additionalInfoCompleted =
              userDoc.data()?['additionalInfoCompleted'] ?? false;

          if (additionalInfoCompleted) {
            // 추가 정보가 완료되었으면 메인 화면으로 이동
            LoggerUtil.info('스플래시 화면: 추가 정보 완료, 메인 화면으로 이동');
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.main,
              (route) => false,
            );
          } else {
            // 추가 정보가 없으면 추가 정보 입력 화면으로 이동
            LoggerUtil.info('스플래시 화면: 추가 정보 미완료, 추가 정보 화면으로 이동');
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.additionalInfo,
              (route) => false,
              arguments: {
                'email': userDoc.data()?['email'] ?? '',
                'name': userDoc.data()?['name'] ?? '',
                'provider': userDoc.data()?['provider'] ?? '',
                'providerId': userDoc.data()?['providerId'] ?? '',
              },
            );
          }
        }
      } else {
        // 로그인되어 있지 않으면 소셜 로그인 화면으로 이동
        LoggerUtil.info('스플래시 화면: 로그인 안됨, 소셜 로그인 화면으로 이동');
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.socialLogin,
          (route) => false, // 모든 이전 라우트 제거
        );
      }
    } catch (e) {
      LoggerUtil.error('스플래시 화면: 로그인 상태 확인 중 오류 발생', e);
      // 오류 발생 시 소셜 로그인 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.socialLogin,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(Assets.logo, width: 150, height: 150),
            const SizedBox(height: 20),
            const Text(
              '옥빛GO!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
