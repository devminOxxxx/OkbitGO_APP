import '../utils/constants.dart';

class ApiConfig {
  static const String neisApiKey = kNeisApiKey;

  // 학교 정보
  static const String schoolCode = kSchoolCode;
  static const String officeCode = kOfficeCode;

  // 서버 URL
  static String get serverUrl {
    return kIsProduction ? kProdServerUrl : kDevServerUrl;
  }

  // API 엔드포인트
  static String get kakaoAuthEndpoint => '$serverUrl/auth/kakao';
  static String get healthCheckEndpoint => '$serverUrl/health';
}
