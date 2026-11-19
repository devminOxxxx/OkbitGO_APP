import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/theme.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  ThemeType _selectedThemeType = ThemeType.system;

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  void _loadCurrentTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _selectedThemeType = themeProvider.themeType;
    });
  }

  void _updateTheme(ThemeType themeType) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _selectedThemeType = themeType;
    });
    themeProvider.setTheme(themeType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('테마 설정'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThemeSelectionSection(),
            const SizedBox(height: 24),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '테마 선택',
          style: TextStyle(
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
              children: [
                _buildThemeOption(
                  themeType: ThemeType.light,
                  title: '라이트 테마',
                  subtitle: '밝은 색상의 테마',
                  icon: Icons.light_mode,
                ),
                const Divider(),
                _buildThemeOption(
                  themeType: ThemeType.dark,
                  title: '다크 테마',
                  subtitle: '어두운 색상의 테마',
                  icon: Icons.dark_mode,
                ),
                const Divider(),
                _buildThemeOption(
                  themeType: ThemeType.system,
                  title: '시스템 테마',
                  subtitle: '기기의 테마 설정에 따라 자동으로 테마가 변경됩니다',
                  icon: Icons.brightness_auto,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required ThemeType themeType,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return RadioListTile<ThemeType>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: themeType,
      groupValue: _selectedThemeType,
      onChanged: (value) => _updateTheme(value!),
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
              '테마 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '테마를 변경하면 앱의 전체적인 색상과 디자인이 변경됩니다. 시스템 테마를 사용하면 기기의 테마 설정에 따라 자동으로 라이트 또는 다크 테마가 적용됩니다.',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
