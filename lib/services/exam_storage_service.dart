import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_model.dart';
import '../utils/logger_util.dart';
import '../config/database_config.dart';

class ExamStorageService {
  static const String _examScoresKey = 'exam_scores';
  late SharedPreferences _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<ExamStorageService> create() async {
    final service = ExamStorageService();
    await service._init();
    return service;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 로컬 시험 점수 관련 메서드
  Future<List<ExamScore>> getExamScores() async {
    final scoresJson = _prefs.getStringList(_examScoresKey) ?? [];
    return scoresJson
        .map((json) => ExamScore.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveExamScore(ExamScore score) async {
    final scores = await getExamScores();
    scores.add(score);
    await _saveExamScores(scores);

    // Firestore에도 익명으로 저장 (등급컷 계산용)
    await _saveScoreToFirestore(score);
  }

  Future<void> _saveExamScores(List<ExamScore> scores) async {
    final scoresJson =
        scores.map((score) => jsonEncode(score.toJson())).toList();
    await _prefs.setStringList(_examScoresKey, scoresJson);
  }

  Future<void> deleteExamScore(ExamScore score) async {
    final scores = await getExamScores();
    scores.removeWhere((s) =>
        s.exam == score.exam &&
        s.subject == score.subject &&
        s.createdAt == score.createdAt);
    await _saveExamScores(scores);
  }

  // Firestore 관련 메서드
  Future<void> _saveScoreToFirestore(ExamScore score) async {
    try {
      final docRef = _firestore
          .collection(DatabaseConfig.examsCollection)
          .doc('${score.exam}_${score.subject}');

      // 기존 문서 가져오기
      final doc = await docRef.get();

      if (doc.exists) {
        // 기존 문서 업데이트
        await docRef.update({
          'scores': FieldValue.arrayUnion([score.score]),
          'totalScore': score.totalScore,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 새 문서 생성
        await docRef.set({
          'exam': score.exam,
          'subject': score.subject,
          'scores': [score.score],
          'totalScore': score.totalScore,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      LoggerUtil.error('Error saving score to Firestore: $e');
    }
  }

  Future<ExamGradeCutoff?> getGradeCutoffs(String exam, String subject) async {
    try {
      final docRef = _firestore
          .collection(DatabaseConfig.examsCollection)
          .doc('${exam}_$subject');

      final doc = await docRef.get();

      if (!doc.exists || !doc.data()!.containsKey('scores')) {
        return null;
      }

      final data = doc.data()!;
      final scores = List<int>.from(data['scores'] as List);

      if (scores.isEmpty) {
        return null;
      }

      // 등급컷 계산
      scores.sort((a, b) => b.compareTo(a));
      final totalStudents = scores.length;
      final cutoffs = <int, int>{};

      // 1등급: 4% 이내
      final grade1Count = (totalStudents * 0.04).ceil();
      if (grade1Count > 0 && grade1Count <= scores.length) {
        cutoffs[1] = scores[grade1Count - 1];
      }

      // 2~8등급: 각 7%
      for (var i = 2; i <= 8; i++) {
        final count = (totalStudents * (0.04 + (i - 1) * 0.07)).ceil();
        if (count > 0 && count < scores.length) {
          cutoffs[i] = scores[count - 1];
        }
      }

      // 9등급: 나머지
      if (scores.isNotEmpty) {
        cutoffs[9] = scores.last;
      }

      return ExamGradeCutoff(
        exam: exam,
        subject: subject,
        cutoffs: cutoffs,
        participantCount: totalStudents,
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    } catch (e) {
      LoggerUtil.error('Error getting grade cutoffs: $e');
      return null;
    }
  }

  // 시험 삭제
  Future<void> deleteExam(String id) async {
    try {
      await _firestore
          .collection(DatabaseConfig.examsCollection)
          .doc(id)
          .delete();
    } catch (e) {
      LoggerUtil.error('Error deleting exam: $e');
      throw Exception('시험 삭제 중 오류가 발생했습니다: $e');
    }
  }
}
