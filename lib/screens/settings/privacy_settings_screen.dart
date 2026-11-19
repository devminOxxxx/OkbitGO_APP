import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common/custom_snackbar.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isLoading = false;

  // 개인정보 설정 상태
  final Map<String, bool> _privacySettings = {
    'profile_public': true, // 프로필 공개 여부
    'show_email': false, // 이메일 표시 여부
    'show_school': true, // 학교 정보 표시 여부
    'allow_search': true, // 검색 허용 여부
    'data_collection': true, // 데이터 수집 동의
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 설정 불러오기
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _privacySettings['profile_public'] =
            prefs.getBool('privacy_profile_public') ?? true;
        _privacySettings['show_email'] =
            prefs.getBool('privacy_show_email') ?? false;
        _privacySettings['show_school'] =
            prefs.getBool('privacy_show_school') ?? true;
        _privacySettings['allow_search'] =
            prefs.getBool('privacy_allow_search') ?? true;
        _privacySettings['data_collection'] =
            prefs.getBool('privacy_data_collection') ?? true;
      });
    } catch (e) {
      // 오류 처리
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 설정 저장하기
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(
          'privacy_profile_public', _privacySettings['profile_public']!);
      await prefs.setBool(
          'privacy_show_email', _privacySettings['show_email']!);
      await prefs.setBool(
          'privacy_show_school', _privacySettings['show_school']!);
      await prefs.setBool(
          'privacy_allow_search', _privacySettings['allow_search']!);
      await prefs.setBool(
          'privacy_data_collection', _privacySettings['data_collection']!);

      if (mounted) {
        CustomSnackbar.showSuccess(
          context: context,
          message: '개인정보 설정이 저장되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: '설정 저장 실패: $e',
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
      appBar: AppBar(
        title: const Text('개인정보 설정'),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveSettings,
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: '프로필 공개 설정',
                    children: [
                      _buildSwitchTile(
                        title: '프로필 공개',
                        subtitle: '다른 사용자에게 내 프로필을 공개합니다',
                        value: _privacySettings['profile_public']!,
                        onChanged: (value) {
                          setState(() {
                            _privacySettings['profile_public'] = value;
                          });
                        },
                        icon: Icons.person,
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        title: '이메일 표시',
                        subtitle: '프로필에 내 이메일을 표시합니다',
                        value: _privacySettings['show_email']!,
                        onChanged: (value) {
                          setState(() {
                            _privacySettings['show_email'] = value;
                          });
                        },
                        icon: Icons.email,
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        title: '학교 정보 표시',
                        subtitle: '프로필에 내 학교 정보를 표시합니다',
                        value: _privacySettings['show_school']!,
                        onChanged: (value) {
                          setState(() {
                            _privacySettings['show_school'] = value;
                          });
                        },
                        icon: Icons.school,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: '검색 및 데이터 설정',
                    children: [
                      _buildSwitchTile(
                        title: '검색 허용',
                        subtitle: '다른 사용자가 나를 검색할 수 있도록 허용합니다',
                        value: _privacySettings['allow_search']!,
                        onChanged: (value) {
                          setState(() {
                            _privacySettings['allow_search'] = value;
                          });
                        },
                        icon: Icons.search,
                      ),
                      const Divider(),
                      _buildSwitchTile(
                        title: '데이터 수집 동의',
                        subtitle: '앱 개선을 위한 사용 데이터 수집에 동의합니다',
                        value: _privacySettings['data_collection']!,
                        onChanged: (value) {
                          setState(() {
                            _privacySettings['data_collection'] = value;
                          });
                        },
                        icon: Icons.analytics,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
    );
  }

  Widget _buildInfoCard() {
    return const Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '개인정보 보호 정책',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '개인정보 설정은 앱 내에서 다른 사용자에게 표시되는 정보를 제어합니다. 자세한 내용은 개인정보 처리방침을 참조하세요.',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '개인정보 처리방침 보기',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
