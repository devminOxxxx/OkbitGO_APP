import 'package:cloud_firestore/cloud_firestore.dart';

class StudyTimer {
  final String id;
  final String userId;
  final String subject;
  final int totalDuration; // 밀리초 단위
  final DateTime lastUpdated;
  final bool isCustom; // 사용자 정의 과목인지 여부

  StudyTimer({
    required this.id,
    required this.userId,
    required this.subject,
    required this.totalDuration,
    required this.lastUpdated,
    this.isCustom = false,
  });

  factory StudyTimer.fromJson(Map<String, dynamic> json) {
    return StudyTimer(
      id: json['id'] as String,
      userId: json['userId'] as String,
      subject: json['subject'] as String,
      totalDuration: json['totalDuration'] as int,
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'totalDuration': totalDuration,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isCustom': isCustom,
    };
  }

  StudyTimer copyWith({
    String? id,
    String? userId,
    String? subject,
    int? totalDuration,
    DateTime? lastUpdated,
    bool? isCustom,
  }) {
    return StudyTimer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      totalDuration: totalDuration ?? this.totalDuration,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

class StudyGroup {
  final String id;
  final String name;
  final String creatorId;
  final List<String> memberIds;
  final DateTime createdAt;
  final String description;
  final String category;
  final String password;
  final int? targetTime;
  final int? maxMembers;

  StudyGroup({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.memberIds,
    required this.createdAt,
    this.description = '',
    this.category = '',
    this.password = '',
    this.targetTime,
    this.maxMembers,
  });

  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      creatorId: json['creatorId'] as String,
      memberIds: List<String>.from(json['memberIds'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      password: json['password'] as String? ?? '',
      targetTime: json['targetTime'] as int?,
      maxMembers: json['maxMembers'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
      'category': category,
      'password': password,
      'targetTime': targetTime,
      'maxMembers': maxMembers,
    };
  }

  StudyGroup copyWith({
    String? id,
    String? name,
    String? creatorId,
    List<String>? memberIds,
    DateTime? createdAt,
    String? description,
    String? category,
    String? password,
    int? targetTime,
    int? maxMembers,
  }) {
    return StudyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      category: category ?? this.category,
      password: password ?? this.password,
      targetTime: targetTime ?? this.targetTime,
      maxMembers: maxMembers ?? this.maxMembers,
    );
  }
}

class GroupMember {
  final String userId;
  final String name;
  final int todayStudyTime; // 밀리초 단위
  final DateTime lastActive;
  final bool isActive;

  GroupMember({
    required this.userId,
    required this.name,
    required this.todayStudyTime,
    required this.lastActive,
    this.isActive = false,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as String,
      name: json['name'] as String,
      todayStudyTime: json['todayStudyTime'] as int,
      lastActive: (json['lastActive'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'todayStudyTime': todayStudyTime,
      'lastActive': Timestamp.fromDate(lastActive),
      'isActive': isActive,
    };
  }
}
