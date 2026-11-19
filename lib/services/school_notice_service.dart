import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../models/notice.dart';
import '../utils/logger_util.dart';
import '../utils/constants.dart';

class SchoolNoticeService {
  static const String _baseUrl = kSchoolBaseUrl;

  // 각 카테고리별 URL
  static const Map<NoticeCategory, String> _categoryUrls = {
    NoticeCategory.notice:
        '$_baseUrl/okbit-h/na/ntt/selectNttList.do?mi=6426&bbsId=3663',
    NoticeCategory.newsletter:
        '$_baseUrl/okbit-h/na/ntt/selectNttList.do?mi=6428&bbsId=3665',
    NoticeCategory.educationNewsletter:
        '$_baseUrl/okbit-h/na/ntt/selectNttList.do?mi=11783&bbsId=11061',
  };

  // 모든 카테고리의 공지사항 가져오기
  Future<List<Notice>> fetchAllNotices() async {
    List<Notice> allNotices = [];

    for (final category in NoticeCategory.values) {
      try {
        final categoryNotices = await fetchNoticesByCategory(category);
        allNotices.addAll(categoryNotices);
      } catch (e) {
        LoggerUtil.error('${category.displayName} 크롤링 오류: $e');
      }
    }

    // 날짜순으로 정렬 (최신순)
    allNotices.sort((a, b) => b.date.compareTo(a.date));

    return allNotices;
  }

  // 특정 카테고리의 공지사항 가져오기
  Future<List<Notice>> fetchNoticesByCategory(NoticeCategory category) async {
    final url = _categoryUrls[category];
    if (url == null) return [];

    try {
      LoggerUtil.info('${category.displayName} 크롤링 시작');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        final document = html.parse(response.body);
        final notices = <Notice>[];

        try {
          // 테이블 기반 게시판 구조 (일반적인 학교 홈페이지)
          final rows = document.querySelectorAll('tr');
          for (final row in rows) {
            try {
              final cells = row.querySelectorAll('td');
              if (cells.length >= 4) {
                // 번호, 제목, 작성자, 날짜 구조
                final numberCell = cells[0];
                final titleCell = cells[1];
                final authorCell = cells[2];
                final dateCell = cells[3];

                final number = numberCell.text.trim();
                final titleElement = titleCell.querySelector('a') ?? titleCell;
                final title = titleElement.text.trim();
                final author = authorCell.text.trim();
                final date = dateCell.text.trim();

                // 링크 처리
                var link = '';
                if (titleCell.querySelector('a') != null) {
                  link = titleCell.querySelector('a')!.attributes['href'] ?? '';
                }

                // JavaScript 링크나 잘못된 링크 처리
                if (link.startsWith('javascript:') ||
                    link.contains('javascript')) {
                  // JavaScript 링크인 경우 onclick에서 실제 링크 추출 시도
                  final onclickAttr = titleElement.attributes['onclick'] ?? '';
                  final linkMatch =
                      RegExp(r"'([^']*)'").firstMatch(onclickAttr);
                  if (linkMatch != null) {
                    link = linkMatch.group(1) ?? '';
                  } else {
                    link = ''; // JavaScript 링크는 처리하지 않음
                  }
                }

                // 상대 경로 처리
                String? fullLink;
                if (link.isNotEmpty) {
                  if (link.startsWith('http')) {
                    fullLink = link;
                  } else if (link.startsWith('/')) {
                    fullLink = '$_baseUrl$link';
                  } else if (link.startsWith('./') || link.startsWith('../')) {
                    fullLink = '$_baseUrl/okbit-h/na/ntt/$link';
                  } else if (link.isNotEmpty) {
                    fullLink = '$_baseUrl/okbit-h/na/ntt/$link';
                  }
                }

                if (number.isNotEmpty &&
                    title.isNotEmpty &&
                    !title.contains('제목') &&
                    !title.contains('번호') &&
                    RegExp(r'^\d+$').hasMatch(number)) {
                  // 제목을 기반으로 한 간단한 요약 생성
                  String summary = _generateSummary(title, category);
                  String content = '📋 $summary';

                  final notice = Notice(
                    id: '${category.name}_$number',
                    title: title,
                    content: content,
                    date: _formatDate(date),
                    author: author.isNotEmpty ? author : '학교',
                    isImportant: title.contains('[중요]') || title.contains('긴급'),
                    link: fullLink ?? url, // 링크가 없으면 기본 URL 사용
                    category: category,
                  );

                  notices.add(notice);
                }
              }
            } catch (e) {
              LoggerUtil.error('공지사항 파싱 오류: $e');
            }
          }

          LoggerUtil.info('${category.displayName} ${notices.length}개 가져오기 완료');
          return notices;
        } catch (e) {
          LoggerUtil.error('공지사항 파싱 전체 오류: $e');
          return [];
        }
      } else {
        LoggerUtil.error(
            '${category.displayName} 접근 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      LoggerUtil.error('${category.displayName} 크롤링 오류: $e');
      return [];
    }
  }

  // 레거시 메서드 (기존 코드 호환성을 위해 유지)
  Future<List<Notice>> fetchNotices() async {
    return await fetchAllNotices();
  }

  // 공지사항 상세 내용 가져오기
  Future<Notice?> getNoticeDetail(String noticeId, String? link) async {
    try {
      LoggerUtil.info('공지사항 상세 내용 가져오기: $noticeId');

      if (link == null || link.isEmpty) {
        return null;
      }

      final response = await http.get(
        Uri.parse(link),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        final document = html.parse(response.body);

        // 다양한 게시판 상세 구조에 대응
        String content = '';
        String title = '';
        String author = '';
        String date = '';

        // 제목 추출
        final titleSelectors = [
          '.view-title',
          '.board-title',
          '.subject',
          'h1',
          '.title',
          '.ntt-title',
          '.post-title'
        ];

        for (final selector in titleSelectors) {
          final element = document.querySelector(selector);
          if (element != null && element.text.trim().isNotEmpty) {
            title = element.text.trim();
            break;
          }
        }

        // 내용 추출 - 더 많은 셀렉터 추가
        final contentSelectors = [
          '.view-content',
          '.board-content',
          '.content',
          '.view-body',
          '.board-body',
          '.ntt-content',
          '.post-content',
          '.article-content',
          '.board-view-content',
          '.text-content'
        ];

        for (final selector in contentSelectors) {
          final element = document.querySelector(selector);
          if (element != null && element.text.trim().isNotEmpty) {
            content = element.text.trim();
            break;
          }
        }

        // 작성자 추출
        final authorSelectors = [
          '.view-writer',
          '.author',
          '.writer',
          '.reg-name',
          '.ntt-writer'
        ];

        for (final selector in authorSelectors) {
          final element = document.querySelector(selector);
          if (element != null && element.text.trim().isNotEmpty) {
            author = element.text.trim();
            break;
          }
        }

        // 날짜 추출
        final dateSelectors = [
          '.view-date',
          '.reg-date',
          '.date',
          '.board-date',
          '.ntt-date'
        ];

        for (final selector in dateSelectors) {
          final element = document.querySelector(selector);
          if (element != null && element.text.trim().isNotEmpty) {
            date = element.text.trim();
            break;
          }
        }

        // HTML 태그 제거 및 텍스트 정리
        content = content.replaceAll(RegExp(r'<[^>]*>'), '');
        content = content.replaceAll(RegExp(r'\s+'), ' ');
        content = content.trim();

        // 내용이 여전히 비어있으면 기본 메시지 설정
        if (content.isEmpty) {
          content = '자세한 내용은 학교 홈페이지를 확인해주세요.';
        }

        final notice = Notice(
          id: noticeId,
          title: title, // 빈 문자열이어도 그대로 반환 (fallback은 NoticeProvider에서 처리)
          content: content,
          date: _formatDate(date), // 빈 문자열이어도 그대로 반환
          author: author, // 빈 문자열이어도 그대로 반환 (fallback은 NoticeProvider에서 처리)
          isImportant: title.contains('[중요]') || title.contains('긴급'),
          link: link,
        );

        LoggerUtil.info('공지사항 상세 내용 로딩 완료');
        return notice;
      } else {
        LoggerUtil.error('공지사항 상세 페이지 접근 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      LoggerUtil.error('공지사항 상세 내용 가져오기 오류: $e');
      return null;
    }
  }

  // 제목과 카테고리를 기반으로 한 간단한 요약 생성
  String _generateSummary(String title, NoticeCategory category) {
    // 카테고리별 기본 설명
    String categoryDesc = '';
    switch (category) {
      case NoticeCategory.notice:
        categoryDesc = '학교 공지사항';
        break;
      case NoticeCategory.newsletter:
        categoryDesc = '가정통신문';
        break;
      case NoticeCategory.educationNewsletter:
        categoryDesc = '교육청 가정통신문';
        break;
    }

    // 공지사항 유형별 스마트 요약
    if (title.contains('입학') || title.contains('신입생')) {
      return '신입생 및 입학 관련 $categoryDesc입니다.';
    } else if (title.contains('수업') ||
        title.contains('교과') ||
        title.contains('시간표')) {
      return '수업 및 교육과정 관련 $categoryDesc입니다.';
    } else if (title.contains('시험') ||
        title.contains('평가') ||
        title.contains('고사')) {
      return '시험 및 평가 관련 $categoryDesc입니다.';
    } else if (title.contains('행사') ||
        title.contains('대회') ||
        title.contains('축제')) {
      return '학교 행사 및 대회 관련 $categoryDesc입니다.';
    } else if (title.contains('방학') ||
        title.contains('휴업') ||
        title.contains('개학')) {
      return '방학 및 학사일정 관련 $categoryDesc입니다.';
    } else if (title.contains('급식') || title.contains('식단')) {
      return '급식 및 식단 관련 $categoryDesc입니다.';
    } else if (title.contains('건강') ||
        title.contains('보건') ||
        title.contains('안전')) {
      return '학생 건강 및 안전 관련 $categoryDesc입니다.';
    } else if (title.contains('진로') ||
        title.contains('상담') ||
        title.contains('진학')) {
      return '진로 및 진학 관련 $categoryDesc입니다.';
    } else if (title.contains('모집') ||
        title.contains('신청') ||
        title.contains('접수')) {
      return '모집 및 신청 관련 $categoryDesc입니다.';
    } else if (title.contains('변경') ||
        title.contains('수정') ||
        title.contains('알림')) {
      return '중요 변경사항 및 알림 $categoryDesc입니다.';
    } else {
      // 기본 요약: 제목이 길면 줄이고, 짧으면 그대로
      if (title.length > 25) {
        return '${title.substring(0, 25)}...';
      }
      return title;
    }
  }

  // 날짜 문자열을 DateTime으로 파싱 후 포맷팅
  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return DateTime.now().toString().split(' ')[0];

      // 다양한 날짜 형식 지원
      final patterns = [
        RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
        RegExp(r'(\d{4})\.(\d{2})\.(\d{2})'),
        RegExp(r'(\d{4})/(\d{2})/(\d{2})'),
        RegExp(r'(\d{2})-(\d{2})-(\d{2})'),
        RegExp(r'(\d{2})\.(\d{2})\.(\d{2})'),
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(dateString);
        if (match != null) {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);

          // 2자리 연도는 20XX로 변환
          final fullYear = year < 100 ? 2000 + year : year;

          return DateTime(fullYear, month, day).toString().split(' ')[0];
        }
      }

      // 패턴이 맞지 않으면 원본 반환
      return dateString;
    } catch (e) {
      return DateTime.now().toString().split(' ')[0];
    }
  }
}
