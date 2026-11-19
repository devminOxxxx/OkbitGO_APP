import '../utils/constants.dart';

/// Firestore 데이터베이스 구조 관리 클래스
class DatabaseConfig {
  // 컬렉션 이름들
  static const String usersCollection = 'users';
  static const String ddaysCollection = 'ddays';
  static const String eventsCollection = 'events';
  static const String examsCollection = 'exams';
  static const String studyTimersCollection = 'studyTimers';
  static const String studyGroupsCollection = 'studyGroups';
  static const String deletedUsersCollection = 'deleted_users';
  static const String notificationsCollection = 'notifications';
  static const String adminLogsCollection = 'admin_logs';
  static const String timetablesSubcollection = 'timetables';

  // 사용자 관련 필드
  static const String userIdField = 'userId';
  static const String emailField = 'email';
  static const String nameField = 'name';
  static const String photoUrlField = 'photoUrl';
  static const String schoolField = 'school';
  static const String gradeField = 'grade';
  static const String classNumberField = 'classNumber';
  static const String studentNumberField = 'studentNumber';
  static const String isAdminField = 'isAdmin';
  static const String notificationSettingsField = 'notificationSettings';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';
  static const String themeField = 'theme';
  static const String allergiesField = 'allergies';
  static const String additionalInfoCompletedField = 'additionalInfoCompleted';
  static const String isTemporaryEmailField = 'isTemporaryEmail';

  // 사용자 차단 및 활동 관련 필드
  static const String isBlockedField = 'isBlocked';
  static const String blockedAtField = 'blockedAt';
  static const String lastActiveField = 'lastActive';

  // 공통 필드
  static const String titleField = 'title';
  static const String dateField = 'date';
  static const String isCompletedField = 'isCompleted';
  static const String subjectField = 'subject';
  static const String scoreField = 'score';
  static const String totalScoreField = 'totalScore';
  static const String scoresField = 'scores';
  static const String totalDurationField = 'totalDuration';
  static const String lastUpdatedField = 'lastUpdated';
  static const String isCustomField = 'isCustom';

  // 스터디 그룹 관련 필드
  static const String memberIdsField = 'memberIds';
  static const String descriptionField = 'description';
  static const String maxMembersField = 'maxMembers';
  static const String isActiveField = 'isActive';

  // 알림 관련 필드
  static const String typeField = 'type';
  static const String messageField = 'message';
  static const String isReadField = 'isRead';
  static const String priorityField = 'priority';
  static const String statusField = 'status';

  // 삭제 관련 필드
  static const String deletedAtField = 'deletedAt';
  static const String deleteReasonField = 'deleteReason';
  static const String deletedByField = 'deletedBy';
  static const String expiresAtField = 'expiresAt';

  // 기본값
  static const String defaultSchool = kSchoolName;
  static const String defaultTheme = 'system';
  static const bool defaultIsAdmin = false;
  static const bool defaultIsCompleted = false;
  static const bool defaultIsCustom = false;
  static const bool defaultIsActive = true;
  static const bool defaultIsRead = false;
  static const bool defaultAdditionalInfoCompleted = false;
  static const bool defaultIsTemporaryEmail = false;

  // 기본 알림 설정
  static const Map<String, bool> defaultNotificationSettings = {
    'meal': true,
    'timetable': true,
    'notice': true,
    'event': true,
    'exam': true,
    'dday': true,
  };

  // 데이터 만료 기간 (일)
  static const int deletedUserExpirationDays = 30;
  static const int notificationExpirationDays = 90;
  static const int adminLogRetentionDays = 365;

  // 페이지네이션 설정
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // 파일 크기 제한 (바이트)
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  /// 컬렉션 경로 생성 헬퍼 메서드들
  static String getUserPath(String userId) => '$usersCollection/$userId';

  static String getUserTimetablePath(String userId, String timetableId) =>
      '$usersCollection/$userId/$timetablesSubcollection/$timetableId';

  static String getDDayPath(String ddayId) => '$ddaysCollection/$ddayId';

  static String getEventPath(String eventId) => '$eventsCollection/$eventId';

  static String getExamPath(String examId) => '$examsCollection/$examId';

  static String getStudyTimerPath(String timerId) =>
      '$studyTimersCollection/$timerId';

  static String getStudyGroupPath(String groupId) =>
      '$studyGroupsCollection/$groupId';

  static String getDeletedUserPath(String userId) =>
      '$deletedUsersCollection/$userId';

  /// 쿼리 제한 설정
  static const int queryLimit = 50;
  static const int maxRetryCount = 3;
  static const Duration queryTimeout = Duration(seconds: 30);

  /// 인덱스 권장사항 (Firestore 콘솔에서 설정 필요)
  static const List<String> recommendedIndexes = [
    'users: userId, createdAt (desc)',
    'ddays: userId, date (asc)',
    'events: userId, date (asc)',
    'exams: userId, date (desc)',
    'studyTimers: userId, lastUpdated (desc)',
    'studyGroups: memberIds (array), createdAt (desc)',
    'notifications: userId, isRead, createdAt (desc)',
  ];

  /// 보안 규칙 권장사항
  static const String securityRulesDescription = '''
  권장 Firestore 보안 규칙:
  
  1. 사용자는 자신의 데이터만 읽기/쓰기 가능
  2. 관리자는 모든 데이터 접근 가능
  3. 삭제된 사용자 데이터는 관리자만 접근 가능
  4. 공개 데이터(공지사항 등)는 인증된 사용자 모두 읽기 가능
  ''';
}
