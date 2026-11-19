import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:okbit_go_app/providers/navigation_provider.dart';
import 'package:okbit_go_app/providers/theme_provider.dart';
import 'package:okbit_go_app/providers/notification_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:okbit_go_app/utils/constants.dart';

import '../utils/enums.dart';
import 'home_screen.dart';
import 'school_life_screen.dart';
import 'events_screen.dart';
import 'settings_screen.dart';
import '../utils/logger_util.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static final Map<NavigationTab, Widget> _screens = {
    NavigationTab.home: const HomeScreen(),
    NavigationTab.schoolLife: const SchoolLifeScreen(),
    NavigationTab.events: const EventsScreen(),
    NavigationTab.settings: const SettingsScreen(),
  };

  @override
  void initState() {
    super.initState();
    // 화면이 로드된 후 임시 이메일 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTemporaryEmail();
    });
  }

  // 임시 이메일 사용자 확인 및 업데이트 다이얼로그 표시
  Future<void> _checkTemporaryEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final isTemporaryEmail = data?['isTemporaryEmail'] ?? false;

          if (isTemporaryEmail && mounted) {
            _showEmailUpdateDialog();
          }
        }
      }
    } catch (e) {
      LoggerUtil.error('임시 이메일 확인 오류', e);
    }
  }

  // 이메일/비밀번호 업데이트 다이얼로그
  void _showEmailUpdateDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // 뒤로가기로 닫을 수 없음
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            '이메일 및 비밀번호 설정',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '계정 보안을 위해 실제 이메일과 비밀번호를 설정해주세요.\n\n이메일 변경 시 검증 이메일이 발송됩니다.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return '올바른 이메일 형식을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: '새 비밀번호',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 다시 입력해주세요';
                    }
                    if (value != passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    '업데이트 중...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!isLoading) ...[
              TextButton(
                onPressed: () {
                  // 나중에 설정하기 옵션
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('설정 > 계정 설정에서 나중에 변경할 수 있습니다.'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text('나중에'),
              ),
            ],
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            throw Exception('사용자 정보를 찾을 수 없습니다.');
                          }

                          // 1단계: 이메일 업데이트
                          try {
                            await user
                                .verifyBeforeUpdateEmail(emailController.text);
                            LoggerUtil.info('이메일 검증 이메일 발송 성공');
                          } catch (emailError) {
                            LoggerUtil.error('이메일 업데이트 실패', emailError);
                            throw Exception('이메일 업데이트 실패: $emailError');
                          }

                          // 2단계: 비밀번호 업데이트
                          try {
                            await user.updatePassword(passwordController.text);
                            LoggerUtil.info('비밀번호 업데이트 성공');
                          } catch (passwordError) {
                            LoggerUtil.error('비밀번호 업데이트 실패', passwordError);
                            throw Exception('비밀번호 업데이트 실패: $passwordError');
                          }

                          // 3단계: Firestore 업데이트 (임시 이메일 플래그만 변경)
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({
                              'isTemporaryEmail': false,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                            LoggerUtil.info('Firestore 업데이트 성공');
                          } catch (firestoreError) {
                            LoggerUtil.error(
                                'Firestore 업데이트 실패', firestoreError);
                            // Firestore 업데이트 실패는 경고만 표시 (Auth는 성공했으므로)
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('비밀번호는 업데이트되었지만, 서버 동기화에 실패했습니다.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              Navigator.of(context).pop();
                              return;
                            }
                          }

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '이메일 검증 이메일이 발송되었습니다. 이메일을 확인하여 변경을 완료해주세요.'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 6),
                              ),
                            );
                          }
                        } catch (e) {
                          LoggerUtil.error('업데이트 전체 실패', e);
                          if (context.mounted) {
                            String errorMessage = '업데이트에 실패했습니다.';

                            // 구체적인 에러 메시지
                            if (e
                                .toString()
                                .contains('requires-recent-login')) {
                              errorMessage = '보안을 위해 다시 로그인해주세요.';
                            } else if (e
                                .toString()
                                .contains('email-already-in-use')) {
                              errorMessage = '이미 사용 중인 이메일입니다.';
                            } else if (e.toString().contains('weak-password')) {
                              errorMessage = '비밀번호가 너무 약합니다.';
                            } else if (e.toString().contains('invalid-email')) {
                              errorMessage = '올바르지 않은 이메일 형식입니다.';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      }
                    },
              child: Text(isLoading ? '처리 중...' : '저장'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // 현재 테마에 따른 색상 설정
    final backgroundColor =
        isDarkMode ? kBackgroundColor : kLightBackgroundColor;
    final unselectedColor = isDarkMode ? Colors.grey : Colors.grey.shade600;

    return Consumer<NavigationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: IndexedStack(
            index: provider.currentIndex,
            children: _screens.values.toList(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: provider.currentIndex,
            onTap: provider.setIndex,
            backgroundColor: backgroundColor,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: unselectedColor,
            items: _buildNavigationBarItems(context),
          ),
        );
      },
    );
  }

  List<BottomNavigationBarItem> _buildNavigationBarItems(BuildContext context) {
    return [
      BottomNavigationBarItem(
        icon: Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.home),
                if (notificationProvider.hasUnreadNotifications)
                  Positioned(
                    top: -2,
                    right: -6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        label: '홈',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.school),
        label: '학교생활',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.event),
        label: '이벤트',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: '설정',
      ),
    ];
  }
}
