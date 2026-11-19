import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/database_config.dart';

/// Firestore 데이터베이스 정리 및 최적화 유틸리티
class DatabaseCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 데이터베이스 전체 정리 실행
  Future<Map<String, dynamic>> performFullCleanup() async {
    final results = <String, dynamic>{};

    try {
      debugPrint('🧹 데이터베이스 정리 시작...');

      // 1. 중복 데이터 정리
      results['duplicates'] = await _removeDuplicateEntries();

      // 2. 오래된 데이터 정리
      results['expired'] = await _removeExpiredData();

      // 3. 고아 데이터 정리
      results['orphaned'] = await _removeOrphanedData();

      // 4. 빈 문서 정리
      results['empty'] = await _removeEmptyDocuments();

      // 5. 데이터 타입 정규화
      results['normalized'] = await _normalizeDataTypes();

      // 6. 인덱스 최적화 권장사항
      results['indexRecommendations'] = getIndexRecommendations();

      debugPrint('✅ 데이터베이스 정리 완료');
      return results;
    } catch (e) {
      debugPrint('❌ 데이터베이스 정리 오류: $e');
      throw Exception('데이터베이스 정리에 실패했습니다: $e');
    }
  }

  /// 중복 데이터 제거
  Future<Map<String, int>> _removeDuplicateEntries() async {
    final results = <String, int>{};

    try {
      debugPrint('🔍 중복 데이터 검사 중...');

      // 사용자별 중복 D-Day 제거
      results['ddays'] = await _removeDuplicateDDays();

      // 사용자별 중복 이벤트 제거
      results['events'] = await _removeDuplicateEvents();

      // 중복 스터디 타이머 제거
      results['studyTimers'] = await _removeDuplicateStudyTimers();

      return results;
    } catch (e) {
      debugPrint('중복 데이터 제거 오류: $e');
      return results;
    }
  }

  /// 중복 D-Day 제거
  Future<int> _removeDuplicateDDays() async {
    int removedCount = 0;

    try {
      final snapshot =
          await _firestore.collection(DatabaseConfig.ddaysCollection).get();

      final Map<String, List<QueryDocumentSnapshot>> userDDays = {};

      // 사용자별로 D-Day 그룹화
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data[DatabaseConfig.userIdField] as String?;
        final title = data[DatabaseConfig.titleField] as String?;

        if (userId != null && title != null) {
          final key = '${userId}_$title';
          userDDays[key] ??= [];
          userDDays[key]!.add(doc);
        }
      }

      // 중복 제거 (가장 최근 것만 남기고 삭제)
      for (final entry in userDDays.entries) {
        if (entry.value.length > 1) {
          // 생성일 기준으로 정렬
          entry.value.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aCreated = aData[DatabaseConfig.createdAtField] as Timestamp?;
            final bCreated = bData[DatabaseConfig.createdAtField] as Timestamp?;

            if (aCreated == null && bCreated == null) return 0;
            if (aCreated == null) return 1;
            if (bCreated == null) return -1;

            return bCreated.compareTo(aCreated); // 최신순
          });

          // 첫 번째(최신)를 제외하고 모두 삭제
          for (int i = 1; i < entry.value.length; i++) {
            await entry.value[i].reference.delete();
            removedCount++;
          }
        }
      }

      debugPrint('중복 D-Day $removedCount개 제거됨');
      return removedCount;
    } catch (e) {
      debugPrint('중복 D-Day 제거 오류: $e');
      return removedCount;
    }
  }

  /// 중복 이벤트 제거
  Future<int> _removeDuplicateEvents() async {
    int removedCount = 0;

    try {
      final snapshot =
          await _firestore.collection(DatabaseConfig.eventsCollection).get();

      final Map<String, List<QueryDocumentSnapshot>> userEvents = {};

      // 사용자별로 이벤트 그룹화
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data[DatabaseConfig.userIdField] as String?;
        final title = data[DatabaseConfig.titleField] as String?;
        final date = data[DatabaseConfig.dateField] as Timestamp?;

        if (userId != null && title != null && date != null) {
          final key = '${userId}_${title}_${date.millisecondsSinceEpoch}';
          userEvents[key] ??= [];
          userEvents[key]!.add(doc);
        }
      }

      // 중복 제거
      for (final entry in userEvents.entries) {
        if (entry.value.length > 1) {
          // 첫 번째를 제외하고 모두 삭제
          for (int i = 1; i < entry.value.length; i++) {
            await entry.value[i].reference.delete();
            removedCount++;
          }
        }
      }

      debugPrint('중복 이벤트 $removedCount개 제거됨');
      return removedCount;
    } catch (e) {
      debugPrint('중복 이벤트 제거 오류: $e');
      return removedCount;
    }
  }

  /// 중복 스터디 타이머 제거
  Future<int> _removeDuplicateStudyTimers() async {
    int removedCount = 0;

    try {
      final snapshot = await _firestore
          .collection(DatabaseConfig.studyTimersCollection)
          .get();

      final Map<String, List<QueryDocumentSnapshot>> userTimers = {};

      // 사용자별, 과목별로 타이머 그룹화
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data[DatabaseConfig.userIdField] as String?;
        final subject = data[DatabaseConfig.subjectField] as String?;

        if (userId != null && subject != null) {
          final key = '${userId}_$subject';
          userTimers[key] ??= [];
          userTimers[key]!.add(doc);
        }
      }

      // 중복 제거 (시간 합계 후 삭제)
      for (final entry in userTimers.entries) {
        if (entry.value.length > 1) {
          // 총 시간 합계 계산
          int totalDuration = 0;
          for (final doc in entry.value) {
            final data = doc.data() as Map<String, dynamic>;
            final duration =
                data[DatabaseConfig.totalDurationField] as int? ?? 0;
            totalDuration += duration;
          }

          // 첫 번째 문서에 합계 업데이트
          await entry.value.first.reference.update({
            DatabaseConfig.totalDurationField: totalDuration,
            DatabaseConfig.lastUpdatedField: FieldValue.serverTimestamp(),
          });

          // 나머지 삭제
          for (int i = 1; i < entry.value.length; i++) {
            await entry.value[i].reference.delete();
            removedCount++;
          }
        }
      }

      debugPrint('중복 스터디 타이머 $removedCount개 제거됨');
      return removedCount;
    } catch (e) {
      debugPrint('중복 스터디 타이머 제거 오류: $e');
      return removedCount;
    }
  }

  /// 만료된 데이터 제거
  Future<Map<String, int>> _removeExpiredData() async {
    final results = <String, int>{};

    try {
      debugPrint('📅 만료된 데이터 검사 중...');

      // 만료된 삭제 사용자 데이터 제거 (30일 이상)
      final expiredDate = DateTime.now()
          .subtract(Duration(days: DatabaseConfig.deletedUserExpirationDays));

      final snapshot = await _firestore
          .collection(DatabaseConfig.deletedUsersCollection)
          .where(DatabaseConfig.deletedAtField,
              isLessThan: Timestamp.fromDate(expiredDate))
          .get();

      int removedCount = 0;
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        removedCount++;
      }

      results['deletedUsers'] = removedCount;
      debugPrint('만료된 삭제 사용자 $removedCount개 제거됨');

      return results;
    } catch (e) {
      debugPrint('만료된 데이터 제거 오류: $e');
      return results;
    }
  }

  /// 고아 데이터 제거
  Future<Map<String, int>> _removeOrphanedData() async {
    final results = <String, int>{};

    try {
      debugPrint('🔗 고아 데이터 검사 중...');

      // 모든 사용자 ID 가져오기
      final userSnapshot =
          await _firestore.collection(DatabaseConfig.usersCollection).get();

      final validUserIds = userSnapshot.docs.map((doc) => doc.id).toSet();

      // 고아 D-Day 제거
      final ddaySnapshot =
          await _firestore.collection(DatabaseConfig.ddaysCollection).get();

      int removedDDays = 0;
      for (final doc in ddaySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data[DatabaseConfig.userIdField] as String?;

        if (userId != null && !validUserIds.contains(userId)) {
          await doc.reference.delete();
          removedDDays++;
        }
      }

      results['orphanedDDays'] = removedDDays;
      debugPrint('고아 D-Day $removedDDays개 제거됨');

      return results;
    } catch (e) {
      debugPrint('고아 데이터 제거 오류: $e');
      return results;
    }
  }

  /// 빈 문서 제거
  Future<Map<String, int>> _removeEmptyDocuments() async {
    final results = <String, int>{};

    try {
      debugPrint('📄 빈 문서 검사 중...');

      final collections = [
        DatabaseConfig.usersCollection,
        DatabaseConfig.ddaysCollection,
        DatabaseConfig.eventsCollection,
      ];

      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        int removedCount = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();

          // 빈 문서 검사
          if (data.isEmpty) {
            await doc.reference.delete();
            removedCount++;
          }
        }

        results[collection] = removedCount;
        if (removedCount > 0) {
          debugPrint('$collection에서 빈 문서 $removedCount개 제거됨');
        }
      }

      return results;
    } catch (e) {
      debugPrint('빈 문서 제거 오류: $e');
      return results;
    }
  }

  /// 데이터 타입 정규화
  Future<Map<String, int>> _normalizeDataTypes() async {
    final results = <String, int>{};

    try {
      debugPrint('🔧 데이터 타입 정규화 중...');

      final snapshot =
          await _firestore.collection(DatabaseConfig.usersCollection).get();

      int normalizedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final updates = <String, dynamic>{};
        bool needsUpdate = false;

        // grade, classNumber, studentNumber를 String으로 정규화
        for (final field in ['grade', 'classNumber', 'studentNumber']) {
          final value = data[field];
          if (value != null && value is! String) {
            updates[field] = value.toString();
            needsUpdate = true;
          }
        }

        // 기본값 설정
        if (data['theme'] == null) {
          updates['theme'] = DatabaseConfig.defaultTheme;
          needsUpdate = true;
        }

        if (data['allergies'] == null) {
          updates['allergies'] = [];
          needsUpdate = true;
        }

        if (data['notificationSettings'] == null) {
          updates['notificationSettings'] =
              DatabaseConfig.defaultNotificationSettings;
          needsUpdate = true;
        }

        if (needsUpdate) {
          await doc.reference.update(updates);
          normalizedCount++;
        }
      }

      results['users'] = normalizedCount;
      debugPrint('사용자 데이터 $normalizedCount개 정규화됨');

      return results;
    } catch (e) {
      debugPrint('데이터 타입 정규화 오류: $e');
      return results;
    }
  }

  /// 데이터베이스 통계 조회
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final stats = <String, dynamic>{};

    try {
      debugPrint('📊 데이터베이스 통계 수집 중...');

      final collections = [
        DatabaseConfig.usersCollection,
        DatabaseConfig.ddaysCollection,
        DatabaseConfig.eventsCollection,
        DatabaseConfig.examsCollection,
        DatabaseConfig.studyTimersCollection,
        DatabaseConfig.studyGroupsCollection,
        DatabaseConfig.deletedUsersCollection,
        DatabaseConfig.notificationsCollection,
        DatabaseConfig.adminLogsCollection,
      ];

      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        stats[collection] = {
          'count': snapshot.docs.length,
          'size': _calculateCollectionSize(snapshot.docs),
        };
      }

      // 전체 통계
      final totalDocs = stats.values
          .fold<int>(0, (sum, item) => sum + (item['count'] as int));
      final totalSize =
          stats.values.fold<int>(0, (sum, item) => sum + (item['size'] as int));

      stats['total'] = {
        'documents': totalDocs,
        'estimatedSize': '${(totalSize / 1024).toStringAsFixed(2)} KB',
      };

      return stats;
    } catch (e) {
      debugPrint('데이터베이스 통계 수집 오류: $e');
      return stats;
    }
  }

  /// 컬렉션 크기 계산 (추정)
  int _calculateCollectionSize(List<QueryDocumentSnapshot> docs) {
    int totalSize = 0;
    for (final doc in docs) {
      // 문서 ID 크기 + 데이터 크기 (대략적 추정)
      totalSize += doc.id.length;
      totalSize += doc.data().toString().length;
    }
    return totalSize;
  }

  /// 인덱스 최적화 권장사항
  List<String> getIndexRecommendations() {
    return [
      '🔍 권장 복합 인덱스:',
      '',
      '1. users 컬렉션:',
      '   - grade (ASC), classNumber (ASC), createdAt (DESC)',
      '   - isAdmin (ASC), createdAt (DESC)',
      '   - school (ASC), grade (ASC)',
      '',
      '2. ddays 컬렉션:',
      '   - userId (ASC), date (ASC)',
      '   - userId (ASC), isCompleted (ASC), date (ASC)',
      '',
      '3. events 컬렉션:',
      '   - userId (ASC), date (ASC)',
      '   - userId (ASC), isCompleted (ASC), date (DESC)',
      '',
      '4. studyTimers 컬렉션:',
      '   - userId (ASC), subject (ASC)',
      '   - userId (ASC), lastUpdated (DESC)',
      '',
      '5. notifications 컬렉션:',
      '   - userId (ASC), isRead (ASC), createdAt (DESC)',
      '   - type (ASC), createdAt (DESC)',
      '',
      '📝 Firebase 콘솔에서 수동으로 생성하세요:',
      'https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/indexes',
    ];
  }
}
