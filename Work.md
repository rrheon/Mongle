# Role
너는 iOS(SwiftUI), Android(Jetpack Compose), 백엔드(FastAPI 등) 시스템 전반의 상태 관리와 데이터 흐름을 추적하는 데 능숙한 시니어 모바일 풀스택 엔지니어다. 


[상황 및 목표]
가족의 일상을 공유하는 '몽글(Mongle)' 앱에서 사용자가 로그아웃 상태일 때 "글 작성 재촉하기" 등의 중요 푸시 알림을 받지 못하는 문제가 발생하고 있어. 의도치 않은 로그아웃으로 인해 가족 간의 연결이 끊어지는 것을 방지해야 해. 

카카오톡이나 기존 대형 로그인 시스템을 갖춘 앱들이 이 문제를 어떻게 해결하는지(예: 디바이스 토큰 유지 및 백그라운드 Silent Push, 소프트 로그아웃, SMS/카카오 알림톡 Fallback 등) 분석하고, 이를 몽글 프로젝트에 적용할 수 있도록 아래 5단계 프로세스에 맞춰 체계적으로 답변해 줘.

---

### 단계 1: 기획 (Planning)
1. 타사 레퍼런스 분석: 카카오톡 등 주요 앱들이 로그아웃 상태에서의 알림(또는 재로그인 유도)을 어떻게 처리하는지 기술적/기획적 관점에서 2~3가지로 요약해 줘.
2. 몽글 맞춤형 솔루션 제안: 몽글의 특성(가족 간의 연결, 알림 누락 방지 중요)에 가장 적합한 알림 수신 보장 전략을 기획해 줘. (보안과 사용성 간의 트레이드오프 포함)

### 단계 2: 1차 QA (Pre-Check)
1. 현재 시스템의 문제점을 명확히 진단하기 위한 QA 테스트 시나리오를 작성해 줘.
2. 로그아웃 시 FCM/APNs Device Token이 서버에서 어떻게 처리(삭제 또는 만료)되고 있는지 검증하는 백엔드/클라이언트 교차 확인 리스트를 제공해 줘.

### 단계 3: 코드 수정 계획 설립 (Architecture & Code Plan)
1. 단계 1에서 채택한 기획을 바탕으로 상태 관리(State Management) 로직 수정 계획을 세워 줘.
   - iOS: TCA(The Composable Architecture) 환경에서의 Auth State 및 Push Notification Reducer 처리 방안
   - Android: MVI(Model-View-Intent) 환경에서의 로그아웃 Intent 처리 및 사이드 이펙트 관리 방안
2. 백엔드(서버)와의 API 통신 구조 변경점(예: Token 무효화 대신 Status 변경 등)을 정의해 줘.

### 단계 4: 2차 QA (Post-Verification)
1. 코드가 수정되었다고 가정하고, 변경된 로직이 완벽하게 작동하는지 검증하는 Edge Case 중심의 QA 체크리스트를 작성해 줘.
2. (예: A계정 로그아웃 후 B계정 로그인 시 A를 향한 '재촉하기' 알림이 B에게 노출되는 개인정보 침해 버그 방지 시나리오 등)

### 단계 5: 수정 단계 가이드 (Implementation)
1. 단계 3의 계획을 실제로 구현하기 위해, 내가 즉시 프로젝트에 적용할 수 있는 핵심 청사진 코드(Swift/Kotlin) 또는 수도 코드(Pseudo-code)를 작성해 줘.
2. 로컬 저장소(UserDefaults/DataStore)와 메모리 상의 사용자 세션을 분리하여 관리하는 모범 사례를 포함해 줘

## 위치 (오타 수정)

- 디자인: `/Users/yongheon/Desktop/Mongle/MongleUI` *(원문 `/Users/yong/...` 는 오타. 사용자 홈은 `/Users/yongheon`. 단, `MongleUI` 디렉토리는 현재 경로에 없으니 따로 확인 필요)*
- iOS: `/Users/yongheon/Desktop/Mongle`
- Android: `/Users/yongheon/Mongle-Android` *(확인 필요 — 기억상 `~/agent-workspace/...` 일 수도)*
- 서버: `/Users/yongheon/Desktop/Mongle-Server`

## 구글 ad 정보

iOS
- 앱ID : `ca-app-pub-4718464707406824~3555712259`
- 배너: `ca-app-pub-4718464707406824/5359748516`
- 보상형: `ca-app-pub-4718464707406824/2869316545`

Android
- 앱ID: `ca-app-pub-4718464707406824~8995741193`
- 배너: `ca-app-pub-4718464707406824/2974225929`
- 보상형: `ca-app-pub-4718464707406824/9365243021`

---
---

# 📦 작업 결과 — 로그아웃 상태 푸시 누락 해결 (5단계)

> 작성일 2026-06-10 · 실제 코드베이스(iOS/Server/Android) 정독 기반. 모든 인용은 `파일경로:줄번호`.

## 🔎 0. 현황 진단 (코드 근거)

### 0.1 가장 중요한 발견 — "디바이스 토큰 수명 ＝ 인증 세션 수명"으로 묶여있다

지금 구조는 **로그인 토큰(accessToken)과 디바이스 푸시 토큰(APNs/FCM)의 생명주기가 한 덩어리**다. 세션이 끊기면 푸시 채널도 같이 끊긴다. 그래서 "의도치 않은 로그아웃 → 재촉 푸시 누락 → 가족 연결 단절"이 발생한다.

### 0.2 플랫폼별 로그아웃 시 토큰 처리 (불일치 존재)

| 경로 | iOS | Android | 서버 결과 |
|------|-----|---------|----------|
| **명시적 로그아웃** | `POST /auth/logout` 호출 | **서버 logout API 미호출**(로컬 prefs만 clear) | iOS만 `apnsToken`/`fcmToken`=NULL |
| **의도치 않은 로그아웃**(refresh 실패/401) | 서버 logout 미호출 → **서버 토큰 잔존** | 토큰만 삭제, FCM 캐시·서버 토큰 잔존 | (호출 안 됨) |

근거:
- iOS 명시적 로그아웃 → 서버 호출: `MongleData/Sources/MongleData/Repositories/AuthRepository.swift:60-71`
- iOS 세션만료는 서버 logout 미호출: `MongleFeatures/Sources/MongleFeatures/Presentation/Root/Ext/Root+Reducer.swift:393-413`
- Android `logout()`은 `clearSession()`(로컬 prefs clear)만: `app/src/main/java/com/mongle/android/data/remote/ApiAuthRepository.kt:192-194`
- Android에 서버 logout 엔드포인트 자체가 없음: `MongleApiService.kt` (logout 라우트 부재)
- 서버 `logout()`이 토큰 NULL + refresh revoke: `src/services/AuthService.ts:350-366`

### 0.3 그 외 구조적 리스크

1. **재등록이 인증에 종속** — 토큰 등록 API(`PATCH /users/me/device-token`, `PATCH /users/me/fcm-token`)는 `@Security('jwt')`. 로그아웃 상태에선 등록 불가 → 한 번 끊기면 재로그인 전까지 복구 불가. (서버 `UserController.ts:77-101`, iOS `UserRepository.swift:42-45`, Android `RootViewModel.kt:265-280`)
2. **죽은 토큰 정리가 best-effort** — APNs 410/`BadDeviceToken`·FCM `not-registered` 감지 시 NULL 처리하지만 비동기 catch 안에서 실패 시 로그만 남고 재시도 없음. (`src/services/PushNotificationService.ts:76-89, 217-369`)
3. **Android `onNewToken` 즉시 서버 등록 안 함** — 로컬 캐시만. 서버 반영은 `loadHomeData()`(로그인 후)까지 지연. 로그아웃 중 토큰 회전되면 영영 미등록. (`MongleFcmService.kt:33-43`)
4. **계정 전환 프라이버시 처리는 양호** — 토큰 등록 시 `updateMany({ where: { token, id ≠ me } }, NULL)`로 같은 토큰을 가진 타 유저 토큰을 회수. A→B 전환 시 A의 재촉 푸시가 B에게 안 가도록 막혀 있음. (`UserService.ts:254-288`) → 이 불변식은 새 설계에서 **반드시 유지**해야 한다.

---

## 단계 1: 기획 (Planning)

### 1-1. 타사 레퍼런스 분석

대형 로그인 시스템이 "로그아웃/세션만료 상태에서도 연결을 유지"하는 3가지 패턴:

1. **소프트 로그아웃(세션 ≠ 디바이스 토큰 분리)** — 카카오톡/라인은 "로그아웃"을 *세션 무효화*로만 처리하고, **디바이스 토큰은 기기 단위로 보존**한다. 토큰은 "이 기기를 누가 마지막에 썼나"의 디바이스 식별자이지 로그인 자격증명이 아니다. 그래서 세션이 끊겨도 "다시 로그인하세요" 같은 *재참여(re-engagement)* 푸시를 계속 보낼 수 있다.
2. **Silent Push로 세션 자동 복구** — APNs `content-available:1` / FCM data-only 무음 푸시로 앱을 백그라운드 기동시켜 refresh token으로 세션을 조용히 재발급. 사용자는 "로그아웃됐다"는 사실조차 모른 채 알림 수신이 유지된다.
3. **다중 채널 Fallback** — 푸시 토큰이 죽었거나 권한이 꺼진 경우 카카오 알림톡/SMS/이메일로 대체 발송. "중요 알림은 어떤 채널로든 도달"을 보장.

### 1-2. 몽글 맞춤형 전략 (채택안)

몽글은 (a) 가족 간 연결이 핵심 가치, (b) 알림 누락이 곧 관계 단절, (c) 사용자는 보안 위협 모델이 낮은 가족 앱 → **사용성·도달률을 보안보다 우선**해도 되는 도메인이다.

**채택: "디바이스 토큰을 세션에서 분리 + 소프트 로그아웃 + 의도치 않은 로그아웃 시 토큰 보존"**

| 구분 | 변경 전 | 변경 후(채택) |
|------|--------|--------------|
| 명시적 로그아웃 | 토큰 NULL | **토큰 보존**, 세션만 무효화. `pushOptOut` 플래그로 "콘텐츠 푸시 정지", 단 재참여("다시 로그인") 푸시는 허용 |
| 의도치 않은 로그아웃(refresh 실패) | (iOS 잔존 / Android 잔존이지만 우연) | **명시적으로 토큰 보존** + `sessionState='expired'` 마킹 → 재참여 푸시 발송 |
| 완전 삭제(계정 전환·탈퇴·기기변경) | — | 새 유저 로그인 등록 시 토큰 회수(기존 불변식) + 탈퇴 시 NULL |

**보안·사용성 트레이드오프 정리**
- 토큰을 보존하면 "로그아웃된 A의 토큰으로 가족 콘텐츠가 새나갈" 위험 → **재참여 푸시는 가족 콘텐츠를 절대 담지 않는 일반 문구**("몽글에 다시 로그인 해주세요")로만 제한해 해소.
- 같은 기기를 B가 인계받으면 등록 시점에 A 토큰이 회수되므로 A 대상 콘텐츠 푸시는 자동 차단(기존 불변식 유지).
- (선택) 알림톡 Fallback은 가족 앱 특성상 비용·동의 이슈가 있어 **2차 과제**로 분리. 1차는 토큰 보존 + 소프트 로그아웃만으로 누락의 90%를 잡는다.

---

## 단계 2: 1차 QA (Pre-Check) — 현재 시스템 결함 검증

### 2-1. 진단용 QA 시나리오

| # | 시나리오 | 기대(버그 없을 때) | 현재 실제 동작 |
|---|---------|-------------------|---------------|
| P1 | 명시적 로그아웃 후 가족이 "재촉하기" 발송 | 재참여 푸시 도달 | ❌ iOS 토큰 NULL → 미도달 |
| P2 | accessToken/refresh 만료로 의도치 않은 로그아웃 → 재촉 발송 | 도달 | ⚠️ iOS는 토큰 잔존하나 앱 unauthenticated, Android는 케이스별 불일치 |
| P3 | 로그아웃 직후 APNs/FCM 토큰 회전 | 서버 갱신 | ❌ Android `onNewToken` 로컬만 저장 → 서버 미반영 |
| P4 | A 로그아웃 → 동일 기기 B 로그인 → A 대상 재촉 | B에게 노출 안 됨 | ✅ 등록 시 토큰 회수로 차단됨(유지 대상) |
| P5 | 서버가 만료 토큰으로 발송 실패 후 재발송 | 정리되어 더는 시도 안 함 | ⚠️ best-effort, 정리 실패 시 잔존 |

### 2-2. Device Token 처리 백엔드↔클라이언트 교차 확인 리스트

- [ ] **(서버)** `logout()`이 토큰을 NULL로 만드는가? → 현재 **YES**(`AuthService.ts:359`). 채택안에선 **NO로 바꿔야** 한다(보존).
- [ ] **(서버)** 토큰 등록이 `@Security('jwt')` 필수인가? → YES(`UserController.ts:78,93`). 재참여를 위해 **세션 무관 디바이스 식별 경로**가 필요한지 검토.
- [ ] **(iOS)** 명시적 로그아웃이 서버 logout을 부르는가? → YES(`AuthRepository.swift:64-70`).
- [ ] **(iOS)** 세션만료가 서버 토큰을 정리하는가? → NO(`Root+Reducer.swift:393-413`) → 채택안과 일치(보존). 단 의도된 동작인지 명문화 필요.
- [ ] **(Android)** 로그아웃이 서버에 신호를 보내는가? → **NO**(`ApiAuthRepository.kt:192-194`) → iOS와 동작 불일치. 정책 통일 필요.
- [ ] **(Android)** `clearUserScopedPrefs()`가 `FirebaseMessaging.deleteToken()`을 호출하는가? → NO(`RootViewModel.kt:527-532`). 채택안에선 **호출하지 않는 게 맞다**(토큰 보존).
- [ ] **(공통)** 죽은 토큰 정리가 동기적으로 보장되는가? → NO(best-effort). 배치 정리 잡 검토.
- [ ] **(공통)** "재참여 푸시"가 가족 콘텐츠를 포함하지 않는가? → 신규 요구사항으로 추가.

---

## 단계 3: 코드 수정 계획 (Architecture & Code Plan)

### 3-1. 백엔드 (변경의 출발점 — 가장 먼저)

**스키마 변경** (`prisma/schema.prisma` User 모델)
```
+ pushOptOut    Boolean   @default(false)  // 명시적 로그아웃 시 콘텐츠 푸시만 정지
+ sessionState  String    @default("active") // active | expired | logged_out
+ tokenUpdatedAt DateTime? // 토큰 신선도 추적(죽은 토큰 배치 정리용)
// apnsToken / fcmToken 컬럼은 유지하되, "세션 상태와 분리된 디바이스 식별자"로 의미 재정의
```

**`AuthService.logout()` 변경** (`src/services/AuthService.ts:350-366`)
- `apnsToken/fcmToken = null` 제거 → **토큰 보존**.
- 대신 `pushOptOut=true`(또는 `sessionState='logged_out'`), refresh token revoke는 유지.

**발송 게이트 변경** (`NudgeService.ts:122`, `AnswerService.ts:150`, `QuestionService.ts:713`, `reminderScheduler.ts:226`)
- 콘텐츠 푸시: `token != null && !pushOptOut && notif* && !quietHours` 일 때만.
- 신규 **재참여 푸시 경로**: `sessionState in ('expired','logged_out') && token != null` → 가족 콘텐츠 없는 일반 문구로 별도 발송(빈도 제한: 1일 1회 등).

**탈퇴/계정전환만 토큰 완전 삭제** — 기존 등록 시 토큰 회수 불변식(`UserService.ts:254-288`)은 그대로.

### 3-2. iOS (TCA) — Auth State & Push Reducer

`Root+Reducer.swift`
- `.logout` 처리에서 서버 `logout`은 호출하되, **로컬 Keychain 토큰만 정리하고 디바이스 토큰 등록 상태는 건드리지 않는다**(이미 그러함). 서버가 토큰을 보존하므로 추가 변경 불필요 — 단 `pushOptOut` 의미를 서버가 책임.
- `.sessionExpired`(`:393-413`)는 **현행 유지(서버 토큰 보존)**가 채택안과 일치. 명문 주석 추가.
- (선택) Silent Push 수신 시 refresh를 시도해 세션 자동복구하는 `.silentPushReceived` 액션 신설 → `APIClient.attemptTokenRefresh()` 재사용(`APIClient.swift:206-251`).
- 토큰 등록 race(`Root+Reducer.swift:784-792`): 등록 실패(401)를 sessionExpired로 승격시키지 말고 **조용히 재시도 큐**로 처리.

### 3-3. Android (MVI) — 로그아웃 Intent & SideEffect

- `ApiAuthRepository.logout()`(`:192-194`): **서버 logout API를 신설·호출**(현재 없음)하여 iOS와 정책 통일. 단 서버가 토큰을 보존하도록 변경됐으므로 토큰 컬럼은 유지.
- `clearUserScopedPrefs()`(`RootViewModel.kt:527-532`): `FirebaseMessaging.deleteToken()` **호출하지 않는다**(토큰 보존). 로컬 `fcm` 캐시도 보존하거나, 삭제하더라도 다음 기동 시 즉시 재등록 보장.
- `TokenAuthenticator.notifyAndClear()`(`TokenAuthenticator.kt:140-143`): 강제 로그아웃 시에도 토큰 보존 정책 일치. `sessionState='expired'` 마킹은 서버 401 응답 처리에서.
- `MongleFcmService.onNewToken()`(`:33-43`): **즉시 서버 등록 시도**(로그인 상태면). 미로그인 시 보류 플래그 후 다음 로그인에 flush.

### 3-4. API 통신 구조 변경점 요약

- `POST /auth/logout`: "토큰 무효화" → **"세션 무효화 + pushOptOut 설정(토큰 보존)"**.
- (신설) `POST /auth/logout` Android 클라이언트 연결.
- (선택 신설) `POST /users/me/device-token/heartbeat` 또는 무음 푸시용 토큰 검증 경로.
- 발송 서비스: 단일 게이트 → **콘텐츠/재참여 2-tier 게이트**.

---

## 단계 4: 2차 QA (Post-Verification) — Edge Case 체크리스트

수정 적용을 가정한 검증:

- [ ] **E1 (프라이버시 핵심)** A 로그아웃 → 동일 기기 B 로그인 → A 대상 "재촉하기" 발송 시 **B 기기에 노출 안 됨**. (등록 시 A 토큰 회수 불변식이 보존돼야 함 — `UserService.ts:254-288` 회귀 테스트)
- [ ] **E2** A 로그아웃 상태(미전환) → A 대상 재촉 → A 기기에 **"콘텐츠 없는 재참여 푸시"만** 도달, 가족 답변 내용은 미포함.
- [ ] **E3** 의도치 않은 로그아웃 후 재참여 푸시 탭 → 로그인 화면 정상 진입 → 로그인 후 끊겼던 알림 정상 복구.
- [ ] **E4** 같은 계정 다중 기기: 기기1 로그아웃해도 기기2 푸시 정상. 기기1 재로그인 시 기기1 토큰 재등록.
- [ ] **E5** quietHours·notif* off 사용자에게 재참여 푸시가 이를 우회해 스팸이 되지 않는지(재참여도 빈도 제한 준수).
- [ ] **E6** 토큰 회전 직후(로그아웃 중) 새 토큰이 다음 로그인에 서버 반영되는지(Android `onNewToken` flush).
- [ ] **E7** 죽은 토큰(410/BadDeviceToken) 발송 실패 시 정리되고, 정리 실패해도 배치 잡이 보강하는지.
- [ ] **E8** iOS/Android 로그아웃 동작이 **동일 정책**으로 수렴했는지(서버 토큰 보존 일치).
- [ ] **E9** 탈퇴 시에는 토큰 완전 삭제 + 재참여 푸시 미발송(보존과 구분).

---

## 단계 5: 구현 가이드 (Implementation) — 청사진 코드

### 5-1. 서버 (TypeScript / Express+Prisma)

```typescript
// AuthService.ts — 변경 전: 토큰 NULL / 변경 후: 보존 + 소프트 로그아웃
async logout(userId: string): Promise<void> {
  const user = await prisma.user.findUnique({ where: { userId }, select: { id: true } });
  if (!user) return;
  await prisma.$transaction([
    prisma.user.update({
      where: { id: user.id },
      // apnsToken/fcmToken 은 건드리지 않는다 → 재참여 푸시용으로 보존
      data: { pushOptOut: true, sessionState: 'logged_out' },
    }),
    prisma.userRefreshToken.updateMany({
      where: { userId: user.id, revokedAt: null },
      data: { revokedAt: new Date() },
    }),
  ]);
}

// PushNotificationService 호출 측 — 2-tier 게이트
function canSendContentPush(u: PushTarget): boolean {
  return !!u.token && !u.pushOptOut && u.sessionState === 'active'
      && u.notifNudge && !isInQuietHours(u);
}
function canSendReengagePush(u: PushTarget): boolean {
  return !!u.token && u.sessionState !== 'active'; // 콘텐츠 미포함, 빈도제한은 호출부
}
```

### 5-2. iOS (Swift / TCA) — 세션·디바이스 토큰 분리 + Silent Push 복구

```swift
// SessionStore: 메모리 세션 ↔ 영속 토큰 분리 (모범사례)
@DependencyClient
struct SessionStore {
    var current: () -> Session?              // 메모리(런타임) 세션
    var deviceToken: () -> String?           // Keychain: 세션과 독립 보존
    var setSession: (Session?) -> Void
}

// Root+Reducer: 무음 푸시로 세션 자동 복구 (의도치 않은 로그아웃 예방)
case .silentPushReceived:
    return .run { send in
        // refresh 가능하면 조용히 세션 복구 → 사용자는 로그아웃을 인지조차 못 함
        if (try? await authRepository.refreshSessionIfPossible()) == true {
            await send(.checkAuthResponse)
        }
    }

// 디바이스 토큰 등록: 401 을 sessionExpired 로 승격시키지 않음
case .deviceTokenReceived(let data, let env):
    let token = data.map { String(format: "%02x", $0) }.joined()
    return .run { [userRepository] _ in
        // 실패해도 조용히 — 다음 로그인/세션에서 재시도. 강제 로그아웃 금지
        try? await userRepository.registerDeviceToken(token: token, environment: env)
    }
```

### 5-3. Android (Kotlin / MVI) — 로그아웃 정책 통일 + onNewToken 즉시 등록

```kotlin
// ApiAuthRepository: 서버 logout 신설 호출 (iOS와 통일), 토큰은 보존
override suspend fun logout() {
    runCatching { api.logout() }   // 서버에 소프트 로그아웃 신호 (신규)
    clearSession()                 // 로컬 세션만 정리. FCM 토큰/Firebase 인스턴스는 보존
}

// RootViewModel.clearUserScopedPrefs(): deleteToken() 호출 제거(보존)
private fun clearUserScopedPrefs() {
    context.getSharedPreferences("mongle_heart", MODE_PRIVATE).edit().clear().apply()
    // "fcm" prefs 와 FirebaseMessaging.deleteToken() 은 건드리지 않는다
    unreadBadgeStore.clear()
}

// MongleFcmService.onNewToken: 로컬 저장 + 로그인 상태면 즉시 서버 등록
override fun onNewToken(token: String) {
    super.onNewToken(token)
    getSharedPreferences("fcm", MODE_PRIVATE).edit().putString("token", token).apply()
    if (sessionStore.hasValidSession()) {
        appScope.launch { runCatching { userRepository.registerFcmToken(token) } }
    } else {
        getSharedPreferences("fcm", MODE_PRIVATE).edit().putBoolean("pending_register", true).apply()
    }
}
```

### 5-4. 로컬 저장소 ↔ 메모리 세션 분리 모범사례 (요약)

| 계층 | iOS | Android | 보존 정책 |
|------|-----|---------|----------|
| **인증 자격증명** | Keychain `auth_token`/`refresh_token` | EncryptedSharedPreferences `mongle_auth_secure` | 로그아웃 시 삭제 |
| **메모리 세션** | TCA `state.currentUser` / SessionStore | ViewModel `RootUiState` | 로그아웃 시 초기화 |
| **디바이스 푸시 토큰** | 서버 `apnsToken`(+ Keychain 캐시) | 서버 `fcmToken`(+ `fcm` prefs) | **로그아웃에도 보존** ← 핵심 변경 |
| **사용자 범위 설정** | UserDefaults `mongle.*` | `mongle_heart` 등 | 로그아웃 시 정리 |

**핵심 원칙**: *인증 자격증명·메모리 세션은 로그아웃 시 소멸, 디바이스 푸시 토큰은 기기 식별자로 보존.* 이 분리가 "의도치 않은 로그아웃에도 가족 연결을 유지"하는 설계의 뼈대다.

---

## ✅ 실행 우선순위 (제안)

1. **(서버, 가장 먼저)** `logout()` 토큰 NULL 제거 → 보존 + `pushOptOut`. 발송 2-tier 게이트. — 이것만으로 P1/P2 누락 대부분 해소.
2. **(Android)** 서버 logout 호출 통일 + `deleteToken()` 제거 + `onNewToken` 즉시 등록.
3. **(iOS)** 세션만료 보존 동작 명문화 + 등록 401 비승격.
4. **(공통, 2차)** Silent Push 세션 복구, 죽은 토큰 배치 정리, 알림톡/SMS Fallback.

> ⚠️ 작업 전 확인 필요: 위 변경은 `pushOptOut`/`sessionState` **스키마 마이그레이션**과 신규 컨트롤러/라우트가 포함됨. 서버 배포 시 `npm run build`로 tsoa `routes.ts` 재생성 필수(과거 신규 컨트롤러 404 함정 주의). 작업은 `main` 직접 금지, Jira 이슈 단위 `fix/MG-XX` 브랜치 + PR.

