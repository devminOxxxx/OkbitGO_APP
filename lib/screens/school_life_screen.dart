import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../providers/meal_provider.dart';
import '../providers/timetable_provider.dart';
import '../providers/event_provider.dart';
import '../widgets/school_life/meal/meal_list_item.dart';
import '../widgets/school_life/timetable/timetable_grid.dart';
import '../widgets/school_life/calendar/calendar_grid.dart';
import '../widgets/school_life/calendar/calendar_header.dart';
import '../widgets/school_life/calendar/weekday_header.dart';
import '../widgets/school_life/calendar/schedule_item.dart';
import '../widgets/school_life/allergy/allergy_info_card.dart';
import '../widgets/school_life/allergy/allergy_info_dialog.dart';
import '../widgets/school_life/timetable/timetable_edit_dialog.dart';
import '../widgets/school_life/timetable/timetable_capture_widget.dart';
import '../models/meal.dart';
import '../models/event.dart';
import '../utils/constants.dart';
import 'event_form_screen.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';
import 'dart:typed_data';

class SchoolLifeScreen extends StatefulWidget {
  const SchoolLifeScreen({super.key});

  @override
  State<SchoolLifeScreen> createState() => _SchoolLifeScreenState();
}

class _SchoolLifeScreenState extends State<SchoolLifeScreen>
    with SingleTickerProviderStateMixin {
  static const _kTabCount = 3;

  late final TabController _tabController;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    _tabController = TabController(length: _kTabCount, vsync: this);
    initializeDateFormatting(kLocale, null);
  }

  Future<void> _loadInitialData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeProviders();
    });
  }

  Future<void> _initializeProviders() async {
    final mealProvider = context.read<MealProvider>();
    final timeTableProvider = context.read<TimeTableProvider>();
    final eventProvider = context.read<EventProvider>();

    if (!mealProvider.isInitialized) {
      await mealProvider.fetchMeals();
    }

    if (!timeTableProvider.isInitialized) {
      await timeTableProvider.fetchTimeTable();
    }

    if (!eventProvider.isInitialized) {
      await eventProvider.fetchEvents();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    final eventProvider = context.watch<EventProvider>();
    return eventProvider.getEventsForDay(day);
  }

  String _getFormattedDate(DateTime date) {
    final formatter = DateFormat('M월 d일 (E)', kLocale);
    return formatter.format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: kBackgroundColor,
              elevation: 0,
              title: const Text(kSchoolLifeTitle, style: kTitleStyle),
              centerTitle: true,
              floating: true,
              pinned: true,
              forceElevated: innerBoxIsScrolled,
            ),
            SliverPersistentHeader(
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[500],
                  labelStyle: kTabStyle,
                  unselectedLabelStyle: kUnselectedTabStyle,
                  tabs: const [
                    Tab(text: '시간표'),
                    Tab(text: '급식'),
                    Tab(text: '캘린더'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTimeTableTab(),
            _buildMealTab(),
            _buildCalendarTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: kSpacing),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text(kRetryButtonText),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildTimeTableTab() {
    return Consumer<TimeTableProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  provider.message ?? '시간표를 불러오는 중입니다...',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return _buildErrorView(
            provider.message ?? '시간표를 불러오는데 실패했습니다.',
            () => provider.fetchTimeTable(forceRefresh: true),
          );
        }

        if (provider.timeTable == null) {
          return _buildErrorView(
            provider.message ?? '시간표 데이터가 없습니다.',
            () => provider.fetchTimeTable(forceRefresh: true),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchTimeTable(forceRefresh: true),
          child: Stack(
            children: [
              ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: kSpacing),
                children: [
                  TimeTableGrid(
                    timeTable: provider.timeTable!,
                    onSubjectTap: _showSubjectEditDialog,
                  ),
                  const SizedBox(height: 80), // 하단 여백 추가 (FAB 공간 확보)
                ],
              ),
              // 공유 버튼
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 안내 문구
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        '눌러서 시간표 캡처하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 공유 버튼
                    FloatingActionButton(
                      onPressed: _isCapturing ? null : _captureAndSaveTimeTable,
                      backgroundColor: _isCapturing ? Colors.grey : Colors.blue,
                      child: _isCapturing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.camera_alt),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealTab() {
    return Consumer<MealProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingView();
        }

        if (provider.error != null) {
          return _buildErrorView(
            kLoadFailedMessage,
            () => provider.fetchMeals(forceRefresh: true),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchMeals(forceRefresh: true),
          child: ListView(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(kSpacing),
            children: [
              AllergyInfoCard(onTap: _showAllergyInfoDialog),
              if (provider.meals.isEmpty)
                _buildErrorView(
                  kNoDataMessage,
                  () => provider.fetchMeals(forceRefresh: true),
                )
              else
                ..._buildMealList(provider.meals),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMealList(List<Meal> meals) {
    final today = DateTime.now();
    final todayStr = int.parse(DateFormat('yyyyMMdd').format(today));

    // 오늘 이후의 급식만 필터링
    final filteredMeals = meals.where((meal) {
      if (meal.date.isEmpty) return false;
      final mealDate = int.parse(meal.date);
      return mealDate >= todayStr;
    }).toList();

    // 날짜순으로 정렬
    filteredMeals.sort((a, b) => a.date.compareTo(b.date));

    if (filteredMeals.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                Icon(
                  Icons.no_meals,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '표시할 급식 정보가 없습니다',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return filteredMeals.map((meal) {
      // 급식 메뉴가 비어있는지 확인
      if (meal.menu.isEmpty) {
        // 날짜 포맷팅
        final mealDate = DateTime(
          int.parse(meal.date.substring(0, 4)),
          int.parse(meal.date.substring(4, 6)),
          int.parse(meal.date.substring(6, 8)),
        );
        final formattedDate = DateFormat('M월 d일 (E)', 'ko_KR').format(mealDate);

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '점심',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.no_meals,
                        size: 36,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '오늘은 급식이 없는 날이에요',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: MealListItem(meal: meal),
      );
    }).toList();
  }

  void _showAllergyInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AllergyInfoDialog(
        selectedAllergies: const [],
        onAllergySelected: (allergies) {
          // 알레르기 정보는 단순 표시용이므로 선택 처리는 하지 않음
        },
      ),
    );
  }

  void _showSubjectEditDialog(int periodIndex, int dayIndex,
      String currentSubject, String currentTeacher) {
    final provider = context.read<TimeTableProvider>();

    showDialog(
      context: context,
      builder: (context) => TimeTableEditDialog(
        timeTable: provider.timeTable!,
        periodIndex: periodIndex,
        dayIndex: dayIndex,
        currentSubject: currentSubject,
        currentTeacher: currentTeacher,
      ),
    ).then((result) {
      if (result != null && result is Map<String, String>) {
        provider.updateSubject(periodIndex, dayIndex, result['subject']!,
            result['originalTeacher'] ?? '');
      }
    });
  }

  // 시간표 캡처 및 갤러리 저장
  Future<void> _captureAndSaveTimeTable() async {
    final provider = context.read<TimeTableProvider>();
    final timeTable = provider.timeTable;

    if (timeTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시간표 데이터가 없습니다.')),
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // 현재 주차 계산
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 4));
      final currentWeek =
          '${DateFormat('M.d').format(weekStart)} ~ ${DateFormat('M.d').format(weekEnd)}';

      // 캡처용 위젯을 이용해 스크린샷 생성
      final captureWidget = TimeTableCaptureWidget(
        timeTable: timeTable,
        currentWeek: currentWeek,
      );

      // 스크린샷 캡처
      final Uint8List? imageBytes =
          await _screenshotController.captureFromWidget(
        captureWidget,
        pixelRatio: 3.0,
      );

      if (imageBytes != null) {
        // 갤러리에 저장
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          name:
              'timetable_${timeTable.grade}_${timeTable.classNum}_${DateFormat('yyyyMMdd_HHmmss').format(now)}',
          quality: 100,
        );

        if (result['isSuccess'] == true) {
          // 저장 성공 후 공유 옵션 제공
          _showShareOptions(imageBytes, timeTable);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('시간표 저장에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시간표 캡처 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  // 공유 옵션 다이얼로그
  void _showShareOptions(Uint8List imageBytes, timeTable) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kSurfaceColor,
          title: const Text(
            '시간표 캡처 완료',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '시간표가 갤러리에 저장되었습니다.\n다른 앱으로 공유하시겠습니까?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _shareImage(imageBytes, timeTable);
              },
              child: const Text('공유하기'),
            ),
          ],
        );
      },
    );
  }

  // 이미지 공유
  Future<void> _shareImage(Uint8List imageBytes, timeTable) async {
    try {
      // 임시 파일로 저장
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/timetable_share.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // 이미지 공유
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: '${timeTable.grade}학년 ${timeTable.classNum}반 시간표',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('공유 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Widget _buildCalendarTab() {
    final eventProvider = context.watch<EventProvider>();

    return Stack(
      children: [
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              color: kSurfaceColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: Column(
                      children: [
                        CalendarHeader(
                          focusedDay: _focusedDay,
                          onPreviousMonth: () {
                            setState(() {
                              _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month - 1,
                                1,
                              );
                            });
                          },
                          onNextMonth: () {
                            setState(() {
                              _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month + 1,
                                1,
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const WeekdayHeader(),
                        CalendarGrid(
                          focusedDay: _focusedDay,
                          selectedDay: _selectedDay,
                          events: eventProvider.events,
                          onDaySelected: (date) {
                            setState(() {
                              _selectedDay = date;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _getFormattedDate(_selectedDay),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: _buildEventsList(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _navigateToEventForm(null),
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList() {
    final events = _getEventsForDay(_selectedDay);

    if (events.isEmpty) {
      return const Center(
        child: Text(
          '일정이 없습니다',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        events.length,
        (index) {
          final event = events[index];
          return Column(
            children: [
              GestureDetector(
                onTap: () => _navigateToEventForm(event),
                child: ScheduleItem(
                  title: event.title,
                  description: event.description ?? '',
                  isToday: _isSameDay(_selectedDay, DateTime.now()),
                  color: event.color,
                  startTime: DateFormat('HH:mm').format(event.start),
                  endTime: DateFormat('HH:mm').format(event.end),
                  notificationTime: event.notificationTime,
                ),
              ),
              if (index < events.length - 1)
                const Divider(
                  color: kBorderColor,
                  height: 32,
                  thickness: 1,
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _navigateToEventForm(Event? event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(
          event: event,
          initialDate: _selectedDay,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }
}

// TabBar를 SliverPersistentHeader로 사용하기 위한 Delegate 클래스
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: kBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
