import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../utils/constants.dart';
import 'package:uuid/uuid.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;
  final DateTime initialDate;

  const EventFormScreen({
    Key? key,
    this.event,
    required this.initialDate,
  }) : super(key: key);

  @override
  _EventFormScreenState createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _hasNotification;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.event?.description ?? '');
    _startDate = widget.event?.start ?? widget.initialDate;
    _endDate =
        widget.event?.end ?? widget.initialDate.add(const Duration(hours: 1));
    _hasNotification = widget.event?.hasNotification ?? false;
    _color = widget.event?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 한국어 월 이름 반환 함수
  String _getKoreanMonth(int month) {
    const months = [
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월'
    ];
    return months[month - 1];
  }

  // 한국어 요일 이름 반환 함수
  String _getKoreanWeekday(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[(weekday - 1) % 7];
  }

  // 날짜를 한국어로 포맷팅하는 함수
  String _formatDateTimeKorean(DateTime dateTime) {
    return '${dateTime.year}년 ${_getKoreanMonth(dateTime.month)} ${dateTime.day}일 (${_getKoreanWeekday(dateTime.weekday)}) ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDateTimePicker(bool isStartDate) {
    final initialDateTime = isStartDate ? _startDate : _endDate;
    DateTime tempDateTime = initialDateTime;

    // 현재 시간 기준으로 최소 날짜 설정 (과거 날짜 선택 방지)
    final DateTime now = DateTime.now();
    final DateTime minimumDate = DateTime(now.year, now.month, now.day);

    // 초기 날짜가 최소 날짜보다 이전인 경우 초기 날짜를 최소 날짜로 설정
    final DateTime safeInitialDateTime = isStartDate
        ? (initialDateTime.isBefore(minimumDate)
            ? minimumDate
            : initialDateTime)
        : (initialDateTime.isBefore(_startDate) ? _startDate : initialDateTime);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          color: kBackgroundColor,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: kSurfaceColor,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('취소'),
                    ),
                    Text(
                      isStartDate ? '시작 날짜 및 시간' : '종료 날짜 및 시간',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (isStartDate) {
                            _startDate = tempDateTime;
                            // 종료 시간이 시작 시간보다 이전인 경우 종료 시간을 시작 시간으로 설정
                            if (_endDate.isBefore(_startDate)) {
                              _endDate =
                                  _startDate.add(const Duration(hours: 1));
                            }
                          } else {
                            _endDate = tempDateTime;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                      surface: Color(0xFF1E1E1E),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      primaryColor: Colors.blue,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    child: Localizations(
                      locale: const Locale('ko', 'KR'),
                      delegates: const [
                        GlobalMaterialLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                      ],
                      child: CupertinoDatePicker(
                        initialDateTime: safeInitialDateTime,
                        minimumDate: isStartDate ? minimumDate : _startDate,
                        mode: CupertinoDatePickerMode.dateAndTime,
                        use24hFormat: true,
                        onDateTimeChanged: (DateTime dateTime) {
                          tempDateTime = dateTime;
                        },
                        backgroundColor: kSurfaceColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveEvent() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목을 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final event = Event(
      id: widget.event?.id ?? const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      start: _startDate,
      end: _endDate,
      hasNotification: _hasNotification,
      color: _color,
      userId: context.read<EventProvider>().getCurrentUserId() ?? 'anonymous',
    );

    if (widget.event == null) {
      eventProvider.addEvent(event);
    } else {
      eventProvider.updateEvent(event);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Text(
          widget.event == null ? '일정 추가' : '일정 수정',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // 삭제 버튼 (기존 일정 수정 시에만 표시)
          if (widget.event != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _showDeleteConfirmation,
            ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveEvent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '제목',
                  labelStyle: TextStyle(color: kTextSecondaryColor),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: '설명',
                  labelStyle: TextStyle(color: kTextSecondaryColor),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '날짜 및 시간',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showDateTimePicker(true),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: kTextSecondaryColor, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '시작',
                          style: TextStyle(
                            color: kTextSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTimeKorean(_startDate),
                          style: const TextStyle(
                            color: kTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showDateTimePicker(false),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: kTextSecondaryColor, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '종료',
                          style: TextStyle(
                            color: kTextSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTimeKorean(_endDate),
                          style: const TextStyle(
                            color: kTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text(
                    '알림 받기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _hasNotification,
                    onChanged: (value) {
                      setState(() {
                        _hasNotification = value;
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '색상',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.teal,
                  Colors.pink,
                  Colors.indigo,
                ].map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _color = color;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == color
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: _color == color
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 삭제 확인 다이얼로그 표시
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text(
          '일정 삭제',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '이 일정을 삭제하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              _deleteEvent(); // 일정 삭제
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // 일정 삭제
  void _deleteEvent() {
    if (widget.event != null) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      eventProvider.deleteEvent(widget.event!.id).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일정이 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // 화면 닫기
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정 삭제 중 오류가 발생했습니다: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }
}
