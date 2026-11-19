import 'package:flutter/material.dart';
import 'package:okbit_go_app/utils/constants.dart';
import 'package:okbit_go_app/routes.dart';
import 'package:okbit_go_app/services/social_auth_service.dart';
import 'package:okbit_go_app/utils/logger_util.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

class SocialLoginScreen extends StatelessWidget {
  const SocialLoginScreen({Key? key}) : super(key: key);

  Future<void> _handleKakaoLogin(BuildContext context) async {
    try {
      LoggerUtil.info('카카오 로그인 시도');
      final socialAuthService = SocialAuthService();
      final userCredential = await socialAuthService.signInWithKakao();

      if (userCredential != null && context.mounted) {
        LoggerUtil.info('카카오 로그인 성공');

        // 사용자가 추가 정보를 이미 입력했는지 확인
        final hasInfo =
            await socialAuthService.hasAdditionalInfo(userCredential.user!.uid);

        if (hasInfo) {
          // 추가 정보가 있으면 바로 홈으로 이동
          LoggerUtil.info('기존 사용자 - 홈 화면으로 이동');
          Navigator.pushReplacementNamed(context, AppRoutes.main);
        } else {
          // 추가 정보가 없으면 약관 동의 화면으로 이동
          LoggerUtil.info('신규 사용자 - 약관 동의 화면으로 이동');

          // 카카오 사용자 정보 가져오기
          final kakaoUser = await kakao.UserApi.instance.me();

          Navigator.pushReplacementNamed(
            context,
            AppRoutes.termsAgreement,
            arguments: {
              'email': kakaoUser.kakaoAccount?.email ?? '',
              'name': kakaoUser.kakaoAccount?.profile?.nickname ?? '',
              'provider': 'kakao',
              'providerId': kakaoUser.id.toString(),
            },
          );
        }
      } else if (context.mounted) {
        LoggerUtil.warning('카카오 로그인 취소됨');
        // 사용자가 취소한 경우는 별도 메시지 표시하지 않음
      }
    } catch (error) {
      LoggerUtil.error('카카오 로그인 오류', error);
      if (context.mounted) {
        String errorMessage = '카카오 로그인에 실패했습니다.';

        // 구체적인 에러 메시지 표시
        if (error.toString().contains('네트워크')) {
          errorMessage = '네트워크 연결을 확인해주세요.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '확인',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleAppleLogin(BuildContext context) async {
    try {
      LoggerUtil.info('애플 로그인 시도');
      final socialAuthService = SocialAuthService();
      final userCredential = await socialAuthService.signInWithApple();

      if (userCredential != null && context.mounted) {
        LoggerUtil.info('애플 로그인 성공');

        // 사용자가 추가 정보를 이미 입력했는지 확인
        final hasInfo =
            await socialAuthService.hasAdditionalInfo(userCredential.user!.uid);

        if (hasInfo) {
          // 추가 정보가 있으면 바로 홈으로 이동
          LoggerUtil.info('기존 사용자 - 홈 화면으로 이동');
          Navigator.pushReplacementNamed(context, AppRoutes.main);
        } else {
          // 추가 정보가 없으면 약관 동의 화면으로 이동
          LoggerUtil.info('신규 사용자 - 약관 동의 화면으로 이동');

          Navigator.pushReplacementNamed(
            context,
            AppRoutes.termsAgreement,
            arguments: {
              'email': userCredential.user?.email ?? '',
              'name': userCredential.user?.displayName ?? '',
              'provider': 'apple',
              'providerId': userCredential.user!.uid,
            },
          );
        }
      } else if (context.mounted) {
        LoggerUtil.warning('애플 로그인 취소됨');
        // 사용자가 취소한 경우는 별도 메시지 표시하지 않음
      }
    } catch (error) {
      LoggerUtil.error('애플 로그인 오류', error);
      LoggerUtil.error('오류 상세 정보: ${error.toString()}');

      if (context.mounted) {
        String errorMessage = 'Apple 로그인에 실패했습니다.';

        // 구체적인 에러 메시지 표시
        if (error.toString().contains('네트워크')) {
          errorMessage = '네트워크 연결을 확인해주세요.';
        } else if (error.toString().contains('APPLE_SIGN_IN_NOT_AVAILABLE')) {
          errorMessage = '이 기기에서는 Apple 로그인을 사용할 수 없습니다.';
        } else if (error.toString().contains('취소')) {
          errorMessage = '로그인이 취소되었습니다.';
        } else if (error.toString().contains('timeout')) {
          errorMessage = '요청 시간이 초과되었습니다. 다시 시도해주세요.';
        } else if (error.toString().contains('network')) {
          errorMessage = '네트워크 연결을 확인해주세요.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '확인',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고 영역
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          Assets.logo,
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '옥빛GO!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${kSchoolName}의 모든 것',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 로그인 버튼 영역
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 카카오 로그인 버튼 (카카오 디자인 가이드라인 준수)
                      _buildKakaoLoginButton(
                        onPressed: () => _handleKakaoLogin(context),
                      ),
                      const SizedBox(height: 12),

                      // 애플 로그인 버튼 (애플 디자인 가이드라인 준수)
                      _buildAppleLoginButton(
                        onPressed: () => _handleAppleLogin(context),
                      ),
                      const SizedBox(height: 24),

                      // 다른 방법으로 로그인과 고객센터 버튼을 가로로 배치
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 다른 방법으로 로그인 버튼
                          TextButton(
                            onPressed: () {
                              LoggerUtil.info('다른 방법으로 로그인 버튼 클릭');
                              Navigator.pushNamed(context, AppRoutes.login);
                            },
                            child: const Text(
                              '다른 방법으로 로그인',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),

                          // 구분선
                          Container(
                            height: 14,
                            width: 1,
                            color: Colors.grey[700],
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),

                          // 고객센터 버튼
                          TextButton(
                            onPressed: () {
                              LoggerUtil.info('고객센터 버튼 클릭');
                              Navigator.pushNamed(
                                  context, AppRoutes.customerService);
                            },
                            child: const Text(
                              '고객센터',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 카카오 로그인 버튼 (카카오 디자인 가이드라인 준수)
  Widget _buildKakaoLoginButton({required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500), // 카카오 노란색
          foregroundColor: const Color(0xFF191919), // 카카오 버튼 텍스트 색상
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 카카오 로고
            Image.asset(
              'assets/icons/kakao.png',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 8),
            // 카카오 로그인 텍스트
            const Text(
              '카카오로 시작하기',
              style: TextStyle(
                color: Color(0xFF191919),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 애플 로그인 버튼 (애플 디자인 가이드라인 준수)
  Widget _buildAppleLoginButton({required VoidCallback onPressed}) {
    return Builder(
      builder: (context) {
        // 현재 테마에 따라 색상 결정
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.white : Colors.black,
              foregroundColor: isDarkMode ? Colors.black : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 애플 로고 - WebP 이미지 사용 (크기 증가)
                Image.asset(
                  'assets/icons/apple.webp',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                // 애플 로그인 텍스트
                Text(
                  'Apple로 로그인',
                  style: TextStyle(
                    color: isDarkMode ? Colors.black : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
