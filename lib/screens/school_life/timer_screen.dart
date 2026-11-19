import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/study_timer_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/format_utils.dart';
import '../../models/study_timer.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['홈', '그룹'];
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescController = TextEditingController();

  // Provider 참조를 저장할 변수 추가
  UserProvider? _userProvider;
  StudyTimerProvider? _timerProvider;

  // 초기화 완료 플래그
  bool _isInitialized = false;

  // 주기적 새로고침 타이머
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 이미 초기화되었으면 중복 초기화 방지
    if (_isInitialized) return;

    // Provider 참조를 안전하게 저장
    _userProvider = Provider.of<UserProvider>(context);
    _timerProvider = Provider.of<StudyTimerProvider>(context);

    // 다음 프레임에서 데이터 로드 (빌드 중에 Provider 업데이트 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTimerData();
        _startPeriodicRefresh();
        _isInitialized = true;
      }
    });
  }

  Future<void> _loadTimerData() async {
    if (_timerProvider == null || _userProvider == null) return;

    // 사용자 ID가 있으면 사용, 없으면 기본값 사용
    final userId = _userProvider?.user?.id ?? 'anonymous_user';
    _timerProvider?.setUserId(userId);

    // 그룹 데이터 로드
    await _timerProvider?.loadUserStudyGroups();
    await _timerProvider?.loadAllStudyGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _groupNameController.dispose();
    _groupDescController.dispose();

    // 모든 타이머 정지
    _timerProvider?.stopAllTimers();

    // 기존 타이머 취소
    _refreshTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('타이머'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: Consumer<StudyTimerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('오류: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadTimerData(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildHomeTab(context, provider),
              _buildGroupTab(context, provider),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<StudyTimerProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton(
            onPressed: () {
              if (_tabController.index == 0) {
                _showAddSubjectDialog(context);
              } else {
                _navigateToStudyGroupsScreen(context);
              }
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, StudyTimerProvider provider) {
    final userTimers = provider.userTimers;

    // 총 공부 시간 계산
    int totalStudyTime = 0;
    for (final timer in userTimers) {
      totalStudyTime += provider.durations[timer.subject] ?? 0;
    }
    final formattedTotalTime =
        FormatUtils.formatDuration(Duration(milliseconds: totalStudyTime));

    return Column(
      children: [
        // 오늘 총 공부 시간 표시 (더 작게 수정)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          margin: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘 총 공부 시간',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              Text(
                formattedTotalTime,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),

        // 타이머 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: userTimers.length,
            itemBuilder: (context, index) {
              final timer = userTimers[index];
              final isRunning = provider.isRunning[timer.subject] ?? false;
              final duration = provider.durations[timer.subject] ?? 0;
              final formattedDuration =
                  FormatUtils.formatDuration(Duration(milliseconds: duration));

              // 열품타 스타일의 타이머 카드
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // 왼쪽: 과목명과 시간
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  timer.subject,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (timer.isCustom)
                                  InkWell(
                                    onTap: () => _deleteCustomSubject(
                                        context, timer.subject),
                                    child: const Icon(Icons.delete,
                                        size: 18, color: Colors.grey),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDuration,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color:
                                    isRunning ? Colors.green : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 오른쪽: 시작/정지 버튼
                      ElevatedButton(
                        onPressed: () {
                          if (isRunning) {
                            provider.stopTimer(timer.subject);
                          } else {
                            provider.startTimer(timer.subject);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isRunning ? Colors.orange : Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isRunning ? '정지' : '시작',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupTab(BuildContext context, StudyTimerProvider provider) {
    final userGroups = provider.userGroups;

    if (userGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('참여 중인 스터디 그룹이 없습니다.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _navigateToStudyGroupsScreen(context),
              child: const Text('그룹 참여하기'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: userGroups.length,
      itemBuilder: (context, index) {
        final group = userGroups[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: InkWell(
            onTap: () {
              // 다이얼로그 대신 그룹 상세 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudyGroupDetailScreen(group: group),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${group.memberIds.length}명 참여 중',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (group.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      group.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToStudyGroupsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudyGroupsScreen(),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    _subjectController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('과목 추가'),
          content: TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: '과목명',
              hintText: '추가할 과목명을 입력하세요',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final subject = _subjectController.text.trim();
                if (subject.isNotEmpty) {
                  final provider = context.read<StudyTimerProvider>();
                  provider.addCustomTimer(subject);
                  Navigator.pop(context);
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCustomSubject(BuildContext context, String subject) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('과목 삭제'),
          content: Text('$subject 과목을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final provider = context.read<StudyTimerProvider>();
                provider.deleteCustomTimer(subject);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$subject 과목이 삭제되었습니다.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  void _refreshTimerData() {
    if (!mounted) return;

    // Provider 참조를 안전하게 저장
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final timerProvider =
        Provider.of<StudyTimerProvider>(context, listen: false);
    final userId = userProvider.user?.id ?? 'anonymous_user';

    // 타이머 데이터 새로고침 - 마이크로태스크 큐를 사용하여 빌드 중에 setState가 간접적으로 호출되는 것을 방지
    Future.microtask(() {
      if (mounted) {
        timerProvider.refreshTimerData(userId);
      }
    });
  }

  void _startPeriodicRefresh() {
    // 기존 타이머 취소
    _refreshTimer?.cancel();

    // 1분마다 타이머 데이터 새로고침
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _refreshTimerData();
      }
    });
  }
}

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  _StudyGroupsScreenState createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['그룹 목록', '그룹 생성'];

  // 그룹 생성 컨트롤러
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescController = TextEditingController();
  final TextEditingController _groupPasswordController =
      TextEditingController();
  final TextEditingController _groupTargetTimeController =
      TextEditingController();
  final TextEditingController _groupMaxMembersController =
      TextEditingController();

  // 그룹 생성 상태 변수
  String _selectedCategory = '1학년';
  final List<String> _categories = ['1학년', '2학년', '3학년'];
  bool _isPasswordProtected = false;

  // Provider 참조를 저장할 변수
  StudyTimerProvider? _timerProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 이미 초기화되었으면 중복 초기화 방지
    if (_isInitialized) return;

    // Provider 참조를 안전하게 저장
    _timerProvider = Provider.of<StudyTimerProvider>(context);

    // 다음 프레임에서 데이터 로드 (빌드 중에 Provider 업데이트 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _timerProvider?.loadAllStudyGroups();
        _isInitialized = true;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupNameController.dispose();
    _groupDescController.dispose();
    _groupPasswordController.dispose();
    _groupTargetTimeController.dispose();
    _groupMaxMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스터디 그룹'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupListTab(),
          _buildCreateGroupTab(),
        ],
      ),
    );
  }

  Widget _buildGroupListTab() {
    return Consumer<StudyTimerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allGroups = provider.allGroups;
        final userGroups = provider.userGroups;

        // 사용자가 아직 참여하지 않은 그룹만 표시
        final availableGroups = allGroups
            .where((group) =>
                !userGroups.any((userGroup) => userGroup.id == group.id))
            .toList();

        if (availableGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('참여 가능한 그룹이 없습니다.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(1), // 그룹 생성 탭으로 이동
                  child: const Text('새 그룹 만들기'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '참여 가능한 스터디 그룹',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: availableGroups.length,
                itemBuilder: (context, index) {
                  final group = availableGroups[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      title: Text(
                        group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${group.memberIds.length}명 참여 중'),
                          if (group.description.isNotEmpty)
                            Text(
                              group.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _joinStudyGroup(group),
                        child: const Text('참여'),
                      ),
                      isThreeLine: group.description.isNotEmpty,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 그룹 참여 메서드 추가
  Future<void> _joinStudyGroup(StudyGroup group) async {
    final provider = _timerProvider ??
        Provider.of<StudyTimerProvider>(context, listen: false);
    final success = await provider.joinStudyGroup(group.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${group.name} 그룹에 참여했습니다.')),
      );
      // 그룹 목록 새로고침
      provider.loadAllStudyGroups();

      // 그룹 상세 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudyGroupDetailScreen(group: group),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹 참여에 실패했습니다: ${provider.error}')),
      );
    }
  }

  Widget _buildCreateGroupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '새 스터디 그룹 만들기',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // 그룹명
          TextField(
            controller: _groupNameController,
            decoration: const InputDecoration(
              labelText: '그룹명 *',
              hintText: '그룹명을 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // 카테고리 선택
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: '카테고리',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // 비밀번호 설정 여부
          SwitchListTile(
            title: const Text('비밀번호 설정'),
            subtitle: const Text('그룹에 비밀번호를 설정합니다'),
            value: _isPasswordProtected,
            onChanged: (value) {
              setState(() {
                _isPasswordProtected = value;
              });
            },
          ),

          // 비밀번호 입력 필드 (선택 시에만 표시)
          if (_isPasswordProtected) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _groupPasswordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '그룹 비밀번호를 입력하세요',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
          ],

          // 일일 목표 시간
          TextField(
            controller: _groupTargetTimeController,
            decoration: const InputDecoration(
              labelText: '일일 목표 시간 (분)',
              hintText: '예: 120',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // 모집 인원
          TextField(
            controller: _groupMaxMembersController,
            decoration: const InputDecoration(
              labelText: '모집 인원',
              hintText: '예: 10',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // 그룹 설명
          TextField(
            controller: _groupDescController,
            decoration: const InputDecoration(
              labelText: '그룹 설명',
              hintText: '그룹에 대한 설명을 입력하세요',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // 생성 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _createGroup(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '그룹 생성하기',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹명을 입력해주세요')),
      );
      return;
    }

    // 그룹 정보 수집
    final description = _groupDescController.text.trim();
    final category = _selectedCategory;
    final password =
        _isPasswordProtected ? _groupPasswordController.text.trim() : '';

    // 목표 시간 및 모집 인원 파싱
    int? targetTime;
    int? maxMembers;

    try {
      if (_groupTargetTimeController.text.isNotEmpty) {
        targetTime = int.parse(_groupTargetTimeController.text);
      }

      if (_groupMaxMembersController.text.isNotEmpty) {
        maxMembers = int.parse(_groupMaxMembersController.text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('목표 시간과 모집 인원은 숫자로 입력해주세요')),
      );
      return;
    }

    // 그룹 생성 요청
    final provider = _timerProvider ??
        Provider.of<StudyTimerProvider>(context, listen: false);
    final success = await provider.createStudyGroup(
      name,
      description,
      category: category,
      password: password,
      targetTime: targetTime,
      maxMembers: maxMembers,
    );

    if (success) {
      // 입력 필드 초기화
      _groupNameController.clear();
      _groupDescController.clear();
      _groupPasswordController.clear();
      _groupTargetTimeController.clear();
      _groupMaxMembersController.clear();
      setState(() {
        _isPasswordProtected = false;
        _selectedCategory = '1학년';
      });

      // 그룹 목록 탭으로 이동
      _tabController.animateTo(0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name 그룹이 생성되었습니다')),
      );

      // 그룹 목록 새로고침
      provider.loadAllStudyGroups();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹 생성에 실패했습니다: ${provider.error}')),
      );
    }
  }
}

// 그룹 상세 화면 클래스 추가
class StudyGroupDetailScreen extends StatefulWidget {
  final StudyGroup group;

  const StudyGroupDetailScreen({Key? key, required this.group})
      : super(key: key);

  @override
  _StudyGroupDetailScreenState createState() => _StudyGroupDetailScreenState();
}

class _StudyGroupDetailScreenState extends State<StudyGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['홈', '출석부', '랭킹', '초대'];

  // Provider 참조를 저장할 변수 추가
  StudyTimerProvider? _timerProvider;

  // 선택된 날짜 (출석부 탭)
  DateTime _selectedDate = DateTime.now();

  // 날짜 변경 플래그
  bool _needsDateUpdate = false;
  DateTime? _pendingDateSelection;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider 참조를 안전하게 저장
    _timerProvider = Provider.of<StudyTimerProvider>(context);

    // 그룹 멤버 정보 로드 및 실시간 업데이트 시작
    _timerProvider?.loadGroupMembers(widget.group.id);
    _timerProvider?.startGroupMemberUpdates(widget.group.id);
  }

  @override
  void didUpdateWidget(StudyGroupDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 보류 중인 날짜 업데이트가 있으면 처리
    if (_needsDateUpdate && _pendingDateSelection != null) {
      setState(() {
        _selectedDate = _pendingDateSelection!;
        _needsDateUpdate = false;
        _pendingDateSelection = null;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();

    // 저장된 Provider 참조를 사용하여 안전하게 업데이트 중지
    _timerProvider?.stopGroupMemberUpdates();

    super.dispose();
  }

  // 날짜 선택 처리 메서드
  void _selectDate(DateTime date) {
    if (!_isSameDay(date, _selectedDate)) {
      _pendingDateSelection = date;
      _needsDateUpdate = true;

      // 다음 프레임에서 상태 업데이트
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _needsDateUpdate) {
            setState(() {
              _selectedDate = _pendingDateSelection!;
              _needsDateUpdate = false;
              _pendingDateSelection = null;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          _buildAttendanceTab(),
          _buildRankingTab(),
          _buildInviteTab(),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Consumer<StudyTimerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = provider.groupMembers[widget.group.id] ?? [];
        final activeMembers = members.where((m) => m.isActive).toList();

        // 공부 중인 멤버를 먼저 표시하기 위해 정렬
        final sortedMembers = [...members];
        sortedMembers.sort((a, b) {
          if (a.isActive && !b.isActive) return -1;
          if (!a.isActive && b.isActive) return 1;
          return b.todayStudyTime.compareTo(a.todayStudyTime);
        });

        return Column(
          children: [
            // 그룹 정보
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.group.name} 스터디',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '멤버: ${widget.group.memberIds.length}명',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (widget.group.category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '카테고리: ${widget.group.category}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  if (widget.group.targetTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '일일 목표: ${widget.group.targetTime}분',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  if (widget.group.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.group.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),

            // 모든 멤버 목록 (공부 중인 멤버 먼저 표시)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '그룹 멤버 (${members.length}명)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '공부 중: ${activeMembers.length}명',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 멤버 목록 (공부 중인 멤버 먼저 표시)
            Expanded(
              child: members.isEmpty
                  ? const Center(
                      child: Text('멤버 정보를 불러오는 중입니다...'),
                    )
                  : ListView.builder(
                      itemCount: sortedMembers.length,
                      itemBuilder: (context, index) {
                        final member = sortedMembers[index];
                        final isActive = member.isActive;
                        final studyTime = FormatUtils.formatDuration(
                          Duration(milliseconds: member.todayStudyTime),
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: isActive
                              ? const Color.fromRGBO(0, 128, 0, 0.1)
                              : null,
                          child: ListTile(
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isActive
                                      ? Colors.green
                                      : Colors.grey[300],
                                  child: Text(
                                    member.name[0],
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              member.name,
                              style: TextStyle(
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '오늘 공부 시간: $studyTime',
                              style: TextStyle(
                                color: isActive ? Colors.green[700] : null,
                              ),
                            ),
                            trailing: isActive
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          '공부 중',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.timer,
                                        color: Colors.green,
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    return Consumer<StudyTimerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = provider.groupMembers[widget.group.id] ?? [];

        // 날짜별 출석 데이터 (최근 7일)
        final today = DateTime.now();
        final dates = List.generate(7, (index) {
          return today.subtract(Duration(days: index));
        });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${widget.group.name} 출석부',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 날짜 선택 리스트
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final isSelected = _isSameDay(date, _selectedDate);

                  return GestureDetector(
                    onTap: () => _selectDate(date),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${date.month}/${date.day}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            [
                              '월',
                              '화',
                              '수',
                              '목',
                              '금',
                              '토',
                              '일'
                            ][date.weekday - 1],
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          if (_isSameDay(date, today))
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '오늘',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            // 멤버 출석 목록
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];

                  // 선택된 날짜에 공부했는지 여부 (실제로는 서버에서 날짜별 데이터를 가져와야 함)
                  // 현재는 오늘 날짜만 실제 데이터를 사용하고, 다른 날짜는 랜덤하게 표시
                  final hasStudied = _isSameDay(_selectedDate, today)
                      ? member.todayStudyTime > 0
                      : index % 2 == 0; // 임시로 짝수 인덱스만 출석으로 표시

                  // 공부 시간 (실제로는 서버에서 날짜별 데이터를 가져와야 함)
                  final studyTime = _isSameDay(_selectedDate, today)
                      ? FormatUtils.formatDuration(
                          Duration(milliseconds: member.todayStudyTime))
                      : hasStudied
                          ? '${(index + 1) * 30}분'
                          : '0분';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: hasStudied ? Colors.green : Colors.grey,
                      child: Text(
                        member.name[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(member.name),
                    subtitle: Text(
                      hasStudied ? '공부 시간: $studyTime' : '공부 기록이 없습니다',
                    ),
                    trailing: Icon(
                      hasStudied ? Icons.check_circle : Icons.cancel,
                      color: hasStudied ? Colors.green : Colors.red,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRankingTab() {
    return Consumer<StudyTimerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = provider.groupMembers[widget.group.id] ?? [];

        // 공부 시간으로 정렬
        final sortedMembers = List<GroupMember>.from(members);
        sortedMembers
            .sort((a, b) => b.todayStudyTime.compareTo(a.todayStudyTime));

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: '일간'),
                  Tab(text: '주간'),
                  Tab(text: '월간'),
                ],
                labelColor: Colors.black,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // 일간 랭킹
                    _buildRankingList(sortedMembers, '오늘'),

                    // 주간 랭킹 (실제로는 서버에서 주간 데이터를 가져와야 함)
                    _buildRankingList(sortedMembers, '이번 주'),

                    // 월간 랭킹 (실제로는 서버에서 월간 데이터를 가져와야 함)
                    _buildRankingList(sortedMembers, '이번 달'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankingList(List<GroupMember> members, String period) {
    if (members.isEmpty) {
      return const Center(
        child: Text('랭킹 데이터가 없습니다'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '$period 공부 시간 랭킹',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 상위 3명 특별 표시
        if (members.length >= 3) ...[
          SizedBox(
            height: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2등
                if (members.length >= 2) _buildTopRanker(members[1], 2, 90),

                // 1등
                _buildTopRanker(members[0], 1, 110),

                // 3등
                if (members.length >= 3) _buildTopRanker(members[2], 3, 80),
              ],
            ),
          ),
          const Divider(),
        ],

        // 전체 랭킹 리스트
        Expanded(
          child: ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final rank = index + 1;
              final studyTime = FormatUtils.formatDuration(
                Duration(milliseconds: member.todayStudyTime),
              );

              // 상위 3등은 이미 위에 표시했으므로 스킵할 수도 있음
              // 여기서는 전체 리스트를 보여줌
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: rank <= 3 ? Colors.amber : Colors.grey[300],
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: rank <= 3 ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(member.name),
                subtitle: Text('공부 시간: $studyTime'),
                trailing: rank <= 3
                    ? const Icon(Icons.emoji_events, color: Colors.amber)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopRanker(GroupMember member, int rank, double height) {
    final studyTime = FormatUtils.formatDuration(
      Duration(milliseconds: member.todayStudyTime),
    );

    final colors = {
      1: Colors.amber,
      2: Colors.blueGrey,
      3: Colors.brown,
    };

    final icons = {
      1: '🥇',
      2: '🥈',
      3: '🥉',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colors[rank],
            child: Text(
              member.name[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            member.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            studyTime,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: height,
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                  (colors[rank]!.r * 255).round(),
                  (colors[rank]!.g * 255).round(),
                  (colors[rank]!.b * 255).round(),
                  0.7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                icons[rank]!,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.group_add,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          const Text(
            '친구를 초대하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '함께 공부하면 더 효율적입니다!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    '초대 링크',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'https://okbit.app/join-group/${widget.group.id}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.link, color: Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // 초대 링크 생성 및 클립보드에 복사
                      // 클립보드에 복사 (실제 앱에서는 clipboard 패키지 사용)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('초대 링크가 클립보드에 복사되었습니다')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('초대 링크 복사'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
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

  // 같은 날짜인지 확인하는 헬퍼 함수
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
