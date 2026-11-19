import 'package:flutter/material.dart';

// 알림 우선순위
enum NotificationPriority { low, normal, high, urgent }

// 알림 유형
enum NotificationType {
  system,
  welcome,
  notice,
  emergency,
  adminAnnouncement,
  adminClassAnnouncement,
  grade,
  schedule,
  meal,
  event,
  reminder,
}

// 알림 상태
enum NotificationStatus { unread, read, archived, deleted }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;
  final bool isRead;
  final NotificationPriority priority;
  final NotificationStatus status;
  final String? relatedId;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionLabel;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.scheduledAt,
    this.expiresAt,
    this.isRead = false,
    this.priority = NotificationPriority.normal,
    this.status = NotificationStatus.unread,
    this.relatedId,
    this.imageUrl,
    this.actionUrl,
    this.actionLabel,
    this.metadata,
  });

  // 알림 유형에 따른 NotificationType 반환
  NotificationType get notificationType {
    switch (type) {
      case 'system':
        return NotificationType.system;
      case 'welcome':
        return NotificationType.welcome;
      case 'notice':
        return NotificationType.notice;
      case 'emergency':
        return NotificationType.emergency;
      case 'admin_announcement':
        return NotificationType.adminAnnouncement;
      case 'admin_class_announcement':
        return NotificationType.adminClassAnnouncement;
      case 'grade':
        return NotificationType.grade;
      case 'schedule':
        return NotificationType.schedule;
      case 'meal':
        return NotificationType.meal;
      case 'event':
        return NotificationType.event;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.system;
    }
  }

  // 알림 유형별 아이콘
  IconData get icon {
    switch (notificationType) {
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.welcome:
        return Icons.waving_hand;
      case NotificationType.notice:
        return Icons.announcement;
      case NotificationType.emergency:
        return Icons.emergency;
      case NotificationType.adminAnnouncement:
        return Icons.admin_panel_settings;
      case NotificationType.adminClassAnnouncement:
        return Icons.group;
      case NotificationType.grade:
        return Icons.grade;
      case NotificationType.schedule:
        return Icons.schedule;
      case NotificationType.meal:
        return Icons.restaurant;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.reminder:
        return Icons.access_time;
    }
  }

  // 알림 유형별 색상
  Color get color {
    switch (notificationType) {
      case NotificationType.system:
        return Colors.blue;
      case NotificationType.welcome:
        return Colors.green;
      case NotificationType.notice:
        return Colors.orange;
      case NotificationType.emergency:
        return Colors.red;
      case NotificationType.adminAnnouncement:
        return Colors.purple;
      case NotificationType.adminClassAnnouncement:
        return Colors.indigo;
      case NotificationType.grade:
        return Colors.teal;
      case NotificationType.schedule:
        return Colors.cyan;
      case NotificationType.meal:
        return Colors.amber;
      case NotificationType.event:
        return Colors.pink;
      case NotificationType.reminder:
        return Colors.grey;
    }
  }

  // 우선순위별 색상
  Color get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  // 우선순위 텍스트
  String get priorityText {
    switch (priority) {
      case NotificationPriority.low:
        return '낮음';
      case NotificationPriority.normal:
        return '보통';
      case NotificationPriority.high:
        return '높음';
      case NotificationPriority.urgent:
        return '긴급';
    }
  }

  // 알림 유형 텍스트
  String get typeText {
    switch (notificationType) {
      case NotificationType.system:
        return '시스템';
      case NotificationType.welcome:
        return '환영';
      case NotificationType.notice:
        return '공지사항';
      case NotificationType.emergency:
        return '긴급';
      case NotificationType.adminAnnouncement:
        return '관리자 공지';
      case NotificationType.adminClassAnnouncement:
        return '학급 공지';
      case NotificationType.grade:
        return '성적';
      case NotificationType.schedule:
        return '시간표';
      case NotificationType.meal:
        return '급식';
      case NotificationType.event:
        return '행사';
      case NotificationType.reminder:
        return '알림';
    }
  }

  // 만료 여부 확인
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // 스케줄된 알림인지 확인
  bool get isScheduled {
    if (scheduledAt == null) return false;
    return DateTime.now().isBefore(scheduledAt!);
  }

  // 액션이 있는지 확인
  bool get hasAction {
    return actionUrl != null && actionLabel != null;
  }

  // 복사본 생성 (값 변경용)
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    DateTime? createdAt,
    DateTime? scheduledAt,
    DateTime? expiresAt,
    bool? isRead,
    NotificationPriority? priority,
    NotificationStatus? status,
    String? relatedId,
    String? imageUrl,
    String? actionUrl,
    String? actionLabel,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      relatedId: relatedId ?? this.relatedId,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      metadata: metadata ?? this.metadata,
    );
  }

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isRead': isRead,
      'priority': priority.index,
      'status': status.index,
      'relatedId': relatedId,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionLabel': actionLabel,
      'metadata': metadata,
    };
  }

  // JSON에서 생성
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt']),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : null,
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      isRead: json['isRead'] ?? false,
      priority: NotificationPriority.values[json['priority'] ?? 1],
      status: NotificationStatus.values[json['status'] ?? 0],
      relatedId: json['relatedId'],
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      actionLabel: json['actionLabel'],
      metadata: json['metadata'],
    );
  }

  // Map 변환 (toJson과 동일)
  Map<String, dynamic> toMap() {
    return toJson();
  }

  // Map에서 생성 (fromJson과 동일)
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel.fromJson(map);
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, priority: $priority, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
