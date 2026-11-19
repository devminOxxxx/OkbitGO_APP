# 옥빛GO 앱

옥빛고등학교 학생들을 위한 종합 정보 앱입니다.

## 소셜 로그인 설정 가이드

### 카카오 로그인 설정

1. **카카오 개발자 콘솔 설정**
   - [카카오 개발자 콘솔](https://developers.kakao.com)에서 앱 등록
   - 네이티브 앱 키는 `secrets.dart` / `secrets.properties`에만 넣기
   - 플랫폼 등록:
     - Android: 패키지명 `com.example.okbit_go_app`, 키 해시 등록
     - iOS: 번들 ID 등록

2. **필수 권한 설정**
   - 카카오 로그인 활성화
   - 필수 동의 항목: 닉네임, 프로필 사진
   - 선택 동의 항목: 이메일 (필수로 변경 권장)

3. **주의사항**
   - 카카오 계정에 이메일이 등록되어 있어야 함
   - 카카오톡이 설치되어 있지 않은 경우 웹 로그인으로 전환됨
   - 실제 서비스에서는 서버를 통한 Firebase Custom Token 발급 필요

### 애플 로그인 설정

1. **Apple Developer 계정 설정**
   - [Apple Developer](https://developer.apple.com)에서 Sign in with Apple 활성화
   - Service ID: `com.okbit.service`
   - 리다이렉트 URL: `https://okbit-go-app.firebaseapp.com/__/auth/handler`

2. **Firebase 설정**
   - Authentication에서 Apple 로그인 활성화
   - Service ID 등록

3. **주의사항**
   - 애플은 첫 로그인 시에만 이름과 이메일 정보를 제공함
   - 이후 로그인에서는 정보가 제공되지 않으므로 첫 로그인 시 저장 필요
   - Android에서는 웹 인증 방식으로 동작함
   - 실제 iOS 기기에서만 정상 작동 (시뮬레이터에서는 작동하지 않음)

### 디자인 가이드라인

1. **카카오 로그인 버튼**
   - 배경색: `#FEE500`
   - 텍스트 색상: `#191919`
   - 텍스트: "카카오로 시작하기" 또는 "카카오로 로그인"
   - 로고와 텍스트 사이 간격: 8px

2. **애플 로그인 버튼**
   - 배경색: 검은색 (`#000000`)
   - 텍스트 색상: 흰색 (`#FFFFFF`)
   - 텍스트: "Apple로 로그인" 또는 "Sign in with Apple"
   - 로고와 텍스트 사이 간격: 8px
   - 테두리: 어두운 회색 (다크 모드에서만)

## 설치 및 실행

비밀값은 git에 올리지 않습니다. 클론 후 예시 파일을 복사하세요.

```bash
cp lib/config/secrets.example.dart lib/config/secrets.dart
cp secrets.properties.example secrets.properties
cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig
cp lib/firebase_options.example.dart lib/firebase_options.dart
cp android/app/google-services.json.example android/app/google-services.json
cp ios/Runner/GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
cp server/env.example server/.env
```

Firebase는 FlutterFire CLI로 다시 생성하거나, 콘솔에서 받은 파일을 위 경로에 넣으면 됩니다.

```bash
# 패키지 설치
flutter pub get

# iOS 설정
cd ios
pod install
cd ..

# 앱 실행
flutter run
```