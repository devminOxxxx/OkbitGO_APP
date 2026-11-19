import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../models/event.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<Event> events;
  final Function(DateTime) onDaySelected;

  const CalendarGrid({
    Key? key,
    required this.focusedDay,
    required this.selectedDay,
    required this.events,
    required this.onDaySelected,
  }) : super(key: key);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return events.where((event) {
      final eventStart =
          DateTime(event.start.year, event.start.month, event.start.day);
      final eventEnd = DateTime(event.end.year, event.end.month, event.end.day);

      // 이벤트 시작일부터 종료일까지의 모든 날짜에 이벤트 표시
      return (normalizedDay.isAtSameMomentAs(eventStart) ||
              normalizedDay.isAfter(eventStart)) &&
          (normalizedDay.isAtSameMomentAs(eventEnd) ||
              normalizedDay.isBefore(eventEnd));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0).day;
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final prevMonthDays = (firstWeekday == 7 ? 0 : firstWeekday);
    final totalDays = prevMonthDays + daysInMonth;
    final totalWeeks = ((totalDays + 6) ~/ 7);
    const cellHeight = 100.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: kBorderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(totalWeeks, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final index = weekIndex * 7 + dayIndex;
              final dayNumber = index - prevMonthDays + 1;

              if (index < prevMonthDays || dayNumber > daysInMonth) {
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: dayIndex < 6
                            ? const BorderSide(color: kBorderColor)
                            : BorderSide.none,
                        bottom: weekIndex < totalWeeks - 1
                            ? const BorderSide(color: kBorderColor)
                            : BorderSide.none,
                      ),
                    ),
                    height: cellHeight,
                  ),
                );
              }

              final date = DateTime(
                focusedDay.year,
                focusedDay.month,
                dayNumber,
              );
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = _isSameDay(date, selectedDay);
              final dayEvents = _getEventsForDay(date);
              final hasEvents = dayEvents.isNotEmpty;

              Color textColor;
              if (dayIndex == 0) {
                textColor = Colors.red[300]!;
              } else if (dayIndex == 6) {
                textColor = Colors.blue[300]!;
              } else {
                textColor = Colors.white;
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDaySelected(date),
                  child: Container(
                    height: cellHeight,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue[400]!.withValues(alpha: 0.15)
                          : Colors.transparent,
                      border: Border(
                        right: dayIndex < 6
                            ? const BorderSide(color: kBorderColor)
                            : BorderSide.none,
                        bottom: weekIndex < totalWeeks - 1
                            ? const BorderSide(color: kBorderColor)
                            : BorderSide.none,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isToday ? Colors.blue : Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                dayNumber.toString(),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: (isToday || isSelected)
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (hasEvents)
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              itemCount:
                                  dayEvents.length > 3 ? 3 : dayEvents.length,
                              itemBuilder: (context, index) {
                                final event = dayEvents[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: event.color.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                        if (hasEvents && dayEvents.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 2),
                            child: Text(
                              '+${dayEvents.length - 3}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}
