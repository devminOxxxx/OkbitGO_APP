import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          kPrivacyPolicyTitle,
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
            _buildPolicySection(
              title: '1. 수집하는 개인정보 항목',
              content: _getSection1Content(),
            ),
            const SizedBox(height: kSpacing),
            _buildPolicySection(
              title: '2. 개인정보의 수집 및 이용목적',
              content: _getSection2Content(),
            ),
            const SizedBox(height: kSpacing),
            _buildPolicySection(
              title: '3. 개인정보의 보유 및 이용기간',
              content: _getSection3Content(),
            ),
            const SizedBox(height: kSpacing),
            _buildPolicySection(
              title: '4. 개인정보의 파기절차 및 방법',
              content: _getSection4Content(),
            ),
            const SizedBox(height: kSpacing),
            _buildPolicySection(
              title: '5. 개인정보 보호책임자',
              content: _getSection5Content(),
            ),
            const SizedBox(height: kSpacing),
            _buildPolicySection(
              title: '6. 이용자 및 법정대리인의 권리와 행사방법',
              content: _getSection6Content(),
            ),
            const SizedBox(height: kSpacing),
            _buildPolicySection(
              title: '7. 개인정보 자동 수집 장치의 설치/운영 및 거부에 관한 사항',
              content: _getSection7Content(),
            ),
            const SizedBox(height: kSpacing * 2),
            Center(
              child: Text(
                '시행일: 2025년 1월 1일',
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
                Icons.security_outlined,
                color: kAccentColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '개인정보 처리방침 안내',
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
            '옥빛GO!는 이용자의 개인정보를 중요시하며, 「개인정보 보호법」을 준수하기 위하여 노력하고 있습니다. 본 개인정보 처리방침은 옥빛GO! 서비스를 이용하는 이용자의 개인정보 보호에 관한 정책을 설명합니다.',
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

  Widget _buildPolicySection({
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

  String _getSection1Content() {
    return '''
옥빛GO!는 회원가입 및 서비스 이용 과정에서 다음과 같은 개인정보를 수집합니다:

필수항목:
- 이름, 학년, 반, 번호
- 이메일 주소
- 비밀번호
- 기기 정보 (기기 식별자, 운영체제 버전 등)

선택항목:
- 프로필 이미지
- 알림 설정 정보
''';
  }

  String _getSection2Content() {
    return '''
옥빛GO!는 수집한 개인정보를 다음의 목적을 위해 활용합니다:

- 회원 관리: 회원제 서비스 이용에 따른 본인확인, 개인 식별, 불량회원의 부정 이용 방지와 비인가 사용 방지, 가입 의사 확인, 연령확인, 불만처리 등 민원처리, 고지사항 전달
- 서비스 제공: 학교 시간표, 급식 정보, 학사 일정 등 맞춤형 서비스 제공
- 서비스 개선: 신규 서비스 개발 및 기존 서비스 개선, 인구통계학적 특성에 따른 서비스 제공 및 광고 게재, 접속 빈도 파악, 서비스 이용에 대한 통계
''';
  }

  String _getSection3Content() {
    return '''
옥빛GO!는 이용자의 개인정보를 원칙적으로 개인정보의 수집 및 이용목적이 달성되면 지체 없이 파기합니다. 단, 다음의 정보에 대해서는 아래의 이유로 명시한 기간 동안 보존합니다:

- 회원 정보: 회원 탈퇴 시까지 (단, 관계 법령에 따라 보존할 필요가 있는 경우 해당 법령에서 정한 기간 동안 보존)
- 접속 로그: 3개월 (통신비밀보호법)
- 결제 기록: 5년 (전자상거래 등에서의 소비자 보호에 관한 법률)
''';
  }

  String _getSection4Content() {
    return '''
옥빛GO!는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체없이 해당 개인정보를 파기합니다. 파기의 절차, 기한 및 방법은 다음과 같습니다:

- 파기절차: 이용자가 입력한 정보는 목적 달성 후 별도의 DB에 옮겨져 내부 방침 및 기타 관련 법령에 따라 일정기간 저장된 후 혹은 즉시 파기됩니다.
- 파기방법: 전자적 파일 형태의 정보는 기록을 재생할 수 없는 기술적 방법을 사용하여 삭제하며, 종이에 출력된 개인정보는 분쇄기로 분쇄하거나 소각을 통하여 파기합니다.
''';
  }

  String _getSection5Content() {
    return '''
옥빛GO!는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 이용자의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다:

- 개인정보 보호책임자
  • 이름: 홍길동
  • 직위: 개인정보 보호팀장
  • 연락처: privacy@okbitgo.com, 02-123-4567

이용자는 옥빛GO! 서비스를 이용하면서 발생한 모든 개인정보 보호 관련 문의, 불만처리, 피해구제 등에 관한 사항을 개인정보 보호책임자에게 문의하실 수 있습니다. 옥빛GO!는 이용자의 문의에 대해 지체 없이 답변 및 처리해드릴 것입니다.
''';
  }

  String _getSection6Content() {
    return '''
이용자 및 법정대리인은 언제든지 등록되어 있는 자신 혹은 당해 만 14세 미만 아동의 개인정보를 조회하거나 수정할 수 있으며, 옥빛GO!의 개인정보의 처리에 동의하지 않는 경우 동의를 거부하거나 가입해지(회원탈퇴)를 요청하실 수 있습니다. 다만, 그러한 경우 서비스의 일부 또는 전부 이용이 어려울 수 있습니다.

이용자가 개인정보의 오류에 대한 정정을 요청하신 경우에는 정정을 완료하기 전까지 당해 개인정보를 이용 또는 제공하지 않습니다. 또한 잘못된 개인정보를 제3자에게 이미 제공한 경우에는 정정 처리결과를 제3자에게 지체 없이 통지하여 정정이 이루어지도록 하겠습니다.

옥빛GO!는 이용자 혹은 법정 대리인의 요청에 의해 해지 또는 삭제된 개인정보는 "3. 개인정보의 보유 및 이용기간"에 명시된 바에 따라 처리하고 그 외의 용도로 열람 또는 이용할 수 없도록 처리하고 있습니다.
''';
  }

  String _getSection7Content() {
    return '''
옥빛GO!는 이용자에게 개별적인 맞춤서비스를 제공하기 위해 이용정보를 저장하고 수시로 불러오는 '쿠키(cookie)'를 사용합니다.

쿠키는 웹사이트를 운영하는데 이용되는 서버(http)가 이용자의 컴퓨터 브라우저에게 보내는 소량의 정보이며 이용자들의 PC 컴퓨터내의 하드디스크에 저장되기도 합니다.

이용자는 쿠키 설치에 대한 선택권을 가지고 있습니다. 따라서, 이용자는 웹브라우저에서 옵션을 설정함으로써 모든 쿠키를 허용하거나, 쿠키가 저장될 때마다 확인을 거치거나, 아니면 모든 쿠키의 저장을 거부할 수도 있습니다.

다만, 쿠키의 저장을 거부할 경우에는 로그인이 필요한 옥빛GO!의 일부 서비스는 이용에 어려움이 있을 수 있습니다.
''';
  }
}
