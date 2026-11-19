import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dday.dart';
import '../providers/dday_provider.dart';
import '../utils/constants.dart';
import '../routes.dart';

class DDayListScreen extends StatefulWidget {
  const DDayListScreen({Key? key}) : super(key: key);

  @override
  State<DDayListScreen> createState() => _DDayListScreenState();
}

class _DDayListScreenState extends State<DDayListScreen> {
  @override
  void initState() {
    super.initState();
    // 위젯이 빌드된 후 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DDayProvider>(context, listen: false);
      if (!provider.isInitialized) {
        provider.fetchDDays();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          '디데이 목록',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.ddayForm);
            },
          ),
        ],
      ),
      body: Consumer<DDayProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[300],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchDDays(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.ddays.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '등록된 디데이가 없습니다',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '+ 버튼을 눌러 중요한 날짜를 등록해보세요',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.ddayForm);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('디데이 추가하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
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

              // 과거 날짜는 나중에 정렬 (최근 지난 날짜가 먼저 오도록)
              if (aDaysRemaining < 0 && bDaysRemaining < 0) {
                return bDaysRemaining.compareTo(aDaysRemaining);
              }

              // 미래 날짜가 과거 날짜보다 먼저 오도록
              return aDaysRemaining >= 0 ? -1 : 1;
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDDays.length,
            itemBuilder: (context, index) {
              final dday = sortedDDays[index];
              return _buildDDayItem(context, dday, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.ddayForm);
        },
        backgroundColor: kAccentColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDDayItem(
    BuildContext context,
    DDay dday,
    DDayProvider provider,
  ) {
    final daysRemaining = dday.getDaysRemaining();
    final ddayText = dday.getDDayText();

    Color badgeColor;
    if (daysRemaining == 0) {
      badgeColor = Colors.red;
    } else if (daysRemaining > 0) {
      badgeColor = kAccentColor;
    } else {
      badgeColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: kSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.ddayForm,
            arguments: dday,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: badgeColor.withAlpha(100),
                    width: 1,
                  ),
                ),
                child: Text(
                  ddayText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dday.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: dday.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dday.date.year}년 ${dday.date.month}월 ${dday.date.day}일',
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Colors.white.withAlpha(150),
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.ddayForm,
                        arguments: dday,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red.withAlpha(150),
                      size: 20,
                    ),
                    onPressed: () {
                      _showDeleteConfirmDialog(context, dday);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, DDay dday) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디데이 삭제'),
        content: const Text('정말 이 디데이를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DDayProvider>().deleteDDay(dday.id);
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
}
