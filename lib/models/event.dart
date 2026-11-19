import 'package:flutter/material.dart';
import '../utils/enums.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final bool hasNotification;
  final NotificationTime notificationTime;
  final Color color;
  final String userId;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.hasNotification = false,
    this.notificationTime = NotificationTime.none,
    required this.color,
    required this.userId,
  });

  // Firebase에서 데이터를 가져올 때 사용할 팩토리 메서드
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      start: DateTime.parse(map['start']),
      end: DateTime.parse(map['end']),
      hasNotification: map['hasNotification'] ?? false,
      notificationTime:
          NotificationTime.fromMinutes(map['notificationMinutes'] ?? 0),
      color: Color(map['color']),
      userId: map['userId'],
    );
  }

  // Firebase에 데이터를 저장할 때 사용할 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'hasNotification': hasNotification,
      'notificationMinutes': notificationTime.minutes,
      'color': color.value,
      'userId': userId,
    };
  }

  // 이벤트 복사본 생성 메서드
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    bool? hasNotification,
    NotificationTime? notificationTime,
    Color? color,
    String? userId,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      hasNotification: hasNotification ?? this.hasNotification,
      notificationTime: notificationTime ?? this.notificationTime,
      color: color ?? this.color,
      userId: userId ?? this.userId,
    );
  }
}
