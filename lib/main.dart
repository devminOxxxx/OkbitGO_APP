import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:okbit_go_app/providers/navigation_provider.dart';
import 'package:okbit_go_app/providers/auth_provider.dart';
import 'package:okbit_go_app/providers/meal_provider.dart';
import 'package:okbit_go_app/providers/event_provider.dart';
import 'package:okbit_go_app/providers/timetable_provider.dart';
import 'package:okbit_go_app/providers/dday_provider.dart';
import 'package:okbit_go_app/providers/theme_provider.dart';
import 'package:okbit_go_app/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:okbit_go_app/firebase_options.dart';
import 'package:okbit_go_app/services/meal_service.dart';
import 'package:okbit_go_app/services/meal_storage_service.dart';
import 'package:okbit_go_app/services/timetable_service.dart';
import 'package:okbit_go_app/services/timetable_storage_service.dart';
import 'package:okbit_go_app/services/event_storage_service.dart';
import 'package:okbit_go_app/services/dday_storage_service.dart';
import 'providers/notice_provider.dart';
import 'providers/user_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/grade_storage_service.dart';
import 'services/timer_storage_service.dart';
import 'services/exam_storage_service.dart';
import 'services/notification_service.dart';
import 'providers/grade_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/exam_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/study_timer_provider.dart';
import 'providers/admin_provider.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:okbit_go_app/utils/logger_util.dart';
import 'package:okbit_go_app/utils/constants.dart';

void main() async {
  try {
    // Flutter 엔진 초기화
    WidgetsFlutterBinding.ensureInitialized();
    LoggerUtil.info('Flutter 엔진 초기화 완료');

    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    LoggerUtil.info('Firebase 초기화 완료');

    // 카카오 SDK 초기화
    KakaoSdk.init(
      nativeAppKey: kKakaoNativeAppKey,
    );
    LoggerUtil.info('카카오 SDK 초기화 완료');

    // 상태바 색상 설정
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    LoggerUtil.info('상태바 설정 완료');

    // 화면 방향 설정
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    LoggerUtil.info('화면 방향 설정 완료');

    // 스토리지 서비스 초기화
    LoggerUtil.info('스토리지 서비스 초기화 시작');
    final mealStorageService = await MealStorageService.create();
    final timeTableStorageService = await TimeTableStorageService.create();
    final eventStorageService = await EventStorageService.create();
    final ddayStorageService = await DDayStorageService.create();
    final gradeStorageService = await GradeStorageService.create();
    final timerStorageService = await TimerStorageService.create();
    final examStorageService = await ExamStorageService.create();
    LoggerUtil.info('스토리지 서비스 초기화 완료');

    // 알림 서비스 초기화
    LoggerUtil.info('알림 서비스 초기화 시작');
    final notificationService = NotificationService();
    await notificationService.initialize();
    LoggerUtil.info('알림 서비스 초기화 완료');

    LoggerUtil.info('앱 시작');
    runApp(MyApp(
      mealStorageService: mealStorageService,
      timeTableStorageService: timeTableStorageService,
      eventStorageService: eventStorageService,
      ddayStorageService: ddayStorageService,
      gradeStorageService: gradeStorageService,
      timerStorageService: timerStorageService,
      examStorageService: examStorageService,
      notificationService: notificationService,
    ));
  } catch (e, stackTrace) {
    LoggerUtil.error('앱 초기화 중 오류 발생', e, stackTrace);
    // 오류가 발생해도 앱을 시작하려고 시도
    runApp(const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            '앱 초기화 중 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final MealStorageService mealStorageService;
  final TimeTableStorageService timeTableStorageService;
  final EventStorageService eventStorageService;
  final DDayStorageService ddayStorageService;
  final GradeStorageService gradeStorageService;
  final TimerStorageService timerStorageService;
  final ExamStorageService examStorageService;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.mealStorageService,
    required this.timeTableStorageService,
    required this.eventStorageService,
    required this.ddayStorageService,
    required this.gradeStorageService,
    required this.timerStorageService,
    required this.examStorageService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DDayProvider(ddayStorageService)),
        ChangeNotifierProvider(
          create: (_) => MealProvider(
            MealService(),
            mealStorageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TimeTableProvider(
            TimeTableService(),
            timeTableStorageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => EventProvider(eventStorageService),
        ),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(
          create: (_) => GradeProvider(gradeStorageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ExamProvider(examStorageService),
        ),
        ChangeNotifierProvider(
          create: (_) => TimerProvider(timerStorageService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationService),
        ),
        ChangeNotifierProvider(
          create: (_) => StudyTimerProvider(),
        ),
        ChangeNotifierProxyProvider<NotificationProvider, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (_, notificationProvider, authProvider) {
            authProvider ??= AuthProvider();
            authProvider.setNotificationProvider(notificationProvider);
            return authProvider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, authProvider, userProvider) {
            if (authProvider.user != null && userProvider != null) {
              userProvider.loadUser(authProvider.user!.uid);
            }
            return userProvider!;
          },
        ),
        ChangeNotifierProxyProvider<NotificationProvider, AdminProvider>(
          create: (_) => AdminProvider(),
          update: (_, notificationProvider, adminProvider) {
            adminProvider ??= AdminProvider();
            adminProvider.setNotificationProvider(notificationProvider);
            return adminProvider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final ThemeData themeWithFont = ThemeData(
            fontFamily: kDefaultFontFamily,
            brightness: themeProvider.themeData.brightness,
            primaryColor: themeProvider.themeData.primaryColor,
            colorScheme: themeProvider.themeData.colorScheme,
            appBarTheme: themeProvider.themeData.appBarTheme.copyWith(
              titleTextStyle:
                  themeProvider.themeData.appBarTheme.titleTextStyle?.copyWith(
                fontFamily: kDefaultFontFamily,
              ),
            ),
            cardTheme: themeProvider.themeData.cardTheme,
            tabBarTheme: themeProvider.themeData.tabBarTheme.copyWith(
              labelStyle: const TextStyle(fontFamily: kDefaultFontFamily),
              unselectedLabelStyle:
                  const TextStyle(fontFamily: kDefaultFontFamily),
            ),
            bottomNavigationBarTheme:
                themeProvider.themeData.bottomNavigationBarTheme,
            textTheme: themeProvider.themeData.textTheme.apply(
              fontFamily: kDefaultFontFamily,
              bodyColor: themeProvider.themeData.brightness == Brightness.dark
                  ? kTextColor
                  : kLightTextColor,
              displayColor:
                  themeProvider.themeData.brightness == Brightness.dark
                      ? kTextColor
                      : kLightTextColor,
            ),
            dividerTheme: themeProvider.themeData.dividerTheme,
            inputDecorationTheme:
                themeProvider.themeData.inputDecorationTheme.copyWith(
              labelStyle: themeProvider
                  .themeData.inputDecorationTheme.labelStyle
                  ?.copyWith(
                fontFamily: kDefaultFontFamily,
              ),
              hintStyle: TextStyle(
                fontFamily: kDefaultFontFamily,
                color: themeProvider.themeData.brightness == Brightness.dark
                    ? kTextSecondaryColor
                    : kLightTextSecondaryColor,
              ),
            ),
            elevatedButtonTheme: themeProvider.themeData.elevatedButtonTheme,
            dialogTheme: themeProvider.themeData.dialogTheme.copyWith(
              titleTextStyle: TextStyle(
                fontFamily: kDefaultFontFamily,
                fontSize: kFontSizeXXXLarge,
                fontWeight: kFontWeightBold,
                color: themeProvider.themeData.brightness == Brightness.dark
                    ? kTextColor
                    : kLightTextColor,
              ),
              contentTextStyle: TextStyle(
                fontFamily: kDefaultFontFamily,
                fontSize: kFontSizeRegular,
                color: themeProvider.themeData.brightness == Brightness.dark
                    ? kTextSecondaryColor
                    : kLightTextSecondaryColor,
              ),
            ),
          );

          return MaterialApp(
            title: 'OKBIT GO',
            theme: themeWithFont,
            darkTheme: themeWithFont.copyWith(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212),
              colorScheme: const ColorScheme.dark(
                primary: Colors.blue,
                secondary: Colors.blueAccent,
                surface: Color(0xFF1E1E1E),
                error: Colors.red,
              ),
            ),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko', 'KR'),
            ],
            locale: const Locale('ko', 'KR'),
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            routes: AppRoutes.getRoutes(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.0)),
                child: Scaffold(
                  resizeToAvoidBottomInset: true,
                  body: child!,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
