# Okbit Auth Server

카카오 로그인을 위한 Firebase Custom Token 발급 서버입니다.

## 설치 및 설정

### 1. 의존성 설치
```bash
npm install
```

### 2. Firebase Service Account 설정
1. Firebase Console에서 프로젝트 설정 → 서비스 계정
2. "새 비공개 키 생성" 클릭
3. 다운로드된 JSON 파일을 `firebase-service-account.json`으로 저장

### 3. 환경 변수 설정
```bash
cp env.example .env
```
`.env` 파일을 편집하여 실제 값으로 설정:
- `FIREBASE_DATABASE_URL`: Firebase 프로젝트의 Realtime Database URL

### 4. 서버 실행
```bash
# 개발 모드
npm run dev

# 프로덕션 모드
npm start
```

## API 엔드포인트

### POST /auth/kakao
카카오 액세스 토큰을 받아 Firebase Custom Token을 반환합니다.

**Request:**
```json
{
  "accessToken": "카카오_액세스_토큰"
}
```

**Response:**
```json
{
  "customToken": "firebase_custom_token",
  "userInfo": {
    "id": "카카오_사용자_ID",
    "email": "사용자_이메일",
    "displayName": "사용자_닉네임",
    "photoURL": "프로필_이미지_URL"
  }
}
```

## 배포

### Heroku 배포
1. Heroku CLI 설치
2. `heroku create your-app-name`
3. `git push heroku main`

### Vercel 배포
1. Vercel CLI 설치
2. `vercel --prod`

## 보안 고려사항

- HTTPS 사용 필수
- CORS 설정에서 허용된 도메인만 접근 가능하도록 설정
- Firebase Service Account 키는 절대 공개하지 않음
- 프로덕션에서는 환경 변수로 민감한 정보 관리 