import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../utils/logger_util.dart';

// 알림 필터 유형
enum NotificationFilter { all, unread, read, archived }

// 알림 정렬 유형
enum NotificationSort { newest, oldest, priority, type }

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  bool _hasUnreadNotifications = false;

  // 필터링 및 정렬
  NotificationFilter _currentFilter = NotificationFilter.all;
  NotificationSort _currentSort = NotificationSort.newest;
  List<NotificationType> _selectedTypes = [];

  NotificationProvider(this._notificationService) {
    _initializeNotifications();
  }

  // Getters
  List<NotificationModel> get notifications =>
      _getFilteredAndSortedNotifications();
  List<NotificationModel> get allNotifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnreadNotifications => _hasUnreadNotifications;
  NotificationFilter get currentFilter => _currentFilter;
  NotificationSort get currentSort => _currentSort;
  List<NotificationType> get selectedTypes => _selectedTypes;

  // 통계 정보
  int get totalCount => _notifications.length;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get readCount => _notifications.where((n) => n.isRead).length;
  int get archivedCount => _notifications
      .where((n) => n.status == NotificationStatus.archived)
      .length;
  int get urgentCount => _notifications
      .where((n) => n.priority == NotificationPriority.urgent)
      .length;

  // 유형별 통계
  Map<NotificationType, int> get countByType {
    final Map<NotificationType, int> result = {};
    for (NotificationType type in NotificationType.values) {
      result[type] =
          _notifications.where((n) => n.notificationType == type).length;
    }
    return result;
  }

  // 초기화
  Future<void> _initializeNotifications() async {
    await loadNotifications();
    await _notificationService.requestPermission();
    await _scheduleRegularNotifications();
  }

  // 알림 로드
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications();
      _updateUnreadStatus();
      LoggerUtil.info('알림 ${_notifications.length}개 로드 완료');
    } catch (e) {
      _error = '알림을 불러오는 중 오류가 발생했습니다: $e';
      LoggerUtil.error('알림 로드 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 알림 추가
  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    String? relatedId,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? scheduledAt,
    DateTime? expiresAt,
    String? imageUrl,
    String? actionUrl,
    String? actionLabel,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        scheduledAt: scheduledAt,
        expiresAt: expiresAt,
        priority: priority,
        relatedId: relatedId,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        actionLabel: actionLabel,
        metadata: metadata,
      );

      await _notificationService.addNotification(
        title: title,
        message: message,
        type: type,
        relatedId: relatedId,
        metadata: metadata,
      );

      _notifications.insert(0, notification);
      _updateUnreadStatus();

      LoggerUtil.info('새로운 알림 추가: $title');
      notifyListeners();
    } catch (e) {
      _error = '알림을 추가하는 중 오류가 발생했습니다: $e';
      LoggerUtil.error('알림 추가 오류: $e');
      notifyListeners();
    }
  }

  // 대량 알림 추가 (관리자용)
  Future<void> addBulkNotifications(
      List<NotificationModel> notifications) async {
    try {
      _isLoading = true;
      notifyListeners();

      for (final notification in notifications) {
        await _notificationService.addNotification(
          title: notification.title,
          message: notification.message,
          type: notification.type,
          relatedId: notification.relatedId,
        );
        _notifications.insert(0, notification);
      }

      _updateUnreadStatus();
      LoggerUtil.info('대량 알림 ${notifications.length}개 추가 완료');
    } catch (e) {
      _error = '대량 알림 추가 중 오류가 발생했습니다: $e';
      LoggerUtil.error('대량 알림 추가 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 알림 읽음 상태 변경
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _updateUnreadStatus();
        notifyListeners();
      }
    } catch (e) {
      _error = '알림 상태를 변경하는 중 오류가 발생했습니다: $e';
      LoggerUtil.error('알림 읽음 상태 변경 오류: $e');
      notifyListeners();
    }
  }

  // 여러 알림 읽음 상태 변경
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      for (final id in notificationIds) {
        await _notificationService.markAsRead(id);
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      }
      _updateUnreadStatus();
      notifyListeners();
    } catch (e) {
      _error = '알림 상태 변경 중 오류가 발생했습니다: $e';
      LoggerUtil.error('다중 알림 읽음 상태 변경 오류: $e');
      notifyListeners();
    }
  }

  // 모든 알림 읽음 상태로 변경
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();

      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();

      _hasUnreadNotifications = false;
      notifyListeners();
    } catch (e) {
      _error = '알림 상태를 변경하는 중 오류가 발생했습니다: $e';
      LoggerUtil.error('모든 알림 읽음 상태 변경 오류: $e');
      notifyListeners();
    }
  }

  // 알림 상태 변경 (보관, 삭제 등)
  Future<void> updateNotificationStatus(
      String notificationId, NotificationStatus status) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(status: status);

        if (status == NotificationStatus.deleted) {
          await _notificationService.deleteNotification(notificationId);
          _notifications.removeAt(index);
        }

        _updateUnreadStatus();
        notifyListeners();
      }
    } catch (e) {
      _error = '알림 상태 변경 중 오류가 발생했습니다: $e';
      LoggerUtil.error('알림 상태 변경 오류: $e');
      notifyListeners();
    }
  }

  // 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    await updateNotificationStatus(notificationId, NotificationStatus.deleted);
  }

  // 모든 알림 삭제
  Future<void> deleteAllNotifications() async {
    try {
      await _notificationService.deleteAllNotifications();
      _notifications.clear();
      _hasUnreadNotifications = false;
      notifyListeners();
    } catch (e) {
      _error = '알림을 삭제하는 중 오류가 발생했습니다: $e';
      LoggerUtil.error('모든 알림 삭제 오류: $e');
      notifyListeners();
    }
  }

  // 만료된 알림 정리
  Future<void> cleanupExpiredNotifications() async {
    try {
      final now = DateTime.now();
      final expiredNotifications =
          _notifications.where((n) => n.isExpired).toList();

      for (final notification in expiredNotifications) {
        await updateNotificationStatus(
            notification.id, NotificationStatus.deleted);
      }

      LoggerUtil.info('만료된 알림 ${expiredNotifications.length}개 정리 완료');
    } catch (e) {
      LoggerUtil.error('만료된 알림 정리 오류: $e');
    }
  }

  // 필터 설정
  void setFilter(NotificationFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // 정렬 설정
  void setSort(NotificationSort sort) {
    _currentSort = sort;
    notifyListeners();
  }

  // 유형 필터 설정
  void setTypeFilter(List<NotificationType> types) {
    _selectedTypes = types;
    notifyListeners();
  }

  // 유형 필터 토글
  void toggleTypeFilter(NotificationType type) {
    if (_selectedTypes.contains(type)) {
      _selectedTypes.remove(type);
    } else {
      _selectedTypes.add(type);
    }
    notifyListeners();
  }

  // 필터 및 정렬 적용
  List<NotificationModel> _getFilteredAndSortedNotifications() {
    var filtered = List<NotificationModel>.from(_notifications);

    // 상태 필터
    switch (_currentFilter) {
      case NotificationFilter.unread:
        filtered = filtered.where((n) => !n.isRead).toList();
        break;
      case NotificationFilter.read:
        filtered = filtered.where((n) => n.isRead).toList();
        break;
      case NotificationFilter.archived:
        filtered = filtered
            .where((n) => n.status == NotificationStatus.archived)
            .toList();
        break;
      case NotificationFilter.all:
        filtered = filtered
            .where((n) => n.status != NotificationStatus.deleted)
            .toList();
        break;
    }

    // 유형 필터
    if (_selectedTypes.isNotEmpty) {
      filtered = filtered
          .where((n) => _selectedTypes.contains(n.notificationType))
          .toList();
    }

    // 정렬
    switch (_currentSort) {
      case NotificationSort.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case NotificationSort.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case NotificationSort.priority:
        filtered.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case NotificationSort.type:
        filtered.sort((a, b) => a.type.compareTo(b.type));
        break;
    }

    return filtered;
  }

  // 특정 유형의 알림 개수
  int getCountByType(NotificationType type) {
    return _notifications.where((n) => n.notificationType == type).length;
  }

  // 특정 우선순위의 알림 개수
  int getCountByPriority(NotificationPriority priority) {
    return _notifications.where((n) => n.priority == priority).length;
  }

  // 정기 알림 예약
  Future<void> _scheduleRegularNotifications() async {
    try {
      await _notificationService.scheduleTimetableNotification();
      await _notificationService.scheduleMealNotification();
    } catch (e) {
      LoggerUtil.error('정기 알림 예약 오류: $e');
    }
  }

  // 읽지 않은 알림 상태 업데이트
  void _updateUnreadStatus() {
    _hasUnreadNotifications =
        _notifications.any((notification) => !notification.isRead);
  }

  // 오류 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 알림 검색
  List<NotificationModel> searchNotifications(String query) {
    if (query.isEmpty) return notifications;

    return notifications.where((notification) {
      return notification.title.toLowerCase().contains(query.toLowerCase()) ||
          notification.message.toLowerCase().contains(query.toLowerCase()) ||
          notification.typeText.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // 시간별 통계 (24시간 기준)
  Map<int, int> getHourlyStats() {
    final Map<int, int> hourlyStats = {};
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    for (final notification in _notifications) {
      if (notification.createdAt.isAfter(yesterday)) {
        final hour = notification.createdAt.hour;
        hourlyStats[hour] = (hourlyStats[hour] ?? 0) + 1;
      }
    }

    return hourlyStats;
  }

  // 주간 통계
  Map<String, int> getWeeklyStats() {
    final Map<String, int> weeklyStats = {};
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final weekDays = ['월', '화', '수', '목', '금', '토', '일'];

    for (final notification in _notifications) {
      if (notification.createdAt.isAfter(weekAgo)) {
        final weekday = weekDays[notification.createdAt.weekday - 1];
        weeklyStats[weekday] = (weeklyStats[weekday] ?? 0) + 1;
      }
    }

    return weeklyStats;
  }

  // 알림 통계 (관리자용)
  Map<String, dynamic> getNotificationStats() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final totalNotifications = _notifications.length;
    final sentToday =
        _notifications.where((n) => n.createdAt.isAfter(todayStart)).length;
    final readNotifications = _notifications.where((n) => n.isRead).length;
    final readRate = totalNotifications > 0
        ? (readNotifications / totalNotifications) * 100
        : 0.0;

    // 유형별 통계
    final Map<String, int> typeStats = {};
    for (final notification in _notifications) {
      typeStats[notification.type] = (typeStats[notification.type] ?? 0) + 1;
    }

    // 우선순위별 통계
    final Map<String, int> priorityStats = {};
    for (final notification in _notifications) {
      priorityStats[notification.priority.name] =
          (priorityStats[notification.priority.name] ?? 0) + 1;
    }

    return {
      'totalNotifications': totalNotifications,
      'sentToday': sentToday,
      'readRate': readRate,
      'unreadCount': totalNotifications - readNotifications,
      'typeStats': typeStats,
      'priorityStats': priorityStats,
    };
  }
}
