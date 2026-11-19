import 'package:equatable/equatable.dart';

class DailyTimerSummary extends Equatable {
  final String userId;
  final String category;
  final int totalDuration; // 밀리초 단위
  final DateTime date;

  const DailyTimerSummary({
    required this.userId,
    required this.category,
    required this.totalDuration,
    required this.date,
  });

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'category': category,
      'totalDuration': totalDuration,
      'date': date.millisecondsSinceEpoch,
    };
  }

  // JSON 역직렬화
  factory DailyTimerSummary.fromJson(Map<String, dynamic> json) {
    return DailyTimerSummary(
      userId: json['userId'],
      category: json['category'],
      totalDuration: json['totalDuration'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
    );
  }

  // Firebase 데이터베이스에서 가져온 데이터로 생성
  factory DailyTimerSummary.fromFirebase(Map<String, dynamic> data) {
    return DailyTimerSummary(
      userId: data['userId'] ?? '',
      category: data['category'] ?? '',
      totalDuration: data['totalDuration'] ?? 0,
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
    );
  }

  // 복사본 생성
  DailyTimerSummary copyWith({
    String? userId,
    String? category,
    int? totalDuration,
    DateTime? date,
  }) {
    return DailyTimerSummary(
      userId: userId ?? this.userId,
      category: category ?? this.category,
      totalDuration: totalDuration ?? this.totalDuration,
      date: date ?? this.date,
    );
  }

  @override
  List<Object?> get props => [userId, category, totalDuration, date];
}
