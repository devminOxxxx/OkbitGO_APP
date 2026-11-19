class Grade {
  final String year;
  final String semester;
  final String subject;
  final double score;
  final double average;
  final double standardDeviation;
  final DateTime createdAt;

  Grade({
    required this.year,
    required this.semester,
    required this.subject,
    required this.score,
    required this.average,
    required this.standardDeviation,
    required this.createdAt,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      year: json['year'] as String,
      semester: json['semester'] as String,
      subject: json['subject'] as String,
      score: (json['score'] as num).toDouble(),
      average: (json['average'] as num).toDouble(),
      standardDeviation: (json['standardDeviation'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'semester': semester,
      'subject': subject,
      'score': score,
      'average': average,
      'standardDeviation': standardDeviation,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MockExam {
  final String year;
  final String examName;
  final String subject;
  final double score;
  final double percentile;
  final double standardScore;
  final DateTime createdAt;

  MockExam({
    required this.year,
    required this.examName,
    required this.subject,
    required this.score,
    required this.percentile,
    required this.standardScore,
    required this.createdAt,
  });

  factory MockExam.fromJson(Map<String, dynamic> json) {
    return MockExam(
      year: json['year'] as String,
      examName: json['examName'] as String,
      subject: json['subject'] as String,
      score: (json['score'] as num).toDouble(),
      percentile: (json['percentile'] as num).toDouble(),
      standardScore: (json['standardScore'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'examName': examName,
      'subject': subject,
      'score': score,
      'percentile': percentile,
      'standardScore': standardScore,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
