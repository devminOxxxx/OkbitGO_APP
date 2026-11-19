import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          kTermsOfServiceTitle,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: kSpacing),
            _buildTermsSection(
              title: '제 1 장 총칙',
              content: _getChapter1Content(),
            ),
            const SizedBox(height: kSpacing),
            _buildTermsSection(
              title: '제 2 장 서비스 이용',
              content: _getChapter2Content(),
            ),
            const SizedBox(height: kSpacing),
            _buildTermsSection(
              title: '제 3 장 권리와 의무',
              content: _getChapter3Content(),
            ),
            const SizedBox(height: kSpacing),
            _buildTermsSection(
              title: '제 4 장 서비스 제한 및 책임',
              content: _getChapter4Content(),
            ),
            const SizedBox(height: kSpacing),
            _buildTermsSection(
              title: '제 5 장 기타',
              content: _getChapter5Content(),
            ),
            const SizedBox(height: kSpacing * 2),
            Center(
              child: Text(
                '최종 개정일: 2025년 1월 1일',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kSpacing),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: kAccentColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '서비스 이용 약관 안내',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '옥빛GO! 서비스를 이용해 주셔서 감사합니다. 본 약관은 옥빛GO! 서비스 이용에 관한 조건 및 절차, 이용자와 당사의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정합니다.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection({
    required String title,
    required String content,
  }) {
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: kSpacing),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getChapter1Content() {
    return '''
제 1 조 (목적)
본 약관은 옥빛고등학교 학생들을 위한 모바일 애플리케이션 '옥빛GO!'(이하 '서비스')의 이용 조건 및 절차, 이용자와 당사의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.

제 2 조 (용어의 정의)
1. '이용자'란 본 약관에 따라 서비스를 이용하는 회원 및 비회원을 말합니다.
2. '회원'이란 서비스에 개인정보를 제공하여 회원등록을 한 자로서, 서비스의 정보를 지속적으로 제공받으며 이용할 수 있는 자를 말합니다.
3. '비회원'이란 회원에 가입하지 않고 서비스를 이용하는 자를 말합니다.

제 3 조 (약관의 효력 및 변경)
1. 본 약관은 서비스를 이용하고자 하는 모든 이용자에게 적용됩니다.
2. 당사는 필요한 경우 약관을 변경할 수 있으며, 변경된 약관은 서비스 내 공지사항에 게시하거나 기타의 방법으로 이용자에게 공지함으로써 효력이 발생합니다.
''';
  }

  String _getChapter2Content() {
    return '''
제 4 조 (서비스의 제공 및 변경)
1. 당사는 다음과 같은 서비스를 제공합니다:
   - 학교 시간표 및 급식 정보 제공
   - 학교 공지사항 및 알림 서비스
   - 학사 일정 관리 및 알림 서비스
   - 기타 학교생활 관련 편의 기능

2. 당사는 서비스의 품질 향상 및 운영상의 이유로 서비스의 내용을 변경할 수 있으며, 이 경우 변경 내용을 사전에 공지합니다.

제 5 조 (서비스 이용 시간)
1. 서비스는 연중무휴, 1일 24시간 제공을 원칙으로 합니다.
2. 다만, 당사는 서비스의 운영 및 유지보수를 위해 필요한 경우 서비스의 전부 또는 일부를 중단할 수 있으며, 이 경우 사전에 공지합니다.

제 6 조 (이용자의 의무)
1. 이용자는 서비스 이용 시 다음 행위를 하지 않아야 합니다:
   - 타인의 개인정보를 도용하거나 부정하게 사용하는 행위
   - 서비스를 이용하여 법령, 공공질서, 미풍양속에 반하는 행위
   - 당사의 서비스를 방해하거나 그 정보를 도용, 변경하는 행위
   - 기타 관련 법령에 위배되는 행위
''';
  }

  String _getChapter3Content() {
    return '''
제 7 조 (회원 가입 및 탈퇴)
1. 이용자는 당사가 정한 가입 양식에 따라 회원정보를 기입한 후 본 약관에 동의함으로써 회원 가입을 신청합니다.
2. 당사는 제1항과 같이 회원으로 가입할 것을 신청한 이용자 중 다음 각 호에 해당하지 않는 한 회원으로 등록합니다:
   - 가입신청자가 본 약관에 의하여 이전에 회원자격을 상실한 적이 있는 경우
   - 등록 내용에 허위, 기재누락, 오기가 있는 경우
   - 기타 회원으로 등록하는 것이 서비스 운영상 적절하지 않다고 판단되는 경우
3. 회원은 언제든지 당사에 탈퇴를 요청할 수 있으며, 당사는 즉시 회원탈퇴를 처리합니다.

제 8 조 (개인정보보호)
1. 당사는 이용자의 개인정보 보호를 위해 최선을 다합니다.
2. 이용자의 개인정보 보호에 관한 상세한 내용은 '개인정보 처리방침'에서 규정합니다.
''';
  }

  String _getChapter4Content() {
    return '''
제 9 조 (서비스 제한 및 정지)
1. 당사는 다음 각 호에 해당하는 경우 서비스 이용을 제한하거나 정지할 수 있습니다:
   - 회원이 본 약관의 의무를 위반하거나 서비스의 정상적인 운영을 방해한 경우
   - 서비스용 설비의 점검, 보수 또는 공사로 인해 부득이한 경우
   - 전기통신사업법에 규정된 기간통신사업자가 전기통신 서비스를 중지했을 경우
   - 국가비상사태, 천재지변 등 불가항력적 사유가 있는 경우

제 10 조 (면책조항)
1. 당사는 천재지변, 전쟁, 기간통신사업자의 서비스 중지 등 불가항력적인 사유로 인한 서비스 중단에 대해 책임을 지지 않습니다.
2. 당사는 이용자의 귀책사유로 인한 서비스 이용의 장애에 대해 책임을 지지 않습니다.
3. 당사는 이용자가 서비스를 통해 얻은 정보 또는 자료 등으로 인해 발생한 손해에 대해 책임을 지지 않습니다.
''';
  }

  String _getChapter5Content() {
    return '''
제 11 조 (분쟁해결)
1. 당사와 이용자 간에 발생한 분쟁은 원만한 합의에 의해 해결함을 원칙으로 합니다.
2. 당사와 이용자 간에 발생한 분쟁에 관한 소송은 민사소송법상의 관할법원에 제기합니다.

제 12 조 (기타)
1. 본 약관에 명시되지 않은 사항은 관련 법령 및 당사가 정한 서비스 운영정책에 따릅니다.
2. 본 약관은 2025년 1월 1일부터 시행합니다.
''';
  }
}
