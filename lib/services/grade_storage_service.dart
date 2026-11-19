import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade_model.dart';

class GradeStorageService {
  static const String _gradesKey = 'grades';
  static const String _mockExamsKey = 'mock_exams';
  late SharedPreferences _prefs;

  static Future<GradeStorageService> create() async {
    final service = GradeStorageService();
    await service._init();
    return service;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 내신 성적 관련 메서드
  Future<List<Grade>> getGrades() async {
    final gradesJson = _prefs.getStringList(_gradesKey) ?? [];
    return gradesJson.map((json) => Grade.fromJson(jsonDecode(json))).toList();
  }

  Future<void> saveGrade(Grade grade) async {
    final grades = await getGrades();
    grades.add(grade);
    await _saveGrades(grades);
  }

  Future<void> _saveGrades(List<Grade> grades) async {
    final gradesJson =
        grades.map((grade) => jsonEncode(grade.toJson())).toList();
    await _prefs.setStringList(_gradesKey, gradesJson);
  }

  Future<void> deleteGrade(Grade grade) async {
    final grades = await getGrades();
    grades.removeWhere((g) =>
        g.year == grade.year &&
        g.semester == grade.semester &&
        g.subject == grade.subject &&
        g.createdAt == grade.createdAt);
    await _saveGrades(grades);
  }

  // 모의고사 성적 관련 메서드
  Future<List<MockExam>> getMockExams() async {
    final mockExamsJson = _prefs.getStringList(_mockExamsKey) ?? [];
    return mockExamsJson
        .map((json) => MockExam.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveMockExam(MockExam mockExam) async {
    final mockExams = await getMockExams();
    mockExams.add(mockExam);
    await _saveMockExams(mockExams);
  }

  Future<void> _saveMockExams(List<MockExam> mockExams) async {
    final mockExamsJson =
        mockExams.map((exam) => jsonEncode(exam.toJson())).toList();
    await _prefs.setStringList(_mockExamsKey, mockExamsJson);
  }

  Future<void> deleteMockExam(MockExam mockExam) async {
    final mockExams = await getMockExams();
    mockExams.removeWhere((e) =>
        e.year == mockExam.year &&
        e.examName == mockExam.examName &&
        e.subject == mockExam.subject &&
        e.createdAt == mockExam.createdAt);
    await _saveMockExams(mockExams);
  }
}
