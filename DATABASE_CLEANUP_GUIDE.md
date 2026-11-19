# 🧹 Firebase 데이터베이스 정리 가이드

## 📋 개요

이 가이드는 OkBit Go 앱의 Firebase Firestore 데이터베이스를 깔끔하게 정리하고 최적화하는 방법을 제공합니다.

## 🔧 자동 정리 기능

### 1. 중복 데이터 제거
- **D-Day 중복**: 같은 사용자의 동일한 제목 D-Day 중복 제거
- **이벤트 중복**: 같은 사용자의 동일한 제목+날짜 이벤트 중복 제거
- **스터디 타이머 중복**: 같은 사용자+과목의 중복 타이머를 병합하여 시간 합계

### 2. 만료된 데이터 제거
- **삭제된 사용자**: 30일 이상 지난 deleted_users 컬렉션 데이터
- **오래된 알림**: 90일 이상 지난 notifications 컬렉션 데이터
- **관리자 로그**: 365일 이상 지난 admin_logs 컬렉션 데이터

### 3. 고아 데이터 제거
- **참조 무결성 검사**: 존재하지 않는 사용자 ID를 참조하는 데이터 제거
- **D-Day, 이벤트, 스터디 타이머**: 유효하지 않은 userId 참조 정리

### 4. 빈 문서 제거
- **빈 문서**: 데이터가 없는 빈 문서 삭제
- **필수 필드 누락**: 필수 필드가 없는 무효한 문서 삭제

### 5. 데이터 타입 정규화
- **문자열 변환**: grade, classNumber, studentNumber를 String 타입으로 정규화
- **기본값 설정**: 누락된 필드에 기본값 설정
- **알림 설정**: 누락된 notificationSettings 보완

## 🚀 사용 방법

### 관리자 패널에서 실행

```dart
// AdminProvider 사용 예시
final adminProvider = Provider.of<AdminProvider>(context, listen: false);

// 1. 데이터베이스 통계 조회
final stats = await adminProvider.getDatabaseStatistics();
print('총 문서 수: ${stats['total']['documents']}');

// 2. 전체 정리 실행
final results = await adminProvider.performDatabaseCleanup();
print(adminProvider.generateCleanupSummary(results));

// 3. 인덱스 권장사항 조회
final recommendations = adminProvider.getDatabaseIndexRecommendations();
```

### 직접 서비스 사용

```dart
// DatabaseCleanupService 직접 사용
final cleanupService = DatabaseCleanupService();

// 통계 조회
final stats = await cleanupService.getDatabaseStats();

// 전체 정리
final results = await cleanupService.performFullCleanup();
```

## 📊 정리 결과 해석

### 정리 전 통계 예시
```json
{
  "users": {"count": 150, "size": 45120},
  "ddays": {"count": 300, "size": 12800},
  "events": {"count": 250, "size": 18500},
  "studyTimers": {"count": 180, "size": 8900},
  "total": {
    "documents": 880,
    "estimatedSize": "82.34 KB"
  }
}
```

### 정리 결과 예시
```json
{
  "duplicates": {
    "ddays": 15,
    "events": 8,
    "studyTimers": 12
  },
  "expired": {
    "deletedUsers": 5,
    "notifications": 23,
    "adminLogs": 45
  },
  "orphaned": {
    "orphanedDDays": 3,
    "orphanedEvents": 2
  },
  "empty": {
    "users": 0,
    "ddays": 1,
    "events": 0
  },
  "normalized": {
    "users": 18
  }
}
```

## 🔍 권장 인덱스

### 성능 최적화를 위한 복합 인덱스

1. **users 컬렉션**
   ```
   - grade (ASC), classNumber (ASC), createdAt (DESC)
   - isAdmin (ASC), createdAt (DESC)
   - school (ASC), grade (ASC)
   ```

2. **ddays 컬렉션**
   ```
   - userId (ASC), date (ASC)
   - userId (ASC), isCompleted (ASC), date (ASC)
   ```

3. **events 컬렉션**
   ```
   - userId (ASC), date (ASC)
   - userId (ASC), isCompleted (ASC), date (DESC)
   ```

4. **studyTimers 컬렉션**
   ```
   - userId (ASC), subject (ASC)
   - userId (ASC), lastUpdated (DESC)
   ```

5. **notifications 컬렉션**
   ```
   - userId (ASC), isRead (ASC), createdAt (DESC)
   - type (ASC), createdAt (DESC)
   ```

### 인덱스 생성 방법
Firebase 콘솔 → Firestore → 인덱스 → 복합 인덱스 생성

## ⚠️ 주의사항

### 정리 전 확인사항
1. **백업 생성**: 중요한 데이터는 사전에 백업
2. **사용량 확인**: 피크 시간대 피하여 실행
3. **권한 확인**: 관리자 권한으로만 실행

### 정리 빈도 권장
- **일일**: 중복 데이터 정리
- **주간**: 만료된 데이터 정리
- **월간**: 전체 정리 + 인덱스 최적화

### 모니터링
```dart
// 정리 후 성능 모니터링
final beforeStats = await cleanupService.getDatabaseStats();
await cleanupService.performFullCleanup();
final afterStats = await cleanupService.getDatabaseStats();

final sizeDiff = beforeStats['total']['estimatedSize'] - 
                afterStats['total']['estimatedSize'];
print('절약된 용량: $sizeDiff KB');
```

## 🛡️ 보안 고려사항

### 데이터 보호
- 삭제된 사용자 데이터는 30일간 보관 후 완전 삭제
- 민감한 정보는 즉시 암호화 또는 익명화
- 정리 작업 로그는 관리자 로그에 기록

### 접근 제어
- 정리 기능은 관리자만 접근 가능
- 모든 정리 작업은 감사 로그에 기록
- 대량 삭제 시 확인 절차 필수

## 📈 성능 개선 효과

### 예상 개선사항
- **쿼리 속도**: 20-30% 향상
- **저장 용량**: 15-25% 절약
- **인덱스 효율성**: 30-40% 향상
- **앱 응답성**: 전반적 향상

### 측정 방법
```dart
// 성능 측정 예시
final stopwatch = Stopwatch()..start();
final users = await FirebaseFirestore.instance
    .collection('users')
    .where('grade', isEqualTo: '1')
    .get();
stopwatch.stop();
print('쿼리 실행 시간: ${stopwatch.elapsedMilliseconds}ms');
```

## 🔄 자동화 계획

### 향후 개선사항
1. **스케줄링**: 정기적 자동 정리
2. **임계값 기반**: 데이터 크기 기준 자동 실행
3. **알림 시스템**: 정리 완료 알림
4. **상세 리포트**: 정리 결과 상세 분석

### 구현 예시
```dart
// 자동 정리 스케줄러 (향후 구현)
class DatabaseScheduler {
  Timer? _cleanupTimer;
  
  void startScheduledCleanup() {
    _cleanupTimer = Timer.periodic(
      Duration(days: 7), // 주간 정리
      (timer) async {
        await DatabaseCleanupService().performFullCleanup();
      },
    );
  }
}
```

## 📞 문의 및 지원

정리 과정에서 문제가 발생하거나 추가 기능이 필요한 경우:
- 개발팀 문의
- GitHub Issues 등록
- 관리자 패널 로그 확인

---

**마지막 업데이트**: 2024년 12월
**버전**: 1.0.0 