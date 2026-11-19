import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/exam_storage_service.dart';
import '../utils/logger_util.dart';

class ExamProvider extends ChangeNotifier {
  final ExamStorageService _storageService;
  List<ExamScore> _examScores = [];
  final Map<String, ExamGradeCutoff?> _gradeCutoffs = {};
  bool _isLoading = false;
  String? _error;

  ExamProvider(this._storageService) {
    _loadData();
  }

  List<ExamScore> get examScores => _examScores;
  Map<String, ExamGradeCutoff?> get gradeCutoffs => _gradeCutoffs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadData() async {
    _setLoading(true);
    try {
      _examScores = await _storageService.getExamScores();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 시험 점수 추가
  Future<void> addExamScore(
    String exam,
    String subject,
    int score,
    int totalScore,
  ) async {
    _setLoading(true);
    try {
      final examScore = ExamScore(
        exam: exam,
        subject: subject,
        score: score,
        totalScore: totalScore,
        createdAt: DateTime.now(),
      );
      await _storageService.saveExamScore(examScore);
      _examScores.add(examScore);
      _error = null;

      // 등급컷 다시 로드
      await _loadGradeCutoffs(exam, subject);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 시험 점수 삭제
  Future<void> deleteExamScore(ExamScore score) async {
    _setLoading(true);
    try {
      await _storageService.deleteExamScore(score);
      _examScores.removeWhere((s) =>
          s.exam == score.exam &&
          s.subject == score.subject &&
          s.createdAt == score.createdAt);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 등급컷 로드
  Future<void> _loadGradeCutoffs(String exam, String subject) async {
    try {
      final key = '${exam}_$subject';
      final cutoffs = await _storageService.getGradeCutoffs(exam, subject);
      _gradeCutoffs[key] = cutoffs;
      notifyListeners();
    } catch (e) {
      LoggerUtil.error('Error loading grade cutoffs: $e');
    }
  }

  // 특정 시험과 과목의 등급컷 가져오기
  Future<ExamGradeCutoff?> getGradeCutoffs(String exam, String subject) async {
    final key = '${exam}_$subject';

    // 캐시된 데이터가 있으면 반환
    if (_gradeCutoffs.containsKey(key)) {
      return _gradeCutoffs[key];
    }

    // 없으면 로드
    await _loadGradeCutoffs(exam, subject);
    return _gradeCutoffs[key];
  }

  // 데이터 새로고침
  Future<void> refreshData() async {
    await _loadData();

    // 모든 시험과 과목 조합에 대한 등급컷 다시 로드
    _gradeCutoffs.clear();
    for (final score in _examScores) {
      final key = '${score.exam}_${score.subject}';
      if (!_gradeCutoffs.containsKey(key)) {
        await _loadGradeCutoffs(score.exam, score.subject);
      }
    }
  }

  // 시험 삭제
  Future<void> deleteExam(String examId) async {
    try {
      await _storageService.deleteExam(examId);
      _examScores.removeWhere((score) =>
          score.exam == examId || '${score.exam}_${score.subject}' == examId);
      notifyListeners();
    } catch (e) {
      _error = '시험 삭제 중 오류가 발생했습니다: $e';
      notifyListeners();
      throw Exception(_error);
    }
  }
}
