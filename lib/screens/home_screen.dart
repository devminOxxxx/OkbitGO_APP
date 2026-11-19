import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:provider/provider.dart';
import '../providers/timetable_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/event_provider.dart';
import '../models/meal.dart';
import '../models/timetable.dart';
import 'package:intl/intl.dart';
import '../utils/enums.dart';
import '../widgets/home/calendar_preview.dart';
import '../widgets/home/dday_section.dart';
import '../providers/notice_provider.dart';
import '../utils/constants.dart';
import '../providers/notification_provider.dart';
import '../providers/dday_provider.dart';
import '../models/dday.dart';
import '../routes.dart';
import '../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '옥빛GO!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Consumer<DDayProvider>(
              builder: (context, provider, child) {
                // 디데이 목록이 비어있거나 로딩 중이면 표시하지 않음
                if (provider.ddays.isEmpty || provider.isLoading) {
                  return const SizedBox.shrink();
                }

                // 날짜순으로 정렬 (가까운 날짜가 먼저 오도록)
                final sortedDDays = List<DDay>.from(provider.ddays)
                  ..sort((a, b) {
                    final aDaysRemaining = a.getDaysRemaining();
                    final bDaysRemaining = b.getDaysRemaining();

                    // 미래 날짜를 먼저 정렬 (D-Day에 가까운 순서대로)
                    if (aDaysRemaining >= 0 && bDaysRemaining >= 0) {
                      return aDaysRemaining.compareTo(bDaysRemaining);
                    }

                    // 과거 날짜는 나중에 정렬
                    if (aDaysRemaining < 0 && bDaysRemaining < 0) {
                      return bDaysRemaining.compareTo(aDaysRemaining);
                    }

                    // 미래 날짜가 과거 날짜보다 먼저 오도록
                    return aDaysRemaining >= 0 ? -1 : 1;
                  });

                // 가장 가까운 디데이 가져오기
                final closestDDay = sortedDDays.firstWhere(
                  (dday) => dday.getDaysRemaining() >= 0,
                  orElse: () => sortedDDays.first,
                );

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kAccentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${closestDDay.getDDayText()} ${closestDDay.title}',
                    style: const TextStyle(
                      color: kAccentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  if (notificationProvider.hasUnreadNotifications)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  _buildNoticeSection(context),
                  const SizedBox(height: 12),
                  _buildSchoolLinkCard(),
                  const SizedBox(height: 16),
                  _buildMainCard(),
                  const SizedBox(height: 16),
                  const DDaySection(),
                  const SizedBox(height: 16),
                  _buildCalendarSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeSection(BuildContext context) {
    return Consumer<NoticeProvider>(
      builder: (context, provider, child) {
        final latestNotice = provider.latestNotice;
        final noticeTitle = latestNotice?.title ?? '2025학년도 1학기 학사일정 안내';
        final hasNewNotices = provider.newNoticeCount > 0;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(kBorderRadius),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.notice);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: kSpacing, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kBorderColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '공지사항',
                      style: TextStyle(
                        color: Colors.blue[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      noticeTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // New 표시 (오른쪽에 배치)
                  if (hasNewNotices)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSchoolLinkCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: InkWell(
        onTap: () async {
          final Uri url = Uri.parse(kSchoolMainUrl);
          if (await url_launcher.canLaunchUrl(url)) {
            await url_launcher.launchUrl(url,
                mode: url_launcher.LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: kSpacing, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kBorderColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '홈페이지',
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '옥빛고등학교',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.open_in_new,
                  color: kTextTertiaryColor, size: kIconSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            child: _buildTimetableSection(),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(kBorderRadius),
            ),
            child: _buildMealSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableSection() {
    return InkWell(
      onTap: () {
        context.read<NavigationProvider>().goToTab(
              context,
              NavigationTab.schoolLife,
              initialTabIndex: 0,
            );
      },
      child: Container(
        padding: const EdgeInsets.all(kSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      '시간표',
                      style: kTitleStyle,
                    ),
                    const SizedBox(width: kSmallSpacing),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kBorderColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Consumer<TimeTableProvider>(
                        builder: (context, provider, child) {
                          return Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              final user = userProvider.user;
                              if (user != null &&
                                  user.grade != null &&
                                  user.classNumber != null) {
                                return Text(
                                  '${user.grade}학년 ${user.classNumber}반',
                                  style: const TextStyle(
                                    color: kTextSecondaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }
                              return Text(
                                provider.timeTable?.className ??
                                    '${kDefaultGrade}학년 ${kDefaultClass}반',
                                style: const TextStyle(
                                  color: kTextSecondaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right,
                    color: kTextTertiaryColor, size: kIconSize),
              ],
            ),
            const SizedBox(height: kSpacing),
            Consumer<TimeTableProvider>(
              builder: (context, provider, child) {
                final timeTable = provider.timeTable;
                if (timeTable == null) {
                  return _buildTodayTimetable(null);
                }

                if (timeTable.subjects.isEmpty) {
                  return _buildTodayTimetable(null);
                }

                return _buildTodayTimetable(timeTable);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTimetable(TimeTable? timeTable) {
    final today = DateTime.now().weekday - 1; // 0 = 월요일, 6 = 일요일
    if (today >= 5) {
      // 주말인 경우
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBorderColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '오늘은 수업이 없는 날이에요',
            style: TextStyle(
              color: kTextSecondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    if (timeTable == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBorderColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '시간표를 불러올 수 없습니다',
            style: TextStyle(
              color: kTextSecondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    // 오늘의 과목들을 가져옵니다 (교사명 제외)
    final todaySubjects = <String>[];
    for (int i = 0; i < timeTable.subjects.length; i++) {
      // 인덱스 범위 확인
      if (today >= 0 && today < timeTable.subjects[i].length) {
        final subjectData = timeTable.subjects[i][today];
        if (subjectData.isNotEmpty && subjectData != '없음') {
          // 과목명만 추출 (교사명 제외)
          final subjectName = subjectData.split('\n').first;
          if (subjectName.isNotEmpty) {
            todaySubjects.add(subjectName);
          }
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBorderColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘 시간표',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            todaySubjects.isEmpty ? '오늘 수업이 없습니다' : todaySubjects.join(', '),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection() {
    return Consumer<MealProvider>(
      builder: (context, provider, child) {
        final today = DateTime.now();
        final todayStr = DateFormat('yyyyMMdd').format(today);
        final todayMeal = provider.meals.firstWhere(
          (meal) => meal.date == todayStr,
          orElse: () => Meal(date: '', calorie: '', menu: []),
        );

        return InkWell(
          onTap: () {
            context.read<NavigationProvider>().goToTab(
                  context,
                  NavigationTab.schoolLife,
                  initialTabIndex: 1,
                );
          },
          child: Container(
            padding: const EdgeInsets.all(kSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '급식',
                          style: kTitleStyle,
                        ),
                        const SizedBox(width: kSmallSpacing),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kBorderColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatDateLong(today),
                            style: const TextStyle(
                              color: kTextSecondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right,
                        color: kTextTertiaryColor, size: kIconSize),
                  ],
                ),
                const SizedBox(height: kSpacing),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBorderColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF333333),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '점심',
                              style: TextStyle(
                                color: kTextSecondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (todayMeal.date.isEmpty || todayMeal.menu.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                '오늘은 급식이 없는 날이에요',
                                style: TextStyle(
                                  color: kTextSecondaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            )
                          else if (!provider.isLoading &&
                              provider.error == null)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF333333),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                todayMeal.calorie,
                                style: const TextStyle(
                                  color: kTextSecondaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (!(!provider.isLoading &&
                          provider.error == null &&
                          (todayMeal.date.isEmpty || todayMeal.menu.isEmpty)))
                        const SizedBox(height: 10),
                      if (provider.isLoading)
                        const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      else if (provider.error != null)
                        const Text(
                          '급식 정보를 불러올 수 없습니다.',
                          style: TextStyle(
                            color: kTextSecondaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      else if (todayMeal.date.isEmpty || todayMeal.menu.isEmpty)
                        const SizedBox.shrink()
                      else
                        Text(
                          _cleanMenuText(todayMeal.menu).join(', '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 알레르기 정보(괄호 안의 숫자) 제거 메서드
  List<String> _removeAllergies(List<String> menuItems) {
    return menuItems.map((item) {
      // 괄호와 그 안의 내용 제거
      return item.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
    }).toList();
  }

  // 메뉴 텍스트에서 '*'와 숫자 제거 메서드
  List<String> _cleanMenuText(List<String> menuItems) {
    return _removeAllergies(menuItems).map((item) {
      // '*' 제거
      String cleaned = item.replaceAll('*', '');
      // 끝에 붙은 숫자 제거 (예: "시금치된장국1" -> "시금치된장국")
      cleaned = cleaned.replaceAll(RegExp(r'\d+$'), '');
      return cleaned;
    }).toList();
  }

  // 긴 형식의 날짜 포맷팅 메서드
  String _formatDateLong(DateTime date) {
    // 2025년 기준으로 날짜 포맷팅
    final int year = date.year;
    final int adjustedYear = year < 2025 ? 2025 : year;
    final DateTime adjustedDate = DateTime(
      adjustedYear,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
    return DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR').format(adjustedDate);
  }

  Widget _buildCalendarSection() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(kBorderRadius),
          ),
          child: InkWell(
            onTap: () {
              context.read<NavigationProvider>().goToTab(
                  context, NavigationTab.schoolLife,
                  initialTabIndex: 2);
            },
            child: const CalendarPreview(),
          ),
        );
      },
    );
  }
}
