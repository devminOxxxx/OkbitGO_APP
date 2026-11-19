class Notice {
  final String id;
  final String title;
  final String content;
  final String date;
  final String author;
  final List<String> attachments;
  final bool isImportant;
  final String? link;
  final NoticeCategory category;
  bool isRead;
  final String? summary; // 간단한 내용 정리

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.author,
    this.attachments = const [],
    this.isImportant = false,
    this.link,
    this.category = NoticeCategory.notice,
    this.isRead = false,
    this.summary,
  });

  // 새로운 공지인지 확인 (3일 이내)
  bool get isNew {
    try {
      final noticeDate = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(noticeDate).inDays;
      return difference <= 3;
    } catch (e) {
      return false;
    }
  }

  factory Notice.fromMap(Map<String, dynamic> map) {
    return Notice(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: map['date'] ?? '',
      author: map['author'] ?? '',
      attachments: List<String>.from(map['attachments'] ?? []),
      isImportant: map['isImportant'] ?? false,
      link: map['link'],
      category: NoticeCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => NoticeCategory.notice,
      ),
      isRead: map['isRead'] ?? false,
      summary: map['summary'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'author': author,
      'attachments': attachments,
      'isImportant': isImportant,
      'link': link,
      'category': category.name,
      'isRead': isRead,
      'summary': summary,
    };
  }

  Notice copyWith({
    String? id,
    String? title,
    String? content,
    String? date,
    String? author,
    List<String>? attachments,
    bool? isImportant,
    String? link,
    bool? isRead,
    String? summary,
  }) {
    return Notice(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      author: author ?? this.author,
      attachments: attachments ?? this.attachments,
      isImportant: isImportant ?? this.isImportant,
      link: link ?? this.link,
      isRead: isRead ?? this.isRead,
      summary: summary ?? this.summary,
    );
  }
}

enum NoticeCategory {
  notice('공지사항'),
  newsletter('가정통신문'),
  educationNewsletter('가정통신문(교육청)');

  const NoticeCategory(this.displayName);
  final String displayName;
}
