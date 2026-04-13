# 작업

아래 이슈를 확인하고 수정할 것
- 노션에 티켓 발급 후 버그리포트 작성
- iOS 에이전트가 수정 후 QA 에이전트에게 컨펌받을 것

---

## BUG-01: 로그아웃 후 다른 계정 알림 수신 (Critical)

**현상:** 아이폰에서 로그아웃하고 다른 계정으로 로그인해도, 이전 계정의 알림이 계속 수신됨

**근본 원인:** 서버 로그아웃 시 device token을 삭제하지 않음
- `POST /auth/logout` → 단순히 `{ message: '로그아웃 되었습니다.' }` 반환만 함
- `User.apnsToken` / `User.fcmToken` 필드를 null 처리하지 않음
- 동일 디바이스 = 동일 APNs 토큰 → 이전 유저 DB에 토큰이 남아있어 양쪽 모두 푸시 수신

**관련 코드:**
- 서버: `MongleServer/src/controllers/AuthController.ts:89-93` — logout 핸들러 (토큰 정리 없음)
- iOS: `Root+Reducer.swift:296-308` — logout action (서버에 토큰 삭제 요청 없음)
- 서버: `MongleServer/src/services/UserService.ts` — registerDeviceToken (덮어쓰기만, 이전 유저 정리 없음)

**수정 방안:**
1. **서버**: `AuthController.logout()` 에서 `User.apnsToken = null`, `User.fcmToken = null` 업데이트
2. **서버**: `registerDeviceToken()` 호출 시, 동일 토큰을 가진 다른 유저의 토큰을 null 처리 (중복 방지)
3. **iOS**: logout action에서 서버에 토큰 삭제 API 호출 (또는 logout 전에 `PATCH /users/me/device-token` body `{"token": null}`)

---

## BUG-02: 앱 내 알림 설정이 서버에 반영되지 않음 (High)

**현상:** 앱 내 알림 설정(답변 알림, 재촉하기 알림, 새 질문 알림)을 끄거나 켜도 실제 푸시 알림 발송에 영향 없음

**근본 원인:** 알림 설정이 클라이언트 UserDefaults에만 저장되고, 서버에 전달되지 않음
- `NotificationSettingsFeature.swift:60-64` — UserDefaults에만 `notification.r1/r3/r5` 저장
- 서버에 알림 선호도 API/모델이 존재하지 않음
- 서버의 `PushNotificationService`는 무조건 푸시 발송 (선호도 체크 없음)
- 방해 금지 시간(`notification.quietHours`)도 클라이언트에만 존재

**수정 방안:**
1. **서버**: `User` 또는 `FamilyMembership` 모델에 알림 선호도 필드 추가
   - `notifAnswer: Boolean` (구성원 답변 알림)
   - `notifNudge: Boolean` (재촉하기 알림)
   - `notifQuestion: Boolean` (새 질문 알림)
   - `quietHoursEnabled: Boolean`, `quietHoursStart: String`, `quietHoursEnd: String`
2. **서버**: `PATCH /users/me/notification-preferences` 엔드포인트 생성
3. **서버**: `PushNotificationService` 발송 전 수신자의 알림 선호도 체크 로직 추가
4. **iOS**: `NotificationSettingsFeature`에서 토글 변경 시 서버 API 호출 추가

---

## BUG-03: 시스템 알림 차단 시 앱 내 설정과 비동기화 (High)

**현상:**
1. 앱에서 처음 알림을 거부 → iOS가 다시 묻지 않음
2. 앱 내 설정에서 알림을 켜도 시스템에 반영 안됨
3. 시스템 설정에서 알림을 켜도 앱이 이를 감지하지 못함

**근본 원인:** 시스템 알림 권한 상태를 체크하지 않음
- `UNUserNotificationCenter.current().getNotificationSettings()` 호출이 없음
- 앱 내 설정 UI에 시스템 알림 권한 상태 표시 없음
- 시스템에서 알림 거부 후 → 앱이 `UIApplication.openSettingsURLString`으로 안내하지 않음
- iOS 정책: `requestAuthorization()`은 최초 1회만 시스템 팝업 표시, 이후 거부 시 직접 설정 앱으로 이동해야 함

**관련 코드:**
- iOS: `Root+Reducer.swift:248-259` — 최초 1회만 권한 요청 (`mongle.didRequestPushPermission` 플래그)
- iOS: `NotificationSettingsView.swift` — 시스템 권한 상태 표시 없음
- iOS: `GroupSelectView+NotificationPermission.swift` — "허용하기"/"나중에" 선택지만 있고 시스템 설정 안내 없음

**수정 방안:**
1. **iOS**: `NotificationSettingsFeature`에 시스템 알림 권한 상태 체크 추가
   ```swift
   UNUserNotificationCenter.current().getNotificationSettings { settings in
       if settings.authorizationStatus == .denied {
           // 시스템 설정으로 이동 안내 배너 표시
       }
   }
   ```
2. **iOS**: 시스템 알림이 꺼져있을 때 설정 화면 상단에 경고 배너 + "시스템 설정으로 이동" 버튼 추가
   ```swift
   UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
   ```
3. **iOS**: 앱이 foreground로 돌아올 때 (`scenePhase == .active`) 알림 권한 상태 재확인
4. **iOS**: 그룹 내 알림 설정 변경 시에도 시스템 알림 상태를 먼저 체크하여 꺼져있으면 시스템 설정 유도

---

## BUG-04: 재촉하기 알림 미수신 (Medium)

**현상:** 재촉하기(Nudge) 기능 사용 시 하트는 차감되지만 상대방에게 푸시 알림이 도착하지 않음

**분석:**
- `NudgeService.ts:73-96` — Lambda 환경에서 `await Promise.all(pushTasks)` 호출 (이전 비동기 이슈 수정 완료)
- 가능한 원인들:
  1. 수신자의 `apnsToken`이 null (토큰 미등록 또는 BUG-01로 인한 토큰 불일치)
  2. APNs 인증서/키 만료 또는 환경변수 미설정
  3. `PushNotificationService`의 APNs HTTP/2 연결 실패 (Lambda cold start)
  4. 수신자의 시스템 알림이 꺼져있음 (BUG-03)

**관련 코드:**
- 서버: `MongleServer/src/services/NudgeService.ts:76-96` — 푸시 발송 (에러 catch 후 warn 로그만)
- 서버: `MongleServer/src/services/PushNotificationService.ts` — APNs/FCM 실제 발송
- iOS: `PeerNudgeFeature.swift` — 재촉하기 UI

**수정 방안:**
1. **서버**: 푸시 실패 시 로그 레벨을 `warn` → `error`로 올리고 실패 원인 상세 기록
2. **서버**: APNs 토큰 유효성 검증 — 410 Gone 응답 시 토큰 자동 삭제
3. **서버**: 푸시 발송 결과를 클라이언트에 반환 (`pushSent: boolean` 필드 추가)
4. **BUG-01 수정 후 재검증** — 토큰 정리가 되면 자연스럽게 해결될 가능성 높음

---

## BUG-05: 전반적인 푸시 알림 미수신 (Medium)

**현상:** 새 질문 알림, 답변 알림 등 전반적으로 푸시 알림이 도착하지 않음

**분석:**
- BUG-01 ~ BUG-04의 복합 원인일 가능성 높음
- 추가 확인 필요 사항:
  1. APNs 환경변수 설정 확인 (`APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_PRIVATE_KEY` 등)
  2. Lambda 스케줄러 (`scheduler.ts`, `reminderScheduler.ts`) 정상 동작 여부
  3. APNs 프로덕션 vs 샌드박스 환경 불일치
  4. FCM 설정 확인 (Android용)

**수정 방안:**
1. **서버**: 푸시 발송 Health Check 엔드포인트 추가 (관리자용)
2. **서버**: 푸시 실패 로그를 CloudWatch/모니터링 시스템에 연동
3. **서버**: APNs 토큰 유효성 검증 + 만료 토큰 자동 정리 로직 추가

---

## BUG-06: 그룹 알림 설정 시 시스템 알림 유도 (Feature Request)

**현상:** 각 그룹에서 알림 설정을 할 때, 앱 자체 알림이 꺼져있으면 시스템 알림 허용 프롬프트를 보여주길 원함

**현재 동작:** 그룹 최초 진입 시 1회 알림 권한 요청 (`mongle.notifSetup.<familyId>` 플래그)만 존재

**수정 방안:**
1. **iOS**: 그룹 알림 토글 ON 시 시스템 알림 상태 체크
2. 시스템 알림이 `.denied`이면 "알림을 받으려면 시스템 설정에서 알림을 허용해주세요" Alert 표시
3. Alert에 "설정으로 이동" 버튼 → `UIApplication.openSettingsURLString`
4. `.notDetermined`이면 `requestAuthorization()` 호출 (iOS가 시스템 팝업 표시)

---

## BUG-07: 그룹 나가기 일수 카운팅 오류 (Medium)

**현상:** 그룹 나가기 시 남은 일수가 제대로 카운팅되지 않음 (항상 3일로 표시될 수 있음)

**현재 구현 분석:**
- **클라이언트** (`GroupManagementFeature.swift:151-158`, `GroupSelectFeature.swift:425-428`):
  ```swift
  let hoursSinceCreation = Date().timeIntervalSince(createdAt) / 3600
  if hoursSinceCreation < 72 {
      let daysLeft = Int(ceil((72 - hoursSinceCreation) / 24))
  }
  ```
- **서버** (`FamilyService.ts:346-351`):
  ```typescript
  const hoursSinceCreation = (Date.now() - family.createdAt.getTime()) / (1000 * 60 * 60);
  if (hoursSinceCreation < 72) {
      const daysLeft = Math.ceil((72 - hoursSinceCreation) / 24);
  }
  ```
- 로직 자체는 올바름: `createdAt` 기준으로 경과 시간 계산 → 72시간 미만이면 남은 일수 표시

**의심되는 원인:**
1. **`createdAt` 타임존 불일치**: 서버가 UTC로 저장하는데 iOS가 로컬 타임존으로 해석할 경우
   - 예: KST(+9) 환경에서 UTC `createdAt`을 로컬로 해석하면 9시간 차이 발생
   - 실제 24시간 지남 → 클라이언트는 15시간만 지난 것으로 계산 → 3일 유지
2. **`createdAt` null/미전달**: API 응답에서 `createdAt`이 누락되면 기본값으로 현재 시각 사용 가능
3. **JSON 날짜 파싱 오류**: ISO 8601 문자열을 Swift `Date`로 변환 시 포맷 불일치

**확인할 사항:**
1. 서버 API에서 `createdAt` 필드가 정상적으로 반환되는지 (ISO 8601 with timezone)
2. iOS `MongleGroup.createdAt` 파싱이 정확한지 (DateFormatter/JSONDecoder dateDecodingStrategy)
3. 실제 3일 경과 후에도 서버에서 거부하는지 (서버 로그 확인)

**수정 방안 (원래 요구사항 반영):**
> "처음 그룹을 생성하고 삭제관련필드 3으로 만들고 하루 지날때마다 -1하고 0이 되면 삭제하도록"

현재 구현은 별도 필드 없이 `createdAt` 기준 실시간 계산 방식이므로, 두 가지 선택지:

**Option A — 현재 방식 유지 + 버그 수정 (권장):**
- 타임존 파싱 문제 수정 (서버는 UTC ISO 8601로 통일, iOS는 UTC 기준 파싱)
- 이 방식이 더 정확하고 별도 스케줄러 불필요

**Option B — 카운트다운 필드 방식 (요구사항대로):**
- 서버: `Family` 모델에 `deletionCountdown: Int` 필드 추가 (기본값 3)
- 서버: 매일 자정 스케줄러로 `deletionCountdown -= 1` 실행
- 서버: `deletionCountdown == 0`이면 그룹장 나가기 허용
- 단점: 스케줄러 추가 필요, 시간 기반보다 정밀도 낮음

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

## iOS App Store 심사 제출 정보

### 프로모션 텍스트 (최대 170자)
매일 하나의 질문으로 가족의 하루를 나눠보세요. 멀리 있어도 마음은 가까이, 오늘의 질문에 답하며 몰랐던 가족의 이야기를 발견하는 따뜻한 가족 소통 앱 몽글입니다.

### 설명 (Description)
몽글은 매일 하나의 질문을 가족 모두에게 건네고, 각자의 답변을 통해 서로의 일상·추억·생각을 나누는 가족 소통 앱입니다.

바쁜 일상 속, 가족과 주고받는 대화는 "밥 먹었어?", "별일 없지?"에서 끝나기 쉽습니다. 몽글은 매일 하나의 질문을 통해 그 이상의 이야기를 자연스럽게 꺼낼 수 있도록 도와줍니다. 어릴 적 기억, 요즘의 고민, 앞으로의 꿈, 오늘 감사한 일까지 — 평소에는 묻기 쑥스러웠던 이야기를 질문 하나로 가볍게 시작해 보세요.

■ 주요 기능

· 오늘의 질문
매일 새로운 질문이 도착합니다. 일상, 추억, 가치관, 미래, 감사 등 다양한 카테고리의 질문을 통해 서로를 더 깊이 알아갈 수 있습니다.

· 가족 답변 한눈에 보기
엄마·아빠·형제·자매·조부모 등 가족 구성원이 각자 남긴 답변을 귀여운 캐릭터와 함께 한 화면에서 확인할 수 있습니다.

· 스트릭(Streak) 기록
연속으로 답변한 날짜가 기록되어, 매일의 작은 습관이 가족의 역사가 됩니다.

· 하트 시스템
하트를 사용해 나만의 질문을 직접 만들거나, 마음에 들지 않는 질문을 다시 받거나, 아직 답하지 않은 가족을 부드럽게 재촉할 수 있습니다.

· 히스토리
월별 달력으로 지난 질문과 답변을 한눈에 되돌아보며 가족의 추억을 아카이빙할 수 있습니다.

· 기분 히스토리
최근 14일간 가족 구성원의 기분 변화를 확인하고 서로의 상태를 살필 수 있습니다.

· 안전한 가족 그룹
초대 코드 기반으로 우리 가족만의 비공개 그룹을 만들 수 있어, 모든 대화는 가족 안에서만 안전하게 공유됩니다.

· 간편한 로그인
카카오·구글·Apple 로그인을 지원하여 복잡한 가입 절차 없이 바로 시작할 수 있습니다.

■ 이런 분들께 추천합니다
- 따로 살고 있어 자주 연락하기 어려운 가족
- 사춘기 자녀와의 대화가 어려운 부모
- 부모님께 평소 못했던 이야기를 나누고 싶은 자녀
- 매일의 소소한 일상을 가족과 기록하고 싶은 분
- 가족의 생각과 추억을 아카이빙하고 싶은 분

몽글과 함께 매일 한 가지 질문으로 가족의 마음을 이어보세요.

문의: yongheon0806@gmail.com

### 키워드 (최대 100자, 쉼표로 구분)
가족,소통,질문,일기,가족앱,대화,부모,자녀,추억,감사,가족채팅,패밀리,가족일기,몽글

### 지원 URL (Support URL)
https://bedecked-latency-99c.notion.site/privacy-policy-ko-33c4d36af6f680ffb927c10bc5d7bd1b

### 마케팅 URL (Marketing URL)
https://mongle.app

### 저작권 (Copyright)
© 2026 최용헌 (Yongheon Choi)

### 심사 정보 — 메모 (App Review Notes)

[앱 소개]
몽글은 매일 하나의 질문을 가족 구성원에게 제시하고, 구성원들이 각자의 답변을 공유하며 서로를 더 깊이 알아갈 수 있도록 돕는 가족 커뮤니케이션 앱입니다. 모든 답변과 대화는 초대 코드 기반의 비공개 가족 그룹 내에서만 공유됩니다.

[테스트 계정 — Apple 로그인]
- Sign in with Apple을 지원합니다. 심사용 Apple ID로 바로 로그인하여 테스트 가능합니다.
- 카카오 / 구글 로그인도 지원되며, 테스트 계정이 별도로 필요하시면 아래 이메일로 요청해 주세요.

[테스트 계정 — 이메일 로그인]
- ID: review@mongle.app
- PW: Review1234!
- 위 계정에는 심사 편의를 위해 테스트용 가족 그룹과 샘플 답변이 미리 세팅되어 있습니다.

[주요 기능 확인 경로]
1) 로그인 → 온보딩 → 가족 그룹 생성 또는 초대 코드 입력
2) 홈 화면: 오늘의 질문 카드 탭 → 답변 작성/제출
3) 히스토리 탭: 월별 달력에서 과거 질문·답변 확인
4) 하트 팝업: 나만의 질문 작성 / 질문 다시받기 / 재촉하기
5) 설정 → 프로필 / 그룹 관리 / 알림 설정

[광고(AdMob) 관련]
- Google AdMob 배너 및 리워드 광고를 사용합니다.
- 최초 실행 시 Google UMP(User Messaging Platform)를 통해 GDPR/CCPA 동의 폼이 노출되며, iOS 14.5+ 기기에서는 App Tracking Transparency(ATT) 프롬프트도 함께 노출됩니다.
- 광고는 가족의 사적인 질문/답변 화면과 분리되어 안전한 영역에만 노출됩니다.

[민감 권한 / 기능 설명]
- 푸시 알림: 새 질문 도착, 가족의 답변 등록, 재촉(Nudge) 알림을 위해 사용됩니다. 최초 로그인 시 1회 권한을 요청합니다.
- 네트워크: 서버와의 질문/답변 동기화를 위해 필요합니다. 오프라인 시 NWPathMonitor를 통해 안내 화면을 표시합니다.
- 추적(ATT): AdMob 광고 개인화를 위해 사용되며, 사용자가 거부해도 앱의 모든 기능을 정상적으로 이용할 수 있습니다.

[사용자 생성 콘텐츠(UGC) 정책]
- 답변/나만의 질문 등 사용자 생성 콘텐츠가 존재합니다.
- 신고(Report) 및 차단(Block) 기능, 욕설/부적절한 콘텐츠에 대한 필터링·삭제 프로세스를 구현했습니다.
- 모든 콘텐츠는 사용자가 직접 생성한 비공개 가족 그룹 내에서만 공유되며, 공개 피드는 존재하지 않습니다.

[계정 삭제]
- App Store 심사 가이드라인 5.1.1(v)에 따라, 앱 내 [설정 → 계정 관리 → 회원 탈퇴]에서 계정 및 관련 데이터를 즉시 삭제할 수 있습니다.

[문의처]
- 개발자: 최용헌
- 이메일: yongheon0806@gmail.com
- 개인정보 처리방침: https://bedecked-latency-99c.notion.site/privacy-policy-ko-33c4d36af6f680ffb927c10bc5d7bd1b
- 이용약관: https://bedecked-latency-99c.notion.site/terms-ko-33c4d36af6f68054a527c510d4f98b7f

추가로 필요한 정보나 테스트 환경이 있으면 위 이메일로 연락 주시면 신속히 회신드리겠습니다. 감사합니다.

---

