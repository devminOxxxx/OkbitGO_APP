import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timetable_provider.dart';
import '../providers/user_provider.dart';
import '../models/timetable.dart';
import '../widgets/school_life/timetable/timetable_grid.dart';
import '../widgets/school_life/timetable/timetable_edit_dialog.dart';
import '../widgets/school_life/timetable/timetable_capture_widget.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'debug_user_info_screen.dart';
import '../services/user_fix_service.dart';

class TimeTableScreen extends StatefulWidget {
  const TimeTableScreen({Key? key}) : super(key: key);

  @override
  State<TimeTableScreen> createState() => _TimeTableScreenState();
}

class _TimeTableScreenState extends State<TimeTableScreen> {
  String _selectedGrade = '1';
  String _selectedClass = '1';
  final List<String> _grades = ['1', '2', '3'];
  final Map<String, List<String>> _classesByGrade = {
    '1': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'],
    '2': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'],
    '3': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'],
  };
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _screenshotKey = GlobalKey();
  bool _isCapturing = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    print('🚀 TimeTableScreen initState 시작');
    // 초기 시간표 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🚀 PostFrameCallback 실행, _loadUserSettings 호출');
      _loadUserSettings();
    });
    print('🚀 TimeTableScreen initState 완료');
  }

  void _loadUserSettings() async {
    print('🔧 _loadUserSettings 시작');
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // 사용자 정보가 로드될 때까지 대기
    if (userProvider.user == null) {
      print('🔧 사용자 정보 없음, checkAuthState 호출');
      await userProvider.checkAuthState();
    }

    final user = userProvider.user;

    print('🔧 강제로 3학년 6반으로 설정');
    setState(() {
      _userId = user?.id;
      _selectedGrade = '3';
      _selectedClass = '6';
    });

    print('📋 시간표 로드 준비:');
    print('   - 사용자 ID: $_userId');
    print('   - 학년: $_selectedGrade');
    print('   - 반: $_selectedClass');

    // 잠깐 대기 후 시간표 로드 (setState가 완료될 때까지)
    await Future.delayed(Duration(milliseconds: 100));

    // 사용자 정보가 설정된 후에 시간표 로드
    print('🔧 _loadTimeTable 호출');
    _loadTimeTable();
    print('🔧 _loadUserSettings 완료');
  }

  void _loadTimeTable() async {
    final provider = Provider.of<TimeTableProvider>(context, listen: false);

    print('🔄 시간표 로드 시작:');
    print('   - 선택된 학년: $_selectedGrade (타입: ${_selectedGrade.runtimeType})');
    print('   - 선택된 반: $_selectedClass (타입: ${_selectedClass.runtimeType})');
    print('   - 사용자 ID: $_userId');

    print('📋 설정 전 프로바이더 상태:');
    print('   - 프로바이더 학년: ${provider.grade}');
    print('   - 프로바이더 반: ${provider.classNum}');
    print('   - 프로바이더 사용자ID: ${provider.userId}');

    // 강제로 사용자 정보 설정
    provider.setGrade(_selectedGrade);
    provider.setClassNum(_selectedClass);
    provider.setUserId(_userId);

    print('📋 설정 후 프로바이더 상태:');
    print('   - 프로바이더 학년: ${provider.grade}');
    print('   - 프로바이더 반: ${provider.classNum}');
    print('   - 프로바이더 사용자ID: ${provider.userId}');

    // 기존 시간표 데이터 완전히 초기화
    await provider.clearTimeTable();

    // 강제로 새로고침
    provider.fetchTimeTable(forceRefresh: true);
  }

  // 시간표 캡처 및 공유
  Future<void> _captureAndShareTimeTable() async {
    final provider = Provider.of<TimeTableProvider>(context, listen: false);
    final timeTable = provider.timeTable;

    if (timeTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시간표 데이터가 없습니다.')),
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // 현재 주차 계산
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 4));
      final currentWeek =
          '${DateFormat('M.d').format(weekStart)} ~ ${DateFormat('M.d').format(weekEnd)}';

      // 캡처용 위젯을 이용해 스크린샷 생성
      final captureWidget = TimeTableCaptureWidget(
        timeTable: timeTable,
        currentWeek: currentWeek,
      );

      // 스크린샷 캡처
      final Uint8List? imageBytes =
          await _screenshotController.captureFromWidget(
        captureWidget,
        pixelRatio: 3.0,
      );

      if (imageBytes != null) {
        // 갤러리에 저장
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          name:
              'timetable_${_selectedGrade}_${_selectedClass}_${DateFormat('yyyyMMdd_HHmmss').format(now)}',
          quality: 100,
        );

        if (result['isSuccess'] == true) {
          // 저장 성공 후 공유 옵션 제공
          _showShareOptions(imageBytes, timeTable);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('시간표 저장에 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시간표 캡처 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  // 공유 옵션 다이얼로그
  void _showShareOptions(Uint8List imageBytes, TimeTable timeTable) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            '시간표 캡처 완료',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '시간표가 갤러리에 저장되었습니다.\n다른 앱으로 공유하시겠습니까?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _shareImage(imageBytes, timeTable);
              },
              child: const Text('공유하기'),
            ),
          ],
        );
      },
    );
  }

  // 이미지 공유
  Future<void> _shareImage(Uint8List imageBytes, TimeTable timeTable) async {
    try {
      // 임시 파일로 저장
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/timetable_share.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // 이미지 공유
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: '${timeTable.grade}학년 ${timeTable.classNum}반 시간표',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('공유 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 시간표 저장
  Future<void> _saveTimeTable() async {
    final provider = Provider.of<TimeTableProvider>(context, listen: false);
    final timeTable = provider.timeTable;

    if (timeTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시간표 데이터가 없습니다.')),
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      // 현재 주차 계산
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 4));
      final currentWeek =
          '${DateFormat('M.d').format(weekStart)} ~ ${DateFormat('M.d').format(weekEnd)}';

      // 캡처용 위젯을 이용해 스크린샷 생성
      final captureWidget = TimeTableCaptureWidget(
        timeTable: timeTable,
        currentWeek: currentWeek,
      );

      // 스크린샷 캡처
      final Uint8List? imageBytes =
          await _screenshotController.captureFromWidget(
        captureWidget,
        pixelRatio: 3.0,
      );

      if (imageBytes != null) {
        // 갤러리에 저장
        final directory = await getApplicationDocumentsDirectory();
        final imagePath =
            '${directory.path}/timetable_${_selectedGrade}_${_selectedClass}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('시간표가 저장되었습니다: $imagePath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시간표 저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  // 과목 수정 다이얼로그 표시
  void _showEditSubjectDialog(int periodIndex, int dayIndex,
      String currentSubject, String currentTeacher) async {
    final provider = Provider.of<TimeTableProvider>(context, listen: false);
    final timeTable = provider.timeTable;

    if (timeTable == null) {
      return;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return TimeTableEditDialog(
          timeTable: timeTable,
          periodIndex: periodIndex,
          dayIndex: dayIndex,
          currentSubject: currentSubject,
          currentTeacher: currentTeacher,
        );
      },
    );

    if (result != null) {
      // 과목명과 교사명 분리
      final fullSubject = result['subject']!;
      final parts = fullSubject.split('\n');
      final subject = parts[0];
      final teacher = parts.length > 1 ? parts[1] : '';

      // 과목 업데이트
      await provider.updateSubject(periodIndex, dayIndex, subject, teacher);

      // 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${timeTable.weekdays[dayIndex]} ${periodIndex + 1}교시 과목이 수정되었습니다.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시간표'),
        elevation: 0,
        actions: [
          // 학년 선택
          _buildGradeSelector(),
          const SizedBox(width: 8),
          // 반 선택
          _buildClassSelector(),
          const SizedBox(width: 8),
          // 저장 버튼
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _isCapturing ? null : _saveTimeTable,
            tooltip: '시간표 저장',
          ),
          // 공유 버튼
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isCapturing ? null : _captureAndShareTimeTable,
            tooltip: '시간표 공유',
          ),
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimeTable,
            tooltip: '시간표 새로고침',
          ),
          // 디버그 버튼
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugUserInfoScreen(),
                ),
              );
            },
            tooltip: '사용자 정보 디버그',
          ),
        ],
      ),
      body: Consumer<TimeTableProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('시간표를 불러오는 중입니다...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTimeTable,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (provider.timeTable == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('시간표 데이터가 없습니다.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTimeTable,
                    child: const Text('시간표 불러오기'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '학년: $_selectedGrade, 반: $_selectedClass, 사용자 ID: ${_userId ?? "없음"}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 시간표 위젯 표시
          return Column(
            children: [
              // 시간표 정보 표시
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${provider.timeTable!.grade}학년 ${provider.timeTable!.classNum}반 시간표',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '과목을 탭하여 수정',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (provider.message != null)
                      Text(
                        provider.message!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              // 시간표 그리드 (Expanded로 감싸서 남은 공간을 모두 차지하도록 함)
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Screenshot(
                    controller: _screenshotController,
                    child: TimeTableGrid(
                      timeTable: provider.timeTable!,
                      onSubjectTap: _showEditSubjectDialog,
                      screenshotKey: _screenshotKey,
                    ),
                  ),
                ),
              ),
              // 시간표 캡처 버튼
              SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: _isCapturing ? null : _captureAndShareTimeTable,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: _isCapturing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('처리 중...'),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt),
                              SizedBox(width: 8),
                              Text('시간표 캡처하기', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGradeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButton<String>(
        value: _selectedGrade,
        hint: const Text('학년'),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        borderRadius: BorderRadius.circular(8.0),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedGrade = newValue;
              // 학년이 변경되면 해당 학년의 첫 번째 반으로 설정
              _selectedClass = _classesByGrade[newValue]![0];
            });
            _loadTimeTable();
          }
        },
        items: _grades.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              '$value학년',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DropdownButton<String>(
        value: _selectedClass,
        hint: const Text('반'),
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        borderRadius: BorderRadius.circular(8.0),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedClass = newValue;
            });
            _loadTimeTable();
          }
        },
        items: _classesByGrade[_selectedGrade]!
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              '$value반',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
