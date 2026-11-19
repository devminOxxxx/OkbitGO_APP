import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class AppNoticeScreen extends StatefulWidget {
  const AppNoticeScreen({Key? key}) : super(key: key);

  @override
  State<AppNoticeScreen> createState() => _AppNoticeScreenState();
}

class _AppNoticeScreenState extends State<AppNoticeScreen> {
  // 앱 공지사항 목록
  final List<Notice> notices = [
    Notice(
      id: '1',
      title: '옥빛GO! 앱 v1.0.0 출시 안내',
      date: '2025년 3월 15일',
      summary:
          '${kSchoolName} 학생들을 위한 옥빛GO! 앱이 정식 출시되었습니다. 학교 생활에 필요한 다양한 기능을 이용해보세요.',
      content: '''
옥빛GO! 앱 v1.0.0이 정식 출시되었습니다.

옥빛GO!는 ${kSchoolName} 학생들의 학교 생활을 더욱 편리하게 만들기 위해 개발된 앱입니다. 다음과 같은 기능을 제공합니다:

1. 학교 시간표 확인
2. 급식 메뉴 확인
3. 학사 일정 관리
4. 학교 공지사항 확인
5. 커뮤니티 기능 (준비 중)

앱을 사용하면서 불편한 점이나 개선 사항이 있으시면 설정 > 고객 센터를 통해 알려주세요.
앞으로도 지속적인 업데이트를 통해 더 나은 서비스를 제공하겠습니다.

감사합니다.
''',
      isNew: true,
    ),
    Notice(
      id: '2',
      title: '시간표 기능 업데이트 안내',
      date: '2025년 3월 20일',
      summary:
          '시간표 기능이 업데이트되었습니다. 이제 주간 시간표를 한눈에 확인할 수 있으며, 과목별 색상 구분 기능이 추가되었습니다.',
      content: '''
시간표 기능 업데이트 안내

안녕하세요, 옥빛GO! 사용자 여러분.
시간표 기능이 다음과 같이 업데이트되었습니다:

1. 주간 시간표 보기 기능 추가
   - 한 주의 전체 시간표를 한눈에 확인할 수 있습니다.
   - 좌우로 스와이프하여 다른 주차의 시간표도 확인 가능합니다.

2. 과목별 색상 구분 기능 추가
   - 각 과목마다 다른 색상이 적용되어 시간표를 더 쉽게 구분할 수 있습니다.
   - 설정에서 과목별 색상을 직접 변경할 수도 있습니다.

3. 시간표 자동 업데이트 기능 개선
   - 학교 서버와 연동하여 시간표 변경 사항이 실시간으로 반영됩니다.
   - 시간표 변경 시 알림을 받을 수 있는 기능이 추가되었습니다.

앱을 최신 버전으로 업데이트하시면 바로 이용하실 수 있습니다.
더 나은 서비스를 제공하기 위해 노력하겠습니다.

감사합니다.
''',
      isNew: true,
    ),
    Notice(
      id: '3',
      title: '급식 메뉴 알레르기 정보 표시 기능 추가',
      date: '2025년 3월 25일',
      summary: '급식 메뉴에 알레르기 정보가 표시됩니다. 알레르기가 있는 학생들은 메뉴를 확인하고 주의하시기 바랍니다.',
      content: '''
급식 메뉴 알레르기 정보 표시 기능 추가

안녕하세요, 옥빛GO! 사용자 여러분.
급식 메뉴 기능에 알레르기 정보 표시 기능이 추가되었습니다:

1. 알레르기 정보 표시
   - 각 메뉴 항목에 포함된 알레르기 유발 성분이 표시됩니다.
   - 알레르기 정보는 식품의약품안전처의 알레르기 표시제에 따라 표기됩니다.

2. 알레르기 필터링 기능
   - 설정에서 자신의 알레르기 정보를 등록하면, 해당 알레르기 유발 성분이 포함된 메뉴를 강조 표시합니다.
   - 알레르기 정보는 앱 내에서만 사용되며, 서버에 저장되지 않습니다.

3. 알레르기 정보 상세 보기
   - 알레르기 정보 아이콘을 탭하면 상세 정보를 확인할 수 있습니다.
   - 알레르기 유발 성분에 대한 설명과 주의사항을 제공합니다.

앱을 최신 버전으로 업데이트하시면 바로 이용하실 수 있습니다.
알레르기가 있는 학생들은 급식 메뉴를 확인하고 주의하시기 바랍니다.

감사합니다.
''',
      isNew: false,
    ),
    Notice(
      id: '4',
      title: '일정 관리 기능 업데이트 안내',
      date: '2025년 4월 5일',
      summary:
          '일정 관리 기능이 업데이트되었습니다. 이제 학교 일정과 개인 일정을 함께 관리할 수 있으며, 알림 기능이 추가되었습니다.',
      content: '''
일정 관리 기능 업데이트 안내

안녕하세요, 옥빛GO! 사용자 여러분.
일정 관리 기능이 다음과 같이 업데이트되었습니다:

1. 학교 일정과 개인 일정 통합 관리
   - 학교 공식 일정과 개인 일정을 한 화면에서 함께 확인할 수 있습니다.
   - 일정 유형별로 필터링하여 볼 수 있습니다.

2. 알림 기능 추가
   - 중요한 일정에 알림을 설정할 수 있습니다.
   - 일정 시작 시간 기준으로 5분, 15분, 30분, 1시간, 1일 전에 알림을 받을 수 있습니다.

3. 일정 공유 기능
   - 개인 일정을 친구나 선생님과 공유할 수 있습니다.
   - 공유 받은 일정은 자동으로 캘린더에 추가됩니다.

4. 반복 일정 설정
   - 매일, 매주, 매월, 매년 반복되는 일정을 설정할 수 있습니다.
   - 특정 기간 동안만 반복되도록 설정할 수도 있습니다.

앱을 최신 버전으로 업데이트하시면 바로 이용하실 수 있습니다.
더 나은 서비스를 제공하기 위해 노력하겠습니다.

감사합니다.
''',
      isNew: false,
    ),
    Notice(
      id: '5',
      title: '커뮤니티 기능 베타 테스트 안내',
      date: '2025년 4월 15일',
      summary: '커뮤니티 기능 베타 테스트를 시작합니다. 학생들 간의 소통과 정보 공유를 위한 공간이 마련되었습니다.',
      content: '''
커뮤니티 기능 베타 테스트 안내

안녕하세요, 옥빛GO! 사용자 여러분.
많은 분들이 기다려온 커뮤니티 기능의 베타 테스트를 시작합니다:

1. 커뮤니티 기능 소개
   - 학생들 간의 소통과 정보 공유를 위한 공간입니다.
   - 학년별, 반별, 동아리별 게시판이 마련되어 있습니다.
   - 익명 게시판도 이용 가능합니다.

2. 베타 테스트 참여 방법
   - 앱 메인 화면의 '커뮤니티' 탭을 통해 접속할 수 있습니다.
   - 베타 테스트 기간 동안에는 일부 기능이 제한될 수 있습니다.
   - 피드백은 설정 > 고객 센터를 통해 보내주세요.

3. 이용 규칙
   - 타인을 비방하거나 명예를 훼손하는 글은 작성하지 않습니다.
   - 불법적인 내용이나 유해한 정보를 공유하지 않습니다.
   - 학교 규칙과 커뮤니티 가이드라인을 준수해야 합니다.

베타 테스트 기간은 2025년 4월 15일부터 5월 15일까지이며, 이후 정식 서비스로 전환될 예정입니다.
여러분의 적극적인 참여와 소중한 피드백 부탁드립니다.

감사합니다.
''',
      isNew: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          kNoticeTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(kSpacing),
        itemCount: notices.length,
        itemBuilder: (context, index) {
          final notice = notices[index];
          return _buildNoticeItem(context, notice);
        },
      ),
    );
  }

  Widget _buildNoticeItem(BuildContext context, Notice notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: kSpacing),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: InkWell(
        onTap: () => _showNoticeDetail(context, notice),
        borderRadius: BorderRadius.circular(kBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(kSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notice.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (notice.isNew) _buildNewBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notice.date,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                notice.summary,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showNoticeDetail(BuildContext context, Notice notice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NoticeDetailSheet(notice: notice),
    );
  }
}

class _NoticeDetailSheet extends StatelessWidget {
  final Notice notice;

  const _NoticeDetailSheet({required this.notice});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        notice.date,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      if (notice.isNew) ...[
                        const SizedBox(width: 8),
                        _buildNewBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: kBorderColor),
                  const SizedBox(height: 16),
                  Text(
                    notice.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kSpacing, vertical: 12),
      decoration: const BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '공지사항 상세',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class Notice {
  final String id;
  final String title;
  final String date;
  final String summary;
  final String content;
  final bool isNew;

  Notice({
    required this.id,
    required this.title,
    required this.date,
    required this.summary,
    required this.content,
    this.isNew = false,
  });
}
