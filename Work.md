# 작업

## 위치
- 디자인: /Users/yong/Desktop/FamTree/MongleUI
- iOS: /Users/yong/Desktop/FamTree
- Android: /Users/yong/Mongle-Android
- 서버: /Users/yong/Desktop/MongleServer

## 구글 ad정보

iOS
앱ID : ca-app-pub-4718464707406824~3555712259
- 배너: ca-app-pub-4718464707406824/5359748516
- 보상형: ca-app-pub-4718464707406824/2869316545

Android
앱ID: ca-app-pub-4718464707406824~8995741193
- 배너: ca-app-pub-4718464707406824/2974225929
- 보상형: ca-app-pub-4718464707406824/9365243021

---

# 배포 전 점검 — 수정 결과

## iOS

### CRITICAL

| # | 상태 | 내용 | 조치 |
|---|------|------|------|
| C1 | ✅ | Secrets.swift | 이미 설정됨 |
| C2 | ✅ | fatalError() 7곳 | → throw Error로 교체 |
| C3 | ✅ | 이용약관/개인정보 URL | 연락처 이메일 support@monggle.app으로 수정 |
| C4 | ✅ | 앱 아이콘 | 이미 존재 |
| C5 | ✅ | Mock 데이터 | #Preview 내에만 존재 |

### WARNING

| # | 상태 | 내용 | 조치 |
|---|------|------|------|
| W1 | ✅ | 초대 링크 도메인 불일치 | AppConfig.swift 생성, 하드코딩 URL 통일 |
| W2 | ✅ | Force unwrap | Optional.map 안전 처리 |
| W3 | ✅ | 토큰 평문 저장 | Keychain 전환 + 자동 마이그레이션 |
| W4 | ✅ | print() 문 | 이미 #if DEBUG 적용 |
| W5 | ⚠️ | TODO 댓글 | fatalError 관련은 해결, 알림설정 저장 등은 별도 |
| W6 | ✅ | 패키지 iOS 버전 불일치 | iOS 17로 통일 |

---

## Android

### CRITICAL

| # | 상태 | 내용 | 조치 |
|---|------|------|------|
| C1 | ✅ | Release signing 미설정 | signingConfigs 추가 + keystore.properties 패턴 |
| C2 | ⚠️ | Auth 토큰 SharedPreferences 저장 | MODE_PRIVATE 사용 중 (EncryptedSharedPreferences 전환은 추후) |
| C3 | ✅ | API 키 하드코딩 | Kakao/Google/Apple/AdMob 키 → BuildConfig로 이동 |
| C4 | ✅ | BASE_URL 중복 하드코딩 | NetworkModule/TokenAuthenticator/SocialLoginHelper → BuildConfig.BASE_URL 통일 |

### WARNING

| # | 상태 | 내용 | 조치 |
|---|------|------|------|
| W1 | ✅ | 민감 정보 로그 | 토큰/이메일/body 로깅 제거 (SocialLoginHelper, ApiAuthRepository) |
| W2 | ✅ | network_security_config.xml 없음 | 생성 + cleartext 차단 설정 |
| W3 | ✅ | allowBackup="true" | → false로 변경 |
| W4 | ✅ | FCM 알림 아이콘 | ic_notification.xml (하트) 생성, ic_launcher 대체 |
| W5 | ✅ | 일본어 번역 누락 | 요일 문자열 7개 추가 (日月火水木金土) |
| W6 | ✅ | google-services.json | .gitignore에 이미 포함, git 추적 안 됨 |
| W7 | ⚠️ | 의존성 버전 오래됨 | 추후 업데이트 예정 |
| - | ✅ | enableJetifier | false로 변경 |
| - | ✅ | .gitignore | keystore.properties 추가 |
