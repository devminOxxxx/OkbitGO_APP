import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_provider.dart';
import '../services/user_migration_service.dart';

class DebugUserInfoScreen extends StatefulWidget {
  const DebugUserInfoScreen({Key? key}) : super(key: key);

  @override
  State<DebugUserInfoScreen> createState() => _DebugUserInfoScreenState();
}

class _DebugUserInfoScreenState extends State<DebugUserInfoScreen> {
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _studentNumberController =
      TextEditingController();

  Map<String, dynamic>? _rawUserData;
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadRawUserData();
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _classController.dispose();
    _studentNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadRawUserData() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _message = '로그인된 사용자가 없습니다.';
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        _rawUserData = doc.data();

        // 텍스트 필드에 현재 값 설정
        _gradeController.text = _rawUserData?['grade']?.toString() ?? '';
        _classController.text = _rawUserData?['classNumber']?.toString() ??
            _rawUserData?['class']?.toString() ??
            '';
        _studentNumberController.text =
            _rawUserData?['studentNumber']?.toString() ??
                _rawUserData?['number']?.toString() ??
                '';

        setState(() {
          _message = '사용자 데이터를 불러왔습니다.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _message = '사용자 문서가 존재하지 않습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = '오류 발생: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _runMigration() async {
    setState(() {
      _isLoading = true;
      _message = '마이그레이션을 실행하는 중...';
    });

    try {
      final migrationService = UserMigrationService();
      await migrationService.migrateUserFields();

      // 마이그레이션 후 데이터 다시 로드
      await _loadRawUserData();

      setState(() {
        _message = '마이그레이션이 완료되었습니다.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = '마이그레이션 오류: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserInfo() async {
    setState(() {
      _isLoading = true;
      _message = '사용자 정보를 업데이트하는 중...';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _message = '로그인된 사용자가 없습니다.';
          _isLoading = false;
        });
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'grade': _gradeController.text.trim(),
        'classNumber': _classController.text.trim(),
        'studentNumber': _studentNumberController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // UserProvider 새로고침
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshUser();

      await _loadRawUserData();

      setState(() {
        _message = '사용자 정보가 업데이트되었습니다.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = '업데이트 오류: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 정보 디버그'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _message!,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            const Text(
              '원본 Firebase 데이터:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _rawUserData?.toString() ?? '데이터 없음',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '사용자 정보 수정:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: '학년',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _classController,
              decoration: const InputDecoration(
                labelText: '반',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _studentNumberController,
              decoration: const InputDecoration(
                labelText: '학번',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runMigration,
                    child: const Text('마이그레이션 실행'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateUserInfo,
                    child: const Text('정보 업데이트'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loadRawUserData,
                child: const Text('데이터 새로고침'),
              ),
            ),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
