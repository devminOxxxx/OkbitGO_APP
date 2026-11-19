import 'package:flutter/material.dart';
import 'package:okbit_go_app/screens/login/login_screen.dart';
import 'package:okbit_go_app/screens/login/signup_screen.dart';
import 'package:okbit_go_app/screens/login/social_login_screen.dart';
import 'package:okbit_go_app/screens/login/terms_agreement_screen.dart';
import 'package:okbit_go_app/screens/login/additional_info_screen.dart';

import 'package:okbit_go_app/screens/splash/splash_screen.dart';
import 'package:okbit_go_app/screens/main_screen.dart';
import 'package:okbit_go_app/providers/navigation_provider.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/notice_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/dday_form_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/settings/theme_settings_screen.dart';
import 'screens/settings/customer_service_screen.dart';
import 'screens/settings/account_info_screen.dart';
import 'screens/settings/terms_of_service_screen.dart';
import 'screens/settings/privacy_policy_screen.dart';
import 'screens/settings/open_source_license_screen.dart';
import 'screens/settings/app_notice_screen.dart';
import 'screens/fortune_screen.dart';
import 'screens/dday_list_screen.dart';
import 'screens/timetable_screen.dart';
import '../../utils/enums.dart';
import 'screens/settings/account_settings_screen.dart';
import 'screens/settings/my_info_screen.dart';

class AppRoutes {
  // 앱의 라우터 정의
  static const String splash = '/';
  static const String socialLogin = '/social-login';
  static const String login = '/login';
  static const String additionalInfo = '/additional-info';
  static const String termsAgreement = '/terms-agreement';

  static const String home = '/home';
  static const String signup = '/signup';
  static const String main = '/main';
  static const String schoolLife = '/school-life';
  static const String community = '/community';
  static const String settings = '/settings';
  static const String notice = '/notice';
  static const String noticeDetail = '/notice-detail';
  static const String fortune = '/fortune';
  static const String ddayForm = '/dday-form';
  static const String notifications = '/notifications';
  static const String ddays = '/ddays';
  static const String timetable = '/timetable';

  // 설정 화면 관련 라우트
  static const String notificationSettings = '/settings/notifications';
  static const String themeSettings = '/settings/theme';
  static const String customerService = '/customer-service';
  static const String accountInfo = '/settings/account-info';
  static const String accountSettings = '/settings/account-settings';
  static const String myInfo = '/settings/my-info';
  static const String termsOfService = '/settings/terms-of-service';
  static const String privacyPolicy = '/settings/privacy-policy';
  static const String openSourceLicense = '/settings/open-source-license';
  static const String appNotice = '/settings/app-notice';

  // 라우터 설정
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      socialLogin: (context) => const SocialLoginScreen(),
      login: (context) => const LoginScreen(),
      termsAgreement: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return TermsAgreementScreen(
          email: args?['email'],
          name: args?['name'],
          provider: args?['provider'],
          providerId: args?['providerId'],
        );
      },
      home: (context) => const HomeScreen(),
      signup: (context) => const SignupScreen(),
      main: (context) => const MainScreen(),
      notice: (context) => const NoticeScreen(),
      notifications: (context) => const NotificationScreen(),
      fortune: (context) => const FortuneScreen(),
      ddayForm: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        return DDayFormScreen(dday: args as dynamic);
      },
      ddays: (context) => const DDayListScreen(),
      timetable: (context) => const TimeTableScreen(),
      notificationSettings: (context) => const NotificationSettingsScreen(),
      themeSettings: (context) => const ThemeSettingsScreen(),
      customerService: (context) => const CustomerServiceScreen(),
      accountInfo: (context) => const AccountInfoScreen(),
      accountSettings: (context) => const AccountSettingsScreen(),
      myInfo: (context) => const MyInfoScreen(),
      termsOfService: (context) => const TermsOfServiceScreen(),
      privacyPolicy: (context) => const PrivacyPolicyScreen(),
      openSourceLicense: (context) => const OpenSourceLicenseScreen(),
      appNotice: (context) => const AppNoticeScreen(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (settings.name?.startsWith('$main/') ?? false) {
      final tabName = settings.name!.split('/').last;
      final tab = NavigationTab.values.firstWhere(
        (tab) => tab.name == tabName,
        orElse: () => NavigationTab.home,
      );

      return MaterialPageRoute(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<NavigationProvider>().setTab(tab);
          });
          return const MainScreen();
        },
      );
    }

    // 추가 정보 화면 처리
    if (settings.name == additionalInfo) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => AdditionalInfoScreen(
          email: args['email'],
          name: args['name'],
          provider: args['provider'],
          providerId: args['providerId'],
          agreedToMarketing: args['agreedToMarketing'] ?? false,
        ),
      );
    }

    final routes = getRoutes();
    final WidgetBuilder? builder = routes[settings.name];

    if (builder != null) {
      return MaterialPageRoute(builder: builder);
    }

    return MaterialPageRoute(builder: (context) => const SplashScreen());
  }
}

final Map<String, WidgetBuilder> routes = {
  '/': (context) => const HomeScreen(),
  '/main': (context) => const MainScreen(),
};
