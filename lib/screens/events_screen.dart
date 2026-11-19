import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../utils/constants.dart';
import '../routes.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late int _luckyNumber;
  late String _todayDate;

  @override
  void initState() {
    super.initState();
    _todayDate = _getFormattedDate();

    // 날짜를 기반으로 행운의 숫자 결정
    final DateTime now = DateTime.now();
    final int seed = now.year * 10000 + now.month * 100 + now.day;
    final Random random = Random(seed);

    _luckyNumber = random.nextInt(100) + 1; // 1~100 사이의 행운의 숫자
  }

  String _getFormattedDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR');
    return formatter.format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          '이벤트',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFortuneCard(),
            const SizedBox(height: 16),
            // 여기에 추가 이벤트 컨텐츠를 넣을 수 있습니다.
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.fortune);
        },
        child: Padding(
          padding: const EdgeInsets.all(kSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '오늘의 운세',
                    style: kTitleStyle,
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: kTextTertiaryColor,
                    size: kIconSize,
                  ),
                ],
              ),
              const SizedBox(height: kSpacing),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _todayDate,
                          style: const TextStyle(
                            color: kTextSecondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '오늘의 학업운과 연애운을 확인해보세요!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              '오늘의 행운의 숫자: ',
                              style: TextStyle(
                                color: kTextSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$_luckyNumber',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
