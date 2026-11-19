import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../models/event.dart';
import '../../screens/event_form_screen.dart';
import '../../utils/enums.dart';

class CalendarPreview extends StatelessWidget {
  const CalendarPreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final today = DateTime.now();
    final upcomingEvents = _getUpcomingEvents(eventProvider.events, today);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          final navigationProvider =
              Provider.of<NavigationProvider>(context, listen: false);
          navigationProvider.goToTab(
            context,
            NavigationTab.schoolLife,
            initialTabIndex: 2, // 캘린더 탭으로 이동
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '캘린더',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
                ],
              ),
              const SizedBox(height: 16),
              upcomingEvents.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          '다가오는 일정이 없습니다',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: upcomingEvents.map((event) {
                        return _buildEventItem(context, event);
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  List<Event> _getUpcomingEvents(List<Event> allEvents, DateTime today) {
    // 오늘 이후의 이벤트만 필터링
    final filteredEvents = allEvents.where((event) {
      return event.start.isAfter(today) ||
          (event.start.day == today.day &&
              event.start.month == today.month &&
              event.start.year == today.year);
    }).toList();

    // 시작 날짜 기준으로 정렬
    filteredEvents.sort((a, b) => a.start.compareTo(b.start));

    // 최대 3개만 반환
    return filteredEvents.take(3).toList();
  }

  String _getNotificationText(NotificationTime? notificationTime) {
    if (notificationTime == null || notificationTime == NotificationTime.none) {
      return '';
    }

    switch (notificationTime) {
      case NotificationTime.fiveMin:
        return '5분 전 알림';
      case NotificationTime.tenMin:
        return '10분 전 알림';
      case NotificationTime.fifteenMin:
        return '15분 전 알림';
      case NotificationTime.thirtyMin:
        return '30분 전 알림';
      case NotificationTime.oneHour:
        return '1시간 전 알림';
      case NotificationTime.sixHours:
        return '6시간 전 알림';
      default:
        return '';
    }
  }

  Widget _buildEventItem(BuildContext context, Event event) {
    final dateFormat = DateFormat('M월 d일');
    final timeFormat = DateFormat('HH:mm');
    final notificationText = _getNotificationText(event.notificationTime);
    final hasNotification =
        event.hasNotification && notificationText.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventFormScreen(
              event: event,
              initialDate: event.start,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: event.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: event.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${dateFormat.format(event.start)} ${timeFormat.format(event.start)} - ${event.start.day != event.end.day ? '${dateFormat.format(event.end)} ' : ''}${timeFormat.format(event.end)}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.description!,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (hasNotification) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          size: 12,
                          color: Colors.blue[300],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notificationText,
                          style: TextStyle(
                            color: Colors.blue[300],
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
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
    );
  }
}
