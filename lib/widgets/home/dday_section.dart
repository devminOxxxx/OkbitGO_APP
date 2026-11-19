import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dday.dart';
import '../../providers/dday_provider.dart';
import '../../utils/constants.dart';
import '../../routes.dart';

class DDaySection extends StatefulWidget {
  const DDaySection({Key? key}) : super(key: key);

  @override
  State<DDaySection> createState() => _DDaySectionState();
}

class _DDaySectionState extends State<DDaySection> {
  bool _isExpanded = false;

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
    return Consumer<DDayProvider>(
      builder: (context, provider, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(kBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(kSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '디데이',
                      style: kTitleStyle,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: kAccentColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(kCircularBorderRadius),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: kAccentColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: kButtonMinWidth,
                          minHeight: kButtonMinHeight,
                        ),
                        iconSize: 20,
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.ddayForm);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _buildDDayList(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDDayList(BuildContext context, DDayProvider provider) {
    if (provider.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kSpacing),
          child: Column(
            children: [
              const SizedBox(
                width: kCardWidth,
                height: kCardHeight,
                child: CircularProgressIndicator(
                  strokeWidth: kBorderWidthThick,
                  valueColor: AlwaysStoppedAnimation<Color>(kAccentColor),
                ),
              ),
              const SizedBox(height: kPaddingMedium),
              Text(
                '디데이 불러오는 중...',
                style: TextStyle(
                  color: kTextSecondaryColor.withValues(alpha: 0.7),
                  fontSize: kFontSizeRegular,
                  fontFamily: kDefaultFontFamily,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.all(kSpacing),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 32,
            ),
            const SizedBox(height: kSmallSpacing),
            Text(
              provider.error!,
              style: TextStyle(
                color: Colors.red[300],
                fontSize: kFontSizeRegular,
                fontFamily: kDefaultFontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kPaddingMedium),
            ElevatedButton.icon(
              onPressed: () => provider.fetchDDays(),
              icon: const Icon(Icons.refresh, size: kIconSizeSmall),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                foregroundColor: kTextColor,
                textStyle: const TextStyle(
                  fontSize: kFontSizeRegular,
                  fontFamily: kDefaultFontFamily,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: kPaddingLarge,
                  vertical: kSmallSpacing,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.ddays.isEmpty) {
      return const SizedBox(height: kSmallSpacing); // 빈 박스 크기 조정
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

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _isExpanded
              ? sortedDDays.length
              : (sortedDDays.length > 3 ? 3 : sortedDDays.length),
          itemBuilder: (context, index) {
            final dday = sortedDDays[index];
            return _buildDDayItem(context, dday, provider);
          },
        ),
        if (sortedDDays.length > 3)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: kBorderColor.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? '접기' : '더보기 (${sortedDDays.length - 3}개 더)',
                      style: const TextStyle(
                        color: kAccentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: kAccentColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.ddayForm,
          arguments: dday,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacing,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: kBorderColor.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.7),
                  width: 1,
                ),
              ),
              child: Text(
                ddayText,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dday.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration:
                          dday.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dday.date.year}년 ${dday.date.month}월 ${dday.date.day}일',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
