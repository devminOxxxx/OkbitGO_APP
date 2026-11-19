import 'package:flutter/material.dart';
import '../../../models/timetable.dart';

class TimeTableCaptureWidget extends StatelessWidget {
  final TimeTable timeTable;
  final String currentWeek;

  const TimeTableCaptureWidget({
    Key? key,
    required this.timeTable,
    required this.currentWeek,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A), // 다크 배경
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          _buildHeader(),
          const SizedBox(height: 24),
          // 시간표 그리드
          _buildTimeTableGrid(),
          const SizedBox(height: 16),
          // 점심시간 표시
          _buildLunchTimeIndicator(),
          const SizedBox(height: 24),
          // 하단 여백
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          '${timeTable.grade}학년 ${timeTable.classNum}반',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.keyboard_arrow_left,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              currentWeek,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.keyboard_arrow_right,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeTableGrid() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF404040),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 요일 헤더
          _buildWeekdayHeader(),
          // 시간표 행들
          ...List.generate(
            timeTable.subjects.length,
            (periodIndex) => _buildTimeTableRow(periodIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF3A3A3A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // 빈 공간 (교시 번호 자리)
          Container(
            width: 60,
            height: 50,
            alignment: Alignment.center,
            child: const Text(
              '',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 요일들
          ...List.generate(
            timeTable.weekdays.length,
            (dayIndex) => Expanded(
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    left: dayIndex > 0
                        ? const BorderSide(color: Color(0xFF404040))
                        : BorderSide.none,
                  ),
                ),
                child: Text(
                  timeTable.weekdays[dayIndex],
                  style: TextStyle(
                    color:
                        dayIndex == 2 ? Colors.blue : Colors.white, // 수요일 파란색
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTableRow(int periodIndex) {
    final isLunchTime = periodIndex == 4; // 5교시 전이 점심시간

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(color: Color(0xFF404040)),
        ),
      ),
      child: Row(
        children: [
          // 교시 번호
          Container(
            width: 60,
            height: 70,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              border: Border(
                right: BorderSide(color: Color(0xFF404040)),
              ),
            ),
            child: Text(
              '${periodIndex + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 각 요일별 과목
          ...List.generate(
            timeTable.weekdays.length,
            (dayIndex) => Expanded(
              child: _buildSubjectCell(periodIndex, dayIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCell(int periodIndex, int dayIndex) {
    final fullSubject = periodIndex < timeTable.subjects.length &&
            dayIndex < timeTable.subjects[periodIndex].length
        ? timeTable.subjects[periodIndex][dayIndex]
        : '';

    String subject = '';
    String teacher = '';

    if (fullSubject.isNotEmpty) {
      final parts = fullSubject.split('\n');
      subject = parts[0];
      if (parts.length > 1) {
        teacher = parts[1];
      }
    }

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: dayIndex == 2
            ? const Color(0xFF2A3A4A)
            : const Color(0xFF2A2A2A), // 수요일 배경 다르게
        border: Border(
          left: dayIndex > 0
              ? const BorderSide(color: Color(0xFF404040))
              : BorderSide.none,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (subject.isNotEmpty) ...[
                ..._formatSubjectName(subject).split('\n').map((line) => Text(
                      line,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: _getFontSize(line),
                        height: 1.2,
                      ),
                    )),
              ],
              if (teacher.isNotEmpty)
                Text(
                  teacher,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w400,
                    fontSize: _getFontSize(teacher) - 1,
                    height: 1.1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLunchTimeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF404040),
          width: 1,
        ),
      ),
      child: const Text(
        '점심시간',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  double _getFontSize(String subject) {
    if (subject.isEmpty) return 14.0;

    final length = subject.length;
    if (length <= 2) return 14.0;
    if (length <= 4) return 12.0;
    if (length <= 6) return 10.0;
    return 9.0;
  }

  String _formatSubjectName(String subject) {
    if (subject.isEmpty) return '';

    // 특정 과목명 처리
    switch (subject) {
      case '기술·가정':
        return '기술\n가정';
      case '기술가정':
        return '기술\n가정';
      case '공통영어1':
        return '공통\n영어1';
      case '공통영어':
        return '공통\n영어';
      case '공통수학1':
        return '공통\n수학1';
      case '공통수학':
        return '공통\n수학';
      case '공통국어1':
        return '공통\n국어1';
      case '공통국어':
        return '공통\n국어';
      case '진로활동':
        return '진로\n활동';
      case '통합사회1':
        return '통합\n사회1';
      case '통합사회':
        return '통합\n사회';
      case '통합과학1':
        return '통합\n과학1';
      case '통합과학':
        return '통합\n과학';
      case '과학탐구실험1':
        return '과학\n탐구실험1';
      case '과학탐구실험':
        return '과학\n탐구실험';
      case '동아리활동':
        return '동아리\n활동';
      case '세계문화와미래사회':
        return '세계문화와\n미래사회';
      case '영어독해와작문':
        return '영어독해와\n작문';
      case '사회문제탐구':
        return '사회문제\n탐구';
      case '음악감상과비평':
        return '음악감상과\n비평';
      default:
        // 5글자 이상인 경우 적절히 줄바꿈
        if (subject.length >= 5) {
          if (subject.length <= 6) {
            final mid = (subject.length / 2).ceil();
            return '${subject.substring(0, mid)}\n${subject.substring(mid)}';
          } else {
            // 7글자 이상인 경우 더 세밀하게 처리
            return '${subject.substring(0, 3)}\n${subject.substring(3)}';
          }
        }
        return subject;
    }
  }
}
