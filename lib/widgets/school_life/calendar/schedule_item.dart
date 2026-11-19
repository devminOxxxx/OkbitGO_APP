import 'package:flutter/material.dart';
import '../../../utils/enums.dart';

class ScheduleItem extends StatelessWidget {
  final String description;
  final String title;
  final bool isToday;
  final Color color;
  final String startTime;
  final String endTime;
  final NotificationTime? notificationTime;

  const ScheduleItem({
    Key? key,
    required this.description,
    required this.title,
    required this.isToday,
    this.color = Colors.blue,
    this.startTime = '',
    this.endTime = '',
    this.notificationTime,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final notificationText = _getNotificationText(notificationTime);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (startTime.isNotEmpty && endTime.isNotEmpty)
                      Text(
                        '$startTime - $endTime',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notificationText.isNotEmpty) ...[
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
    );
  }
}
