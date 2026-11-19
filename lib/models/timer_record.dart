import 'package:equatable/equatable.dart';

class TimerRecord extends Equatable {
  final String id;
  final String category;
  final int duration; // 밀리초 단위
  final DateTime date;
  final List<int> laps; // 밀리초 단위의 랩 타임 목록
  final String userId; // 사용자 ID

  const TimerRecord({
    required this.id,
    required this.category,
    required this.duration,
    required this.date,
    required this.userId,
    this.laps = const [],
  });

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'duration': duration,
      'date': date.millisecondsSinceEpoch,
      'laps': laps,
      'userId': userId,
    };
  }

  // JSON 역직렬화
  factory TimerRecord.fromJson(Map<String, dynamic> json) {
    return TimerRecord(
      id: json['id'],
      category: json['category'],
      duration: json['duration'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      laps: List<int>.from(json['laps'] ?? []),
      userId: json['userId'],
    );
  }

  // Firebase 데이터베이스에서 가져온 데이터로 생성
  factory TimerRecord.fromFirebase(Map<String, dynamic> data, String id) {
    return TimerRecord(
      id: id,
      category: data['category'] ?? '',
      duration: data['duration'] ?? 0,
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      laps: List<int>.from(data['laps'] ?? []),
      userId: data['userId'] ?? '',
    );
  }

  // 복사본 생성
  TimerRecord copyWith({
    String? id,
    String? category,
    int? duration,
    DateTime? date,
    List<int>? laps,
    String? userId,
  }) {
    return TimerRecord(
      id: id ?? this.id,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      laps: laps ?? this.laps,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [id, category, duration, date, laps, userId];
}
