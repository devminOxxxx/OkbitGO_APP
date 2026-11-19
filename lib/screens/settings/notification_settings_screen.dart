import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = false;
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final settings = userProvider.user?.notificationSettings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('시간표 알림'),
                  subtitle: const Text('매일 오전 8시에 시간표 알림을 받습니다.'),
                  value: (settings?['timetableEnabled'] as bool?) ?? false,
                  onChanged: (value) => _updateSettings(
                    context,
                    timetableEnabled: value,
                    mealEnabled: (settings?['mealEnabled'] as bool?) ?? false,
                  ),
                ),
                SwitchListTile(
                  title: const Text('급식 알림'),
                  subtitle: const Text('매일 오전 8시에 급식 알림을 받습니다.'),
                  value: (settings?['mealEnabled'] as bool?) ?? false,
                  onChanged: (value) => _updateSettings(
                    context,
                    timetableEnabled:
                        (settings?['timetableEnabled'] as bool?) ?? false,
                    mealEnabled: value,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _updateSettings(
    BuildContext context, {
    required bool timetableEnabled,
    required bool mealEnabled,
  }) async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (timetableEnabled || mealEnabled) {
        final hasPermission = await _notificationService.requestPermission();
        if (!hasPermission) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림 권한이 필요합니다.')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      await userProvider.updateUser(
        notificationSettings: {
          'timetableEnabled': timetableEnabled,
          'mealEnabled': mealEnabled,
        },
      );

      if (timetableEnabled) {
        await _notificationService.scheduleTimetableNotification();
      }
      if (mealEnabled) {
        await _notificationService.scheduleMealNotification();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 설정이 저장되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 설정 저장에 실패했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
