# 서버 배포 가이드

## 1. Firebase Service Account 설정

1. **Firebase Console 접속**
   - https://console.firebase.google.com
   - 프로젝트 선택

2. **서비스 계정 키 생성**
   - 프로젝트 설정 → 서비스 계정
   - "새 비공개 키 생성" 클릭
   - JSON 파일 다운로드

3. **서버에 키 파일 저장**
   - 다운로드한 JSON 파일을 `firebase-service-account.json`으로 저장
   - **주의**: 이 파일은 절대 Git에 커밋하지 마세요!

## 2. Heroku 배포 (추천)

### Heroku CLI 설치
```bash
# macOS
brew install heroku/brew/heroku

# Windows
# https://devcenter.heroku.com/articles/heroku-cli 에서 다운로드
```

### 앱 생성 및 배포
```bash
# Heroku 로그인
heroku login

# 앱 생성
heroku create your-okbit-auth-server

# 환경 변수 설정
heroku config:set FIREBASE_DATABASE_URL="https://your-project-id.firebaseio.com"

# Service Account 키 설정 (Base64 인코딩)
heroku config:set FIREBASE_SERVICE_ACCOUNT="$(base64 -i firebase-service-account.json)"

# 배포
git add .
git commit -m "Initial deployment"
git push heroku main
```

### 서버 코드 수정 (Heroku용)
`server.js`에서 Service Account 로딩 부분을 수정:

```javascript
// Firebase Admin 초기화 (Heroku용)
let serviceAccount;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  // Heroku 환경 변수에서 로드
  serviceAccount = JSON.parse(
    Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString()
  );
} else {
  // 로컬 파일에서 로드
  serviceAccount = require('./firebase-service-account.json');
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL
});
```

## 3. Vercel 배포

### Vercel CLI 설치
```bash
npm i -g vercel
```

### 배포
```bash
# 로그인
vercel login

# 배포
vercel --prod
```

### 환경 변수 설정
Vercel 대시보드에서 환경 변수 설정:
- `FIREBASE_DATABASE_URL`
- `FIREBASE_SERVICE_ACCOUNT` (Base64 인코딩)

## 4. Flutter 앱 설정 업데이트

서버 배포 후 Flutter 앱의 API 설정을 업데이트:

```dart
// lib/config/api_config.dart
class ApiConfig {
  // 프로덕션 환경
  static const String prodServerUrl = 'https://your-okbit-auth-server.herokuapp.com';
  
  // 배포 시 true로 변경
  static const bool isProduction = true;
}
```

## 5. 보안 체크리스트

- [ ] HTTPS 사용 확인
- [ ] CORS 설정에서 앱 도메인만 허용
- [ ] Firebase Service Account 키 보안
- [ ] 환경 변수로 민감한 정보 관리
- [ ] 로그에서 민감한 정보 제거

## 6. 테스트

배포 후 서버가 정상 동작하는지 테스트:

```bash
# 헬스 체크
curl https://your-server-url.herokuapp.com/health

# 카카오 인증 테스트 (실제 토큰 필요)
curl -X POST https://your-server-url.herokuapp.com/auth/kakao \
  -H "Content-Type: application/json" \
  -d '{"accessToken":"your_kakao_access_token"}'
``` 