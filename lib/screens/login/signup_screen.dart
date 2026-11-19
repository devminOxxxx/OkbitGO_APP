import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:okbit_go_app/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 사용을 위해 다시 추가
import 'package:provider/provider.dart';
import 'package:okbit_go_app/providers/theme_provider.dart';
import 'package:okbit_go_app/utils/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = FirebaseAuth.instance;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _gradeController = TextEditingController();
  final _classController = TextEditingController();
  final _studentNumberController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _gradeController.dispose();
    _classController.dispose();
    _studentNumberController.dispose();
    super.dispose();
  }

  // 회원가입 기능
  Future<void> _signup() async {
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      // 비밀번호 확인 불일치 처리
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('비밀번호 불일치'),
            content: const Text('비밀번호가 일치하지 않습니다.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Firestore에 사용자 정보 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'grade': int.parse(_gradeController.text.trim()),
        'class': int.parse(_classController.text.trim()),
        'studentNumber': int.parse(_studentNumberController.text.trim()),
        'createdAt': Timestamp.now(),
        'isLoggedIn': false,
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // 오류 처리
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('회원가입 실패'),
            content: const Text('이미 사용 중인 이메일이거나 오류가 발생했습니다.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // 현재 테마에 따른 색상 설정
    final backgroundColor =
        isDarkMode ? kBackgroundColor : kLightBackgroundColor;
    final textColor = isDarkMode ? kTextColor : kLightTextColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('회원가입', style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이름 입력
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '이름',
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: textColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            // 이메일 입력
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '이메일',
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: textColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            // 비밀번호 입력
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '비밀번호',
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: textColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              style: TextStyle(color: textColor),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            // 비밀번호 확인 입력
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: textColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              style: TextStyle(color: textColor),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            // 학년 입력
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gradeController,
                    decoration: InputDecoration(
                      labelText: '학년',
                      labelStyle:
                          TextStyle(color: textColor.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: textColor.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _classController,
                    decoration: InputDecoration(
                      labelText: '반',
                      labelStyle:
                          TextStyle(color: textColor.withValues(alpha: 0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: textColor.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 번호 입력
            TextField(
              controller: _studentNumberController,
              decoration: InputDecoration(
                labelText: '번호',
                labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: textColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signup(),
            ),
            const SizedBox(height: 24),
            // 회원가입 버튼
            CustomButton(
              text: '회원가입',
              onPressed: _signup,
            ),
            const SizedBox(height: 16),
            // 로그인 화면으로 돌아가기
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '이미 계정이 있으신가요?',
                  style: TextStyle(color: textColor),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    '로그인',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
