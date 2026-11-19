import 'package:flutter/material.dart';
import '../models/grade_model.dart';
import '../services/grade_storage_service.dart';

class GradeProvider extends ChangeNotifier {
  final GradeStorageService _storageService;
  List<Grade> _grades = [];
  List<MockExam> _mockExams = [];
  bool _isLoading = false;
  String? _error;

  GradeProvider(this._storageService) {
    _loadData();
  }

  List<Grade> get grades => _grades;
  List<MockExam> get mockExams => _mockExams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadData() async {
    _setLoading(true);
    try {
      _grades = await _storageService.getGrades();
      _mockExams = await _storageService.getMockExams();
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

  // 내신 성적 관련 메서드
  Future<void> addGrade(
    String year,
    String semester,
    String subject,
    double score,
    double average,
    double standardDeviation,
  ) async {
    _setLoading(true);
    try {
      final grade = Grade(
        year: year,
        semester: semester,
        subject: subject,
        score: score,
        average: average,
        standardDeviation: standardDeviation,
        createdAt: DateTime.now(),
      );
      await _storageService.saveGrade(grade);
      _grades.add(grade);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteGrade(Grade grade) async {
    _setLoading(true);
    try {
      await _storageService.deleteGrade(grade);
      _grades.removeWhere((g) =>
          g.year == grade.year &&
          g.semester == grade.semester &&
          g.subject == grade.subject &&
          g.createdAt == grade.createdAt);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 모의고사 성적 관련 메서드
  Future<void> addMockExam(
    String year,
    String examName,
    String subject,
    double score,
    double percentile,
    double standardScore,
  ) async {
    _setLoading(true);
    try {
      final mockExam = MockExam(
        year: year,
        examName: examName,
        subject: subject,
        score: score,
        percentile: percentile,
        standardScore: standardScore,
        createdAt: DateTime.now(),
      );
      await _storageService.saveMockExam(mockExam);
      _mockExams.add(mockExam);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMockExam(MockExam mockExam) async {
    _setLoading(true);
    try {
      await _storageService.deleteMockExam(mockExam);
      _mockExams.removeWhere((e) =>
          e.year == mockExam.year &&
          e.examName == mockExam.examName &&
          e.subject == mockExam.subject &&
          e.createdAt == mockExam.createdAt);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // 데이터 새로고침
  Future<void> refreshData() async {
    await _loadData();
  }
}
