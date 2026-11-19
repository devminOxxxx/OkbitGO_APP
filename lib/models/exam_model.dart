class ExamScore {
  final String exam;
  final String subject;
  final int score;
  final int totalScore;
  final DateTime createdAt;

  ExamScore({
    required this.exam,
    required this.subject,
    required this.score,
    required this.totalScore,
    required this.createdAt,
  });

  factory ExamScore.fromJson(Map<String, dynamic> json) {
    return ExamScore(
      exam: json['exam'] as String,
      subject: json['subject'] as String,
      score: json['score'] as int,
      totalScore: json['totalScore'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exam': exam,
      'subject': subject,
      'score': score,
      'totalScore': totalScore,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ExamGradeCutoff {
  final String exam;
  final String subject;
  final Map<int, int> cutoffs; // 등급별 점수 컷
  final int participantCount;
  final DateTime updatedAt;

  ExamGradeCutoff({
    required this.exam,
    required this.subject,
    required this.cutoffs,
    required this.participantCount,
    required this.updatedAt,
  });

  factory ExamGradeCutoff.fromJson(Map<String, dynamic> json) {
    final cutoffsMap = json['cutoffs'] as Map<String, dynamic>;
    final cutoffs = cutoffsMap.map(
      (key, value) => MapEntry(int.parse(key), value as int),
    );

    return ExamGradeCutoff(
      exam: json['exam'] as String,
      subject: json['subject'] as String,
      cutoffs: cutoffs,
      participantCount: json['participantCount'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final cutoffsMap = cutoffs.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    return {
      'exam': exam,
      'subject': subject,
      'cutoffs': cutoffsMap,
      'participantCount': participantCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
