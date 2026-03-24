# 작업 결과 보고

## 작업 일자
2026-03-21

---

## 재촉하기 알림 전체 플로우 구현

### 구현 내용

#### 1. 실시간 푸시 알림 (APNs)

**서버 변경 사항:**

- `prisma/schema.prisma` — `User.apnsToken String? @map("apns_token")` 필드 추가, `prisma db push`로 적용
- `src/services/PushNotificationService.ts` (신규) — APNs 토큰 기반 인증(ES256/JWT)으로 HTTP/2 푸시 발송
- `src/services/UserService.ts` — `registerDeviceToken(userId, token)` 추가
- `src/controllers/UserController.ts` — `PATCH /users/me/device-token` 엔드포인트 추가
- `src/services/NudgeService.ts` — 알림 DB 저장 후 APNs 푸시 발송 (`target.apnsToken` 있을 때만, 실패 무시)

**APNs 환경 변수 설정 필요 (서버):**
```
APNS_KEY_ID       = Apple Push Key ID (10자리)
APNS_TEAM_ID      = Apple Team ID (10자리)
APNS_BUNDLE_ID    = 앱 Bundle ID (예: com.yourcompany.mongle)
APNS_PRIVATE_KEY  = .p8 파일 내용 (줄바꿈 \n 또는 base64 인코딩)
NODE_ENV          = production (실서버) / 그 외 sandbox
```

#### 2. iOS 디바이스 토큰 등록

- `Domain/UserRepositoryProtocol.swift` — `registerDeviceToken(token:)` 메서드 추가
- `MongleData/.../APIEndpoint.swift` — `UserEndpoint.registerDeviceToken(token:)` 케이스 추가 (`PATCH /users/me/device-token`)
- `MongleData/.../UserRepository.swift` — 구현
- `MongleApp.swift` — `UIApplicationDelegateAdaptor`로 `MongleAppDelegate` 추가:
  - `didRegisterForRemoteNotificationsWithDeviceToken` → `.deviceTokenReceived(Data)` 액션 전달
  - `willPresent` → 포그라운드 알림 배너 표시
  - `didReceive response` → `type == "ANSWER_REQUEST"` 이면 `.openQuestion` 액션 전달
  - `UNUserNotificationCenter.delegate` 설정

#### 3. 푸시 알림 탭 → 마음남기기 화면 이동

- `Root+Action.swift` — `.deviceTokenReceived(Data)`, `.openQuestion` 액션 추가
- `Root+State.swift` — `pendingOpenQuestion: Bool` 플래그 추가
- `Root+Reducer.swift`:
  - `loadDataResponse(.success)` 시 APNs 등록 호출 (`UIApplication.shared.registerForRemoteNotifications()`)
  - `.deviceTokenReceived` → 서버에 토큰 등록
  - `.openQuestion` → 인증 상태면 즉시 질문 화면 이동, 로딩 중이면 `pendingOpenQuestion = true` 후 로딩 완료 시 이동

#### 4. 인앱 알림창 탭 → 마음남기기 화면 이동

- `NotificationFeature.swift` — `.answerRequest` 탭 처리를 `.navigateToQuestion` 위임 액션으로 변경 (기존: `.navigateToPeerNotAnsweredNudge` → 재촉화면으로 잘못 이동)
- `MainTab+Reducer.swift` — `.notification(.delegate(.navigateToQuestion))` 핸들러 추가: 알림 화면 pop 후 오늘의 질문 QuestionDetailView push

### 푸시 알림 페이로드 구조
```json
{
  "aps": {
    "alert": { "title": "재촉하기 알림", "body": "{이름}님이 오늘의 질문에 답변해달라고 합니다 🌿" },
    "sound": "default",
    "badge": 1
  },
  "type": "ANSWER_REQUEST"
}
```

### 빌드 확인
- 서버: `npm run build` 성공
- iOS: `xcodebuild` BUILD SUCCEEDED
