import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/notice_provider.dart';
import '../models/notice.dart';
import '../utils/constants.dart';

class NoticeDetailScreen extends StatefulWidget {
  final String noticeId;
  final String? fallbackTitle;

  const NoticeDetailScreen({
    Key? key,
    required this.noticeId,
    this.fallbackTitle,
  }) : super(key: key);

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  late Future<Notice?> _noticeFuture;
  late NoticeProvider _noticeProvider;

  @override
  void initState() {
    super.initState();
    _noticeProvider = Provider.of<NoticeProvider>(context, listen: false);
    _noticeFuture = _noticeProvider.getNoticeById(widget.noticeId);
  }

  // 학교 홈페이지 링크 열기
  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) {
      _showErrorDialog('링크를 찾을 수 없습니다.');
      return;
    }

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorDialog('링크를 열 수 없습니다.');
      }
    } catch (e) {
      _showErrorDialog('링크를 여는 중 오류가 발생했습니다.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '공지사항',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Notice?>(
        future: _noticeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '공지사항 세부내용을 불러올 수 없습니다.',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '관리자에게 문의해주세요.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _noticeFuture =
                            _noticeProvider.getNoticeById(widget.noticeId);
                      });
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final notice = snapshot.data;
          if (notice == null) {
            return const Center(
              child: Text(
                '공지사항을 찾을 수 없습니다.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // 공지사항을 읽음 상태로 변경
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<NoticeProvider>(context, listen: false)
                .markAsRead(widget.noticeId);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 중요 공지사항 표시
                if (notice.isImportant)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '중요',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                if (notice.isImportant) const SizedBox(height: 12),

                // New 태그
                if (notice.isNew)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                if (notice.isNew) const SizedBox(height: 12),

                // 제목
                Text(
                  notice.title.trim().isNotEmpty
                      ? notice.title
                      : (widget.fallbackTitle ?? '제목 없음'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // 정보 행
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      notice.author.trim().isNotEmpty
                          ? notice.author
                          : '작성자 미상',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      notice.date.trim().isNotEmpty ? notice.date : '날짜 미상',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 구분선
                Container(
                  height: 1,
                  color: Colors.grey[700],
                ),

                const SizedBox(height: 24),

                // 내용 정리 (summary가 있으면 표시)
                if (notice.summary != null && notice.summary!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[700]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notice.summary!,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 원본 내용
                Text(
                  notice.content,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // 자세히보러가기 텍스트 링크
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => _launchUrl(notice.link),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: Text(
                        '자세히보러가기',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[300],
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 안내 메시지
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[300],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '자세한 내용은 학교 홈페이지에서 확인하실 수 있습니다.',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
