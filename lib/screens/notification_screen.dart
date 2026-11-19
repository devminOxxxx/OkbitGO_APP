import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';
import '../widgets/common/custom_text_field.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // 검색 기능 제거
  // final TextEditingController _searchController = TextEditingController();
  // List<NotificationModel> _searchResults = [];
  // bool _isSearching = false;
  Set<String> _selectedNotifications = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    // 기본적으로 모든 알림을 보여주도록 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false)
          .setFilter(NotificationFilter.all);
    });
  }

  @override
  void dispose() {
    // _searchController.dispose();
    super.dispose();
  }

  void _clearSelection() {
    setState(() {
      _selectedNotifications.clear();
      _isSelectionMode = false;
    });
  }

  void _toggleSelection(String notificationId) {
    setState(() {
      if (_selectedNotifications.contains(notificationId)) {
        _selectedNotifications.remove(notificationId);
        if (_selectedNotifications.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNotifications.add(notificationId);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll() {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    setState(() {
      _selectedNotifications = provider.notifications.map((n) => n.id).toSet();
      _isSelectionMode = true;
    });
  }

  // 검색 기능 제거
  /*
  void _onSearch(String query) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    setState(() {
      if (query.isEmpty) {
        _isSearching = false;
        _searchResults.clear();
      } else {
        _isSearching = true;
        _searchResults = provider.searchNotifications(query);
      }
    });
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Text(
          _isSelectionMode ? '${_selectedNotifications.length}개 선택됨' : '알림',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: !_isSelectionMode,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _clearSelection,
              )
            : null,
        actions: _isSelectionMode
            ? [
                // 선택 모드에서는 삭제만 가능
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: _handleBatchAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('삭제하기', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : [
                // 일반 모드에서는 새로고침만 가능
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () async {
                    await Provider.of<NotificationProvider>(context,
                            listen: false)
                        .loadNotifications();
                  },
                ),
              ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          // 검색 기능 제거로 항상 모든 알림 표시
          final notifications = provider.notifications;

          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadNotifications();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '알림이 없습니다',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final isSelected = _selectedNotifications.contains(notification.id);
    final isAdminNotification = notification.type == 'admin_announcement' ||
        notification.type == 'admin_class_announcement';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue.withValues(alpha: 0.1)
            : notification.isRead
                ? kSurfaceColor.withValues(alpha: 0.7) // 읽은 알림은 어두운 색
                : kSurfaceColor, // 읽지 않은 알림은 밝은 색
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(notification.id);
          } else {
            _openNotificationDetail(notification);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelection(notification.id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 관리자 공지인 경우 OKBIT 로고, 아닌 경우 기본 아이콘
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isAdminNotification
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/okbit_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.blue,
                              child: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: _getNotificationColor(notification.type),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 보내는 부서 표시
                        if (notification.metadata?['department'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.metadata!['department'],
                              style: TextStyle(
                                color: Colors.orange[400],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        // 읽지 않은 알림 표시 제거 (배경색으로 대체)
                        const Spacer(),
                        // 시간 표시
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 파일 첨부 표시
                    if (notification.metadata?['hasFile'] == true) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '첨부파일',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotificationDetail(NotificationModel notification) {
    // 알림을 읽음으로 표시
    if (!notification.isRead) {
      Provider.of<NotificationProvider>(context, listen: false)
          .markAsRead(notification.id);
    }

    // 별도 화면으로 알림 상세보기 열기
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NotificationDetailScreen(notification: notification),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'admin_announcement':
      case 'admin_class_announcement':
        return Colors.blue;
      case 'emergency':
        return Colors.red;
      case 'notice':
        return Colors.green;
      case 'grade':
        return Colors.purple;
      case 'schedule':
        return Colors.orange;
      case 'meal':
        return Colors.teal;
      case 'event':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'admin_announcement':
      case 'admin_class_announcement':
        return Icons.campaign;
      case 'emergency':
        return Icons.warning;
      case 'notice':
        return Icons.info;
      case 'grade':
        return Icons.grade;
      case 'schedule':
        return Icons.schedule;
      case 'meal':
        return Icons.restaurant;
      case 'event':
        return Icons.event;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  void _handleBatchAction(String action) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    switch (action) {
      case 'delete':
        for (String id in _selectedNotifications) {
          await provider.deleteNotification(id);
        }
        break;
    }

    _clearSelection();
  }

  // 검색 기능 제거
  /*
  void _handleMenuAction(String action) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    switch (action) {
      case 'refresh':
        await provider.loadNotifications();
        break;
      case 'mark_all_read':
        await provider.markAllAsRead();
        break;
      case 'cleanup':
        await provider.cleanupExpiredNotifications();
        break;
      case 'settings':
        Navigator.pushNamed(context, '/notification-settings');
        break;
      case 'stats':
        _showStatsDialog();
        break;
    }
  }
  */

  // 검색 기능 제거
  /*
  void _showStatsDialog() {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text(
          '알림 통계',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatItem('전체 알림', provider.totalCount),
            _buildStatItem('읽지 않은 알림', provider.unreadCount),
            _buildStatItem('읽은 알림', provider.readCount),
            _buildStatItem('보관된 알림', provider.archivedCount),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
  */

  // 검색 기능 제거
  /*
  Widget _buildStatItem(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  */
}

// 알림 상세 화면
class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({Key? key, required this.notification})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAdminNotification = notification.type == 'admin_announcement' ||
        notification.type == 'admin_class_announcement';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          '알림 상세',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => _handleAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('삭제하기', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 정보
            Row(
              children: [
                // 관리자 공지인 경우 OKBIT 로고, 아닌 경우 기본 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isAdminNotification
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/okbit_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.blue,
                                child: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 보내는 부서
                      if (notification.metadata?['department'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notification.metadata!['department'],
                            style: TextStyle(
                              color: Colors.orange[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDateTime(notification.createdAt),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 제목
            Text(
              notification.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 내용
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notification.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),

            // 파일 첨부
            if (notification.metadata?['hasFile'] == true) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '첨부파일',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.metadata?['fileName'] ??
                                'attachment.pdf',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _downloadFile(context, notification),
                      icon: const Icon(
                        Icons.download,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _downloadFile(BuildContext context, NotificationModel notification) {
    final fileName = notification.metadata?['fileName'] ?? 'attachment.pdf';
    final fileUrl = notification.metadata?['fileUrl'];

    if (fileUrl != null) {
      // 실제 파일 URL이 있는 경우 다운로드
      _launchUrl(fileUrl);
    } else {
      // 파일 URL이 없는 경우 더미 동작
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$fileName 파일을 다운로드하는 중...'),
          backgroundColor: Colors.blue,
        ),
      );

      // 실제 구현에서는 Firebase Storage나 서버에서 파일을 다운로드
      Future.delayed(const Duration(seconds: 2), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileName 파일이 다운로드 폴더에 저장되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'admin_announcement':
      case 'admin_class_announcement':
        return Colors.blue;
      case 'emergency':
        return Colors.red;
      case 'notice':
        return Colors.green;
      case 'grade':
        return Colors.purple;
      case 'schedule':
        return Colors.orange;
      case 'meal':
        return Colors.teal;
      case 'event':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'admin_announcement':
      case 'admin_class_announcement':
        return Icons.campaign;
      case 'emergency':
        return Icons.warning;
      case 'notice':
        return Icons.info;
      case 'grade':
        return Icons.grade;
      case 'schedule':
        return Icons.schedule;
      case 'meal':
        return Icons.restaurant;
      case 'event':
        return Icons.event;
      default:
        return Icons.notifications;
    }
  }

  void _handleAction(BuildContext context, String action) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    switch (action) {
      case 'delete':
        await provider.deleteNotification(notification.id);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림이 삭제되었습니다.')),
        );
        break;
    }
  }
}
