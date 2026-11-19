import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          '${user.name}님의 정보',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 이미지 섹션
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 기본 정보 항목들
            _buildInfoItem(context, '이름', user.name, Icons.chevron_right),
            _buildInfoItem(context, '영문이름', '없음', Icons.chevron_right),
            _buildInfoItem(context, '생년월일', '2007.04.16', Icons.chevron_right),
            _buildInfoItem(
                context, '휴대폰 번호', '010-2189-5275', Icons.chevron_right),
            _buildInfoItem(
                context, '이메일 주소', user.email ?? '없음', Icons.chevron_right),
            _buildInfoItem(context, '회사', '없음', Icons.chevron_right),

            if (user.grade != null && user.classNumber != null)
              _buildInfoItem(
                  context,
                  '학년/반/번호',
                  '${user.grade}학년 ${user.classNumber}반 ${user.studentNumber ?? ""}',
                  Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context, String title, String value, IconData? icon) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: TextStyle(
                    color: value == '없음' ? Colors.grey : Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 10),
                Icon(icon, color: Colors.grey, size: 16),
              ],
            ],
          ),
        ),
        const Divider(
          height: 1,
          color: Colors.grey,
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }
}
