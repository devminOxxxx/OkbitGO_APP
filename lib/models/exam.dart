import 'package:cloud_firestore/cloud_firestore.dart';

class Exam {
  final String id;
  final String subject;
  final String examType;
  final int score;
  final int totalScore;
  final String userId;
  final DateTime date;

  Exam({
    required this.id,
    required this.subject,
    required this.examType,
    required this.score,
    required this.totalScore,
    required this.userId,
    required this.date,
  });

  double get percentage => (score / totalScore) * 100;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'examType': examType,
      'score': score,
      'totalScore': totalScore,
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'],
      subject: json['subject'],
      examType: json['examType'],
      score: json['score'],
      totalScore: json['totalScore'],
      userId: json['userId'],
      date: json['date'] is Timestamp
          ? (json['date'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(json['date']),
    );
  }

  Exam copyWith({
    String? id,
    String? subject,
    String? examType,
    int? score,
    int? totalScore,
    String? userId,
    DateTime? date,
  }) {
    return Exam(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      examType: examType ?? this.examType,
      score: score ?? this.score,
      totalScore: totalScore ?? this.totalScore,
      userId: userId ?? this.userId,
      date: date ?? this.date,
    );
  }
}
