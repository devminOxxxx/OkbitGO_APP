import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/study_timer.dart';
import '../config/database_config.dart';

class StudyTimerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 사용자의 모든 타이머 가져오기
  Future<List<StudyTimer>> getUserTimers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(DatabaseConfig.studyTimersCollection)
          .where(DatabaseConfig.userIdField, isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => StudyTimer.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 타이머 생성 또는 업데이트
  Future<bool> saveTimer(StudyTimer timer) async {
    try {
      await _firestore
          .collection(DatabaseConfig.studyTimersCollection)
          .doc(timer.id)
          .set(timer.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // 타이머 삭제
  Future<bool> deleteTimer(String timerId) async {
    try {
      await _firestore
          .collection(DatabaseConfig.studyTimersCollection)
          .doc(timerId)
          .delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // 스터디 그룹 생성
  Future<String?> createStudyGroup(StudyGroup group) async {
    try {
      final docRef =
          _firestore.collection(DatabaseConfig.studyGroupsCollection).doc();
      final newGroup = group.copyWith(id: docRef.id);
      await docRef.set(newGroup.toJson());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // 모든 스터디 그룹 가져오기
  Future<List<StudyGroup>> getAllStudyGroups() async {
    try {
      final snapshot = await _firestore.collection('studyGroups').get();
      return snapshot.docs
          .map((doc) => StudyGroup.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 사용자가 속한 스터디 그룹 가져오기
  Future<List<StudyGroup>> getUserStudyGroups(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('studyGroups')
          .where('memberIds', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => StudyGroup.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 스터디 그룹 참여
  Future<bool> joinStudyGroup(String groupId, String userId) async {
    try {
      await _firestore.collection('studyGroups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId])
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 스터디 그룹 탈퇴
  Future<bool> leaveStudyGroup(String groupId, String userId) async {
    try {
      await _firestore.collection('studyGroups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId])
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // 그룹 멤버 정보 가져오기
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final groupDoc =
          await _firestore.collection('studyGroups').doc(groupId).get();
      final group = StudyGroup.fromJson(groupDoc.data()!);

      final List<GroupMember> members = [];
      for (final memberId in group.memberIds) {
        final userDoc =
            await _firestore.collection('users').doc(memberId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;

          // 사용자의 오늘 공부 시간 계산
          final timerSnapshot = await _firestore
              .collection('studyTimers')
              .where('userId', isEqualTo: memberId)
              .get();

          int todayStudyTime = 0;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // 활성 상태 확인 (최근 3분 이내에 활동이 있으면 활성 상태로 간주)
          bool isActive = false;
          final threeMinutesAgo = now.subtract(const Duration(minutes: 3));

          // 사용자의 마지막 활동 시간 확인
          final lastActive = userData['lastActive'] != null
              ? (userData['lastActive'] as Timestamp).toDate()
              : null;

          // 최근 3분 이내에 활동이 있고, 활성 타이머가 있으면 활성 상태로 간주
          if (lastActive != null &&
              lastActive.isAfter(threeMinutesAgo) &&
              userData['activeTimers'] != null &&
              (userData['activeTimers'] as List).isNotEmpty) {
            isActive = true;
          }

          // 오늘 공부 시간 계산
          for (final timerDoc in timerSnapshot.docs) {
            final timer = StudyTimer.fromJson(timerDoc.data());
            if (timer.lastUpdated.isAfter(today)) {
              todayStudyTime += timer.totalDuration;
            }
          }

          members.add(GroupMember(
            userId: memberId,
            name: userData['name'] ?? '알 수 없음',
            todayStudyTime: todayStudyTime,
            lastActive: lastActive ?? DateTime.now(),
            isActive: isActive,
          ));
        }
      }

      return members;
    } catch (e) {
      return [];
    }
  }

  // 사용자의 활성 타이머 업데이트
  Future<bool> updateActiveTimers(
      String userId, List<String> activeSubjects) async {
    try {
      // 현재 시간을 서버 타임스탬프로 기록
      await _firestore.collection('users').doc(userId).update({
        'activeTimers': activeSubjects,
        'lastActive': FieldValue.serverTimestamp(),
      });

      // 사용자 상태 업데이트 (공부 중 여부)
      await _firestore.collection('users').doc(userId).update({
        'isStudying': activeSubjects.isNotEmpty,
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
