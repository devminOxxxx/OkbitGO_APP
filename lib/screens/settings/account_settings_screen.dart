import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '계정 설정',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 이미지 섹션
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 기본 정보 항목들
            _buildInfoItem(context, '이름', user.name, Icons.chevron_right, () {
              // 이름 변경 기능 (추후 구현)
            }),
            _buildInfoItem(
              context,
              '이메일 주소',
              user.email,
              Icons.chevron_right,
              () {
                _showChangeEmailDialog(context);
              },
            ),
            _buildInfoItem(context, '비밀번호', '********', Icons.chevron_right,
                () {
              _showChangePasswordDialog(context);
            }),
            _buildInfoItem(
                context, '학년', user.grade ?? '설정 필요', Icons.chevron_right, () {
              _showGradeDialog(context);
            }),
            _buildInfoItem(
                context, '반', user.classNumber ?? '설정 필요', Icons.chevron_right,
                () {
              _showClassDialog(context);
            }),
            _buildInfoItem(context, '번호', user.studentNumber ?? '설정 필요',
                Icons.chevron_right, () {
              _showStudentNumberDialog(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String title, String value,
      IconData? icon, VoidCallback? onPressed) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: value == '없음' || value == '설정 필요'
                          ? Colors.grey
                          : Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 10),
                  Icon(icon, color: Colors.grey, size: 16),
                ],
              ],
            ),
          ),
        ),
        const Divider(
          height: 1,
          color: Colors.grey,
          indent: 20,
          endIndent: 20,
        ),
      ],
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

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 변경'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: '현재 비밀번호',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '현재 비밀번호를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '새 비밀번호를 입력해주세요';
                      }
                      if (value.length < 6) {
                        return '비밀번호는 6자 이상이어야 합니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호 확인',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '새 비밀번호를 다시 입력해주세요';
                      }
                      if (value != newPasswordController.text) {
                        return '비밀번호가 일치하지 않습니다';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  await _changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                }
              },
              child: const Text('변경'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword(
      String currentPassword, String newPassword) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.changePassword(currentPassword, newPassword);

      if (mounted) {
        CustomSnackbar.showSuccess(
          context: context,
          message: '비밀번호가 변경되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: '비밀번호 변경 실패: $e',
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

  Future<void> _confirmLogout(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: '로그아웃 실패: $e',
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

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final TextEditingController passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('계정 삭제'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '계정을 삭제하면 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다. 정말 삭제하시겠습니까?',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  await _deleteAccount(passwordController.text);
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(String password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.deleteAccount(password);

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: '계정 삭제 실패: $e',
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

  // 학년 선택 다이얼로그
  Future<void> _showGradeDialog(BuildContext context) async {
    final TextEditingController gradeController = TextEditingController();
    gradeController.text =
        Provider.of<UserProvider>(context, listen: false).user?.grade ?? '';

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('학년 설정', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: gradeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '학년',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: '1~3',
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (gradeController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _updateUserField('grade', gradeController.text);
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  // 반 선택 다이얼로그
  Future<void> _showClassDialog(BuildContext context) async {
    final TextEditingController classController = TextEditingController();
    classController.text =
        Provider.of<UserProvider>(context, listen: false).user?.classNumber ??
            '';

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('반 설정', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: classController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '반',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: '1~10',
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (classController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _updateUserField('classNumber', classController.text);
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  // 번호 선택 다이얼로그
  Future<void> _showStudentNumberDialog(BuildContext context) async {
    final TextEditingController studentNumberController =
        TextEditingController();
    studentNumberController.text =
        Provider.of<UserProvider>(context, listen: false).user?.studentNumber ??
            '';

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('번호 설정', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: studentNumberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '번호',
              labelStyle: TextStyle(color: Colors.white70),
              hintText: '1~40',
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (studentNumberController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _updateUserField(
                      'studentNumber', studentNumberController.text);
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  // 사용자 필드 업데이트
  Future<void> _updateUserField(String field, String value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // 필드에 따라 적절한 메서드 호출
      switch (field) {
        case 'grade':
          await userProvider.updateUser(grade: value);
          break;
        case 'classNumber':
          await userProvider.updateUser(classNumber: value);
          break;
        case 'studentNumber':
          await userProvider.updateUser(studentNumber: value);
          break;
        default:
          throw Exception('지원하지 않는 필드: $field');
      }

      if (mounted) {
        CustomSnackbar.showSuccess(
          context: context,
          message: '정보가 업데이트되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          message: '정보 업데이트 실패: $e',
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

  Future<void> _showChangeEmailDialog(BuildContext context) async {
    final TextEditingController emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    emailController.text = user?.email ?? '';

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            '이메일 변경',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user?.email != null &&
                    user!.email!.contains('@temp.okbit.com')) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '임시 이메일을 실제 이메일로 변경해주세요.',
                            style:
                                TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: '새 이메일',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  await _changeEmail(emailController.text);
                }
              },
              child: const Text('변경'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeEmail(String newEmail) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      // Firebase Auth 이메일 업데이트
      await user.verifyBeforeUpdateEmail(newEmail);

      // Firestore 업데이트 (임시 이메일 플래그만 변경)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isTemporaryEmail': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // UserProvider 새로고침
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshUser();

      if (mounted) {
        CustomSnackbar.showSuccess(
          context: context,
          message: '이메일 검증 이메일이 발송되었습니다. 이메일을 확인하여 변경을 완료해주세요.',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '이메일 변경에 실패했습니다.';

        if (e.toString().contains('requires-recent-login')) {
          errorMessage = '보안을 위해 다시 로그인해주세요.';
        } else if (e.toString().contains('email-already-in-use')) {
          errorMessage = '이미 사용 중인 이메일입니다.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = '올바르지 않은 이메일 형식입니다.';
        }

        CustomSnackbar.showError(
          context: context,
          message: errorMessage,
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
}
