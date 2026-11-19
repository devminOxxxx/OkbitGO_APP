import 'package:flutter/material.dart';
import '../../../models/timetable.dart';

class TimeTableEditDialog extends StatefulWidget {
  final TimeTable timeTable;
  final int periodIndex;
  final int dayIndex;
  final String currentSubject;
  final String currentTeacher;

  const TimeTableEditDialog({
    Key? key,
    required this.timeTable,
    required this.periodIndex,
    required this.dayIndex,
    required this.currentSubject,
    required this.currentTeacher,
  }) : super(key: key);

  @override
  State<TimeTableEditDialog> createState() => _TimeTableEditDialogState();
}

class _TimeTableEditDialogState extends State<TimeTableEditDialog> {
  late TextEditingController _subjectController;
  late TextEditingController _teacherController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // 과목명과 교사명 분리
    String subject = widget.currentSubject;
    String teacher = widget.currentTeacher;

    // 만약 과목명에 교사명이 포함되어 있다면 분리
    if (widget.currentSubject.contains('\n')) {
      final parts = widget.currentSubject.split('\n');
      subject = parts[0];
      teacher = parts.length > 1 ? parts[1] : '';
    }

    // 포맷팅된 과목명을 원본으로 복원
    subject = _restoreOriginalSubjectName(subject);

    _subjectController = TextEditingController(text: subject);
    _teacherController = TextEditingController(text: teacher);
  }

  // 포맷팅된 과목명을 원본으로 복원
  String _restoreOriginalSubjectName(String formattedSubject) {
    // 원본 과목명에서 교사명을 제거한 상태로 복원
    switch (formattedSubject) {
      case '기술':
        return '기술·가정';
      case '공통':
        return '공통영어1'; // 기본값, 실제로는 더 정확한 로직 필요
      case '진로':
        return '진로활동';
      case '통합':
        return '통합사회1';
      case '과학':
        return '과학탐구실험1';
      case '동아리':
        return '동아리활동';
      default:
        return formattedSubject;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final period = widget.periodIndex + 1;
    final weekday = widget.timeTable.weekdays[widget.dayIndex];

    return AlertDialog(
      title: Text('$period교시 ($weekday요일) 수정'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: '과목명',
                border: OutlineInputBorder(),
                hintText: '예: 국어, 수학, 영어',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '과목명을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: '담당교사 (선택사항)',
                border: OutlineInputBorder(),
                hintText: '예: 김선생님',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final subject = _subjectController.text.trim();
              final teacher = _teacherController.text.trim();

              // 과목명과 교사명을 합쳐서 저장
              final finalSubject =
                  teacher.isNotEmpty ? '$subject\n$teacher' : subject;

              Navigator.of(context).pop({
                'subject': finalSubject,
                'originalSubject': widget.currentSubject,
                'originalTeacher': widget.currentTeacher,
              });
            }
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}
