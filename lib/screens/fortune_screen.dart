import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../utils/enums.dart';

class FortuneScreen extends StatefulWidget {
  const FortuneScreen({Key? key}) : super(key: key);

  @override
  _FortuneScreenState createState() => _FortuneScreenState();
}

class _FortuneScreenState extends State<FortuneScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _luckyNumber;
  late DateTime _today;
  late String _formattedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: FortuneCategory.values.length,
      vsync: this,
    );
    _today = DateTime.now();
    _formattedDate = DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR').format(_today);
    _generateLuckyNumber();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateLuckyNumber() {
    // 오늘 날짜를 시드로 사용하여 같은 날에는 같은 운세가 나오도록 함
    final seed = _today.year * 10000 + _today.month * 100 + _today.day;
    final seededRandom = Random(seed);
    _luckyNumber = seededRandom.nextInt(100) + 1; // 1~100 사이의 행운의 숫자
  }

  String _getFortuneMessage(FortuneCategory category) {
    // 오늘 날짜를 시드로 사용하여 같은 날에는 같은 운세가 나오도록 함
    final seed = _today.year * 10000 + _today.month * 100 + _today.day;
    final seededRandom = Random(seed);

    // 카테고리에 따라 다른 운세 메시지 목록 사용
    final List<String> messages =
        category == FortuneCategory.study ? kStudyFortunes : kLoveFortunes;

    // 랜덤하게 운세 메시지 선택
    final index = seededRandom.nextInt(messages.length);
    return messages[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          kFortuneTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: FortuneCategory.values
                .map((category) => Tab(text: category.label))
                .toList(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: kAccentColor,
            indicatorSize: TabBarIndicatorSize.label,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: FortuneCategory.values
                  .map((category) => _buildFortuneTab(category))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFortuneTab(FortuneCategory category) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateCard(),
          const SizedBox(height: kSpacing),
          _buildFortuneCard(category),
          const SizedBox(height: kSpacing),
          _buildLuckyNumberCard(),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSpacing),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 날짜',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formattedDate,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFortuneCard(FortuneCategory category) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSpacing),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(
          color: kAccentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 ${category.label}',
            style: const TextStyle(
              color: kAccentColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getFortuneMessage(category),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyNumberCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSpacing),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 행운의 숫자',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _luckyNumber.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '오늘의 행운의 숫자는 $_luckyNumber입니다.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
