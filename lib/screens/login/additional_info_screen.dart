import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';
import '../../routes.dart';
import '../../providers/user_provider.dart';
import '../../utils/logger_util.dart';
import '../../services/social_auth_service.dart';

class AdditionalInfoScreen extends StatefulWidget {
  final String email;
  final String name;
  final String provider;
  final String providerId;
  final bool agreedToMarketing;

  const AdditionalInfoScreen({
    Key? key,
    required this.email,
    required this.name,
    required this.provider,
    required this.providerId,
    this.agreedToMarketing = false,
  }) : super(key: key);

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gradeController = TextEditingController();
  final _classController = TextEditingController();
  final _studentNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _gradeController.dispose();
    _classController.dispose();
    _studentNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveAdditionalInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      // SocialAuthService를 사용하여 추가 정보 저장
      final socialAuthService = SocialAuthService();
      await socialAuthService.saveAdditionalInfo(
        user.uid,
        int.parse(_gradeController.text),
        int.parse(_classController.text),
        int.parse(_studentNumberController.text),
      );

      // UserProvider 업데이트
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.refreshUser();
      } catch (e) {
        LoggerUtil.warning('UserProvider 업데이트 실패 (무시됨): $e');
      }

      if (mounted) {
        // 메인 화면으로 이동
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    } catch (error) {
      LoggerUtil.error('추가 정보 저장 오류', error);
      LoggerUtil.error('오류 상세 정보', error.toString());

      if (mounted) {
        String errorMessage = '정보 저장에 실패했습니다.';

        // 구체적인 오류 메시지 표시
        if (error.toString().contains('permission-denied')) {
          errorMessage = '권한이 없습니다. Firebase 보안 규칙을 확인해주세요.';
        } else if (error.toString().contains('unavailable')) {
          errorMessage = '네트워크 연결을 확인해주세요.';
        } else if (error.toString().contains('not-found')) {
          errorMessage = '사용자 정보를 찾을 수 없습니다.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '재시도',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _saveAdditionalInfo();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          '추가 정보 입력',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 환영 메시지
                Text(
                  '${widget.name}님, 환영합니다!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '서비스 이용을 위해 추가 정보를 입력해주세요.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // 학년 입력
                TextFormField(
                  controller: _gradeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '학년',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: '1~3',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '학년을 입력해주세요';
                    }
                    final grade = int.tryParse(value);
                    if (grade == null || grade < 1 || grade > 3) {
                      return '1~3학년 중 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 반 입력
                TextFormField(
                  controller: _classController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '반',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: '1~10',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '반을 입력해주세요';
                    }
                    final classNum = int.tryParse(value);
                    if (classNum == null || classNum < 1 || classNum > 10) {
                      return '1~10반 중 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 번호 입력
                TextFormField(
                  controller: _studentNumberController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: '번호',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: '1~30',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '번호를 입력해주세요';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number < 1 || number > 30) {
                      return '1~30번 중 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // 저장 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAdditionalInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            '저장하고 시작하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // 임시 테스트 버튼 (개발용)
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushReplacementNamed(
                                context, AppRoutes.main);
                          },
                    child: const Text(
                      '테스트: 메인 화면으로 이동',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
