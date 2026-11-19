import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class CustomerServiceScreen extends StatefulWidget {
  const CustomerServiceScreen({Key? key}) : super(key: key);

  @override
  State<CustomerServiceScreen> createState() => _CustomerServiceScreenState();
}

class _CustomerServiceScreenState extends State<CustomerServiceScreen> {
  // 문의 유형
  final List<String> _inquiryTypes = [
    '앱 오류 신고',
    '기능 개선 요청',
    '계정 관련 문의',
    '기타 문의',
  ];
  String _selectedInquiryType = '앱 오류 신고';

  // 컨트롤러
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(text: 'student@example.com');

  // 첨부 파일
  final List<String> _attachments = [];

  // 폼 키
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          kCustomerServiceTitle,
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: kSpacing),
              _buildInquiryForm(),
              const SizedBox(height: kSpacing),
              _buildFAQSection(),
              const SizedBox(height: kSpacing),
              _buildContactInfo(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
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
                '고객 센터 안내',
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
            '앱 사용 중 불편한 점이나 개선 사항이 있으시면 문의해 주세요. 빠른 시일 내에 답변 드리겠습니다. 문의 내용은 서비스 개선에 소중하게 활용됩니다.',
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

  Widget _buildInquiryForm() {
    return Container(
      padding: const EdgeInsets.all(kSpacing),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '문의하기',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: kSpacing),
          _buildDropdown(
            label: '문의 유형',
            value: _selectedInquiryType,
            items: _inquiryTypes,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedInquiryType = value;
                });
              }
            },
          ),
          const SizedBox(height: kSpacing),
          _buildTextField(
            controller: _titleController,
            label: '제목',
            hintText: '문의 제목을 입력하세요',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '제목을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: kSpacing),
          _buildTextField(
            controller: _contentController,
            label: '내용',
            hintText: '문의 내용을 자세히 입력해주세요',
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '내용을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: kSpacing),
          _buildTextField(
            controller: _emailController,
            label: '답변 받을 이메일',
            hintText: '이메일 주소를 입력하세요',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이메일을 입력해주세요';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return '유효한 이메일 주소를 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: kSpacing),
          _buildAttachmentSection(),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: kBorderColor,
            borderRadius: BorderRadius.circular(kBorderRadius / 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
              dropdownColor: kSurfaceColor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: kBorderColor,
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadius / 2),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '첨부 파일',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: kBorderColor,
                  borderRadius: BorderRadius.circular(kBorderRadius / 2),
                ),
                child: Text(
                  _attachments.isEmpty
                      ? '파일을 첨부해주세요'
                      : '${_attachments.length}개의 파일 첨부됨',
                  style: TextStyle(
                    color:
                        _attachments.isEmpty ? Colors.grey[600] : Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _addAttachment,
              borderRadius: BorderRadius.circular(kBorderRadius / 2),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kAccentColor,
                  borderRadius: BorderRadius.circular(kBorderRadius / 2),
                ),
                child: const Icon(
                  Icons.attach_file,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _attachments.map((attachment) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kBorderColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      attachment,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _attachments.remove(attachment);
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildFAQSection() {
    return Container(
      padding: const EdgeInsets.all(kSpacing),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '자주 묻는 질문',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: kSpacing),
          _buildFAQItem(
            question: '비밀번호를 잊어버렸어요.',
            answer: '로그인 화면에서 "비밀번호 찾기"를 통해 이메일로 비밀번호 재설정 링크를 받을 수 있습니다.',
          ),
          const Divider(color: kBorderColor, height: 32),
          _buildFAQItem(
            question: '앱에 오류가 있어요.',
            answer:
                '앱을 최신 버전으로 업데이트하고 다시 시도해보세요. 문제가 지속되면 위의 문의하기 양식을 통해 자세한 오류 내용을 알려주세요.',
          ),
          const Divider(color: kBorderColor, height: 32),
          _buildFAQItem(
            question: '시간표가 정확하지 않아요.',
            answer:
                '시간표는 학교 서버에서 제공받는 정보를 기반으로 합니다. 변경된 시간표가 반영되지 않았다면 위의 문의하기 양식을 통해 알려주세요.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.grey,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Text(
              answer,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(kSpacing),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '연락처 정보',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: kSpacing),
          _buildContactItem(
            icon: Icons.email_outlined,
            title: '이메일',
            content: 'support@okbitgo.com',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.phone_outlined,
            title: '전화번호',
            content: '02-123-4567 (평일 09:00-18:00)',
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            icon: Icons.location_on_outlined,
            title: '주소',
            content: '서울특별시 강남구 테헤란로 123 옥빛빌딩 4층',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(kSpacing),
      decoration: const BoxDecoration(
        color: kSurfaceColor,
        border: Border(
          top: BorderSide(
            color: kBorderColor,
            width: 1,
          ),
        ),
      ),
      child: ElevatedButton(
        onPressed: _submitInquiry,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccentColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kBorderRadius / 2),
          ),
        ),
        child: const Text(
          '문의하기',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _addAttachment() {
    // 실제 앱에서는 파일 선택 기능 구현
    setState(() {
      _attachments.add('screenshot_${_attachments.length + 1}.png');
    });
  }

  void _submitInquiry() {
    if (_formKey.currentState!.validate()) {
      // 문의 제출 로직 구현
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('문의가 접수되었습니다. 빠른 시일 내에 답변 드리겠습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      // 폼 초기화
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _attachments.clear();
      });
    }
  }
}
