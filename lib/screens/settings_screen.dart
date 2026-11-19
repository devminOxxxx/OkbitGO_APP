import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../routes.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'school_life/timer_screen.dart';
import 'admin/admin_panel_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          kSettingsTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용자 정보 카드
            if (user != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: kAccentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0] : '?',
                          style: const TextStyle(
                            color: kAccentColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${user.grade ?? '?'}학년 ${user.classNumber ?? '?'}반 ${user.studentNumber ?? '?'}번',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 개인정보 카테고리
            _buildCategoryHeader('내 정보 관리'),
            _buildSettingItem(
              title: '내 정보 관리',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.myInfo);
              },
            ),

            const SizedBox(height: kSpacing),

            // 설정 카테고리
            _buildCategoryHeader('설정'),
            _buildSettingItem(
              title: kNotificationSettingsTitle,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.notificationSettings);
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              title: kThemeSettingsTitle,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.themeSettings);
              },
            ),

            const SizedBox(height: kSpacing),

            // 학습 도구 카테고리
            _buildCategoryHeader('학습 도구'),
            _buildSettingItem(
              title: '타이머',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TimerScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: kSpacing),

            // 기타 카테고리
            _buildCategoryHeader('기타'),
            _buildSettingItem(
              title: kCustomerServiceTitle,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.customerService);
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              title: kNoticeTitle,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.notice);
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              title: kTermsOfServiceTitle,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.termsOfService);
              },
            ),
            _buildDivider(),
            _buildSettingItem(
              title: kOpenSourceLicenseTitle,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.openSourceLicense);
              },
            ),
            _buildDivider(),
            // 관리자 권한이 있는 사용자에게만 표시
            if (user?.isAdmin == true)
              _buildSettingItem(
                title: '관리자 패널',
                onTap: () {
                  // 관리자 권한이 있으면 바로 관리자 패널로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminPanelScreen(),
                    ),
                  );
                },
              ),

            const SizedBox(height: kSpacing * 2),
            Center(
              child: Text(
                '© $kAppYear 옥빛GO!',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: kSpacing),
            Center(
              child: Text(
                '버전 1.0.0',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: kSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: kTitleStyle,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: kIconSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: kBorderColor,
      height: 1,
      indent: 16.0,
      endIndent: 16.0,
    );
  }
}
