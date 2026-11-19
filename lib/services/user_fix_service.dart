import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger_util.dart';

class UserFixService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 사용자 정보를 3학년 6반으로 강제 설정
  Future<void> forceSetUserTo3Grade6Class() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ 로그인된 사용자가 없습니다.');
        return;
      }

      print('🔧 사용자 정보를 3학년 6반으로 강제 설정 중...');
      print('   - 사용자 ID: ${currentUser.uid}');

      // 현재 사용자 정보 확인
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        final currentData = userDoc.data()!;
        print('📋 현재 사용자 정보:');
        print('   - grade: ${currentData['grade']}');
        print('   - classNumber: ${currentData['classNumber']}');
        print('   - class: ${currentData['class']}');
        print('   - studentNumber: ${currentData['studentNumber']}');
        print('   - number: ${currentData['number']}');
      }

      // 강제로 3학년 6반으로 설정
      await _firestore.collection('users').doc(currentUser.uid).update({
        'grade': '3',
        'classNumber': '6',
        'studentNumber': '1',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ 사용자 정보가 3학년 6반으로 업데이트되었습니다.');

      // 업데이트 후 확인
      final updatedDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (updatedDoc.exists) {
        final updatedData = updatedDoc.data()!;
        print('📋 업데이트된 사용자 정보:');
        print('   - grade: ${updatedData['grade']}');
        print('   - classNumber: ${updatedData['classNumber']}');
        print('   - studentNumber: ${updatedData['studentNumber']}');
      }
    } catch (e) {
      print('❌ 사용자 정보 업데이트 오류: $e');
      LoggerUtil.error('사용자 정보 강제 설정 오류: $e');
    }
  }

  /// 현재 사용자 정보 확인
  Future<void> checkCurrentUserInfo() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ 로그인된 사용자가 없습니다.');
        return;
      }

      print('🔍 현재 사용자 정보 확인:');
      print('   - 사용자 ID: ${currentUser.uid}');

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        print('📋 Firebase 사용자 정보:');
        data.forEach((key, value) {
          print('   - $key: $value (${value.runtimeType})');
        });
      } else {
        print('❌ 사용자 문서가 존재하지 않습니다.');
      }
    } catch (e) {
      print('❌ 사용자 정보 확인 오류: $e');
      LoggerUtil.error('사용자 정보 확인 오류: $e');
    }
  }
}
