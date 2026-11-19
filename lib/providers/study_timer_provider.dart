import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/study_timer.dart';
import '../services/study_timer_service.dart';
import '../utils/logger_util.dart';

class StudyTimerProvider extends ChangeNotifier {
  final StudyTimerService _timerService = StudyTimerService();
  final Uuid _uuid = const Uuid();

  String _userId = '';
  bool _isLoading = false;
  String? _error;

  // 타이머 상태
  final Map<String, bool> _isRunning = {};
  final Map<String, int> _durations = {};
  final Map<String, Timer?> _timers = {};

  // 자정 리셋 타이머
  Timer? _resetTimer;
  DateTime? _lastResetDate;

  // 사용자 타이머 목록
  List<StudyTimer> _userTimers = [];

  // 스터디 그룹 관련
  List<StudyGroup> _allGroups = [];
  List<StudyGroup> _userGroups = [];
  final Map<String, List<GroupMember>> _groupMembers = {};

  // 기본 과목 목록
  final List<String> _defaultSubjects = ['국어', '수학', '영어', '한국사', '과학'];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, bool> get isRunning => _isRunning;
  Map<String, int> get durations => _durations;
  List<StudyTimer> get userTimers => _userTimers;
  List<String> get defaultSubjects => _defaultSubjects;
  List<StudyGroup> get allGroups => _allGroups;
  List<StudyGroup> get userGroups => _userGroups;
  Map<String, List<GroupMember>> get groupMembers => _groupMembers;

  // 사용자 ID 설정
  void setUserId(String userId) {
    _userId = userId;
    loadUserTimers();
    _setupResetTimer();
  }

  // 타이머 데이터 새로고침
  Future<void> refreshTimerData(String userId) async {
    if (userId.isEmpty) return;

    // 사용자 ID 업데이트
    _userId = userId;

    // 타이머 데이터 새로고침 (로딩 상태 표시 없이)
    try {
      final timers = await _timerService.getUserTimers(_userId);

      // 기존 타이머 상태 유지하면서 데이터 업데이트
      for (final timer in timers) {
        final index = _userTimers.indexWhere((t) => t.id == timer.id);
        if (index >= 0) {
          _userTimers[index] = timer;
          _durations[timer.subject] = timer.totalDuration;
        }
      }

      // 그룹 데이터도 새로고침
      await loadUserStudyGroups();

      // 현재 활성화된 그룹이 있으면 멤버 정보 업데이트
      if (_currentGroupId != null) {
        await _loadGroupMembersWithoutNotify(_currentGroupId!);
      }

      // 마이크로태스크 큐를 사용하여 빌드 중에 notifyListeners가 호출되는 것을 방지
      Future.microtask(() {
        notifyListeners();
      });
    } catch (e) {
      LoggerUtil.error('타이머 데이터 새로고침 중 오류 발생: $e');
    }
  }

  // 그룹 멤버 정보 로드 (notifyListeners 호출 없이)
  Future<void> _loadGroupMembersWithoutNotify(String groupId) async {
    try {
      final members = await _timerService.getGroupMembers(groupId);
      _groupMembers[groupId] = members;
    } catch (e) {
      LoggerUtil.error('그룹 멤버 정보를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  // 04시 리셋 타이머 설정
  void _setupResetTimer() {
    // 기존 타이머 취소
    _resetTimer?.cancel();

    // 현재 날짜 확인
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 마지막 리셋 날짜 확인
    if (_lastResetDate == null) {
      _lastResetDate = today;
    }

    // 오늘 날짜의 04시 계산
    final resetTime = DateTime(now.year, now.month, now.day, 4, 0);

    // 이미 04시가 지났으면 다음날 04시로 설정
    Duration timeUntilReset;
    if (now.isAfter(resetTime)) {
      final tomorrow = today.add(const Duration(days: 1));
      final nextResetTime =
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 4, 0);
      timeUntilReset = nextResetTime.difference(now);
    } else {
      timeUntilReset = resetTime.difference(now);
    }

    // 리셋 타이머 설정
    _resetTimer = Timer(timeUntilReset, () {
      _resetAllTimers();
      _lastResetDate = DateTime.now();
      // 다음 리셋 타이머 설정
      _setupResetTimer();
    });
  }

  // 모든 타이머 리셋
  void _resetAllTimers() {
    for (final subject in _durations.keys.toList()) {
      _durations[subject] = 0;
    }

    // 타이머 데이터 저장
    for (final timer in _userTimers) {
      final updatedTimer = timer.copyWith(
        totalDuration: 0,
        lastUpdated: DateTime.now(),
      );
      _timerService.saveTimer(updatedTimer);
    }

    notifyListeners();
  }

  // 사용자 타이머 로드
  Future<void> loadUserTimers() async {
    if (_userId.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userTimers = await _timerService.getUserTimers(_userId);

      // 기본 과목이 없으면 생성
      for (final subject in _defaultSubjects) {
        if (!_userTimers.any((timer) => timer.subject == subject)) {
          final newTimer = StudyTimer(
            id: _uuid.v4(),
            userId: _userId,
            subject: subject,
            totalDuration: 0,
            lastUpdated: DateTime.now(),
            isCustom: false,
          );

          _userTimers.add(newTimer);
          await _timerService.saveTimer(newTimer);
        }
      }

      // 타이머 상태 초기화
      for (final timer in _userTimers) {
        _durations[timer.subject] = timer.totalDuration;
        _isRunning[timer.subject] = false;
      }

      // 오늘 날짜와 마지막 업데이트 날짜 비교
      final now = DateTime.now();
      final today4am = DateTime(now.year, now.month, now.day, 4, 0);

      // 현재 시간이 오늘 04시 이후이고, 타이머의 마지막 업데이트가 오늘 04시 이전이면 리셋
      if (now.isAfter(today4am)) {
        for (final timer in _userTimers) {
          if (timer.lastUpdated.isBefore(today4am)) {
            _durations[timer.subject] = 0;
            final updatedTimer = timer.copyWith(
              totalDuration: 0,
              lastUpdated: DateTime.now(),
            );
            await _timerService.saveTimer(updatedTimer);
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '타이머 데이터를 불러오는 중 오류가 발생했습니다: $e';
      notifyListeners();
    }
  }

  // 타이머 시작
  void startTimer(String subject) {
    if (_isRunning[subject] == true) return;

    _isRunning[subject] = true;

    // 기존 타이머가 있으면 취소
    _timers[subject]?.cancel();

    // 시작 시간 기록 (백그라운드에서도 정확한 시간 계산을 위해)
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final initialDuration = _durations[subject] ?? 0;

    // 새 타이머 시작
    _timers[subject] =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // 현재 시간과 시작 시간의 차이를 계산하여 정확한 경과 시간 계산
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final elapsedSinceStart = currentTime - startTime;
      _durations[subject] = initialDuration + elapsedSinceStart;

      // 주기적으로 데이터 저장 (10초마다)
      if (elapsedSinceStart % 10000 < 100) {
        _saveTimerData(subject);
      }

      notifyListeners();
    });

    // 활성 타이머 목록 업데이트
    _updateActiveTimers();

    notifyListeners();
  }

  // 타이머 데이터 저장 (백그라운드에서도 작동하도록)
  Future<void> _saveTimerData(String subject) async {
    final timerIndex = _userTimers.indexWhere((t) => t.subject == subject);
    if (timerIndex >= 0) {
      final updatedTimer = _userTimers[timerIndex].copyWith(
        totalDuration: _durations[subject] ?? 0,
        lastUpdated: DateTime.now(),
      );

      _userTimers[timerIndex] = updatedTimer;
      await _timerService.saveTimer(updatedTimer);
    }
  }

  // 타이머 정지
  Future<void> stopTimer(String subject) async {
    if (_isRunning[subject] != true) return;

    _timers[subject]?.cancel();
    _isRunning[subject] = false;

    // 타이머 데이터 저장
    await _saveTimerData(subject);

    // 활성 타이머 목록 업데이트
    _updateActiveTimers();

    notifyListeners();
  }

  // 타이머 리셋
  void resetTimer(String subject) {
    _durations[subject] = 0;
    notifyListeners();
  }

  // 사용자 정의 타이머 추가
  Future<void> addCustomTimer(String subject) async {
    if (subject.isEmpty) return;

    // 이미 존재하는 과목인지 확인
    if (_userTimers.any((timer) => timer.subject == subject)) {
      _error = '이미 존재하는 과목입니다.';
      notifyListeners();
      return;
    }

    final newTimer = StudyTimer(
      id: _uuid.v4(),
      userId: _userId,
      subject: subject,
      totalDuration: 0,
      lastUpdated: DateTime.now(),
      isCustom: true,
    );

    _userTimers.add(newTimer);
    _durations[subject] = 0;
    _isRunning[subject] = false;

    await _timerService.saveTimer(newTimer);
    notifyListeners();
  }

  // 사용자 정의 타이머 삭제
  Future<void> deleteCustomTimer(String subject) async {
    final timerIndex =
        _userTimers.indexWhere((t) => t.subject == subject && t.isCustom);
    if (timerIndex < 0) return;

    final timer = _userTimers[timerIndex];
    _userTimers.removeAt(timerIndex);
    _durations.remove(subject);
    _isRunning.remove(subject);
    _timers[subject]?.cancel();
    _timers.remove(subject);

    await _timerService.deleteTimer(timer.id);
    notifyListeners();
  }

  // 모든 스터디 그룹 로드
  Future<void> loadAllStudyGroups() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allGroups = await _timerService.getAllStudyGroups();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '스터디 그룹을 불러오는 중 오류가 발생했습니다: $e';
      notifyListeners();
    }
  }

  // 사용자의 스터디 그룹 로드
  Future<void> loadUserStudyGroups() async {
    if (_userId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _userGroups = await _timerService.getUserStudyGroups(_userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '사용자의 스터디 그룹을 불러오는 중 오류가 발생했습니다: $e';
      notifyListeners();
    }
  }

  // 스터디 그룹 생성
  Future<bool> createStudyGroup(
    String name,
    String description, {
    String category = '',
    String password = '',
    int? targetTime,
    int? maxMembers,
  }) async {
    if (_userId.isEmpty || name.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final newGroup = StudyGroup(
        id: '', // 서비스에서 자동 생성
        name: name,
        creatorId: _userId,
        memberIds: [_userId], // 생성자는 자동으로 멤버에 추가
        createdAt: DateTime.now(),
        description: description,
        category: category,
        password: password,
        targetTime: targetTime,
        maxMembers: maxMembers,
      );

      final groupId = await _timerService.createStudyGroup(newGroup);
      if (groupId != null) {
        await loadUserStudyGroups(); // 그룹 목록 새로고침
        return true;
      }

      _isLoading = false;
      _error = '스터디 그룹 생성에 실패했습니다.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = '스터디 그룹 생성 중 오류가 발생했습니다: $e';
      notifyListeners();
      return false;
    }
  }

  // 스터디 그룹 참여
  Future<bool> joinStudyGroup(String groupId) async {
    if (_userId.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _timerService.joinStudyGroup(groupId, _userId);
      if (success) {
        await loadUserStudyGroups(); // 그룹 목록 새로고침
        return true;
      }

      _isLoading = false;
      _error = '스터디 그룹 참여에 실패했습니다.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = '스터디 그룹 참여 중 오류가 발생했습니다: $e';
      notifyListeners();
      return false;
    }
  }

  // 스터디 그룹 탈퇴
  Future<bool> leaveStudyGroup(String groupId) async {
    if (_userId.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _timerService.leaveStudyGroup(groupId, _userId);
      if (success) {
        await loadUserStudyGroups(); // 그룹 목록 새로고침
        return true;
      }

      _isLoading = false;
      _error = '스터디 그룹 탈퇴에 실패했습니다.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = '스터디 그룹 탈퇴 중 오류가 발생했습니다: $e';
      notifyListeners();
      return false;
    }
  }

  // 활성 타이머 목록 업데이트
  Future<void> _updateActiveTimers() async {
    if (_userId.isEmpty) return;

    // 현재 실행 중인 타이머 과목 목록
    final activeSubjects = _isRunning.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // 서버에 활성 타이머 목록 업데이트
    await _timerService.updateActiveTimers(_userId, activeSubjects);

    // 사용자가 속한 그룹의 멤버 정보 업데이트
    for (final group in _userGroups) {
      loadGroupMembers(group.id);
    }
  }

  // 그룹 멤버 정보 주기적 업데이트 시작
  Timer? _memberUpdateTimer;
  String? _currentGroupId;

  void startGroupMemberUpdates(String groupId) {
    // 기존 타이머 취소
    _memberUpdateTimer?.cancel();
    _currentGroupId = groupId;

    // 즉시 한 번 로드
    loadGroupMembers(groupId);

    // 1초마다 그룹 멤버 정보 업데이트 (실시간 업데이트)
    _memberUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isLoading) {
        loadGroupMembers(groupId);
      }
    });
  }

  void stopGroupMemberUpdates() {
    _memberUpdateTimer?.cancel();
    _memberUpdateTimer = null;
    _currentGroupId = null;
  }

  // 그룹 멤버 정보 로드
  Future<void> loadGroupMembers(String groupId) async {
    // 이미 로딩 중이면 중복 요청 방지
    if (_isLoading) return;

    try {
      final members = await _timerService.getGroupMembers(groupId);

      // 기존 멤버 정보가 있으면 업데이트만 수행 (로딩 상태 변경 없이)
      if (_groupMembers.containsKey(groupId)) {
        _groupMembers[groupId] = members;
        // 마이크로태스크 큐를 사용하여 빌드 중에 notifyListeners가 호출되는 것을 방지
        Future.microtask(() {
          if (!_isLoading) {
            notifyListeners();
          }
        });
      } else {
        // 처음 로드하는 경우에만 로딩 상태 변경
        _isLoading = true;
        notifyListeners();

        _groupMembers[groupId] = members;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      // 오류가 발생해도 UI에 영향을 최소화
      LoggerUtil.error('그룹 멤버 정보를 불러오는 중 오류가 발생했습니다: $e');

      // 이미 데이터가 있는 경우 오류 표시하지 않음
      if (!_groupMembers.containsKey(groupId)) {
        _isLoading = false;
        _error = '그룹 멤버 정보를 불러오는 중 오류가 발생했습니다: $e';
        notifyListeners();
      }
    }
  }

  // 모든 타이머 정지
  Future<void> stopAllTimers() async {
    for (final subject in _isRunning.keys.toList()) {
      if (_isRunning[subject] == true) {
        await stopTimer(subject);
      }
    }
  }

  @override
  void dispose() {
    // 모든 타이머 정지
    for (final timer in _timers.values) {
      timer?.cancel();
    }

    // 리셋 타이머 취소
    _resetTimer?.cancel();

    // 멤버 업데이트 타이머 취소
    _memberUpdateTimer?.cancel();

    super.dispose();
  }
}
