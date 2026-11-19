import 'package:flutter/material.dart';
import '../config/secrets.dart';

// App Constants
const kLocale = 'ko_KR';
const kAppYear = 2025; // 앱 기준 연도
const kSchoolName = '옥빛고등학교'; // 학교 이름
const kDefaultGrade = '1'; // 기본 학년
const kDefaultClass = '3'; // 기본 반

// API Keys & URLs (값은 git에 올라가지 않는 secrets.dart에서 읽음)
const kKakaoNativeAppKey = Secrets.kakaoNativeAppKey;
const kSchoolBaseUrl = 'https://okbit-h.goedy.kr';
const kSchoolMainUrl = '$kSchoolBaseUrl/okbit-h/main.do';

// NEIS API
const kNeisApiKey = Secrets.neisApiKey;
const kSchoolCode = '7531393'; // 옥빛고등학교 코드
const kOfficeCode = 'J10'; // 경기도교육청 코드

// Server Configuration
const kDevServerUrl = 'http://localhost:3000';
const kProdServerUrl = 'https://your-auth-server.herokuapp.com';
const kIsProduction = false;

// Font Constants
const kDefaultFontFamily = 'GmarketSansMedium';

// Font Size Constants
const kFontSizeXSmall = 10.0;
const kFontSizeSmall = 12.0;
const kFontSizeMedium = 13.0;
const kFontSizeRegular = 14.0;
const kFontSizeLarge = 15.0;
const kFontSizeXLarge = 16.0;
const kFontSizeXXLarge = 17.0;
const kFontSizeXXXLarge = 18.0;
const kFontSizeTitle = 20.0;
const kFontSizeHeading = 24.0;

// Font Weight Constants
const kFontWeightRegular = FontWeight.w400;
const kFontWeightMedium = FontWeight.w500;
const kFontWeightSemiBold = FontWeight.w600;
const kFontWeightBold = FontWeight.bold;

// Colors
const kBackgroundColor = Color(0xFF121212);
const kSurfaceColor = Color(0xFF1E1E1E);
const kBorderColor = Color(0xFF2A2A2A);
const kAccentColor = Colors.blue;
const kBackButtonColor = Color(0xFFFFFFFF); // 뒤로가기 버튼 색상 (순수 흰색)

// 다크 테마 추가 색상
const kTextColor = Colors.white;
const kTextSecondaryColor = Color(0xFFB3B3B3); // 회색 텍스트 색상
const kTextTertiaryColor = Color(0xFF808080); // 더 어두운 회색 텍스트 색상
const kInactiveColor = Color(0xFF4D4D4D); // 비활성화 색상

// 라이트 테마 색상
const kLightBackgroundColor = Colors.white;
const kLightSurfaceColor = Color(0xFFF5F5F5);
const kLightBorderColor = Color(0xFFEEEEEE);
const kLightTextColor = Colors.black;
const kLightTextSecondaryColor = Color(0xFF666666);
const kLightTextTertiaryColor = Color(0xFFAAAAAA);

// Text Styles
const kTitleStyle = TextStyle(
  color: Colors.white,
  fontSize: kFontSizeXLarge,
  fontWeight: kFontWeightSemiBold,
  fontFamily: kDefaultFontFamily,
);

const kSubtitleStyle = TextStyle(
  color: Colors.white70,
  fontSize: kFontSizeRegular,
  fontWeight: kFontWeightRegular,
  fontFamily: kDefaultFontFamily,
);

const kTabStyle = TextStyle(
  fontSize: kFontSizeRegular,
  fontWeight: kFontWeightSemiBold,
  fontFamily: kDefaultFontFamily,
);

const kUnselectedTabStyle = TextStyle(
  fontSize: kFontSizeRegular,
  fontWeight: kFontWeightMedium,
  fontFamily: kDefaultFontFamily,
);

// UI Constants
const kSpacing = 16.0;
const kSmallSpacing = 8.0;
const kBorderRadius = 12.0;
const kSmallBorderRadius = 8.0;
const kCircularBorderRadius = 20.0;
const kIconSize = 20.0;
const kIconSizeSmall = 16.0;
const kIconSizeLarge = 24.0;

// Padding Constants
const kPaddingXSmall = 4.0;
const kPaddingSmall = 8.0;
const kPaddingMedium = 12.0;
const kPaddingLarge = 16.0;
const kPaddingXLarge = 24.0;

// Margin Constants
const kMarginXSmall = 4.0;
const kMarginSmall = 8.0;
const kMarginMedium = 12.0;
const kMarginLarge = 16.0;
const kMarginXLarge = 24.0;

// Size Constants
const kButtonMinWidth = 36.0;
const kButtonMinHeight = 36.0;
const kCardWidth = 24.0;
const kCardHeight = 24.0;
const kTimetableCellHeight = 65.0;
const kTimetableHeaderHeight = 45.0;
const kTimetableTimeWidth = 50.0;
const kTimetableCaptureTimeWidth = 60.0;
const kTimetableCaptureHeaderHeight = 50.0;
const kTimetableCaptureCellHeight = 70.0;
const kCalendarCellWidth = 30.0;
const kCalendarCellHeight = 24.0;

// Border Width Constants
const kBorderWidthThin = 0.5;
const kBorderWidthRegular = 1.0;
const kBorderWidthThick = 2.0;

// Line Height Constants
const kLineHeightTight = 1.1;
const kLineHeightNormal = 1.2;
const kLineHeightLoose = 1.5;

// Error Messages
const kLoadFailedMessage = '데이터를 불러오는데 실패했습니다.';
const kNoDataMessage = '데이터가 없습니다.';
const kRetryButtonText = '다시 시도';
const kRefreshButtonText = '새로고침';

// Dialog Constants
const kDialogMaxHeightFactor = 0.8;
const kDialogPadding = 20.0;
const kDialogIconSize = 24.0;
const kDialogTitleSize = 18.0;

// Screen Titles
const kSchoolLifeTitle = '학교생활';
const kSettingsTitle = '서비스 설정';
const kNotificationSettingsTitle = '알림 설정';
const kProfileSettingsTitle = '내 정보 관리';
const kThemeSettingsTitle = '화면 테마 설정';
const kCustomerServiceTitle = '고객 센터';
const kAccountInfoTitle = '계정 정보';
const kTermsOfServiceTitle = '서비스 이용 약관';
const kPrivacyPolicyTitle = '개인정보 처리방침';
const kOpenSourceLicenseTitle = '오픈소스 라이선스';
const kNoticeTitle = '공지사항';
const kFortuneTitle = '오늘의 운세';

// Settings Screen
const kNotificationSettingsSubtitle = '알림 수신 여부를 설정합니다';
const kProfileSettingsSubtitle = '개인 정보를 관리합니다';
const kThemeSettingsSubtitle = '앱 테마를 설정합니다';
const kCustomerServiceSubtitle = '문의 및 건의사항을 등록합니다';
const kAccountInfoSubtitle = '계정 관련 정보를 확인합니다';
const kTermsOfServiceSubtitle = '서비스 이용 약관을 확인합니다';
const kPrivacyPolicySubtitle = '개인정보 처리방침을 확인합니다';
const kOpenSourceLicenseSubtitle = '오픈소스 라이선스를 확인합니다';
const kNoticeSubtitle = '앱 관련 공지사항을 확인합니다';

// Fortune Messages
const kStudyFortunes = [
  '오늘은 집중력이 높아지는 날입니다. 어려운 과목에 도전해보세요.',
  '새로운 학습 방법을 시도하면 좋은 결과가 있을 것입니다.',
  '오늘 공부한 내용은 오래 기억에 남을 것입니다. 중요한 내용을 복습하세요.',
  '그룹 스터디가 효과적인 날입니다. 친구들과 함께 공부해보세요.',
  '오늘은 창의적인 사고가 필요한 과목에 집중하면 좋습니다.',
  '꾸준한 노력이 결실을 맺는 날입니다. 포기하지 마세요.',
  '어려운 문제도 차근차근 풀어나가면 해결할 수 있습니다.',
  '오늘은 복습이 중요한 날입니다. 이전에 배운 내용을 정리해보세요.',
  '새로운 지식을 얻기 좋은 날입니다. 관심 있는 분야를 탐구해보세요.',
  '집중력이 떨어질 수 있으니 짧은 휴식을 자주 취하는 것이 좋습니다.',
  '오늘 배운 내용을 실생활에 적용해보면 더 깊이 이해할 수 있습니다.',
  '어려운 과목도 오늘은 이해가 잘 될 것입니다. 도전해보세요.',
];

const kLoveFortunes = [
  '오늘은 솔직한 대화가 행운을 가져올 것입니다.',
  '평소보다 더 적극적인 모습을 보이면 좋은 인연이 찾아올 수 있습니다.',
  '작은 배려가 큰 감동을 줄 수 있는 날입니다.',
  '오해가 생길 수 있으니 의사소통에 주의하세요.',
  '오늘은 새로운 만남이 있을 수 있는 날입니다. 기회를 놓치지 마세요.',
  '상대방의 마음을 이해하려는 노력이 필요한 날입니다.',
  '평소 관심 있던 사람에게 다가가기 좋은 날입니다.',
  '작은 선물이나 메시지가 큰 효과를 볼 수 있습니다.',
  '오늘은 솔로라면 새로운 인연을, 연인이 있다면 더 깊은 관계로 발전할 수 있는 날입니다.',
  '감정을 솔직하게 표현하면 좋은 결과가 있을 것입니다.',
  '상대방의 작은 변화에 민감하게 반응하지 마세요.',
  '오늘은 자신을 돌아보고 사랑하는 시간을 가져보세요.',
];

// 알레르기 정보
const Map<String, List<String>> kAllergyItems = {
  '해산물': ['7.고등어', '8.게', '9.새우', '17.오징어', '18.조개류'],
  '육류': ['10.돼지고기', '15.닭고기', '16.쇠고기'],
  '곡류': ['3.메밀', '6.밀'],
  '견과류': ['4.땅콩', '14.호두', '19.잣'],
  '기타': ['1.난류', '2.우유', '5.대두', '11.복숭아', '12.토마토', '13.아황산류'],
};

class Assets {
  static const String logo = 'assets/images/okbit_logo.png';
}

class Constants {
  static const String emailLabel = '이메일';
  static const String passwordLabel = '비밀번호';
  static const String loginButtonText = '로그인';
  static const String loginTitle = '로그인';
  static const String signupPrompt = '회원가입이 필요하신가요?';
  static const String signupButtonText = '회원가입';
}
