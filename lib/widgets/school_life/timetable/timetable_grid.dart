import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../models/timetable.dart';

typedef SubjectTapCallback = void Function(int periodIndex, int dayIndex,
    String currentSubject, String currentTeacher);

class TimeTableGrid extends StatelessWidget {
  final TimeTable timeTable;
  final SubjectTapCallback? onSubjectTap;
  final GlobalKey? screenshotKey;

  const TimeTableGrid({
    Key? key,
    required this.timeTable,
    this.onSubjectTap,
    this.screenshotKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: screenshotKey,
      child: Container(
        color: kSurfaceColor,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  timeTable.periods.length,
                  (periodIndex) => SizedBox(
                    height: kTimetableCellHeight,
                    width: MediaQuery.of(context).size.width,
                    child: _buildRow(context, periodIndex),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: kTimetableHeaderHeight,
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(
        color: kBorderColor,
        border: Border(
            bottom: BorderSide(color: kBorderColor, width: kBorderWidthThick)),
      ),
      child: Row(
        children: [
          Container(
            width: kTimetableTimeWidth,
            alignment: Alignment.center,
            child: const Text(
              '교시',
              style: TextStyle(
                color: kTextColor,
                fontSize: kFontSizeXLarge,
                fontWeight: kFontWeightSemiBold,
                fontFamily: kDefaultFontFamily,
              ),
            ),
          ),
          ...List.generate(
            timeTable.weekdays.length,
            (dayIndex) => Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: kBorderColor),
                  ),
                ),
                child: Text(
                  timeTable.weekdays[dayIndex],
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: kFontSizeXLarge,
                    fontWeight: kFontWeightSemiBold,
                    fontFamily: kDefaultFontFamily,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, int periodIndex) {
    return Row(
      children: [
        // 교시 번호
        Container(
          width: kTimetableTimeWidth,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kBorderColor,
            border: Border(
              bottom: periodIndex < timeTable.periods.length - 1
                  ? const BorderSide(color: kBorderColor)
                  : BorderSide.none,
            ),
          ),
          child: Text(
            timeTable.periods[periodIndex],
            style: const TextStyle(
              color: kTextColor,
              fontSize: kFontSizeRegular,
              fontWeight: kFontWeightSemiBold,
              fontFamily: kDefaultFontFamily,
            ),
          ),
        ),

        // 각 요일별 과목
        ...List.generate(
          timeTable.weekdays.length,
          (dayIndex) => Expanded(
            child: _buildSubjectCell(
              context,
              periodIndex,
              dayIndex,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCell(
      BuildContext context, int periodIndex, int dayIndex) {
    final fullSubject = periodIndex < timeTable.subjects.length &&
            dayIndex < timeTable.subjects[periodIndex].length
        ? timeTable.subjects[periodIndex][dayIndex]
        : '';

    // 과목명과 교사명 분리
    String subject = '';
    String teacher = '';

    if (fullSubject.isNotEmpty) {
      final parts = fullSubject.split('\n');
      subject = parts[0];
      if (parts.length > 1) {
        teacher = parts[1];
      }
    }

    return InkWell(
      onTap: onSubjectTap != null
          ? () {
              onSubjectTap!(periodIndex, dayIndex, subject, teacher);
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: const BorderSide(color: kBorderColor),
            bottom: periodIndex < timeTable.periods.length - 1
                ? const BorderSide(color: kBorderColor)
                : BorderSide.none,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: kPaddingXSmall, horizontal: kPaddingXSmall / 2),
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
                          color: kTextColor,
                          fontWeight: kFontWeightSemiBold,
                          fontSize: _getFontSize(line),
                          height: kLineHeightNormal,
                          fontFamily: kDefaultFontFamily,
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
                      color: kTextTertiaryColor,
                      fontWeight: kFontWeightRegular,
                      fontSize: _getFontSize(teacher) - 1,
                      height: kLineHeightTight,
                      fontFamily: kDefaultFontFamily,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 과목명 길이에 따라 폰트 크기 조정
  double _getFontSize(String subject) {
    if (subject.isEmpty) return 16.0;

    final length = subject.length;
    if (length <= 2) return 16.0;
    if (length <= 4) return 14.0;
    if (length <= 6) return 12.0;
    return 10.0;
  }

  // 과목명을 적절히 줄바꿈하여 표시
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
      case '동아리':
        return '동아리';
      case '한국사1':
        return '한국사1';
      case '체육1':
        return '체육1';
      case '미술':
        return '미술';
      default:
        // 4글자 이상인 경우 2글자씩 줄바꿈
        if (subject.length > 4) {
          final mid = (subject.length / 2).ceil();
          return '${subject.substring(0, mid)}\n${subject.substring(mid)}';
        }
        return subject;
    }
  }
}
