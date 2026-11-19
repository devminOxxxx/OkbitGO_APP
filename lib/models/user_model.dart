import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? school;
  final String? grade;
  final String? classNumber;
  final String? studentNumber;
  final bool isAdmin;
  final Map<String, dynamic> notificationSettings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String theme;
  final List<String> allergies;
  final bool additionalInfoCompleted;
  final bool isTemporaryEmail;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.school,
    this.grade,
    this.classNumber,
    this.studentNumber,
    this.isAdmin = false,
    required this.notificationSettings,
    required this.createdAt,
    required this.updatedAt,
    this.theme = 'system',
    this.allergies = const [],
    this.additionalInfoCompleted = false,
    this.isTemporaryEmail = false,
  });

  // 빈 사용자 생성
  factory UserModel.empty() {
    return UserModel(
      id: '',
      email: '',
      name: '',
      isAdmin: false,
      notificationSettings: const {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      theme: 'system',
      allergies: const [],
    );
  }

  // Firebase 사용자 데이터로부터 생성
  factory UserModel.fromFirebase(Map<String, dynamic> data, String uid) {
    return UserModel(
      id: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      school: data['school'],
      grade: data['grade'],
      classNumber: data['classNumber'],
      studentNumber: data['studentNumber'],
      isAdmin: data['isAdmin'] ?? false,
      notificationSettings: data['notificationSettings'] ?? {},
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
          : DateTime.now(),
      theme: data['theme'] ?? 'system',
      allergies: List<String>.from(data['allergies'] ?? []),
      additionalInfoCompleted: data['additionalInfoCompleted'] ?? false,
      isTemporaryEmail: data['isTemporaryEmail'] ?? false,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'school': school,
      'grade': grade,
      'classNumber': classNumber,
      'studentNumber': studentNumber,
      'isAdmin': isAdmin,
      'notificationSettings': notificationSettings,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'theme': theme,
      'allergies': allergies,
      'additionalInfoCompleted': additionalInfoCompleted,
      'isTemporaryEmail': isTemporaryEmail,
    };
  }

  // 복사본 생성
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? school,
    String? grade,
    String? classNumber,
    String? studentNumber,
    bool? isAdmin,
    Map<String, dynamic>? notificationSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? theme,
    List<String>? allergies,
    bool? additionalInfoCompleted,
    bool? isTemporaryEmail,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      school: school ?? this.school,
      grade: grade ?? this.grade,
      classNumber: classNumber ?? this.classNumber,
      studentNumber: studentNumber ?? this.studentNumber,
      isAdmin: isAdmin ?? this.isAdmin,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      theme: theme ?? this.theme,
      allergies: allergies ?? this.allergies,
      additionalInfoCompleted:
          additionalInfoCompleted ?? this.additionalInfoCompleted,
      isTemporaryEmail: isTemporaryEmail ?? this.isTemporaryEmail,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        photoUrl,
        school,
        grade,
        classNumber,
        studentNumber,
        isAdmin,
        notificationSettings,
        createdAt,
        updatedAt,
        theme,
        allergies,
        additionalInfoCompleted,
        isTemporaryEmail,
      ];
}
