import 'package:flutter/material.dart';

// 네비게이션 탭 enum
enum NavigationTab {
  home(0, '홈', Icons.home),
  schoolLife(1, '학교생활', Icons.school),
  events(2, '이벤트', Icons.event),
  settings(3, '설정', Icons.settings);

  final int tabIndex;
  final String label;
  final IconData icon;

  const NavigationTab(this.tabIndex, this.label, this.icon);

  static NavigationTab fromIndex(int index) {
    return NavigationTab.values.firstWhere(
      (tab) => tab.tabIndex == index,
      orElse: () => NavigationTab.home,
    );
  }
}

// 알림 시간 enum
enum NotificationTime {
  none('설정안함', 0),
  fiveMin('5분전', 5),
  tenMin('10분전', 10),
  fifteenMin('15분전', 15),
  thirtyMin('30분전', 30),
  oneHour('1시간전', 60),
  sixHours('6시간전', 360);

  final String label;
  final int minutes;

  const NotificationTime(this.label, this.minutes);

  static NotificationTime fromMinutes(int minutes) {
    return NotificationTime.values.firstWhere(
      (time) => time.minutes == minutes,
      orElse: () => NotificationTime.none,
    );
  }
}

// 알레르기 카테고리 enum
enum AllergyCategory {
  seafood('해산물', Colors.blue),
  meat('육류', Colors.red),
  grain('곡류', Colors.amber),
  nuts('견과류', Colors.brown),
  other('기타', Colors.green);

  final String label;
  final Color color;

  const AllergyCategory(this.label, this.color);

  static AllergyCategory fromLabel(String label) {
    return AllergyCategory.values.firstWhere(
      (category) => category.label == label,
      orElse: () => AllergyCategory.other,
    );
  }
}

// 운세 카테고리 enum
enum FortuneCategory {
  study('학업운'),
  love('연애운');

  final String label;

  const FortuneCategory(this.label);

  static FortuneCategory fromLabel(String label) {
    return FortuneCategory.values.firstWhere(
      (category) => category.label == label,
      orElse: () => FortuneCategory.study,
    );
  }
}

// 테마 모드 enum
enum ThemeMode {
  light('라이트 모드'),
  dark('다크 모드'),
  system('시스템 설정');

  final String label;

  const ThemeMode(this.label);
}

// 계정 유형 enum
enum AccountType {
  student('학생'),
  teacher('교사'),
  parent('학부모'),
  other('기타');

  final String label;

  const AccountType(this.label);
}

// 인증 상태 enum
enum VerificationStatus {
  verified('인증 완료'),
  pending('인증 대기중'),
  unverified('미인증');

  final String label;

  const VerificationStatus(this.label);
}
