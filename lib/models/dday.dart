import 'package:cloud_firestore/cloud_firestore.dart';

class DDay {
  final String id;
  final String title;
  final DateTime date;
  final String userId;
  final bool isCompleted;

  DDay({
    required this.id,
    required this.title,
    required this.date,
    required this.userId,
    this.isCompleted = false,
  });

  // Firebase에서 데이터를 가져올 때 사용할 팩토리 메서드
  factory DDay.fromMap(Map<String, dynamic> map, String id) {
    return DDay(
      id: id,
      title: map['title'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  // Firebase에 데이터를 저장할 때 사용할 메서드
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'isCompleted': isCompleted,
    };
  }

  // 디데이 복사본 생성 메서드
  DDay copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? userId,
    bool? isCompleted,
  }) {
    return DDay(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // 남은 일수 계산 메서드
  int getDaysRemaining() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return targetDate.difference(today).inDays;
  }

  // 디데이 표시 문자열 반환 메서드
  String getDDayText() {
    final daysRemaining = getDaysRemaining();

    if (daysRemaining == 0) {
      return 'D-Day';
    } else if (daysRemaining > 0) {
      return 'D-$daysRemaining';
    } else {
      return 'D+${daysRemaining.abs()}';
    }
  }
}
