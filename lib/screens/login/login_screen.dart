import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:okbit_go_app/providers/auth_provider.dart';
import 'package:okbit_go_app/providers/navigation_provider.dart';
import 'package:okbit_go_app/utils/constants.dart'; // 상수 파일을 import
import 'package:cloud_firestore/cloud_firestore.dart';
// 테마 파일을 import
import 'package:okbit_go_app/widgets/custom_button.dart';
import 'package:okbit_go_app/providers/theme_provider.dart';
import 'package:okbit_go_app/widgets/common/custom_text_field.dart'; // 새로 만든 위젯 import
import 'package:okbit_go_app/routes.dart'; // AppRoutes import

import '../../utils/enums.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // 로그인 기능
  Future<void> _login() async {
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      final user = authProvider.user;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'isLoggedIn': true}, SetOptions(merge: true));

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        context.read<NavigationProvider>().setTab(NavigationTab.home);
      }
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('로그인 실패'),
            content: const Text('이메일 또는 비밀번호가 잘못되었습니다.'),
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

  // 로그인 상태 확인
  Future<void> _checkLoginStatus() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final isLoggedIn = doc.data()?['isLoggedIn'] ?? false;
      if (isLoggedIn && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        context.read<NavigationProvider>().setTab(NavigationTab.home);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 이메일 입력 필드에 자동 포커스 설정
    FocusScope.of(context).requestFocus(_emailFocusNode);
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          Constants.loginTitle,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0, // 그림자 제거
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 이메일 입력
                CustomTextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  labelText: Constants.emailLabel,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                  textColor: textColor,
                  labelColor: textColor.withValues(alpha: 0.7),
                  borderColor: textColor.withValues(alpha: 0.3),
                  focusedBorderColor: Theme.of(context).primaryColor,
                  autofocus: true,
                  enableSuggestions: true,
                  autocorrect: false,
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                const SizedBox(height: 16),
                // 비밀번호 입력
                CustomTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  labelText: Constants.passwordLabel,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  textColor: textColor,
                  labelColor: textColor.withValues(alpha: 0.7),
                  borderColor: textColor.withValues(alpha: 0.3),
                  focusedBorderColor: Theme.of(context).primaryColor,
                  enableSuggestions: false,
                  autocorrect: false,
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                const SizedBox(height: 24),
                // 로그인 버튼
                CustomButton(
                    text: Constants.loginButtonText, onPressed: _login),
                const SizedBox(height: 16),
                // 회원가입 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Constants.signupPrompt,
                      style: TextStyle(color: textColor),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.termsAgreement);
                      },
                      child: Text(
                        Constants.signupButtonText,
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
