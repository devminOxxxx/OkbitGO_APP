import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:okbit_go_app/config/api_config.dart';
import 'package:okbit_go_app/models/timetable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger_util.dart';

class TimeTableService {
  final http.Client _client = http.Client();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 나이스 API 기본 URL
  final String _naisBaseUrl = 'https://open.neis.go.kr/hub/hisTimetable';

  // 나이스 API 키 (실제 API 키)
  final String _apiKey = ApiConfig.neisApiKey;

  // 시간표 파싱 메서드
  Future<TimeTable> fetchTimeTable({
    required String grade,
    required String classNum,
    String? userId,
    String date = '',
  }) async {
    try {
      LoggerUtil.info('시간표 데이터 로드 시작 - 학년: $grade, 반: $classNum');

      // 1. 사용자별 커스텀 시간표 확인 (Firestore)
      if (userId != null) {
        final customTimeTable =
            await _getCustomTimeTable(userId, grade, classNum);
        if (customTimeTable != null) {
          LoggerUtil.info('사용자 커스텀 시간표 로드 완료');
          return customTimeTable;
        }
      }

      // 2. 나이스 API에서 시간표 데이터 가져오기
      return await _fetchNaisTimeTable(grade, classNum, userId);
    } catch (e) {
      LoggerUtil.error('시간표 데이터 로드 오류: $e');
      return _getDefaultTimeTable(grade, classNum);
    }
  }

  // 나이스 API에서 시간표 데이터 가져오기
  Future<TimeTable> _fetchNaisTimeTable(
      String grade, String classNum, String? userId) async {
    try {
      LoggerUtil.info('나이스 API 시간표 데이터 요청 시작 - 학년: $grade, 반: $classNum');

      // 학교 정보 (실제 학교 정보로 변경)
      final String atptOfcdcScCode = 'J10'; // 경기도 교육청 코드
      final String sdSchulCode = '7531393'; // 학교 코드

      // 현재 날짜 기준 주간 시간표 요청
      final now = DateTime.now();

      // 2025년 3월 17일 기준으로 요청 (API 응답에 맞춤)
      final startDate = DateTime(2025, 3, 17);
      final endDate = DateTime(2025, 3, 21);

      final startDateStr =
          '${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}';
      final endDateStr =
          '${endDate.year}${endDate.month.toString().padLeft(2, '0')}${endDate.day.toString().padLeft(2, '0')}';

      LoggerUtil.info('시간표 요청 기간: $startDateStr ~ $endDateStr');

      // API 요청 URL 구성
      final url =
          Uri.parse('$_naisBaseUrl?KEY=$_apiKey&Type=json&pIndex=1&pSize=500'
              '&ATPT_OFCDC_SC_CODE=$atptOfcdcScCode'
              '&SD_SCHUL_CODE=$sdSchulCode'
              '&GRADE=$grade'
              '&CLASS_NM=$classNum'
              '&TI_FROM_YMD=$startDateStr'
              '&TI_TO_YMD=$endDateStr');

      print('🔍 나이스 API 요청 상세:');
      print('   - 요청 학년: $grade (타입: ${grade.runtimeType})');
      print('   - 요청 반: $classNum (타입: ${classNum.runtimeType})');
      print('   - 사용자 ID: $userId');
      print('   - URL: $url');
      LoggerUtil.info('나이스 API 요청 URL: $url');

      // API 요청
      final response = await _client.get(url);
      LoggerUtil.info('나이스 API 응답 상태 코드: ${response.statusCode}');

      // 응답 본문 로깅 (처음 500자만)
      final responseBody = response.body;
      final previewLength = min(500, responseBody.length);
      LoggerUtil.info(
          '나이스 API 응답 본문 미리보기: ${responseBody.substring(0, previewLength)}...');

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);

        // API 응답 확인
        if (data.containsKey('hisTimetable') &&
            data['hisTimetable'].length >= 2) {
          LoggerUtil.info('나이스 API 응답에 시간표 데이터가 있습니다.');

          // 전체 데이터 개수 확인
          final totalCount =
              data['hisTimetable'][0]['head'][0]['list_total_count'];
          LoggerUtil.info('총 시간표 데이터 수: $totalCount');

          // 요청한 학년, 반과 응답 받은 데이터 비교
          print('🔍 요청 vs 응답 비교:');
          print('   - 요청한 학년: $grade');
          print('   - 요청한 반: $classNum');

          // 첫 번째 데이터에서 실제 학년, 반 확인
          if (data['hisTimetable'][1]['row'] != null &&
              data['hisTimetable'][1]['row'].isNotEmpty) {
            final firstRow = data['hisTimetable'][1]['row'][0];
            print('   - 응답 받은 학년: ${firstRow['GRADE']}');
            print('   - 응답 받은 반: ${firstRow['CLASS_NM']}');
          }

          return _parseNaisTimeTable(data, grade, classNum);
        } else if (data.containsKey('RESULT')) {
          // 오류 응답 처리
          final errorCode = data['RESULT']['CODE'];
          final errorMessage = data['RESULT']['MESSAGE'];
          LoggerUtil.error('나이스 API 오류: [$errorCode] $errorMessage');

          // 오류 로그 출력 후 기본 시간표 반환
          return _getDefaultTimeTable(grade, classNum);
        } else {
          LoggerUtil.info(
              '나이스 API 응답에 시간표 데이터가 없습니다. 응답 구조: ${data.keys.join(', ')}');
          return _getDefaultTimeTable(grade, classNum);
        }
      } else {
        LoggerUtil.error(
            '나이스 API 요청 실패: ${response.statusCode}, 응답: ${response.body}');
        return _getDefaultTimeTable(grade, classNum);
      }
    } catch (e) {
      LoggerUtil.error('나이스 API 요청 오류: $e');
      return _getDefaultTimeTable(grade, classNum);
    }
  }

  // 나이스 API 응답 파싱
  TimeTable _parseNaisTimeTable(
      Map<String, dynamic> data, String grade, String classNum) {
    try {
      // 응답 데이터 구조 확인
      if (!data.containsKey('hisTimetable') ||
          data['hisTimetable'].length < 2) {
        LoggerUtil.error('유효한 시간표 데이터 구조가 아닙니다.');
        return _getDefaultTimeTable(grade, classNum);
      }

      // 'row' 데이터 추출
      var rowData;
      try {
        rowData = data['hisTimetable'][1]['row'];
        if (rowData == null || !(rowData is List) || rowData.isEmpty) {
          LoggerUtil.error('시간표 행 데이터가 없거나 유효하지 않습니다.');
          return _getDefaultTimeTable(grade, classNum);
        }
      } catch (e) {
        LoggerUtil.error('시간표 행 데이터 추출 오류: $e');
        return _getDefaultTimeTable(grade, classNum);
      }

      LoggerUtil.info('나이스 API 응답 데이터 수: ${rowData.length}개');

      // 날짜별 데이터 정리
      Map<String, Map<String, String>> dateSubjects = {};

      // 요일별, 교시별 시간표 데이터 구성 (최대 10교시까지 지원)
      final List<List<String>> subjects =
          List.generate(10, (_) => List.filled(5, ''));
      final List<String> weekdays = ['월', '화', '수', '목', '금'];

      // 최대 교시 수 추적
      int maxPeriod = 0;

      // 각 수업 데이터 처리
      for (var row in rowData) {
        try {
          // 요청한 학년, 반과 일치하는 데이터만 처리
          final String rowGrade = row['GRADE']?.toString() ?? '';
          final String rowClass = row['CLASS_NM']?.toString() ?? '';

          // 학년, 반이 일치하지 않으면 건너뛰기
          if (rowGrade != grade || rowClass != classNum) {
            print(
                '⏭️ 건너뛰기: ${rowGrade}학년 ${rowClass}반 (요청: ${grade}학년 ${classNum}반)');
            continue;
          }

          print('🎯 일치하는 데이터 발견: ${rowGrade}학년 ${rowClass}반');

          print(
              '✅ 처리: ${rowGrade}학년 ${rowClass}반 - ${row['ITRT_CNTNT']} (${row['PERIO']}교시)');

          // 날짜 정보 추출
          final String allTiYmd = row['ALL_TI_YMD']?.toString() ?? '';

          // 교시
          final String perioStr = row['PERIO']?.toString() ?? '0';
          final int period = int.parse(perioStr) - 1;

          // 최대 교시 업데이트
          if (period + 1 > maxPeriod) {
            maxPeriod = period + 1;
          }

          // 과목명 (ITRT_CNTNT 또는 SBJECT_NM 필드 사용)
          String subject = '';
          if (row.containsKey('ITRT_CNTNT') && row['ITRT_CNTNT'] != null) {
            subject = row['ITRT_CNTNT'].toString();
          } else if (row.containsKey('SBJECT_NM') && row['SBJECT_NM'] != null) {
            subject = row['SBJECT_NM'].toString();
          }

          // 교사명
          String teacher = '';
          if (row.containsKey('TCHR_NM') && row['TCHR_NM'] != null) {
            teacher = row['TCHR_NM'].toString();
          }

          // 날짜별 데이터 저장
          if (allTiYmd.isNotEmpty) {
            // 날짜로부터 요일 계산 (2025-03-17은 월요일)
            DateTime date = DateTime(
              int.parse(allTiYmd.substring(0, 4)),
              int.parse(allTiYmd.substring(4, 6)),
              int.parse(allTiYmd.substring(6, 8)),
            );

            int dayOfWeek = date.weekday - 1; // 0: 월, 1: 화, ...

            if (dayOfWeek >= 0 && dayOfWeek < 5 && period >= 0 && period < 10) {
              LoggerUtil.info(
                  '파싱된 데이터: 날짜=$allTiYmd, ${weekdays[dayOfWeek]}요일 ${period + 1}교시 - 과목: $subject, 교사: $teacher');

              if (teacher.isNotEmpty) {
                subject = '$subject\n$teacher';
              }

              // 빈 문자열이 아닌 경우에만 업데이트
              if (subject.isNotEmpty) {
                subjects[period][dayOfWeek] = subject;
              }
            }
          }
        } catch (e) {
          LoggerUtil.error('행 데이터 파싱 오류: $e, 데이터: $row');
          continue;
        }
      }

      // 실제 사용된 교시만 포함하도록 조정 (최소 7교시 보장)
      final int actualMaxPeriod = maxPeriod > 7 ? maxPeriod : 7;
      final List<List<String>> finalSubjects =
          subjects.sublist(0, actualMaxPeriod);

      LoggerUtil.info('최종 시간표 교시 수: $actualMaxPeriod');

      // 각 요일별 과목 데이터 로그 출력
      for (int i = 0; i < finalSubjects.length; i++) {
        LoggerUtil.info('${i + 1}교시: ${finalSubjects[i].join(' | ')}');
      }

      // 빈 시간표인지 확인
      bool isEmpty = true;
      for (var row in finalSubjects) {
        for (var cell in row) {
          if (cell.isNotEmpty) {
            isEmpty = false;
            break;
          }
        }
        if (!isEmpty) break;
      }

      if (isEmpty) {
        LoggerUtil.info('파싱된 시간표가 비어있습니다. 기본 시간표를 반환합니다.');
        return _getDefaultTimeTable(grade, classNum);
      }

      final result = TimeTable(
        grade: grade,
        classNum: classNum,
        subjects: finalSubjects,
        periods: List.generate(actualMaxPeriod, (i) => '${i + 1}교시'),
        weekdays: weekdays,
        startTime: '9:00',
      );

      print('🎯 최종 시간표 생성 완료:');
      print('   - 학년: ${result.grade}');
      print('   - 반: ${result.classNum}');
      print('   - 교시 수: ${result.periods.length}');

      return result;
    } catch (e) {
      LoggerUtil.error('나이스 API 응답 파싱 오류: $e');
      return _getDefaultTimeTable(grade, classNum);
    }
  }

  // 사용자별 커스텀 시간표 가져오기
  Future<TimeTable?> _getCustomTimeTable(
      String userId, String grade, String classNum) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('timetables')
          .doc('${grade}_${classNum}')
          .get();

      if (doc.exists && doc.data() != null) {
        return TimeTable.fromJson(doc.data()!);
      }

      return null;
    } catch (e) {
      LoggerUtil.error('커스텀 시간표 로드 오류: $e');
      return null;
    }
  }

  // 사용자별 커스텀 시간표 저장
  Future<void> saveCustomTimeTable(String userId, TimeTable timeTable) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('timetables')
          .doc('${timeTable.grade}_${timeTable.classNum}')
          .set(timeTable.toJson());

      LoggerUtil.info('커스텀 시간표 저장 완료');
    } catch (e) {
      LoggerUtil.error('커스텀 시간표 저장 오류: $e');
      throw Exception('시간표 저장에 실패했습니다: $e');
    }
  }

  // 기본 시간표 반환
  TimeTable _getDefaultTimeTable(String grade, String classNum) {
    LoggerUtil.info('기본 시간표 반환 - 학년: $grade, 반: $classNum');
    return TimeTable(
      grade: grade,
      classNum: classNum,
      subjects: [
        ['국어', '수학', '영어', '과학', '사회'],
        ['체육', '수학', '국어', '영어', '음악'],
        ['사회', '국어', '수학', '미술', '영어'],
        ['과학', '영어', '국어', '수학', '체육'],
        ['음악', '사회', '과학', '국어', '수학'],
        ['영어', '과학', '사회', '수학', '국어'],
        ['진로', '창체', '창체', '창체', '자율'],
      ],
      periods: List.generate(7, (i) => '${i + 1}교시'),
      weekdays: const ['월', '화', '수', '목', '금'],
      startTime: '9:00',
    );
  }

  // 최소값 계산 헬퍼 함수
  int min(int a, int b) {
    return a < b ? a : b;
  }

  void dispose() {
    _client.close();
  }
}
