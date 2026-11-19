import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // 초기화
  Future<void> initialize() async {
    try {
      // 타임존 초기화
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      // 로컬 알림 초기화
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // 알림을 탭했을 때 처리
          debugPrint('알림 응답 수신: ${response.payload}');
        },
      );

      debugPrint('NotificationService: 초기화 완료');
    } catch (e) {
      debugPrint('NotificationService: 초기화 오류 - $e');
    }
  }

  // 알림 권한 요청
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        final bool? granted =
            await androidImplementation?.requestNotificationsPermission();
        debugPrint('NotificationService: Android 알림 권한 요청 결과 - $granted');
        return granted ?? false;
      } else if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iOSImplementation =
            _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>();

        final bool? granted = await iOSImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('NotificationService: iOS 알림 권한 요청 결과 - $granted');
        return granted ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('NotificationService: 권한 요청 오류 - $e');
      return false;
    }
  }

  // 알림 가져오기
  Future<List<NotificationModel>> getNotifications() async {
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    debugPrint('NotificationService: 알림 가져오기 시작 - $userId');

    try {
      // 로컬 저장소에서 먼저 가져오기
      final localNotifications = await _getLocalNotifications();

      // Firestore에서 가져오기
      // 인덱스 오류를 방지하기 위해 쿼리 방식 변경
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      // 메모리에서 정렬 수행
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationModel.fromMap(data);
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 내림차순 정렬

      // 로컬 저장소에 저장
      await _saveLocalNotifications(notifications);

      debugPrint('NotificationService: 알림 가져오기 완료 - ${notifications.length}개');
      return notifications;
    } catch (e) {
      debugPrint('NotificationService: 알림 가져오기 오류 - $e');
      // 오류 발생 시 로컬 저장소의 데이터 반환
      return await _getLocalNotifications();
    }
  }

  // 알림 추가
  Future<NotificationModel> addNotification({
    required String title,
    required String message,
    required String type,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    debugPrint('NotificationService: 알림 추가 시작 - $userId');

    try {
      final notificationData = {
        'title': title,
        'message': message,
        'time': Timestamp.now(),
        'type': type,
        'isRead': false,
        'userId': userId,
        'relatedId': relatedId,
        'metadata': metadata,
      };

      // Firestore에 저장
      final docRef =
          await _firestore.collection('notifications').add(notificationData);

      final notification = NotificationModel(
        id: docRef.id,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        type: type,
        isRead: false,
        relatedId: relatedId,
        metadata: metadata,
      );

      // 로컬 저장소에 추가
      final localNotifications = await _getLocalNotifications();
      localNotifications.insert(0, notification);
      await _saveLocalNotifications(localNotifications);

      // 로컬 알림 표시
      await _showLocalNotification(notification);

      debugPrint('NotificationService: 알림 추가 완료 - ${notification.id}');
      return notification;
    } catch (e) {
      debugPrint('NotificationService: 알림 추가 오류 - $e');
      rethrow;
    }
  }

  // 시간표 알림 예약 (매일 오전 8시)
  Future<void> scheduleTimetableNotification() async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        8, // 오전 8시
        0,
      );

      // 현재 시간이 오전 8시 이후라면 다음 날로 설정
      if (now.hour >= 8) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        1, // ID
        '오늘의 시간표',
        '오늘 수업 시간표를 확인해보세요.',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'timetable_channel',
            '시간표 알림',
            channelDescription: '매일 오전 8시에 시간표 알림을 보냅니다.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('NotificationService: 시간표 알림 예약 완료');
    } catch (e) {
      debugPrint('NotificationService: 시간표 알림 예약 오류 - $e');
    }
  }

  // 급식 알림 예약 (매일 오전 8시)
  Future<void> scheduleMealNotification() async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        8, // 오전 8시
        0,
      );

      // 현재 시간이 오전 8시 이후라면 다음 날로 설정
      if (now.hour >= 8) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        2, // ID
        '오늘의 급식',
        '오늘 급식 메뉴를 확인해보세요.',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'meal_channel',
            '급식 알림',
            channelDescription: '매일 오전 8시에 급식 알림을 보냅니다.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('NotificationService: 급식 알림 예약 완료');
    } catch (e) {
      debugPrint('NotificationService: 급식 알림 예약 오류 - $e');
    }
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification(NotificationModel notification) async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'general_channel',
            '일반 알림',
            channelDescription: '일반 알림을 표시합니다.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: notification.id,
      );
      debugPrint('NotificationService: 로컬 알림 표시 완료');
    } catch (e) {
      debugPrint('NotificationService: 로컬 알림 표시 오류 - $e');
    }
  }

  // 로컬 저장소에서 알림 가져오기
  Future<List<NotificationModel>> _getLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];

      if (notificationsJson.isEmpty) {
        return [];
      }

      final notifications = notificationsJson
          .map((jsonStr) {
            try {
              final Map<String, dynamic> data = json.decode(jsonStr);
              return NotificationModel.fromMap(data);
            } catch (e) {
              debugPrint('NotificationService: JSON 파싱 오류 - $e');
              return null;
            }
          })
          .whereType<NotificationModel>()
          .toList();

      return notifications;
    } catch (e) {
      debugPrint('NotificationService: 로컬 저장소에서 알림 가져오기 오류 - $e');
      return [];
    }
  }

  // 로컬 저장소에 알림 저장
  Future<void> _saveLocalNotifications(
      List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = notifications.map((notification) {
        final Map<String, dynamic> data = {
          ...notification.toMap(),
          'id': notification.id,
        };
        return json.encode(data);
      }).toList();

      await prefs.setStringList('notifications', notificationsJson);
      debugPrint('NotificationService: 로컬 저장소에 알림 저장 완료');
    } catch (e) {
      debugPrint('NotificationService: 로컬 저장소에 알림 저장 오류 - $e');
    }
  }

  // 알림 읽음 상태 변경
  Future<void> markAsRead(String notificationId) async {
    try {
      debugPrint('NotificationService: 알림 읽음 상태 변경 시작 - $notificationId');
      // Firestore 업데이트
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // 로컬 저장소 업데이트
      final localNotifications = await _getLocalNotifications();
      final index =
          localNotifications.indexWhere((n) => n.id == notificationId);

      if (index != -1) {
        localNotifications[index] =
            localNotifications[index].copyWith(isRead: true);
        await _saveLocalNotifications(localNotifications);
      }
      debugPrint('NotificationService: 알림 읽음 상태 변경 완료');
    } catch (e) {
      debugPrint('NotificationService: 알림 읽음 상태 변경 오류 - $e');
    }
  }

  // 모든 알림 읽음 상태로 변경
  Future<void> markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      debugPrint('NotificationService: 모든 알림 읽음 상태 변경 시작 - $userId');

      // Firestore 업데이트
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // 로컬 저장소 업데이트
      final localNotifications = await _getLocalNotifications();
      for (int i = 0; i < localNotifications.length; i++) {
        localNotifications[i] = localNotifications[i].copyWith(isRead: true);
      }
      await _saveLocalNotifications(localNotifications);

      debugPrint('NotificationService: 모든 알림 읽음 상태 변경 완료');
    } catch (e) {
      debugPrint('NotificationService: 모든 알림 읽음 상태 변경 오류 - $e');
    }
  }

  // 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    try {
      debugPrint('NotificationService: 알림 삭제 시작 - $notificationId');
      // Firestore에서 삭제
      await _firestore.collection('notifications').doc(notificationId).delete();

      // 로컬 저장소에서 삭제
      final localNotifications = await _getLocalNotifications();
      localNotifications.removeWhere((n) => n.id == notificationId);
      await _saveLocalNotifications(localNotifications);

      debugPrint('NotificationService: 알림 삭제 완료');
    } catch (e) {
      debugPrint('NotificationService: 알림 삭제 오류 - $e');
    }
  }

  // 모든 알림 삭제
  Future<void> deleteAllNotifications() async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      debugPrint('NotificationService: 모든 알림 삭제 시작 - $userId');

      // Firestore에서 삭제
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // 로컬 저장소 비우기
      await _saveLocalNotifications([]);

      debugPrint('NotificationService: 모든 알림 삭제 완료');
    } catch (e) {
      debugPrint('NotificationService: 모든 알림 삭제 오류 - $e');
    }
  }
}
