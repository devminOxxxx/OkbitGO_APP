import 'package:flutter/foundation.dart';
import '../models/notice.dart';
import '../services/school_notice_service.dart';
import '../utils/logger_util.dart';

class NoticeProvider with ChangeNotifier {
  final SchoolNoticeService _noticeService = SchoolNoticeService();

  List<Notice> _notices = [];
  bool _isLoading = false;
  String? _error;
  NoticeCategory _selectedCategory = NoticeCategory.notice;

  // 이전 공지사항 개수 추적
  int _previousNoticeCount = 0;

  List<Notice> get notices => _notices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  NoticeCategory get selectedCategory => _selectedCategory;

  Notice? get latestNotice => _notices.isNotEmpty ? _notices.first : null;

  // 카테고리별 공지사항 필터링
  List<Notice> get filteredNotices {
    return _notices
        .where((notice) => notice.category == _selectedCategory)
        .toList();
  }

  // 카테고리별 공지사항 개수
  int getNoticeCountByCategory(NoticeCategory category) {
    return _notices.where((notice) => notice.category == category).length;
  }

  // 새로운 공지사항 개수 (3일 이내)
  int get newNoticeCount {
    return _notices.where((notice) => notice.isNew).length;
  }

  // 카테고리별 새로운 공지사항 개수
  int getNewNoticeCountByCategory(NoticeCategory category) {
    return _notices
        .where((notice) => notice.category == category && notice.isNew)
        .length;
  }

  NoticeProvider() {
    fetchNotices();
  }

  // 카테고리 선택
  void selectCategory(NoticeCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // 공지사항 가져오기
  Future<void> fetchNotices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      LoggerUtil.info('공지사항 가져오기 시작');

      // 모든 카테고리의 공지사항 가져오기
      List<Notice> notices = await _noticeService.fetchAllNotices();

      if (notices.isEmpty) {
        // 크롤링 실패 시 샘플 데이터 표시
        LoggerUtil.warning('학교 공지사항 크롤링 실패, 샘플 데이터 표시');
        _error = '학교 홈페이지에 접속할 수 없습니다';
        notices = _getSampleNotices();
      }

      // 새로운 공지사항이 있는지 확인하고 알림 생성
      if (_notices.isNotEmpty && notices.length > _previousNoticeCount) {
        final newNotices =
            notices.take(notices.length - _previousNoticeCount).toList();
        _createNoticeNotifications(newNotices);
      }

      _notices = notices;
      _previousNoticeCount = notices.length;
      LoggerUtil.info('공지사항 ${_notices.length}개 로딩 완료');
    } catch (e) {
      LoggerUtil.error('공지사항 가져오기 오류: $e');
      _error = '공지사항을 불러오는 중 오류가 발생했습니다';
      _notices = _getSampleNotices();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 새로운 공지사항에 대한 알림 생성
  void _createNoticeNotifications(List<Notice> newNotices) {
    for (final notice in newNotices) {
      // 알림 생성 로직을 여기서 구현
      // 실제로는 NotificationProvider를 통해 알림을 생성해야 함
      LoggerUtil.info('새로운 공지사항 알림 생성: ${notice.title}');
    }
  }

  // 특정 카테고리의 공지사항만 가져오기
  Future<void> fetchNoticesByCategory(NoticeCategory category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      LoggerUtil.info('${category.displayName} 가져오기 시작');

      List<Notice> notices =
          await _noticeService.fetchNoticesByCategory(category);

      if (notices.isEmpty) {
        LoggerUtil.warning('${category.displayName} 크롤링 실패');
        _error = '${category.displayName}을 불러올 수 없습니다';
      } else {
        // 기존 공지사항에서 해당 카테고리만 교체
        _notices.removeWhere((notice) => notice.category == category);
        _notices.addAll(notices);
        _notices.sort((a, b) => b.date.compareTo(a.date));
      }

      LoggerUtil.info('${category.displayName} ${notices.length}개 로딩 완료');
    } catch (e) {
      LoggerUtil.error('${category.displayName} 가져오기 오류: $e');
      _error = '${category.displayName}을 불러오는 중 오류가 발생했습니다';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 특정 공지사항 가져오기
  Future<Notice?> getNoticeById(String id) async {
    try {
      // 먼저 목록에서 찾기
      final existingNotice = _notices.firstWhere(
        (notice) => notice.id == id,
        orElse: () => Notice(
          id: '',
          title: '',
          content: '',
          date: '',
          author: '',
        ),
      );

      if (existingNotice.id.isNotEmpty) {
        // 항상 학교 홈페이지에서 세부내용 가져오기
        if (existingNotice.link != null && existingNotice.link!.isNotEmpty) {
          LoggerUtil.info('공지사항 세부내용 가져오기 시작: ${existingNotice.title}');
          final detailNotice =
              await _noticeService.getNoticeDetail(id, existingNotice.link);
          if (detailNotice != null) {
            LoggerUtil.info('공지사항 세부내용 가져오기 완료');
            // title이 비어있으면 목록의 title을 사용
            if (detailNotice.title.trim().isEmpty) {
              return Notice(
                id: detailNotice.id,
                title: existingNotice.title,
                content: detailNotice.content,
                date: detailNotice.date.trim().isNotEmpty
                    ? detailNotice.date
                    : existingNotice.date,
                author: detailNotice.author.trim().isNotEmpty
                    ? detailNotice.author
                    : existingNotice.author,
                isImportant: detailNotice.isImportant,
                isRead: detailNotice.isRead,
                category: detailNotice.category,
                link: detailNotice.link,
                summary: detailNotice.summary,
              );
            }
            // title이 정상이어도 date나 author가 비어있을 수 있으므로 fallback 처리
            return Notice(
              id: detailNotice.id,
              title: detailNotice.title,
              content: detailNotice.content,
              date: detailNotice.date.trim().isNotEmpty
                  ? detailNotice.date
                  : existingNotice.date,
              author: detailNotice.author.trim().isNotEmpty
                  ? detailNotice.author
                  : existingNotice.author,
              isImportant: detailNotice.isImportant,
              isRead: detailNotice.isRead,
              category: detailNotice.category,
              link: detailNotice.link,
              summary: detailNotice.summary,
            );
          }
        }
        return existingNotice;
      }

      return null;
    } catch (e) {
      LoggerUtil.error('공지사항 가져오기 오류: $e');
      return null;
    }
  }

  // 특정 공지사항을 읽음 상태로 변경
  void markAsRead(String id) {
    final index = _notices.indexWhere((notice) => notice.id == id);
    if (index != -1) {
      _notices[index].isRead = true;
      notifyListeners();
    }
  }

  // 샘플 데이터 (크롤링 실패 시 사용)
  List<Notice> _getSampleNotices() {
    return [
      Notice(
        id: 'sample_1',
        title: '공지사항 불러오기 안내',
        content: '학교 공지사항 및 중요 안내사항을 확인하실 수 있습니다.',
        date: DateTime.now().toString().split(' ')[0],
        author: '시스템',
        isImportant: true,
        category: NoticeCategory.notice,
        summary: '학교 공지사항 및 중요 안내사항을 확인하실 수 있습니다.',
      ),
    ];
  }
}
