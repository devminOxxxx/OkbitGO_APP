import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger_util.dart';

class UserMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 사용자 데이터 필드명 마이그레이션
  /// 'class' -> 'classNumber'
  /// 'number' -> 'studentNumber'
  Future<void> migrateUserFields() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        LoggerUtil.info('로그인된 사용자가 없어 마이그레이션을 건너뜁니다.');
        return;
      }

      LoggerUtil.info('사용자 데이터 마이그레이션 시작: ${currentUser.uid}');

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        LoggerUtil.info('사용자 문서가 존재하지 않아 마이그레이션을 건너뜁니다.');
        return;
      }

      final data = userDoc.data()!;
      final updates = <String, dynamic>{};
      bool needsUpdate = false;

      // 'class' 필드를 'classNumber'로 마이그레이션
      if (data.containsKey('class') && !data.containsKey('classNumber')) {
        final classValue = data['class'];
        if (classValue != null) {
          updates['classNumber'] = classValue.toString();
          needsUpdate = true;
          LoggerUtil.info('class 필드를 classNumber로 마이그레이션: $classValue');
        }
      }

      // 'number' 필드를 'studentNumber'로 마이그레이션
      if (data.containsKey('number') && !data.containsKey('studentNumber')) {
        final numberValue = data['number'];
        if (numberValue != null) {
          updates['studentNumber'] = numberValue.toString();
          needsUpdate = true;
          LoggerUtil.info('number 필드를 studentNumber로 마이그레이션: $numberValue');
        }
      }

      // grade 필드를 String으로 정규화
      if (data.containsKey('grade')) {
        final gradeValue = data['grade'];
        if (gradeValue != null && gradeValue is! String) {
          updates['grade'] = gradeValue.toString();
          needsUpdate = true;
          LoggerUtil.info('grade 필드를 String으로 정규화: $gradeValue');
        }
      }

      if (needsUpdate) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await userDoc.reference.update(updates);
        LoggerUtil.info('사용자 데이터 마이그레이션 완료');
      } else {
        LoggerUtil.info('마이그레이션이 필요한 필드가 없습니다.');
      }
    } catch (e) {
      LoggerUtil.error('사용자 데이터 마이그레이션 오류: $e');
    }
  }
}
