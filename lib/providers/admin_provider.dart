import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../services/database_cleanup_service.dart';
import '../utils/logger_util.dart';

// 관리자 활동 로그 모델
class AdminActivityLog {
  final String id;
  final String action;
  final String description;
  final DateTime timestamp;
  final String? targetUser;
  final Map<String, dynamic>? metadata;

  AdminActivityLog({
    required this.id,
    required this.action,
    required this.description,
    required this.timestamp,
    this.targetUser,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'targetUser': targetUser,
      'metadata': metadata,
    };
  }

  factory AdminActivityLog.fromJson(Map<String, dynamic> json) {
    return AdminActivityLog(
      id: json['id'],
      action: json['action'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      targetUser: json['targetUser'],
      metadata: json['metadata'],
    );
  }
}

// 알림 템플릿 모델
class NotificationTemplate {
  final String id;
  final String title;
  final String content;
  final String type;
  final NotificationPriority priority;
  final int usageCount;
  final DateTime createdAt;
  final DateTime lastUsed;
  final bool isActive;

  NotificationTemplate({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.usageCount = 0,
    required this.createdAt,
    required this.lastUsed,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'priority': priority.index,
      'usageCount': usageCount,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      priority: NotificationPriority.values[json['priority'] ?? 1],
      usageCount: json['usageCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: DateTime.parse(json['lastUsed']),
      isActive: json['isActive'] ?? true,
    );
  }

  NotificationTemplate copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    NotificationPriority? priority,
    int? usageCount,
    DateTime? createdAt,
    DateTime? lastUsed,
    bool? isActive,
  }) {
    return NotificationTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      isActive: isActive ?? this.isActive,
    );
  }
}

class AdminProvider with ChangeNotifier {
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService();
  final DatabaseCleanupService _databaseCleanupService =
      DatabaseCleanupService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  NotificationProvider? _notificationProvider;
  bool _isLoggedIn = false;
  String? _adminUsername;
  bool _isLoading = false;
  String? _error;

  // 활동 로그
  List<AdminActivityLog> _activityLogs = [];

  // 알림 템플릿
  List<NotificationTemplate> _notificationTemplates = [];

  // 통계 데이터
  Map<String, dynamic> _dashboardStats = {};

  // 예약된 알림
  List<NotificationModel> _scheduledNotifications = [];

  AdminProvider([this._notificationProvider]) {
    _loadAdminState();
    _initializeDefaultTemplates();
  }

  // NotificationProvider 설정
  void setNotificationProvider(NotificationProvider notificationProvider) {
    _notificationProvider = notificationProvider;
  }

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String? get adminUsername => _adminUsername;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AdminActivityLog> get activityLogs => List.unmodifiable(_activityLogs);
  List<NotificationTemplate> get notificationTemplates =>
      List.unmodifiable(_notificationTemplates);
  Map<String, dynamic> get dashboardStats => Map.unmodifiable(_dashboardStats);
  List<NotificationModel> get scheduledNotifications =>
      List.unmodifiable(_scheduledNotifications);

  // 관리자 자동 로그인 (권한이 있는 사용자용)
  Future<bool> autoLoginAsAdmin(String name, String email) async {
    try {
      _isLoggedIn = true;
      _adminUsername = name;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_logged_in', true);
      await prefs.setString('admin_username', name);
      await prefs.setString('admin_email', email);

      await _logActivity(
        action: 'LOGIN',
        description: '관리자가 자동 로그인했습니다 ($name)',
      );

      LoggerUtil.info('관리자 자동 로그인 성공: $name ($email)');
      notifyListeners();
      return true;
    } catch (e) {
      LoggerUtil.error('관리자 자동 로그인 오류: $e');
      return false;
    }
  }

  // 관리자 로그인 (데이터베이스 기반)
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userService = UserService();

      // 이메일로 사용자 검색
      final user = await userService.getUserByEmail(email);

      if (user == null) {
        _error = '존재하지 않는 사용자입니다.';
        await _logActivity(
          action: 'LOGIN_FAILED',
          description: '관리자 로그인 실패: 존재하지 않는 사용자 ($email)',
        );
        return false;
      }

      // 관리자 권한 확인
      if (!user.isAdmin) {
        _error = '관리자 권한이 없습니다.';
        await _logActivity(
          action: 'LOGIN_FAILED',
          description: '관리자 로그인 실패: 관리자 권한 없음 (${user.name})',
        );
        return false;
      }

      // 비밀번호 확인 (실제 앱에서는 암호화된 비밀번호 비교)
      // 임시로 간단한 비밀번호 확인 로직
      if (password.isEmpty || password.length < 6) {
        _error = '올바른 비밀번호를 입력해주세요.';
        await _logActivity(
          action: 'LOGIN_FAILED',
          description: '관리자 로그인 실패: 잘못된 비밀번호 (${user.name})',
        );
        return false;
      }

      // 로그인 성공
      _isLoggedIn = true;
      _adminUsername = user.name;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_logged_in', true);
      await prefs.setString('admin_username', user.name);
      await prefs.setString('admin_email', user.email);

      await _logActivity(
        action: 'LOGIN',
        description: '관리자가 로그인했습니다 (${user.name})',
        targetUser: user.id,
      );

      await _updateDashboardStats();

      LoggerUtil.info('관리자 로그인 성공: ${user.name} (${user.email})');
      return true;
    } catch (e) {
      _error = '로그인 중 오류가 발생했습니다: $e';
      LoggerUtil.error('관리자 로그인 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 관리자 로그아웃
  Future<void> logout() async {
    try {
      await _logActivity(
        action: 'LOGOUT',
        description: '관리자가 로그아웃했습니다',
      );

      _isLoggedIn = false;
      _adminUsername = null;
      _activityLogs.clear();
      _dashboardStats.clear();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('admin_logged_in');
      await prefs.remove('admin_username');

      LoggerUtil.info('관리자 로그아웃');
      notifyListeners();
    } catch (e) {
      LoggerUtil.error('관리자 로그아웃 오류: $e');
    }
  }

  // 전체 알림 발송
  Future<bool> sendNotificationToAll({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? expiresAt,
    String? actionUrl,
    String? actionLabel,
    String? department,
    String? senderName,
    String? fileName,
    String? fileUrl,
  }) async {
    if (!_isLoggedIn) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _notificationProvider?.addNotification(
        title: title,
        message: message,
        type: 'admin_announcement',
        priority: priority,
        expiresAt: expiresAt,
        actionUrl: actionUrl,
        actionLabel: actionLabel,
        metadata: {
          'sent_by': _adminUsername,
          'target': 'all_users',
          'timestamp': DateTime.now().toIso8601String(),
          'department': department ?? '관리자',
          'sender_name': senderName,
          'hasFile': fileName != null,
          'fileName': fileName,
          'fileUrl': fileUrl,
        },
      );

      await _logActivity(
        action: 'SEND_NOTIFICATION',
        description: '전체 사용자에게 알림 발송: $title',
        metadata: {
          'title': title,
          'message': message,
          'priority': priority.name,
          'target': 'all_users',
        },
      );

      await _updateDashboardStats();
      LoggerUtil.info('전체 알림 발송 완료: $title');
      return true;
    } catch (e) {
      _error = '알림 발송 중 오류가 발생했습니다: $e';
      LoggerUtil.error('전체 알림 발송 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 학급별 알림 발송
  Future<bool> sendNotificationToClass({
    required String title,
    required String message,
    required int grade,
    required int classNumber,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? expiresAt,
    String? department,
    String? senderName,
    String? fileName,
    String? fileUrl,
  }) async {
    if (!_isLoggedIn) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _notificationProvider?.addNotification(
        title: title,
        message: message,
        type: 'admin_class_announcement',
        priority: priority,
        expiresAt: expiresAt,
        metadata: {
          'sent_by': _adminUsername,
          'target_grade': grade,
          'target_class': classNumber,
          'target': '${grade}학년 ${classNumber}반',
          'timestamp': DateTime.now().toIso8601String(),
          'department': department ?? '관리자',
          'sender_name': senderName,
          'hasFile': fileName != null,
          'fileName': fileName,
          'fileUrl': fileUrl,
        },
      );

      await _logActivity(
        action: 'SEND_CLASS_NOTIFICATION',
        description: '${grade}학년 ${classNumber}반에게 알림 발송: $title',
        metadata: {
          'title': title,
          'message': message,
          'grade': grade,
          'class': classNumber,
        },
      );

      await _updateDashboardStats();
      LoggerUtil.info('학급별 알림 발송 완료: ${grade}학년 ${classNumber}반 - $title');
      return true;
    } catch (e) {
      _error = '학급별 알림 발송 중 오류가 발생했습니다: $e';
      LoggerUtil.error('학급별 알림 발송 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 긴급 알림 발송
  Future<bool> sendEmergencyNotification({
    required String title,
    required String message,
    String? actionUrl,
    String? actionLabel,
  }) async {
    if (!_isLoggedIn) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _notificationProvider?.addNotification(
        title: title,
        message: message,
        type: 'emergency',
        priority: NotificationPriority.urgent,
        actionUrl: actionUrl,
        actionLabel: actionLabel,
        metadata: {
          'sent_by': _adminUsername,
          'is_emergency': true,
          'target': 'all_users',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      await _logActivity(
        action: 'SEND_EMERGENCY',
        description: '긴급 알림 발송: $title',
        metadata: {
          'title': title,
          'message': message,
          'is_emergency': true,
        },
      );

      await _updateDashboardStats();
      LoggerUtil.info('긴급 알림 발송 완료: $title');
      return true;
    } catch (e) {
      _error = '긴급 알림 발송 중 오류가 발생했습니다: $e';
      LoggerUtil.error('긴급 알림 발송 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 템플릿을 사용한 알림 발송
  Future<bool> sendNotificationFromTemplate({
    required String templateId,
    String? customTitle,
    String? customMessage,
    String? target,
  }) async {
    if (!_isLoggedIn) return false;

    final template = _notificationTemplates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => throw Exception('템플릿을 찾을 수 없습니다'),
    );

    final title = customTitle ?? template.title;
    final message = customMessage ?? template.content;

    bool success = false;

    switch (target) {
      case 'all':
        success = await sendNotificationToAll(
          title: title,
          message: message,
          priority: template.priority,
        );
        break;
      case 'emergency':
        success = await sendEmergencyNotification(
          title: title,
          message: message,
        );
        break;
      default:
        success = await sendNotificationToAll(
          title: title,
          message: message,
          priority: template.priority,
        );
    }

    if (success) {
      await _updateTemplateUsage(templateId);
    }

    return success;
  }

  // 예약 알림 생성
  Future<bool> scheduleNotification({
    required String title,
    required String message,
    required DateTime scheduledAt,
    required String type,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? expiresAt,
  }) async {
    if (!_isLoggedIn) return false;

    try {
      final scheduledNotification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        scheduledAt: scheduledAt,
        expiresAt: expiresAt,
        priority: priority,
        metadata: {
          'scheduled_by': _adminUsername,
          'is_scheduled': true,
        },
      );

      _scheduledNotifications.add(scheduledNotification);
      await _saveScheduledNotifications();

      await _logActivity(
        action: 'SCHEDULE_NOTIFICATION',
        description: '알림 예약: $title (발송 예정: ${scheduledAt.toString()})',
        metadata: {
          'title': title,
          'scheduled_at': scheduledAt.toIso8601String(),
          'type': type,
        },
      );

      LoggerUtil.info('알림 예약 완료: $title');
      notifyListeners();
      return true;
    } catch (e) {
      _error = '알림 예약 중 오류가 발생했습니다: $e';
      LoggerUtil.error('알림 예약 오류: $e');
      return false;
    }
  }

  // 템플릿 생성
  Future<bool> createTemplate({
    required String title,
    required String content,
    required String type,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    if (!_isLoggedIn) return false;

    try {
      final template = NotificationTemplate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        type: type,
        priority: priority,
        createdAt: DateTime.now(),
        lastUsed: DateTime.now(),
      );

      _notificationTemplates.add(template);
      await _saveTemplates();

      await _logActivity(
        action: 'CREATE_TEMPLATE',
        description: '알림 템플릿 생성: $title',
        metadata: {
          'template_id': template.id,
          'title': title,
          'type': type,
        },
      );

      LoggerUtil.info('템플릿 생성 완료: $title');
      notifyListeners();
      return true;
    } catch (e) {
      _error = '템플릿 생성 중 오류가 발생했습니다: $e';
      LoggerUtil.error('템플릿 생성 오류: $e');
      return false;
    }
  }

  // 템플릿 수정
  Future<bool> updateTemplate({
    required String templateId,
    String? title,
    String? content,
    String? type,
    NotificationPriority? priority,
    bool? isActive,
  }) async {
    if (!_isLoggedIn) return false;

    try {
      final index =
          _notificationTemplates.indexWhere((t) => t.id == templateId);
      if (index == -1) {
        _error = '템플릿을 찾을 수 없습니다';
        return false;
      }

      final oldTemplate = _notificationTemplates[index];
      final updatedTemplate = oldTemplate.copyWith(
        title: title,
        content: content,
        type: type,
        priority: priority,
        isActive: isActive,
      );

      _notificationTemplates[index] = updatedTemplate;
      await _saveTemplates();

      await _logActivity(
        action: 'UPDATE_TEMPLATE',
        description: '알림 템플릿 수정: ${updatedTemplate.title}',
        metadata: {
          'template_id': templateId,
          'title': updatedTemplate.title,
        },
      );

      LoggerUtil.info('템플릿 수정 완료: ${updatedTemplate.title}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = '템플릿 수정 중 오류가 발생했습니다: $e';
      LoggerUtil.error('템플릿 수정 오류: $e');
      return false;
    }
  }

  // 템플릿 삭제
  Future<bool> deleteTemplate(String templateId) async {
    if (!_isLoggedIn) return false;

    try {
      final template = _notificationTemplates.firstWhere(
        (t) => t.id == templateId,
        orElse: () => throw Exception('템플릿을 찾을 수 없습니다'),
      );

      _notificationTemplates.removeWhere((t) => t.id == templateId);
      await _saveTemplates();

      await _logActivity(
        action: 'DELETE_TEMPLATE',
        description: '알림 템플릿 삭제: ${template.title}',
        metadata: {
          'template_id': templateId,
          'title': template.title,
        },
      );

      LoggerUtil.info('템플릿 삭제 완료: ${template.title}');
      notifyListeners();
      return true;
    } catch (e) {
      _error = '템플릿 삭제 중 오류가 발생했습니다: $e';
      LoggerUtil.error('템플릿 삭제 오류: $e');
      return false;
    }
  }

  // 사용자 통계 조회
  Map<String, dynamic> getUserStatistics() {
    // 실제 앱에서는 서버에서 데이터를 가져옴
    return {
      'total_users': 247,
      'active_users_today': 156,
      'new_users_this_week': 12,
      'users_by_grade': {
        '1': 82,
        '2': 85,
        '3': 80,
      },
      'login_stats': {
        'today': 156,
        'yesterday': 134,
        'this_week': 892,
      },
    };
  }

  // 알림 통계 조회
  Map<String, dynamic> getNotificationStatistics() {
    final notifications = _notificationProvider?.allNotifications ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = now.subtract(Duration(days: now.weekday - 1));

    return {
      'total_sent': notifications.length,
      'sent_today':
          notifications.where((n) => n.createdAt.isAfter(today)).length,
      'sent_this_week':
          notifications.where((n) => n.createdAt.isAfter(thisWeek)).length,
      'by_type': _getNotificationsByType(notifications),
      'by_priority': _getNotificationsByPriority(notifications),
      'read_rate': _calculateReadRate(notifications),
    };
  }

  // 시스템 상태 조회
  Map<String, dynamic> getSystemStatus() {
    return {
      'server_status': 'online',
      'database_status': 'online',
      'notification_service_status': 'online',
      'uptime': '99.9%',
      'last_backup': DateTime.now().subtract(const Duration(hours: 6)),
      'storage_usage': '87.2%',
      'memory_usage': '62.4%',
      'cpu_usage': '34.1%',
    };
  }

  // 활동 로그 조회 (최근 순)
  List<AdminActivityLog> getRecentActivities({int limit = 50}) {
    final sortedLogs = List<AdminActivityLog>.from(_activityLogs);
    sortedLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedLogs.take(limit).toList();
  }

  // 대시보드 통계 새로고침
  Future<void> refreshDashboard() async {
    await _updateDashboardStats();
    notifyListeners();
  }

  // 알림 발송 (통합 메서드)
  Future<bool> sendNotification({
    required String title,
    required String message,
    required String target,
    NotificationPriority priority = NotificationPriority.normal,
    String? senderName,
    String? department,
    String? fileName,
    String? fileUrl,
  }) async {
    if (!_isLoggedIn) return false;

    switch (target) {
      case '1학년':
        return await sendNotificationToClass(
          title: title,
          message: message,
          grade: 1,
          classNumber: 0, // 전체 1학년
          priority: priority,
          department: department,
          senderName: senderName,
          fileName: fileName,
          fileUrl: fileUrl,
        );
      case '2학년':
        return await sendNotificationToClass(
          title: title,
          message: message,
          grade: 2,
          classNumber: 0, // 전체 2학년
          priority: priority,
          department: department,
          senderName: senderName,
          fileName: fileName,
          fileUrl: fileUrl,
        );
      case '3학년':
        return await sendNotificationToClass(
          title: title,
          message: message,
          grade: 3,
          classNumber: 0, // 전체 3학년
          priority: priority,
          department: department,
          senderName: senderName,
          fileName: fileName,
          fileUrl: fileUrl,
        );
      default: // '전체'
        return await sendNotificationToAll(
          title: title,
          message: message,
          priority: priority,
          department: department,
          senderName: senderName,
          fileName: fileName,
          fileUrl: fileUrl,
        );
    }
  }

  // 사용자 정보 업데이트
  Future<bool> updateUserInfo({
    required String userId,
    String? name,
    String? email,
    String? grade,
    String? classNumber,
    bool? allowNotifications,
    bool? isActive,
  }) async {
    if (!_isLoggedIn) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _userService.updateUserByAdmin(userId, {
        'name': name,
        'email': email,
        'grade': grade,
        'classNumber': classNumber,
        'allowNotifications': allowNotifications,
        'isActive': isActive,
      });

      await _logActivity(
        action: 'UPDATE_USER',
        description: '사용자 정보 수정: $name',
        targetUser: userId,
        metadata: {
          'name': name,
          'email': email,
          'grade': grade,
          'classNumber': classNumber,
        },
      );

      LoggerUtil.info('사용자 정보 업데이트 완료: $userId');
      return true;
    } catch (e) {
      _error = '사용자 정보 업데이트 중 오류가 발생했습니다: $e';
      LoggerUtil.error('사용자 정보 업데이트 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 사용자 차단
  Future<bool> blockUser({
    required String userId,
    required String reason,
  }) async {
    if (!_isLoggedIn) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _userService.blockUser(userId);

      await _logActivity(
        action: 'USER_BLOCKED',
        description: '사용자 차단: $reason',
        targetUser: userId,
        metadata: {
          'reason': reason,
          'blocked_by': _adminUsername,
        },
      );

      LoggerUtil.info('사용자 차단 완료: $userId');
      return true;
    } catch (e) {
      _error = '사용자 차단 중 오류가 발생했습니다: $e';
      LoggerUtil.error('사용자 차단 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 사용자 차단 해제
  Future<bool> unblockUser(String userId) async {
    if (!_isLoggedIn) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _userService.unblockUser(userId);

      await _logActivity(
        action: 'USER_UNBLOCKED',
        description: '사용자 차단 해제',
        targetUser: userId,
        metadata: {
          'unblocked_by': _adminUsername,
        },
      );

      LoggerUtil.info('사용자 차단 해제 완료: $userId');
      return true;
    } catch (e) {
      _error = '사용자 차단 해제 중 오류가 발생했습니다: $e';
      LoggerUtil.error('사용자 차단 해제 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 사용자 삭제 (30일 보관)
  Future<bool> deleteUser({
    required String userId,
    required String reason,
  }) async {
    if (!_isLoggedIn) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _userService.deleteUserData(userId);

      await _logActivity(
        action: 'USER_DELETED',
        description: '사용자 삭제 (30일 보관): $reason',
        targetUser: userId,
        metadata: {
          'reason': reason,
          'deleted_by': _adminUsername,
          'retention_days': 30,
        },
      );

      LoggerUtil.info('사용자 삭제 완료: $userId');
      return true;
    } catch (e) {
      _error = '사용자 삭제 중 오류가 발생했습니다: $e';
      LoggerUtil.error('사용자 삭제 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 사용자 복구
  Future<bool> restoreUser(String userId) async {
    if (!_isLoggedIn) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _userService.restoreUser(userId);

      await _logActivity(
        action: 'USER_RESTORED',
        description: '사용자 복구',
        targetUser: userId,
        metadata: {
          'restored_by': _adminUsername,
        },
      );

      LoggerUtil.info('사용자 복구 완료: $userId');
      return true;
    } catch (e) {
      _error = '사용자 복구 중 오류가 발생했습니다: $e';
      LoggerUtil.error('사용자 복구 오류: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Private 메서드들
  Future<void> _loadAdminState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('admin_logged_in') ?? false;
      _adminUsername = prefs.getString('admin_username');

      if (_isLoggedIn) {
        await _loadActivityLogs();
        await _loadTemplates();
        await _loadScheduledNotifications();
        await _updateDashboardStats();
      }
    } catch (e) {
      LoggerUtil.error('관리자 상태 로드 오류: $e');
    }
  }

  Future<void> _logActivity({
    required String action,
    required String description,
    String? targetUser,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final log = AdminActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        action: action,
        description: description,
        timestamp: DateTime.now(),
        targetUser: targetUser,
        metadata: metadata,
      );

      _activityLogs.add(log);

      // 최대 1000개의 로그만 유지
      if (_activityLogs.length > 1000) {
        _activityLogs = _activityLogs.sublist(_activityLogs.length - 1000);
      }

      await _saveActivityLogs();
    } catch (e) {
      LoggerUtil.error('활동 로그 저장 오류: $e');
    }
  }

  Future<void> _saveActivityLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _activityLogs.map((log) => log.toJson()).toList();
      await prefs.setString('admin_activity_logs', logsJson.toString());
    } catch (e) {
      LoggerUtil.error('활동 로그 저장 오류: $e');
    }
  }

  Future<void> _loadActivityLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsString = prefs.getString('admin_activity_logs');
      if (logsString != null) {
        // 실제 구현에서는 JSON.decode를 사용해야 함
        _activityLogs = []; // 임시로 빈 리스트
      }
    } catch (e) {
      LoggerUtil.error('활동 로그 로드 오류: $e');
    }
  }

  Future<void> _initializeDefaultTemplates() async {
    if (_notificationTemplates.isEmpty) {
      final defaultTemplates = [
        NotificationTemplate(
          id: 'template_1',
          title: '학사 일정 안내',
          content: '중요한 학사 일정을 안내드립니다.',
          type: 'schedule',
          priority: NotificationPriority.normal,
          createdAt: DateTime.now(),
          lastUsed: DateTime.now(),
        ),
        NotificationTemplate(
          id: 'template_2',
          title: '긴급 상황 알림',
          content: '긴급 상황이 발생했습니다. 즉시 확인해주세요.',
          type: 'emergency',
          priority: NotificationPriority.urgent,
          createdAt: DateTime.now(),
          lastUsed: DateTime.now(),
        ),
        NotificationTemplate(
          id: 'template_3',
          title: '성적 발표',
          content: '성적이 발표되었습니다. 확인해주세요.',
          type: 'grade',
          priority: NotificationPriority.high,
          createdAt: DateTime.now(),
          lastUsed: DateTime.now(),
        ),
      ];

      _notificationTemplates.addAll(defaultTemplates);
      await _saveTemplates();
    }
  }

  Future<void> _saveTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson =
          _notificationTemplates.map((t) => t.toJson()).toList();
      await prefs.setString('notification_templates', templatesJson.toString());
    } catch (e) {
      LoggerUtil.error('템플릿 저장 오류: $e');
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesString = prefs.getString('notification_templates');
      if (templatesString != null) {
        // 실제 구현에서는 JSON.decode를 사용해야 함
        // _notificationTemplates = ...;
      }
    } catch (e) {
      LoggerUtil.error('템플릿 로드 오류: $e');
    }
  }

  Future<void> _updateTemplateUsage(String templateId) async {
    try {
      final index =
          _notificationTemplates.indexWhere((t) => t.id == templateId);
      if (index != -1) {
        final template = _notificationTemplates[index];
        _notificationTemplates[index] = template.copyWith(
          usageCount: template.usageCount + 1,
          lastUsed: DateTime.now(),
        );
        await _saveTemplates();
        notifyListeners();
      }
    } catch (e) {
      LoggerUtil.error('템플릿 사용량 업데이트 오류: $e');
    }
  }

  Future<void> _saveScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledJson =
          _scheduledNotifications.map((n) => n.toJson()).toList();
      await prefs.setString(
          'scheduled_notifications', scheduledJson.toString());
    } catch (e) {
      LoggerUtil.error('예약 알림 저장 오류: $e');
    }
  }

  Future<void> _loadScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledString = prefs.getString('scheduled_notifications');
      if (scheduledString != null) {
        // 실제 구현에서는 JSON.decode를 사용해야 함
        _scheduledNotifications = [];
      }
    } catch (e) {
      LoggerUtil.error('예약 알림 로드 오류: $e');
    }
  }

  Future<void> _updateDashboardStats() async {
    try {
      LoggerUtil.info('대시보드 통계 업데이트 시작');

      // 파이어베이스에서 실제 사용자 통계 가져오기
      final userStats = await _userService.getUserStats();
      final onlineUsers = await _userService.getOnlineUsersCount();

      // 알림 통계 (NotificationProvider에서 가져오기)
      final notificationStats =
          _notificationProvider?.getNotificationStats() ?? {};

      _dashboardStats = {
        'totalUsers': userStats['totalUsers'] ?? 0,
        'activeUsers': userStats['activeUsers'] ?? 0,
        'newUsersToday': userStats['newUsersToday'] ?? 0,
        'onlineUsers': onlineUsers,
        'totalNotifications': notificationStats['totalNotifications'] ?? 0,
        'sentToday': notificationStats['sentToday'] ?? 0,
        'readRate': notificationStats['readRate'] ?? 0.0,
        'errorRate': 0.003, // 시스템 오류율은 하드코딩
        'systemUptime': 99.97, // 시스템 가동율은 하드코딩
        'storageUsage': 0.34, // 저장소 사용량은 하드코딩
        'apiCalls': 1234, // API 호출 수는 하드코딩
        'responseTime': 0.15, // 응답 시간은 하드코딩
        'gradeCount': userStats['gradeCount'] ?? {},
        'classCount': userStats['classCount'] ?? {},
        'last_updated': DateTime.now().toIso8601String(),
      };

      LoggerUtil.info('대시보드 통계 업데이트 완료: $_dashboardStats');
      notifyListeners();
    } catch (e) {
      LoggerUtil.error('대시보드 통계 업데이트 오류: $e');
      // 오류 발생 시 기본 통계 사용
      _dashboardStats = {
        'totalUsers': 0,
        'activeUsers': 0,
        'newUsersToday': 0,
        'onlineUsers': 0,
        'totalNotifications': 0,
        'sentToday': 0,
        'readRate': 0.0,
        'errorRate': 0.0,
        'systemUptime': 0.0,
        'storageUsage': 0.0,
        'apiCalls': 0,
        'responseTime': 0.0,
        'gradeCount': {},
        'classCount': {},
        'last_updated': DateTime.now().toIso8601String(),
      };
      notifyListeners();
    }
  }

  // 템플릿 관리 메서드들
  Future<bool> saveNotificationTemplate(
    String title,
    String content,
    String type,
    NotificationPriority priority,
  ) async {
    try {
      final template = NotificationTemplate(
        id: 'template_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        content: content,
        type: type,
        priority: priority,
        createdAt: DateTime.now(),
        lastUsed: DateTime.now(),
      );

      _notificationTemplates.add(template);
      await _saveTemplates();

      await _logActivity(
        action: 'ADMIN_TEMPLATE_CREATED',
        description: '알림 템플릿이 생성되었습니다: $title',
      );

      notifyListeners();
      return true;
    } catch (e) {
      LoggerUtil.error('템플릿 저장 오류: $e');
      return false;
    }
  }

  Future<bool> deleteNotificationTemplate(String templateId) async {
    try {
      _notificationTemplates
          .removeWhere((template) => template.id == templateId);
      await _saveTemplates();

      await _logActivity(
        action: 'ADMIN_TEMPLATE_DELETED',
        description: '알림 템플릿이 삭제되었습니다: $templateId',
      );

      notifyListeners();
      return true;
    } catch (e) {
      LoggerUtil.error('템플릿 삭제 오류: $e');
      return false;
    }
  }

  // 예약 알림 관리 메서드들 (기존 scheduleNotification 메서드 사용)

  Future<bool> deleteScheduledNotification(String notificationId) async {
    try {
      _scheduledNotifications
          .removeWhere((notification) => notification.id == notificationId);
      await _saveScheduledNotifications();

      await _logActivity(
        action: 'ADMIN_SCHEDULED_NOTIFICATION_DELETED',
        description: '예약 알림이 삭제되었습니다: $notificationId',
      );

      notifyListeners();
      return true;
    } catch (e) {
      LoggerUtil.error('예약 알림 삭제 오류: $e');
      return false;
    }
  }

  Map<String, int> _getNotificationsByType(
      List<NotificationModel> notifications) {
    final typeMap = <String, int>{};
    for (final notification in notifications) {
      typeMap[notification.type] = (typeMap[notification.type] ?? 0) + 1;
    }
    return typeMap;
  }

  Map<String, int> _getNotificationsByPriority(
      List<NotificationModel> notifications) {
    final priorityMap = <String, int>{};
    for (final notification in notifications) {
      final priority = notification.priority.name;
      priorityMap[priority] = (priorityMap[priority] ?? 0) + 1;
    }
    return priorityMap;
  }

  double _calculateReadRate(List<NotificationModel> notifications) {
    if (notifications.isEmpty) return 0.0;
    final readCount = notifications.where((n) => n.isRead).length;
    return (readCount / notifications.length) * 100;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 데이터베이스 정리 관련 메서드들

  /// 데이터베이스 전체 정리 실행
  Future<Map<String, dynamic>> performDatabaseCleanup() async {
    try {
      LoggerUtil.info('관리자가 데이터베이스 정리 시작');

      final results = await _databaseCleanupService.performFullCleanup();

      await _logActivity(
        action: 'DATABASE_CLEANUP',
        description: '데이터베이스 전체 정리 완료',
        metadata: results,
      );

      LoggerUtil.info('데이터베이스 정리 완료');
      return results;
    } catch (e) {
      LoggerUtil.error('데이터베이스 정리 오류: $e');
      throw Exception('데이터베이스 정리에 실패했습니다: $e');
    }
  }

  /// 데이터베이스 통계 조회
  Future<Map<String, dynamic>> getDatabaseStatistics() async {
    try {
      LoggerUtil.info('데이터베이스 통계 조회 시작');

      final stats = await _databaseCleanupService.getDatabaseStats();

      LoggerUtil.info('데이터베이스 통계 조회 완료');
      return stats;
    } catch (e) {
      LoggerUtil.error('데이터베이스 통계 조회 오류: $e');
      throw Exception('데이터베이스 통계 조회에 실패했습니다: $e');
    }
  }

  /// 인덱스 최적화 권장사항 조회
  List<String> getDatabaseIndexRecommendations() {
    return _databaseCleanupService.getIndexRecommendations();
  }

  /// 데이터베이스 정리 요약 정보 생성
  String generateCleanupSummary(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('🧹 데이터베이스 정리 완료 보고서');
    buffer.writeln('');

    // 중복 데이터 정리 결과
    if (results.containsKey('duplicates')) {
      final duplicates = results['duplicates'] as Map<String, int>;
      buffer.writeln('📋 중복 데이터 정리:');
      duplicates.forEach((key, value) {
        if (value > 0) {
          buffer.writeln('  - $key: $value개 제거');
        }
      });
      buffer.writeln('');
    }

    // 만료된 데이터 정리 결과
    if (results.containsKey('expired')) {
      final expired = results['expired'] as Map<String, int>;
      buffer.writeln('📅 만료된 데이터 정리:');
      expired.forEach((key, value) {
        if (value > 0) {
          buffer.writeln('  - $key: $value개 제거');
        }
      });
      buffer.writeln('');
    }

    // 고아 데이터 정리 결과
    if (results.containsKey('orphaned')) {
      final orphaned = results['orphaned'] as Map<String, int>;
      buffer.writeln('🔗 고아 데이터 정리:');
      orphaned.forEach((key, value) {
        if (value > 0) {
          buffer.writeln('  - $key: $value개 제거');
        }
      });
      buffer.writeln('');
    }

    // 빈 문서 정리 결과
    if (results.containsKey('empty')) {
      final empty = results['empty'] as Map<String, int>;
      buffer.writeln('📄 빈 문서 정리:');
      empty.forEach((key, value) {
        if (value > 0) {
          buffer.writeln('  - $key: $value개 제거');
        }
      });
      buffer.writeln('');
    }

    // 데이터 정규화 결과
    if (results.containsKey('normalized')) {
      final normalized = results['normalized'] as Map<String, int>;
      buffer.writeln('🔧 데이터 정규화:');
      normalized.forEach((key, value) {
        if (value > 0) {
          buffer.writeln('  - $key: $value개 정규화');
        }
      });
      buffer.writeln('');
    }

    buffer.writeln('✅ 정리 작업이 성공적으로 완료되었습니다.');
    return buffer.toString();
  }
}
