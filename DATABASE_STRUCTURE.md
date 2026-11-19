# 📊 데이터베이스 구조 문서

## 🏗️ Firestore 컬렉션 구조

### 1. **users** 컬렉션
사용자 정보를 저장하는 메인 컬렉션

```typescript
{
  id: string,                    // 사용자 고유 ID (Firebase UID)
  email: string,                 // 이메일 주소
  name: string,                  // 사용자 이름
  photoUrl?: string,             // 프로필 사진 URL
  school?: string,               // 학교명 (기본: 옥빛고등학교)
  grade?: string,                // 학년 (String 타입으로 정규화)
  classNumber?: string,          // 반 (String 타입으로 정규화)
  studentNumber?: string,        // 학번 (String 타입으로 정규화)
  isAdmin: boolean,              // 관리자 여부 (기본: false)
  isBlocked?: boolean,           // 차단 여부
  blockedAt?: Timestamp,         // 차단 시간
  lastActive?: Timestamp,        // 마지막 활동 시간
  notificationSettings: {        // 알림 설정
    meal: boolean,
    timetable: boolean,
    notice: boolean,
    event: boolean,
    exam: boolean,
    dday: boolean
  },
  createdAt: Timestamp,          // 계정 생성일
  updatedAt: Timestamp,          // 마지막 업데이트일
  theme: string,                 // 테마 설정 (기본: 'system')
  allergies: string[],           // 알레르기 정보
  additionalInfoCompleted: boolean, // 추가 정보 입력 완료 여부
  isTemporaryEmail: boolean      // 임시 이메일 여부
}
```

**서브컬렉션:**
- `timetables/`: 사용자별 커스텀 시간표

### 2. **ddays** 컬렉션
디데이 정보 저장

```typescript
{
  id: string,                    // 디데이 고유 ID
  title: string,                 // 디데이 제목
  date: Timestamp,               // 목표 날짜
  userId: string,                // 사용자 ID
  isCompleted: boolean,          // 완료 여부 (기본: false)
  createdAt: Timestamp           // 생성일
}
```

### 3. **events** 컬렉션
사용자 개인 일정 저장

```typescript
{
  id: string,                    // 이벤트 고유 ID
  title: string,                 // 일정 제목
  description?: string,          // 일정 설명
  date: Timestamp,               // 일정 날짜
  userId: string,                // 사용자 ID
  isCompleted: boolean,          // 완료 여부
  type: string                   // 일정 유형
}
```

### 4. **exams** 컬렉션
시험 점수 및 등급컷 정보

```typescript
{
  id: string,                    // 시험 ID (exam_subject 형식)
  exam: string,                  // 시험명
  subject: string,               // 과목명
  scores: number[],              // 점수 배열 (익명)
  totalScore: number,            // 만점
  updatedAt: Timestamp           // 마지막 업데이트
}
```

### 5. **studyTimers** 컬렉션
공부 타이머 기록

```typescript
{
  id: string,                    // 타이머 고유 ID
  userId: string,                // 사용자 ID
  subject: string,               // 과목명
  totalDuration: number,         // 총 공부 시간 (밀리초)
  lastUpdated: Timestamp,        // 마지막 업데이트
  isCustom: boolean              // 사용자 정의 과목 여부
}
```

### 6. **studyGroups** 컬렉션
스터디 그룹 정보

```typescript
{
  id: string,                    // 그룹 고유 ID
  title: string,                 // 그룹명
  description?: string,          // 그룹 설명
  memberIds: string[],           // 멤버 ID 배열
  maxMembers: number,            // 최대 멤버 수
  isActive: boolean,             // 활성 상태
  createdAt: Timestamp           // 생성일
}
```

### 7. **deleted_users** 컬렉션
삭제된 사용자 백업 (30일 보관)

```typescript
{
  id: string,                    // 원본 사용자 ID
  originalUserId: string,        // 원본 사용자 ID (참조용)
  deletedAt: Timestamp,          // 삭제 시간
  expiresAt: Timestamp,          // 만료 시간 (30일 후)
  ...userData                    // 원본 사용자 데이터
}
```

### 8. **notifications** 컬렉션
알림 정보

```typescript
{
  id: string,                    // 알림 고유 ID
  userId: string,                // 대상 사용자 ID
  type: string,                  // 알림 타입
  title: string,                 // 알림 제목
  message: string,               // 알림 내용
  isRead: boolean,               // 읽음 여부
  priority: string,              // 우선순위 (high, normal, low)
  createdAt: Timestamp,          // 생성일
  expiresAt: Timestamp           // 만료일 (90일 후)
}
```

### 9. **admin_logs** 컬렉션
관리자 활동 로그

```typescript
{
  id: string,                    // 로그 고유 ID
  adminId: string,               // 관리자 ID
  action: string,                // 수행한 작업
  description: string,           // 작업 설명
  targetUser?: string,           // 대상 사용자 (해당되는 경우)
  metadata?: object,             // 추가 메타데이터
  createdAt: Timestamp,          // 생성일
  expiresAt: Timestamp           // 만료일 (365일 후)
}
```

## 🧹 데이터베이스 정리 및 최적화

### 자동 정리 기능

1. **중복 데이터 제거**
   - 같은 사용자의 중복 D-Day, 이벤트, 스터디 타이머 정리
   - 스터디 타이머는 시간 합계 후 통합

2. **만료된 데이터 제거**
   - deleted_users: 30일 후 완전 삭제
   - notifications: 90일 후 자동 삭제
   - admin_logs: 365일 후 자동 삭제

3. **고아 데이터 제거**
   - 존재하지 않는 userId를 참조하는 데이터 정리
   - 참조 무결성 유지

4. **데이터 타입 정규화**
   - grade, classNumber, studentNumber를 String 타입으로 통일
   - 누락된 기본값 설정

### 정리 서비스 사용법

```dart
// DatabaseCleanupService 사용
final cleanupService = DatabaseCleanupService();

// 전체 정리 실행
final results = await cleanupService.performFullCleanup();

// 통계 조회
final stats = await cleanupService.getDatabaseStats();

// 관리자 패널에서 사용
final adminProvider = AdminProvider();
await adminProvider.performDatabaseCleanup();
```

## 🔍 성능 최적화

### 권장 복합 인덱스

1. **users 컬렉션**
   ```
   - grade (ASC), classNumber (ASC), createdAt (DESC)
   - isAdmin (ASC), createdAt (DESC)
   - school (ASC), grade (ASC)
   - isBlocked (ASC), createdAt (DESC)
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
   - expiresAt (ASC)
   ```

6. **admin_logs 컬렉션**
   ```
   - adminId (ASC), createdAt (DESC)
   - action (ASC), createdAt (DESC)
   - expiresAt (ASC)
   ```

### 쿼리 최적화 가이드

1. **페이지네이션 사용**
   ```dart
   // 좋은 예시
   final query = FirebaseFirestore.instance
       .collection('users')
       .orderBy('createdAt', descending: true)
       .limit(20);
   ```

2. **복합 인덱스 활용**
   ```dart
   // 복합 인덱스 활용 예시
   final query = FirebaseFirestore.instance
       .collection('ddays')
       .where('userId', isEqualTo: userId)
       .where('isCompleted', isEqualTo: false)
       .orderBy('date');
   ```

3. **불필요한 필드 제외**
   ```dart
   // 필요한 필드만 선택
   final query = FirebaseFirestore.instance
       .collection('users')
       .select(['name', 'grade', 'classNumber']);
   ```

## 🛡️ 보안 규칙

### 권장 Firestore 보안 규칙

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 사용자는 자신의 데이터만 접근 가능
    match /users/{userId} {
      allow read, write: if request.auth != null && 
                         (request.auth.uid == userId || 
                          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true);
    }
    
    // D-Day는 소유자만 접근 가능
    match /ddays/{ddayId} {
      allow read, write: if request.auth != null && 
                         request.auth.uid == resource.data.userId;
    }
    
    // 이벤트는 소유자만 접근 가능
    match /events/{eventId} {
      allow read, write: if request.auth != null && 
                         request.auth.uid == resource.data.userId;
    }
    
    // 스터디 타이머는 소유자만 접근 가능
    match /studyTimers/{timerId} {
      allow read, write: if request.auth != null && 
                         request.auth.uid == resource.data.userId;
    }
    
    // 삭제된 사용자 데이터는 관리자만 접근 가능
    match /deleted_users/{userId} {
      allow read, write: if request.auth != null && 
                         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // 알림은 대상 사용자와 관리자만 접근 가능
    match /notifications/{notificationId} {
      allow read: if request.auth != null && 
                  (request.auth.uid == resource.data.userId || 
                   get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true);
      allow write: if request.auth != null && 
                   get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // 관리자 로그는 관리자만 접근 가능
    match /admin_logs/{logId} {
      allow read, write: if request.auth != null && 
                         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

## 📊 모니터링 및 분석

### 데이터베이스 상태 모니터링

```dart
// 정기적 상태 체크
class DatabaseMonitor {
  static Future<Map<String, dynamic>> getHealthStatus() async {
    final cleanupService = DatabaseCleanupService();
    final stats = await cleanupService.getDatabaseStats();
    
    return {
      'totalDocuments': stats['total']['documents'],
      'estimatedSize': stats['total']['estimatedSize'],
      'collections': stats.keys.where((k) => k != 'total').length,
      'lastCleanup': await _getLastCleanupTime(),
      'needsCleanup': await _needsCleanup(stats),
    };
  }
}
```

### 성능 메트릭

1. **쿼리 성능**
   - 평균 응답 시간: < 500ms
   - 복합 쿼리: < 1000ms
   - 대용량 쿼리: < 2000ms

2. **저장 용량**
   - 사용자당 평균: < 1KB
   - 전체 데이터베이스: < 100MB
   - 증가율: < 10MB/월

3. **정리 효과**
   - 중복 제거율: 5-10%
   - 용량 절약: 15-25%
   - 쿼리 속도 향상: 20-30%

---

**마지막 업데이트**: 2024년 12월  
**버전**: 2.0.0 (정리 기능 추가) 