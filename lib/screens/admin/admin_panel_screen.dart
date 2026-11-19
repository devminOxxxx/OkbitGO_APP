import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../models/notification_model.dart';
import '../../services/user_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // 사용자 검색
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 사용자 카테고리
  int _selectedUserCategory = 0; // 0: 전체, 1: 차단됨, 2: 삭제됨

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // 현재 사용자가 관리자 권한이 있으면 자동으로 로그인 상태로 설정
      if (userProvider.user?.isAdmin == true) {
        await adminProvider.autoLoginAsAdmin(
          userProvider.user!.name,
          userProvider.user!.email,
        );
      }

      await adminProvider.refreshDashboard();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 파일 선택 메서드
  Future<String?> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.single.name;
      }
      return null;
    } catch (e) {
      // FilePicker가 지원되지 않는 경우 더미 파일명 반환
      print('FilePicker 오류: $e');
      return 'example_file.pdf';
    }
  }

  // 한국어 월 이름 반환 함수
  String _getKoreanMonth(int month) {
    const months = [
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월'
    ];
    return months[month - 1];
  }

  // 한국어 요일 이름 반환 함수
  String _getKoreanWeekday(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[(weekday - 1) % 7];
  }

  // 날짜를 한국어로 포맷팅하는 함수
  String _formatDateTimeKorean(DateTime dateTime) {
    return '${dateTime.year}년 ${_getKoreanMonth(dateTime.month)} ${dateTime.day}일 (${_getKoreanWeekday(dateTime.weekday)}) ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // 날짜/시간 선택 다이얼로그
  void _showDateTimePicker(DateTime initialDate, TimeOfDay initialTime,
      Function(DateTime) onDateTimeChanged) {
    final initialDateTime = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
      initialTime.hour,
      initialTime.minute,
    );
    DateTime tempDateTime = initialDateTime;

    // 현재 시간 기준으로 최소 날짜 설정
    final DateTime now = DateTime.now();
    final DateTime minimumDate = DateTime(now.year, now.month, now.day);

    // 초기 날짜가 최소 날짜보다 이전인 경우 초기 날짜를 최소 날짜로 설정
    final DateTime safeInitialDateTime =
        initialDateTime.isBefore(minimumDate) ? minimumDate : initialDateTime;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 300,
          color: kBackgroundColor,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: kSurfaceColor,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('취소'),
                    ),
                    const Text(
                      '예약 날짜 및 시간',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        onDateTimeChanged(tempDateTime);
                        Navigator.pop(context);
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.orange,
                      onPrimary: Colors.white,
                      surface: Color(0xFF1E1E1E),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      primaryColor: Colors.orange,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    child: Localizations(
                      locale: const Locale('ko', 'KR'),
                      delegates: const [
                        GlobalMaterialLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                      ],
                      child: CupertinoDatePicker(
                        initialDateTime: safeInitialDateTime,
                        minimumDate: minimumDate,
                        mode: CupertinoDatePickerMode.dateAndTime,
                        use24hFormat: true,
                        onDateTimeChanged: (DateTime dateTime) {
                          tempDateTime = dateTime;
                        },
                        backgroundColor: kSurfaceColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // 관리자 권한이 없으면 접근 차단
    if (userProvider.user?.isAdmin != true) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Colors.red.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              const Text(
                '관리자 권한이 필요합니다',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '이 기능은 관리자만 사용할 수 있습니다.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  '돌아가기',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          '관리자 패널',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      adminProvider.adminUsername ?? '관리자',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildNotificationPage(),
          _buildUsersPage(),
          _buildLogsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: kSurfaceColor,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: '알림',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '사용자',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: '로그',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPage() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: kSurfaceColor,
            child: const TabBar(
              indicatorColor: Colors.blue,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: '알림 보내기'),
                Tab(text: '알림 예약'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSendNotificationTab(),
                _buildScheduleNotificationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 알림 보내기 탭
  Widget _buildSendNotificationTab() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final senderNameController = TextEditingController();
    final departmentController = TextEditingController();
    List<String> selectedRecipients = ['전체'];
    String? selectedFileName;

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '알림 보내기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 알림 제목
              const Text(
                '알림 제목',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '알림 제목을 입력하세요',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: kSurfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),

              // 알림 내용
              const Text(
                '알림 내용',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '알림 내용을 입력하세요',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: kSurfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),

              // 보내는 부서
              const Text(
                '보내는 부서',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '부서를 선택하세요',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDepartmentChip(
                            '옥빛고 교무실', departmentController, setState),
                        _buildDepartmentChip(
                            '옥빛고 학생회', departmentController, setState),
                        _buildDepartmentChip(
                            '옥빛GO 주인', departmentController, setState),
                        _buildDepartmentChip(
                            '기타', departmentController, setState),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 알림 받는 사용자 선택
              const Text(
                '알림 받는 사용자',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '대상을 선택하세요 (중복 선택 가능)',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildRecipientChip('전체', selectedRecipients, setState),
                        _buildRecipientChip(
                            '1학년', selectedRecipients, setState),
                        _buildRecipientChip(
                            '2학년', selectedRecipients, setState),
                        _buildRecipientChip(
                            '3학년', selectedRecipients, setState),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 보내는 사람 이름 (선택사항)
              const Text(
                '보내는 사람 이름 (선택사항)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: senderNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '보내는 사람 이름을 입력하세요',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: kSurfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),

              // 파일 첨부 (선택사항)
              const Text(
                '파일 첨부 (선택사항)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.grey[700]!, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.attach_file, color: Colors.grey[400], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      selectedFileName ?? '파일을 선택하세요',
                      style: TextStyle(
                        color: selectedFileName != null
                            ? Colors.white
                            : Colors.grey[400],
                        fontWeight: selectedFileName != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              // 파일 선택 기능 구현
                              final result = await _pickFile();
                              if (result != null) {
                                setState(() {
                                  selectedFileName = result;
                                });
                                _showSuccessSnackBar('파일이 선택되었습니다: $result');
                              }
                            } catch (e) {
                              _showErrorSnackBar('파일 선택 중 오류가 발생했습니다: $e');
                            }
                          },
                          icon: const Icon(Icons.folder_open, size: 16),
                          label: const Text('파일 선택'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (selectedFileName != null) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                selectedFileName = null;
                              });
                              _showInfoSnackBar('파일 선택이 취소되었습니다.');
                            },
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('취소'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 발송 버튼
              SizedBox(
                width: double.infinity,
                child: Consumer<AdminProvider>(
                  builder: (context, adminProvider, child) {
                    return ElevatedButton.icon(
                      onPressed: adminProvider.isLoading
                          ? null
                          : () async {
                              if (titleController.text.trim().isEmpty ||
                                  contentController.text.trim().isEmpty) {
                                _showErrorSnackBar('제목과 내용을 모두 입력해주세요.');
                                return;
                              }

                              if (departmentController.text.trim().isEmpty) {
                                _showErrorSnackBar('보내는 부서를 입력해주세요.');
                                return;
                              }

                              if (selectedRecipients.isEmpty) {
                                _showErrorSnackBar('알림 받는 사용자를 선택해주세요.');
                                return;
                              }

                              try {
                                // 여러 수신자 그룹에 대해 순차적으로 알림 발송
                                bool allSuccess = true;
                                for (String recipient in selectedRecipients) {
                                  final success =
                                      await adminProvider.sendNotification(
                                    title: titleController.text.trim(),
                                    message: contentController.text.trim(),
                                    target: recipient,
                                    department:
                                        departmentController.text.trim(),
                                    senderName:
                                        senderNameController.text.trim(),
                                    fileName: selectedFileName,
                                    fileUrl: selectedFileName != null
                                        ? 'https://example.com/files/$selectedFileName'
                                        : null,
                                  );

                                  if (!success) {
                                    allSuccess = false;
                                  }
                                }

                                if (allSuccess) {
                                  _showSuccessSnackBar('알림이 성공적으로 발송되었습니다.');

                                  // 폼 초기화
                                  titleController.clear();
                                  contentController.clear();
                                  departmentController.clear();
                                  senderNameController.clear();
                                  setState(() {
                                    selectedRecipients = ['전체'];
                                  });
                                } else {
                                  _showErrorSnackBar('일부 알림 발송에 실패했습니다.');
                                }
                              } catch (e) {
                                _showErrorSnackBar('알림 발송 중 오류가 발생했습니다: $e');
                              }
                            },
                      icon: adminProvider.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Container(
                        width: double.infinity,
                        child: Text(
                          adminProvider.isLoading ? '발송 중...' : '알림 발송',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 수신자 선택 칩 위젯
  Widget _buildRecipientChip(
      String label, List<String> selectedRecipients, StateSetter setState) {
    final isSelected = selectedRecipients.contains(label);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (label == '전체') {
            // 전체 선택 시 다른 모든 선택 해제
            if (selected) {
              selectedRecipients.clear();
              selectedRecipients.add('전체');
            } else {
              selectedRecipients.remove('전체');
            }
          } else {
            // 개별 학년 선택 시 전체 선택 해제
            if (selected) {
              selectedRecipients.remove('전체');
              selectedRecipients.add(label);
            } else {
              selectedRecipients.remove(label);
              // 아무것도 선택되지 않으면 전체 선택
              if (selectedRecipients.isEmpty) {
                selectedRecipients.add('전체');
              }
            }
          }
        });
      },
      backgroundColor: kSurfaceColor,
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.grey[600]!,
        width: 1,
      ),
    );
  }

  // 부서 선택 칩 위젯
  Widget _buildDepartmentChip(String label,
      TextEditingController departmentController, StateSetter setState) {
    final isSelected = departmentController.text == label;
    final isOther = label == '기타';
    final isOtherSelected = isOther &&
        departmentController.text.isNotEmpty &&
        !['옥빛고 교무실', '옥빛고 학생회', '옥빛GO 주인'].contains(departmentController.text);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color:
              (isSelected || isOtherSelected) ? Colors.white : Colors.grey[400],
          fontWeight: (isSelected || isOtherSelected)
              ? FontWeight.w600
              : FontWeight.normal,
        ),
      ),
      selected: isSelected || isOtherSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            if (isOther) {
              // 기타 선택 시 텍스트 입력 다이얼로그 표시
              _showOtherDepartmentDialog(departmentController, setState);
            } else {
              departmentController.text = label;
            }
          } else {
            departmentController.clear();
          }
        });
      },
      backgroundColor: kSurfaceColor,
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color:
            (isSelected || isOtherSelected) ? Colors.blue : Colors.grey[600]!,
        width: 1,
      ),
    );
  }

  // 기타 부서 입력 다이얼로그
  void _showOtherDepartmentDialog(
      TextEditingController departmentController, StateSetter setState) {
    final otherController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('기타 부서 입력', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: otherController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '부서명을 입력하세요',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (otherController.text.trim().isNotEmpty) {
                setState(() {
                  departmentController.text = otherController.text.trim();
                });
                Navigator.pop(context);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleNotificationTab() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final senderNameController = TextEditingController();
    final departmentController = TextEditingController();
    List<String> selectedRecipients = ['전체'];
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    return StatefulBuilder(
      builder: (context, setState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '알림 예약',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 알림 제목
              const Text(
                '알림 제목',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '알림 제목을 입력하세요',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: kSurfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),

              // 알림 내용
              const Text(
                '알림 내용',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '알림 내용을 입력하세요',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: kSurfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),

              // 보내는 부서
              const Text(
                '보내는 부서',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '부서를 선택하세요',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDepartmentChip(
                            '옥빛고 교무실', departmentController, setState),
                        _buildDepartmentChip(
                            '옥빛고 학생회', departmentController, setState),
                        _buildDepartmentChip(
                            '옥빛GO 주인', departmentController, setState),
                        _buildDepartmentChip(
                            '기타', departmentController, setState),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 알림 받는 사용자 선택
              const Text(
                '알림 받는 사용자',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '대상을 선택하세요 (중복 선택 가능)',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildRecipientChip('전체', selectedRecipients, setState),
                        _buildRecipientChip(
                            '1학년', selectedRecipients, setState),
                        _buildRecipientChip(
                            '2학년', selectedRecipients, setState),
                        _buildRecipientChip(
                            '3학년', selectedRecipients, setState),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 보내는 사람 이름 (선택사항)
              const Text(
                '보내는 사람 이름 (선택사항)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: senderNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '보내는 사람 이름을 입력하세요',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: kSurfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),

              // 예약 날짜 및 시간
              const Text(
                '예약 날짜 및 시간',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () =>
                    _showDateTimePicker(selectedDate, selectedTime, (dateTime) {
                  setState(() {
                    selectedDate =
                        DateTime(dateTime.year, dateTime.month, dateTime.day);
                    selectedTime =
                        TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
                  });
                }),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[400]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '예약 일시',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTimeKorean(DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              )),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 예약 버튼
              SizedBox(
                width: double.infinity,
                child: Consumer<AdminProvider>(
                  builder: (context, adminProvider, child) {
                    return ElevatedButton.icon(
                      onPressed: adminProvider.isLoading
                          ? null
                          : () async {
                              if (titleController.text.trim().isEmpty ||
                                  contentController.text.trim().isEmpty) {
                                _showErrorSnackBar('제목과 내용을 모두 입력해주세요.');
                                return;
                              }

                              if (departmentController.text.trim().isEmpty) {
                                _showErrorSnackBar('보내는 부서를 입력해주세요.');
                                return;
                              }

                              final scheduledDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );

                              if (scheduledDateTime.isBefore(DateTime.now())) {
                                _showErrorSnackBar('예약 시간은 현재 시간보다 이후여야 합니다.');
                                return;
                              }

                              final success =
                                  await adminProvider.scheduleNotification(
                                title: titleController.text.trim(),
                                message: contentController.text.trim(),
                                scheduledAt: scheduledDateTime,
                                type: 'admin_announcement',
                              );

                              if (success) {
                                titleController.clear();
                                contentController.clear();
                                senderNameController.clear();
                                departmentController.clear();
                                setState(() {
                                  selectedRecipients = ['전체'];
                                  selectedDate = DateTime.now();
                                  selectedTime = TimeOfDay.now();
                                });
                                _showSuccessSnackBar('알림이 예약되었습니다.');
                              } else {
                                _showErrorSnackBar('알림 예약에 실패했습니다.');
                              }
                            },
                      icon: adminProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.schedule),
                      label: const Text('알림 예약'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersPage() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목과 검색
              Row(
                children: [
                  const Text(
                    '사용자 관리',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // 총 사용자 수
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getAllUsers(),
                    builder: (context, snapshot) {
                      final totalUsers = snapshot.data?.length ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '총 ${totalUsers}명',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 심플한 검색창
              Container(
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: '사용자 이름 또는 이메일 검색...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 사용자 카테고리 탭
              Container(
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCategoryTab('전체', 0),
                    ),
                    Expanded(
                      child: _buildCategoryTab('차단됨', 1),
                    ),
                    Expanded(
                      child: _buildCategoryTab('삭제됨', 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 사용자 목록
              _buildUsersList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryTab(String title, int index) {
    final isSelected = _selectedUserCategory == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedUserCategory = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[400],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                '사용자 데이터를 불러오는 중 오류가 발생했습니다.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final allUsers = snapshot.data ?? [];
        final filteredUsers = _getFilteredUsers(allUsers);

        if (filteredUsers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _selectedUserCategory == 0
                    ? '등록된 사용자가 없습니다.'
                    : _selectedUserCategory == 1
                        ? '차단된 사용자가 없습니다.'
                        : '삭제된 사용자가 없습니다.',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredUsers.length,
            separatorBuilder: (context, index) =>
                const Divider(color: Colors.grey),
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildUserItem(user);
            },
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredUsers(
      List<Map<String, dynamic>> users) {
    // 카테고리 필터링
    List<Map<String, dynamic>> categoryFiltered;
    switch (_selectedUserCategory) {
      case 1: // 차단됨
        categoryFiltered =
            users.where((user) => user['status'] == 'blocked').toList();
        break;
      case 2: // 삭제됨
        categoryFiltered =
            users.where((user) => user['status'] == 'deleted').toList();
        break;
      default: // 전체
        categoryFiltered =
            users.where((user) => user['status'] == 'active').toList();
    }

    // 검색 필터링
    if (_searchQuery.isEmpty) {
      return categoryFiltered;
    }

    return categoryFiltered.where((user) {
      final name = user['name']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[700],
        child: Text(
          user['name']?.isNotEmpty == true
              ? user['name'][0].toUpperCase()
              : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        user['name'] ?? '이름 없음',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        user['email'] ?? '이메일 없음',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상태 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(user['status']).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(user['status']),
              style: TextStyle(
                color: _getStatusColor(user['status']),
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 관리 메뉴
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'view':
                  _showUserDetails(user);
                  break;
                case 'edit':
                  _editUser(user);
                  break;
                case 'block':
                  _blockUser(user);
                  break;
                case 'unblock':
                  _unblockUser(user);
                  break;
                case 'delete':
                  _deleteUser(user);
                  break;
                case 'restore':
                  _restoreUser(user);
                  break;
              }
            },
            itemBuilder: (context) {
              List<PopupMenuItem<String>> items = [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 16),
                      SizedBox(width: 8),
                      Text('상세 정보'),
                    ],
                  ),
                ),
              ];

              if (user['status'] == 'active') {
                items.addAll([
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('수정'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('차단'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('삭제'),
                      ],
                    ),
                  ),
                ]);
              } else if (user['status'] == 'blocked') {
                items.add(
                  const PopupMenuItem(
                    value: 'unblock',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text('차단 해제'),
                      ],
                    ),
                  ),
                );
              } else if (user['status'] == 'deleted') {
                items.add(
                  const PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        Icon(Icons.restore, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('복구'),
                      ],
                    ),
                  ),
                );
              }

              return items;
            },
          ),
        ],
      ),
      onTap: () => _showUserDetails(user),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'blocked':
        return Colors.red;
      case 'deleted':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'active':
        return '활성';
      case 'blocked':
        return '차단됨';
      case 'deleted':
        return '삭제됨';
      default:
        return '알 수 없음';
    }
  }

  Widget _buildLogsPage() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color: kSurfaceColor,
                child: const TabBar(
                  indicatorColor: Colors.blue,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: '사용자 로그'),
                    Tab(text: '관리자 로그'),
                    Tab(text: '알림 로그'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildLogList(adminProvider
                        .getRecentActivities()
                        .where((log) =>
                            log.action.contains('USER_') ||
                            log.action == 'LOGIN' ||
                            log.action == 'LOGOUT')
                        .toList()),
                    _buildLogList(adminProvider
                        .getRecentActivities()
                        .where((log) =>
                            log.action.contains('ADMIN_') ||
                            log.action.contains('SEND_'))
                        .toList()),
                    _buildLogList(adminProvider
                        .getRecentActivities()
                        .where((log) =>
                            log.action.contains('NOTIFICATION_') ||
                            log.action.contains('SEND_'))
                        .toList()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogList(List<dynamic> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          '로그가 없습니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (context, index) => const Divider(color: Colors.grey),
      itemBuilder: (context, index) {
        final log = logs[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getLogColor(log.action).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getLogIcon(log.action),
              color: _getLogColor(log.action),
              size: 16,
            ),
          ),
          title: Text(
            log.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            _formatTime(log.timestamp),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  // 헬퍼 메서드들
  Future<List<Map<String, dynamic>>> _getAllUsers() async {
    try {
      final userService = UserService();
      final allUsers = await userService.getAllUsers();
      final blockedUsers = await userService.getBlockedUsers();
      final deletedUsers = await userService.getDeletedUsers();

      return allUsers.map((user) {
        // 사용자 상태 확인
        String status = 'active';
        if (blockedUsers.any((blocked) => blocked.id == user.id)) {
          status = 'blocked';
        } else if (deletedUsers.any((deleted) => deleted.id == user.id)) {
          status = 'deleted';
        }

        return {
          'id': user.id,
          'name': user.name,
          'email':
              user.email.isNotEmpty ? user.email : '${user.name}@okbit.com',
          'grade': user.grade?.isNotEmpty == true &&
                  user.classNumber?.isNotEmpty == true
              ? '${user.grade}학년 ${user.classNumber}반'
              : '정보 없음',
          'status': status,
          'joinDate': _formatDate(user.createdAt),
          'lastLogin': _getLastLoginTime(user.updatedAt),
          'loginCount': _getRandomLoginCount(),
          'isAdmin': user.isAdmin,
        };
      }).toList();
    } catch (e) {
      debugPrint('사용자 데이터 로딩 오류: $e');
      return [];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _getLastLoginTime(DateTime updatedAt) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }

  int _getRandomLoginCount() {
    return (DateTime.now().millisecondsSinceEpoch % 100) + 1;
  }

  IconData _getLogIcon(String action) {
    switch (action.toUpperCase()) {
      case 'LOGIN':
        return Icons.login;
      case 'LOGOUT':
        return Icons.logout;
      case 'NOTIFICATION_SENT':
      case 'SEND_NOTIFICATION':
        return Icons.send;
      case 'USER_REGISTERED':
        return Icons.person_add;
      case 'USER_BLOCKED':
        return Icons.block;
      case 'USER_DELETED':
        return Icons.delete;
      case 'USER_RESTORED':
        return Icons.restore;
      case 'SCREEN_VIEW':
        return Icons.visibility;
      case 'BUTTON_CLICK':
        return Icons.touch_app;
      default:
        return Icons.info;
    }
  }

  Color _getLogColor(String action) {
    switch (action.toUpperCase()) {
      case 'LOGIN':
        return Colors.green;
      case 'LOGOUT':
        return Colors.orange;
      case 'NOTIFICATION_SENT':
      case 'SEND_NOTIFICATION':
        return Colors.blue;
      case 'USER_REGISTERED':
        return Colors.purple;
      case 'USER_BLOCKED':
        return Colors.red;
      case 'USER_DELETED':
        return Colors.orange;
      case 'USER_RESTORED':
        return Colors.blue;
      case 'SCREEN_VIEW':
        return Colors.lightBlue;
      case 'BUTTON_CLICK':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }

  // 액션 메서드들
  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedTarget = '전체';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('알림 발송', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '제목',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '내용',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedTarget,
              dropdownColor: kSurfaceColor,
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: '전체', child: Text('전체 사용자')),
                DropdownMenuItem(value: '1학년', child: Text('1학년')),
                DropdownMenuItem(value: '2학년', child: Text('2학년')),
                DropdownMenuItem(value: '3학년', child: Text('3학년')),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedTarget = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return TextButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty ||
                      contentController.text.trim().isEmpty) {
                    _showErrorSnackBar('제목과 내용을 모두 입력해주세요.');
                    return;
                  }

                  final success = await adminProvider.sendNotificationToAll(
                    title: titleController.text.trim(),
                    message: contentController.text.trim(),
                  );

                  Navigator.pop(context);

                  if (success) {
                    _showSuccessSnackBar('$selectedTarget 알림이 발송되었습니다.');
                  } else {
                    _showErrorSnackBar('알림 발송에 실패했습니다.');
                  }
                },
                child: const Text('발송'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEmergencyNotificationDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('긴급 알림', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '긴급 알림은 모든 사용자에게 즉시 발송됩니다.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '긴급 알림 제목',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '긴급 알림 내용',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return TextButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty ||
                      contentController.text.trim().isEmpty) {
                    _showErrorSnackBar('제목과 내용을 모두 입력해주세요.');
                    return;
                  }

                  final success = await adminProvider.sendEmergencyNotification(
                    title: titleController.text.trim(),
                    message: contentController.text.trim(),
                  );

                  Navigator.pop(context);

                  if (success) {
                    _showSuccessSnackBar('긴급 알림이 발송되었습니다.');
                  } else {
                    _showErrorSnackBar('긴급 알림 발송에 실패했습니다.');
                  }
                },
                child: const Text('발송', style: TextStyle(color: Colors.red)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: Text('${user['name']} 상세 정보',
            style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserInfoRow('이름', user['name'] ?? '정보 없음'),
              _buildUserInfoRow('이메일', user['email'] ?? '정보 없음'),
              _buildUserInfoRow('학년/반', user['grade'] ?? '정보 없음'),
              _buildUserInfoRow('상태', _getStatusText(user['status'])),
              _buildUserInfoRow('가입일', user['joinDate'] ?? '정보 없음'),
              _buildUserInfoRow('마지막 로그인', user['lastLogin'] ?? '정보 없음'),
              _buildUserInfoRow('로그인 횟수', '${user['loginCount'] ?? 0}회'),
              _buildUserInfoRow(
                  '관리자 권한', user['isAdmin'] == true ? '있음' : '없음'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editUser(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    final gradeController = TextEditingController();
    final classController = TextEditingController();

    bool allowNotifications = true;
    bool isAccountActive = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('사용자 정보 수정', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: '이름',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      labelStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.email, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: gradeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: '학년',
                            labelStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.school, color: Colors.grey),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: classController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: '반',
                            labelStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.class_, color: Colors.grey),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('알림 수신 허용',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text('앱 알림을 받을 수 있습니다',
                        style: TextStyle(color: Colors.grey)),
                    value: allowNotifications,
                    onChanged: (value) {
                      setState(() {
                        allowNotifications = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('계정 활성화',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text('로그인 및 앱 사용이 가능합니다',
                        style: TextStyle(color: Colors.grey)),
                    value: isAccountActive,
                    onChanged: (value) {
                      setState(() {
                        isAccountActive = value;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return TextButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    _showErrorSnackBar('이름을 입력해주세요.');
                    return;
                  }

                  final success = await adminProvider.updateUserInfo(
                    userId: user['id'],
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    grade: gradeController.text.trim(),
                    classNumber: classController.text.trim(),
                    allowNotifications: allowNotifications,
                    isActive: isAccountActive,
                  );

                  Navigator.pop(context);

                  if (success) {
                    _showSuccessSnackBar('사용자 정보가 수정되었습니다.');
                    setState(() {}); // 목록 새로고침
                  } else {
                    _showErrorSnackBar('사용자 정보 수정에 실패했습니다.');
                  }
                },
                child: const Text('저장'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _blockUser(Map<String, dynamic> user) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('사용자 차단', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${user['name']} 사용자를 차단하시겠습니까?',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '차단 사유 (필수)',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: '차단 사유를 입력해주세요',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return TextButton(
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) {
                    _showErrorSnackBar('차단 사유를 입력해주세요.');
                    return;
                  }

                  final success = await adminProvider.blockUser(
                    userId: user['id'],
                    reason: reasonController.text.trim(),
                  );

                  Navigator.pop(context);

                  if (success) {
                    _showSuccessSnackBar('사용자가 차단되었습니다.');
                    setState(() {}); // 목록 새로고침
                  } else {
                    _showErrorSnackBar('사용자 차단에 실패했습니다.');
                  }
                },
                child: const Text('차단', style: TextStyle(color: Colors.red)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _unblockUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('차단 해제', style: TextStyle(color: Colors.white)),
        content: Text(
          '${user['name']} 사용자의 차단을 해제하시겠습니까?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return TextButton(
                onPressed: () async {
                  final success = await adminProvider.unblockUser(user['id']);

                  Navigator.pop(context);

                  if (success) {
                    _showSuccessSnackBar('사용자 차단이 해제되었습니다.');
                    setState(() {}); // 목록 새로고침
                  } else {
                    _showErrorSnackBar('차단 해제에 실패했습니다.');
                  }
                },
                child: const Text('해제', style: TextStyle(color: Colors.green)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> user) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('사용자 삭제', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${user['name']} 사용자를 삭제하시겠습니까?\n\n⚠️ 삭제된 데이터는 30일간 보관되며, 이후 자동으로 영구 삭제됩니다.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '삭제 사유 (필수)',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: '삭제 사유를 입력해주세요',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return TextButton(
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) {
                    _showErrorSnackBar('삭제 사유를 입력해주세요.');
                    return;
                  }

                  final success = await adminProvider.deleteUser(
                    userId: user['id'],
                    reason: reasonController.text.trim(),
                  );

                  Navigator.pop(context);

                  if (success) {
                    _showSuccessSnackBar('사용자가 삭제되었습니다. (30일간 복구 가능)');
                    setState(() {}); // 목록 새로고침
                  } else {
                    _showErrorSnackBar('사용자 삭제에 실패했습니다.');
                  }
                },
                child: const Text('삭제', style: TextStyle(color: Colors.orange)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _restoreUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('사용자 복구', style: TextStyle(color: Colors.white)),
        content: Text(
          '${user['name']} 사용자를 복구하시겠습니까?\n\n복구된 사용자는 다시 앱을 사용할 수 있습니다.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          Consumer<AdminProvider>(
            builder: (context, adminProvider, child) {
              return TextButton(
                onPressed: () async {
                  final success = await adminProvider.restoreUser(user['id']);

                  Navigator.pop(context);

                  if (success) {
                    _showSuccessSnackBar('사용자가 복구되었습니다.');
                    setState(() {}); // 목록 새로고침
                  } else {
                    _showErrorSnackBar('사용자 복구에 실패했습니다.');
                  }
                },
                child: const Text('복구', style: TextStyle(color: Colors.blue)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToTemplateManagement() {
    _showTemplateManagementDialog();
  }

  void _navigateToScheduleManagement() {
    _showScheduleManagementDialog();
  }

  void _showTemplateManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => _TemplateManagementDialog(),
    );
  }

  void _showScheduleManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => _ScheduleManagementDialog(),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// 템플릿 관리 다이얼로그
class _TemplateManagementDialog extends StatefulWidget {
  @override
  _TemplateManagementDialogState createState() =>
      _TemplateManagementDialogState();
}

class _TemplateManagementDialogState extends State<_TemplateManagementDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedType = '일반';
  NotificationPriority _selectedPriority = NotificationPriority.normal;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.description, color: Colors.purple, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '템플릿 관리',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 탭 바
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const TabBar(
                        indicatorColor: Colors.purple,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: '템플릿 목록'),
                          Tab(text: '새 템플릿'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildTemplateList(),
                          _buildNewTemplateForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateList() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final templates = adminProvider.notificationTemplates;

        if (templates.isEmpty) {
          return const Center(
            child: Text(
              '저장된 템플릿이 없습니다.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(template.priority)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getPriorityText(template.priority),
                          style: TextStyle(
                            color: _getPriorityColor(template.priority),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'use') {
                            _useTemplate(template);
                          } else if (value == 'edit') {
                            _editTemplate(template);
                          } else if (value == 'delete') {
                            _deleteTemplate(template);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'use',
                            child: Row(
                              children: [
                                Icon(Icons.send, size: 16),
                                SizedBox(width: 8),
                                Text('사용하기'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('수정'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('삭제'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template.content,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${template.usageCount}회 사용',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${template.createdAt.month}/${template.createdAt.day}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNewTemplateForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          const Text(
            '제목',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '템플릿 제목을 입력하세요',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 내용
          const Text(
            '내용',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '템플릿 내용을 입력하세요',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 타입 선택
          const Text(
            '타입',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedType,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: '일반', child: Text('일반')),
                DropdownMenuItem(value: '긴급', child: Text('긴급')),
                DropdownMenuItem(value: '공지', child: Text('공지')),
                DropdownMenuItem(value: '이벤트', child: Text('이벤트')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // 우선순위 선택
          const Text(
            '우선순위',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<NotificationPriority>(
              value: _selectedPriority,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                    value: NotificationPriority.low, child: Text('낮음')),
                DropdownMenuItem(
                    value: NotificationPriority.normal, child: Text('보통')),
                DropdownMenuItem(
                    value: NotificationPriority.high, child: Text('높음')),
                DropdownMenuItem(
                    value: NotificationPriority.urgent, child: Text('긴급')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
          ),
          const SizedBox(height: 24),

          // 저장 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveTemplate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '템플릿 저장',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveTemplate() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목과 내용을 모두 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final success = await adminProvider.saveNotificationTemplate(
      _titleController.text,
      _contentController.text,
      _selectedType,
      _selectedPriority,
    );

    if (success) {
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _selectedType = '일반';
        _selectedPriority = NotificationPriority.normal;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('템플릿이 저장되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('템플릿 저장에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _useTemplate(NotificationTemplate template) {
    Navigator.pop(context);
    // 템플릿을 사용하여 알림 발송 다이얼로그 열기
    // 이 부분은 알림 발송 폼에 템플릿 내용을 미리 채우는 기능으로 구현
  }

  void _editTemplate(NotificationTemplate template) {
    _titleController.text = template.title;
    _contentController.text = template.content;
    _selectedType = template.type;
    _selectedPriority = template.priority;
    setState(() {});
  }

  void _deleteTemplate(NotificationTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('템플릿 삭제', style: TextStyle(color: Colors.white)),
        content: Text(
          '${template.title} 템플릿을 삭제하시겠습니까?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final adminProvider =
                  Provider.of<AdminProvider>(context, listen: false);
              final success =
                  await adminProvider.deleteNotificationTemplate(template.id);

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('템플릿이 삭제되었습니다.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('템플릿 삭제에 실패했습니다.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.green;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  String _getPriorityText(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return '낮음';
      case NotificationPriority.normal:
        return '보통';
      case NotificationPriority.high:
        return '높음';
      case NotificationPriority.urgent:
        return '긴급';
    }
  }
}

// 예약 관리 다이얼로그
class _ScheduleManagementDialog extends StatefulWidget {
  @override
  _ScheduleManagementDialogState createState() =>
      _ScheduleManagementDialogState();
}

class _ScheduleManagementDialogState extends State<_ScheduleManagementDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedTarget = '전체';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '예약 알림 관리',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 탭 바
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const TabBar(
                        indicatorColor: Colors.orange,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: '예약 목록'),
                          Tab(text: '새 예약'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildScheduleList(),
                          _buildNewScheduleForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final schedules = adminProvider.scheduledNotifications;

        if (schedules.isEmpty) {
          return const Center(
            child: Text(
              '예약된 알림이 없습니다.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            final isExpired =
                schedule.scheduledAt?.isBefore(DateTime.now()) ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpired
                      ? Colors.red.withValues(alpha: 0.5)
                      : Colors.grey[700]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isExpired ? '만료됨' : '예약됨',
                          style: TextStyle(
                            color: isExpired ? Colors.red : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editSchedule(schedule);
                          } else if (value == 'delete') {
                            _deleteSchedule(schedule);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('수정'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('삭제'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    schedule.message,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        schedule.scheduledAt != null
                            ? '${schedule.scheduledAt!.month}/${schedule.scheduledAt!.day} ${schedule.scheduledAt!.hour}:${schedule.scheduledAt!.minute.toString().padLeft(2, '0')}'
                            : '시간 미정',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        schedule.metadata?['target'] ?? '전체',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNewScheduleForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          const Text(
            '제목',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '알림 제목을 입력하세요',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 내용
          const Text(
            '내용',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '알림 내용을 입력하세요',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 발송 대상
          const Text(
            '발송 대상',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedTarget,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: '전체', child: Text('전체 사용자')),
                DropdownMenuItem(value: '1학년', child: Text('1학년')),
                DropdownMenuItem(value: '2학년', child: Text('2학년')),
                DropdownMenuItem(value: '3학년', child: Text('3학년')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTarget = value!;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // 예약 날짜
          const Text(
            '예약 날짜',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 예약 시간
          const Text(
            '예약 시간',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedTime.hour}시 ${_selectedTime.minute}분',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 예약 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _scheduleNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '알림 예약',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orange,
              surface: kSurfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orange,
              surface: kSurfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _scheduleNotification() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('제목과 내용을 모두 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('예약 시간은 현재 시간보다 이후여야 합니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final success = await adminProvider.scheduleNotification(
      title: _titleController.text,
      message: _contentController.text,
      scheduledAt: scheduledDateTime,
      type: 'admin_announcement',
    );

    if (success) {
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
        _selectedTarget = '전체';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림이 예약되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림 예약에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editSchedule(NotificationModel schedule) {
    // 예약 수정 로직 구현
    _titleController.text = schedule.title;
    _contentController.text = schedule.message;
    if (schedule.scheduledAt != null) {
      _selectedDate = schedule.scheduledAt!;
      _selectedTime = TimeOfDay.fromDateTime(schedule.scheduledAt!);
    }
    _selectedTarget = schedule.metadata?['target'] ?? '전체';
    setState(() {});
  }

  void _deleteSchedule(NotificationModel schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('예약 삭제', style: TextStyle(color: Colors.white)),
        content: Text(
          '${schedule.title} 예약을 삭제하시겠습니까?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final adminProvider =
                  Provider.of<AdminProvider>(context, listen: false);
              final success =
                  await adminProvider.deleteScheduledNotification(schedule.id);

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('예약이 삭제되었습니다.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('예약 삭제에 실패했습니다.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
