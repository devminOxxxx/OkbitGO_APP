import 'package:flutter/material.dart';
import 'package:okbit_go_app/routes.dart';
import 'package:okbit_go_app/utils/constants.dart';

class TermsAgreementScreen extends StatefulWidget {
  final String? email;
  final String? name;
  final String? provider;
  final String? providerId;

  const TermsAgreementScreen({
    Key? key,
    this.email,
    this.name,
    this.provider,
    this.providerId,
  }) : super(key: key);

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool _privacyAgreed = false;
  bool _termsAgreed = false;

  bool get _canProceed => _privacyAgreed && _termsAgreed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '이용약관 동의',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '서비스 이용을 위해\n약관에 동의해주세요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildAgreementTile(
                title: '개인정보 처리방침',
                isChecked: _privacyAgreed,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                onChanged: (value) {
                  setState(() {
                    _privacyAgreed = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildAgreementTile(
                title: '서비스 이용약관',
                isChecked: _termsAgreed,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.termsOfService),
                onChanged: (value) {
                  setState(() {
                    _termsAgreed = value ?? false;
                  });
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _canProceed
                    ? () {
                        // 소셜 로그인에서 온 경우 추가 정보 화면으로, 아니면 회원가입 화면으로
                        if (widget.provider != null) {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.additionalInfo,
                            arguments: {
                              'email': widget.email ?? '',
                              'name': widget.name ?? '',
                              'provider': widget.provider!,
                              'providerId': widget.providerId ?? '',
                            },
                          );
                        } else {
                          Navigator.pushNamed(context, AppRoutes.signup);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canProceed ? Colors.blue : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementTile({
    required String title,
    required bool isChecked,
    required VoidCallback onTap,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onTap,
              child: const Text(
                '보기',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            Checkbox(
              value: isChecked,
              onChanged: onChanged,
              activeColor: Colors.blue,
              checkColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
