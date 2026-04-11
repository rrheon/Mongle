# Mongle v2 PRD — 캐릭터 성장 / Streak 알림 / 배지 시스템

작성: planner · 2026-04-11
상태: **Approved** (2026-04-11, 사용자가 §11 오픈 이슈 10개 전부 추천안 수용)

---

## 1. 개요

Mongle v1은 가족이 매일 한 개의 질문에 답하며 소통하는 앱으로 앱스토어에 출시되어 있다. v2에서는 **사용자 개인의 지속 사용을 보상**하는 경량 게이미피케이션 레이어를 추가한다. 세 축으로 구성한다.

1. **몽글캐릭터 단계별 성장** — 개인 streak가 쌓일수록 홈 화면의 내 캐릭터가 점진적으로 커진다.
2. **Streak 위험 알림** — 오늘 답변이 없고 streak가 끊기기 직전인 저녁에 맞춤 푸시를 보낸다.
3. **배지/업적 시스템** — streak/누적 답변 마일스톤을 달성하면 배지를 수여하고 프로필·설정에 노출한다.

### 목표

- D7/D30 리텐션 상승 (정확 수치는 애널리틱스 팀과 후속 정의).
- 기존 핵심 루프(오늘의 질문 → 답변 → 가족 확인)에 시각적 보상을 부여해 “어제도 왔다”는 감정을 만든다.
- 서버/클라이언트 모두 **v1 아키텍처 위에서 점진 증분**으로 구현한다. 재작성 금지.

### 비목표

- 레벨 경쟁, 리더보드, 친구 비교.
- 가족 단위 streak 시스템 확장 (이미 `FamilyService.getFamilyStreakDays`가 있으나 v2 범위 외).
- Privacy/ToS 개편 (이미 웹링크 노출로 완료).
- 캐릭터 커스터마이징 (색/이모티콘) — v3 후보.
- 유료화/결제.

---

## 2. 캐릭터 성장 시스템

### 2.1 현재 상태 (코드 확인)

- 홈 뷰: `FamTree/MongleFeatures/Sources/MongleFeatures/Presentation/Home/HomeView.swift:119` → `MongleSceneView`
- 캐릭터 구현: `FamTree/MongleFeatures/Sources/MongleFeatures/Design/Components.swift:1123` `MongleView` / `MongleMonggle`
- 크기 파라미터: `Components.swift:396` `size: CGFloat = 56`, `:404` `eyeSize = size * 0.18`, `:434` `.frame(width: name != nil ? 72 : size)`
- `MongleSceneView`는 `(name, color, hasAnswered, hasSkipped)` 튜플만 받는다 → **size를 멤버별로 전달할 필드가 없음** → v2에서 튜플 스키마 확장 필요.
- Android 대응: `Mongle-Android/app/src/main/java/com/mongle/android/ui/common/MongleCharacter.kt:77` `fun MongleCharacter(... size: Dp = 56.dp, ...)` — 이미 size 파라미터 보유.
- Streak 소스: `MongleServer/src/services/UserService.ts:152` `getStreak(userId)`, 라우트 `GET /users/me/streak` (`UserController.ts:53`).
- 클라이언트 사용: iOS `HomeFeature.State.streakDays` (`HomeFeature.swift:39`), Android 동일 필드 존재.

### 2.2 스테이지 정의 (권장안)

| 스테이지 | 이름 (ko / en / ja) | 필요 streak | 본체 크기 배율 | 비고 |
| :--- | :--- | :--- | :--- | :--- |
| 0 | 씨앗 / Seed / たね | 0–2일 | 1.00× (56pt) | 기본 |
| 1 | 새싹 / Sprout / めばえ | 3–6일 | 1.10× (≈62pt) | 첫 보상 |
| 2 | 잎사귀 / Leaf / はっぱ | 7–13일 | 1.20× (≈67pt) | 주간 달성 |
| 3 | 꽃봉오리 / Bud / つぼみ | 14–29일 | 1.32× (≈74pt) | 2주 |
| 4 | 꽃 / Bloom / はな | 30–99일 | 1.45× (≈81pt) | 월간 |
| 5 | 만개 / Radiance / まんかい | 100일+ | 1.60× (≈90pt) | 최종 |

**근거**
- 5단계는 너무 자주 오르지 않되 첫 주 내 초기 보상(3일)을 줘서 이탈률이 가장 높은 초기 구간을 방어.
- 크기 변동을 1.0→1.6 범위로 두면 홈 화면의 다른 가족 캐릭터(고정 56pt)와 겹쳐도 충돌 로직(`collisionRadius: 76`)을 깨지 않는다. 1.6× ≈ 90pt < 76+56 여유.
- 이름은 식물 성장 메타포(씨앗→만개). Mongle 앱의 식물/자연 톤(푸시 이모지 🌿)과 일치.

**대안 A (3단계 축소)**: 작음/보통/큼 — 구현은 가볍지만 보상 주기가 드물어 게이미피케이션 효과 약함.
**대안 B (7단계 확장)**: 이름 풀과 에셋 확보 비용이 크고, 인접 단계의 시각 차가 미세해 사용자 지각이 어려움.

→ **5단계(0~5) 권장.**

### 2.3 크기 적용 위치

- iOS: `Components.swift:1251` `MongleSceneView`의 `members` 튜플 요소에 `stage: Int` (또는 `sizeMultiplier: CGFloat`) 추가. 내부 루프 `MongleView(...)`에 전달 → `MongleMonggle`의 `size` 파라미터로 사용.
- Android: `MongleCharacter.kt:77` `MongleCharacter(... size: Dp)` 이미 지원. `MongleSceneView` 호출부에서 stage에 따라 size 계산.
- 현재 사용자(`isCurrentUser == true`)만 stage를 반영. 가족의 다른 멤버는 v2 범위에서 항상 1.00× 유지 (다른 사람 streak 데이터를 홈 API에 싣지 않기 위함).

### 2.4 전환 애니메이션

- 크기 변화는 `withAnimation(.spring(response: 0.6, dampingFraction: 0.7))` (iOS) / Compose `animateFloatAsState(tween 450ms)` (Android)로 부드럽게.
- **스테이지 업 순간 전용 연출**: 앱 진입 후 첫 fetch 결과 `stage`가 로컬 캐시 `lastKnownStage`보다 크면,
  1) 캐릭터 위로 이모지 펄스(✨) + “새싹이 되었어요!”류 토스트(1.5초).
  2) 햅틱 `.success` (iOS) / `HapticFeedbackType.LongPress` (Android).
- 연출 이후 로컬 캐시를 새 stage로 갱신. 앱 삭제/재설치 후 첫 진입에서는 연출을 억제한다(로컬 캐시 미존재 ⇒ 연출 off + 바로 최신 stage 반영).

### 2.5 리셋 규칙 (권장안)

- **streak가 0으로 떨어지면 stage도 0으로 초기화**.
- 근거: v2 핵심 가치 제안은 “어제도 왔다는 감정”이므로 지속성에 의미를 준다. 단계가 영구 해금이면 “한 번만 찍고 돌아오지 않아도 큰 캐릭터가 남아있다” → 보상의 의미 희석.
- 대신 **배지는 영구 수여** (“과거에 꽃 단계를 달성했음”이라는 기록이 배지로 남음). 이 이중 구조가 핵심.

**대안**: 영구 유지 + 별도 “오늘의 활기” 인디케이터. 스트레스는 낮지만 성장 동기가 약해짐. → **권장안 채택.**

### 2.6 엣지 — 하루 공백 허용?

- `getStreak`의 현재 구현(`UserService.ts:173-193`)은 **“오늘 또는 어제”** 답변이 있으면 연속 계산을 시작한다. 즉 오늘 아직 답 안 해도 streak은 유지 (어제 답했다면). 이 정의를 그대로 따른다. streak 위험 알림(3절)이 이 유예 시간을 이용한다.

---

## 3. Streak 위험 알림

### 3.1 현재 상태

- AWS EventBridge + Lambda 기반 재촉 스케줄러가 이미 존재: `MongleServer/src/reminderScheduler.ts:35` `sendDailyReminders()`. 24h 경과한 DQ에 대해 미답변자에게 `ANSWER_REQUEST` 푸시.
- 푸시 다국어 사전: `MongleServer/src/utils/i18n/push.ts:26` (`answerReminder` 항목). `PushNotificationService.sendApnsPush` / `sendFcmPush` 사용.
- `User.locale` 기반 로컬라이즈 (`resolveLocaleFromHeader`).
- 타임존: 현재 스케줄러는 **KST 고정**(`getKstToday`). v2에서도 **서버는 KST로 판단**하되 문구는 수신자 locale로 로컬라이즈.

### 3.2 트리거 조건 (권장안)

사용자 U에 대해 매일 **KST 21:00**에 실행되는 새로운 Lambda 핸들러에서 다음을 모두 만족하면 푸시를 보낸다:

1. `getStreak(U) >= 2` (즉, 오늘 끊기면 잃을 streak이 있어야 함)
2. 오늘 KST 날짜에 U가 작성한 Answer 레코드 없음
3. 어제 KST 날짜에 U가 작성한 Answer 레코드 있음 (= 유예일을 쓰고 있는 상태)
4. U가 속한 가족의 오늘 DailyQuestion이 존재함 (답할 질문이 있어야 함)
5. U가 streak 알림을 비활성화하지 않음 (옵트아웃 플래그, 3.3 참조)
6. U가 오늘 이미 동일 알림을 받지 않음 (중복 방지)

조건 1의 임계값을 `>= 2`로 두는 이유: streak 1일은 잃어도 심리적 손실이 미미하고, 알림 피로도가 더 큼. 2일부터 “연속”이라는 감각이 생긴다.

**대안**: `>= 3` — 더 보수적이지만 도달 전 사용자를 보호하지 못함. → **2 권장.**

### 3.3 옵트아웃 UX

- 설정 → 알림 화면에 토글 “Streak 위험 알림” 추가. 기본값 **ON**.
- DB: `User` 테이블에 `streakRiskNotify: Boolean @default(true)` 신규 필드. 마이그레이션 필수.
- 토글은 기존 푸시 권한(OS 레벨)과 독립. OS 권한이 꺼져 있으면 토글 자체는 건드리지 않고 서버가 `apnsToken/fcmToken`이 null이면 자연 차단.

### 3.4 알림 문구

`push.ts`의 `PushMessages` 인터페이스에 `streakRisk` 추가:

| locale | title | body |
| :--- | :--- | :--- |
| ko | 🌿 연속 기록이 곧 끊겨요 | 지금 오늘의 질문에 답하면 {n}일 연속을 지킬 수 있어요. |
| en | 🌿 Your streak is about to end | Answer today’s question now to keep your {n}-day streak. |
| ja | 🌿 連続記録が途切れそうです | 今日の質問に答えて{n}日連続を守りましょう。 |

`{n}` 은 현재 streak 값.

### 3.5 구현 방식 — 서버 크론 vs 로컬 알림

**권장: 서버 크론 (신규 Lambda `streakRiskScheduler.ts` + EventBridge 규칙 `cron(0 12 * * ? *)` — UTC 12:00 = KST 21:00).**

근거:
- 기존 `reminderScheduler.ts`가 동일 패턴으로 이미 검증됨. 운영/관측 관점에서 동질.
- 클라이언트 로컬 알림은 “오늘 아직 답 안 했는지”를 오프라인으로 정확히 판정할 수 없고 (서버 상태 필요), 앱을 한 번도 안 연 사용자는 스케줄링 자체가 안 된다.
- 타임존은 v2 범위에서는 KST 고정 (사용자가 해외여도 21:00 KST). 글로벌 대응은 Section 9 오픈 이슈로 이관.

---

## 4. 배지/업적 시스템

### 4.1 현재 상태

- `schema.prisma:199` `NotificationType` enum에 `BADGE_EARNED` 값이 **이미 선언되어 있으나**, 실제로 이를 생성하거나 수여하는 서비스/테이블은 존재하지 않는다 (grep 결과 참조뿐). 즉 v1에서 배지 UI/DB는 미구현.

### 4.2 초기 배지 세트 (6개 권장)

| 코드 | 이름 (ko / en / ja) | 조건 | 근거 |
| :--- | :--- | :--- | :--- |
| `STREAK_3` | 새싹 / First Sprout / めばえ | streak 3일 달성 | 첫 주 리워드 |
| `STREAK_7` | 한 주의 약속 / One Week / いっしゅうかん | streak 7일 달성 | 주간 마일스톤 |
| `STREAK_30` | 한 달의 결실 / One Month / ひとつき | streak 30일 달성 | 월간 마일스톤 |
| `STREAK_100` | 백일의 기록 / Century / 百日 | streak 100일 달성 | 장기 상징 |
| `ANSWERS_10` | 열 번의 이야기 / Ten Stories / 10の物語 | 누적 답변 10개 | streak과 독립적 성취 경로 |
| `ANSWERS_50` | 쉰 번의 이야기 / Fifty Stories / 50の物語 | 누적 답변 50개 | 중기 목표 |

**확장 여지 (v2.1)**: 카테고리 전 섭렵(`QuestionCategory` 6개 모두 답변 1회 이상), 가족 단위 달성 등. v2 초기 릴리즈에서는 위 6개로 고정.

### 4.3 획득 UX

- **획득 시점**: 서버가 답변 생성 직후(`AnswerService.createAnswer` 또는 후처리 훅)에서 배지 조건을 점검하고 수여.
- **알림**: 수여와 동시에
  1) `Notification` 테이블에 `type: BADGE_EARNED` 레코드 생성.
  2) APNs/FCM 푸시 1회 (title: “새 배지를 받았어요!”, body: 배지 이름).
  3) 클라이언트는 다음 `GET /users/me/badges` 응답에서 `newlySeen=false`인 배지를 감지해 **획득 팝업**(`MonglePopupView` 재사용) 표시 → 확인 시 `POST /users/me/badges/mark-seen` 호출.
- **표시 위치**:
  - 설정 → “내 배지” 신규 row (설정의 `profileSection` 또는 `accountSection` 상단). 진입 시 `BadgesView` (iOS) / `BadgesScreen` (Android) 그리드 표시.
  - 획득한 배지는 컬러 + 획득 날짜, 미획득은 회색+조건 텍스트.
  - 홈 화면 진입 시에는 배지 아이콘을 노출하지 않음 (UI 복잡도 관리).

### 4.4 DB 스키마 (Prisma)

```prisma
model BadgeDefinition {
  code        String     @id            // "STREAK_3"
  category    BadgeCategory
  thresholdNumeric Int?                  // streak/count 기준 등
  iconKey     String                     // 클라이언트 에셋 키
  createdAt   DateTime   @default(now())
  awards      UserBadge[]
}

enum BadgeCategory {
  STREAK
  ANSWER_COUNT
  // 확장 여지: CATEGORY_COMPLETION, FAMILY
}

model UserBadge {
  id          String     @id @default(uuid())
  userId      String     @map("user_id")
  badgeCode   String     @map("badge_code")
  awardedAt   DateTime   @default(now()) @map("awarded_at")
  seenAt      DateTime?  @map("seen_at")   // null = 미확인(팝업 대상)
  user        User       @relation(fields: [userId], references: [id])
  badge       BadgeDefinition @relation(fields: [badgeCode], references: [code])

  @@unique([userId, badgeCode])
  @@index([userId, awardedAt(sort: Desc)])
  @@map("user_badges")
}
```

`User` 모델에 `badges UserBadge[]` 관계 추가. 배지 정의는 seed 스크립트로 초기 6개 삽입.

### 4.5 이름/아이콘 다국어 전략

문구 자체는 배지 정의 테이블에 저장하지 않고 **클라이언트 Localizable**에 `badge_streak_3_name`, `badge_streak_3_condition` 등으로 둔다. 서버는 `code`만 돌려주고 클라이언트가 번역. 사유: 다국어 필드를 DB에 3 컬럼씩 두면 회귀 위험 + 이미 앱 스트링스 리소스 흐름이 이 패턴.

---

## 5. API 변경

### 5.1 기존 유지

- `GET /users/me/streak` 그대로. 응답 `{ streakDays: number }`.
- `PUT /users/me` 확장: `UpdateUserRequest`에 `streakRiskNotify?: boolean`, `badgeEarnedNotify?: boolean` 추가. `UserResponse`(본인 응답)에서도 두 필드 노출. 클라이언트 알림 토글 UI(§7 iOS / §8 Android)는 이 엔드포인트로 저장. 구현: MG `[Engine] 8`.

### 5.2 신규

#### `GET /users/me/character-stage`
```
200 OK
{
  "stage": 3,
  "stageKey": "BUD",
  "streakDays": 17,
  "nextStageStreak": 30,
  "sizeMultiplier": 1.32
}
```
- 서버가 streak → stage 매핑을 단일 진실 소스로 제공. 클라이언트가 각자 계산하지 않도록 한다 (iOS/Android 불일치 방지).
- `nextStageStreak`은 최종 단계면 `null`.

#### `GET /users/me/badges`
```
200 OK
{
  "badges": [
    {
      "code": "STREAK_3",
      "category": "STREAK",
      "iconKey": "badge_streak_3",
      "awardedAt": "2026-04-09T12:00:00Z",
      "seenAt": null
    },
    ...
  ],
  "definitions": [
    { "code": "STREAK_7", "category": "STREAK", "iconKey": "badge_streak_7" },
    ...
  ]
}
```
- `badges`는 **획득한 것만**. `definitions`는 조건 표시를 위한 **전체 목록**(미획득 포함). 클라이언트는 둘의 차집합으로 미획득 UI를 그린다.

#### `POST /users/me/badges/mark-seen`
```
Body: { "codes": ["STREAK_3"] }
200 OK { "ok": true }
```
- 클라이언트가 팝업을 보여준 뒤 호출. 서버는 `UserBadge.seenAt` 갱신.

#### (내부용) 배지 수여 훅
- 별도 엔드포인트 없음. `AnswerService.createAnswer` 성공 후 `BadgeService.checkAndAward(userId)` 호출. 여기서 streak 재조회 + 누적 답변 수 조회 후 미보유 배지 수여.

### 5.3 응답 스키마 문서화

`MongleServer/src/models/` 에 `CharacterStageResponse`, `BadgeListResponse`, `MarkBadgesSeenRequest` 추가. tsoa가 OpenAPI를 자동 생성.

---

## 6. DB 스키마 변경 / 마이그레이션

새 Prisma 마이그레이션 하나로 묶는다.

1. `User` 테이블: `streak_risk_notify BOOLEAN NOT NULL DEFAULT TRUE` 컬럼 추가.
2. `BadgeDefinition` 테이블 생성 + seed (6 rows).
3. `UserBadge` 테이블 생성 + 인덱스.
4. `BadgeCategory` enum 생성.
5. (옵션) `User` ↔ `UserBadge` 관계 필드 선언.

마이그레이션 이름: `v2_character_growth_and_badges`. 배포 절차: Prisma migrate → seed → 서버 롤아웃 → 클라이언트 롤아웃 (API는 클라이언트 구버전도 무시 가능).

---

## 7. iOS 구현 영향 (TCA)

- `HomeFeature.State`: `characterStage: Int = 0`, `sizeMultiplier: CGFloat = 1.0`, `lastSeenStage: Int` (UserDefaults 동기화) 추가.
- `HomeFeature.Action`: `.characterStageFetched(TaskResult<CharacterStageResponse>)`, `.onStageUp(from: Int, to: Int)` 추가. `onAppear` effect에서 `userClient.fetchCharacterStage()` 병렬 fire-and-join.
- 새 클라이언트: `Domain/UserClient.swift` (또는 동등 위치)에 `fetchCharacterStage`, `fetchBadges`, `markBadgesSeen` 추가. `DependencyKey`.
- 새 Feature: `BadgesFeature` (Presentation/Badges/). State: 배지 목록, 정의 목록, 로딩/에러. Action: `onAppear`, `badgesFetched`, `markedSeen`. View: `BadgesView` (그리드 + 셀).
- `SettingsFeature`: 프로필/계정 섹션에 “내 배지” 행 추가 (`SettingsTabView.swift`의 기존 `settingsSection` 패턴 재사용). `Action.badgesTapped` → Navigation.
- `MongleSceneView` 시그니처 확장: `members` 튜플에 `sizeMultiplier: CGFloat` 추가. 호출부에서 현재 사용자만 값 주입.
- 배지 획득 팝업: 앱 전역 루트(`FamTreeApp`)에 `.badgeAwardOverlay` 리듀서/뷰. 홈→답변 작성→배지 수여 시점에 자동 트리거.
- Localizable.strings에 신규 키 추가 (ko/en/ja):
  - 스테이지 이름 × 6단계 × 3언어
  - 배지 이름/조건 × 6개 × 3언어
  - 스테이지 업 토스트, 배지 팝업 문구, 알림 설정 토글 텍스트
- **TCA 예외**는 이 프로젝트에 한해 유지 (CLAUDE.md §2 참조).

---

## 8. Android 구현 영향 (MVVM Compose)

- `HomeViewModel`: `characterStage`, `sizeMultiplierDp` StateFlow 추가. `init` 또는 `refresh()`에서 `userRepository.getCharacterStage()` 호출.
- `ApiUserRepository.kt`: `getCharacterStage`, `getBadges`, `markBadgesSeen` 추가. `MongleApiService`에 Retrofit 인터페이스 선언.
- `MongleCharacter.kt:77`의 `size: Dp` 파라미터를 `MongleSceneView`에서 현재 사용자 한정 override.
- 새 화면: `ui/badges/BadgesScreen.kt` + `BadgesViewModel.kt`. MVVM 구조 (TCA 금지 — YCompany 공통 규칙 유지).
- `SettingsScreen.kt`: `legalSection` 위에 `profileSection`에 “내 배지” 행 추가 (기존 `openLegalUrl` 패턴 참조).
- `res/values/strings.xml`, `values-en/strings.xml`, `values-ja/strings.xml`에 신규 문구 추가.
- 배지 수여 팝업은 `MonglePopup` 컴포저블 재사용.
- 알림 설정 토글 화면이 이미 있으면 그쪽에, 없으면 `SettingsScreen` 내 “알림” 섹션에 토글 추가.

---

## 9. 엣지 케이스

1. **streak 0 상태에서 stage API 호출** — 서버는 `stage: 0, sizeMultiplier: 1.0, nextStageStreak: 3` 반환. 클라이언트는 캐릭터를 기본 크기로.
2. **네트워크 실패** — stage/badges 페치 실패는 조용히 폴백 (마지막 성공 stage 유지, 배지 화면은 로딩/에러 상태 토스트). 홈 렌더링을 막지 말 것.
3. **배지 중복 수여 방지** — `UserBadge @@unique([userId, badgeCode])`로 DB 레벨 가드. 서비스 로직에서도 `findFirst` → upsert 대신 조건부 create.
4. **여러 배지 동시 달성** (ex: 가입 후 몰아서 답변 100개 테스트) — `BadgeService.checkAndAward`는 미획득 배지를 모두 순회. 팝업은 우선순위가 높은 하나만 표시하고 나머지는 큐 → 팝업 닫을 때마다 순차.
5. **타임존** — 서버 streak 계산은 이미 UTC 기준(`UserService.ts:173`), 알림 스케줄러는 KST 고정. stage 임계값은 `getStreak`의 반환 정수에만 의존하므로 타임존 이슈가 추가되지 않는다. 단, UTC 경계 답변자는 현재 구현상 1일 차이가 날 수 있음 → v2에서 별도 수정하지 않음 (Section 11 리스크).
6. **푸시 권한 미부여** — 알림 설정 토글은 ON이어도 `apnsToken/fcmToken`이 null이면 스케줄러가 자연 스킵. 앱 진입 시 권한 요청 프롬프트는 기존 `showNotificationPermission` 플로우 재사용.
7. **스테이지 강등 연출** — stage가 내려가는 경우 특별 연출/알림 없이 조용히 크기만 축소 (사용자에게 부정적 경험을 피함).
8. **가입 직후 빈 답변 히스토리** — `stage: 0`, 배지 0개. 첫 답변 제출 직후 `STREAK_3`까진 시간이 필요하므로 “곧 첫 배지가 생겨요” 같은 투어스크린은 v2 비포함.
9. **게스트 사용자** — `HomeFeature.State.isGuest == true`면 stage/badges API 호출 스킵. 홈 캐릭터는 1.0× 고정.
10. **여러 가족에 속한 사용자** — 스트릭/배지는 사용자 단위이며 가족과 독립. 가족 전환 시 값 유지.

---

## 10. 티켓 분해 초안

아래는 승인 후 **노션 티켓으로 발급할 항목**이다. 현재 생성하지 않음. 접두사는 `[Mongle]` 에픽, `[Engine]` 서버, `[UI]` 클라이언트, `[QA]`, `[Docs]`.

1. `[Mongle] 0. v2 에픽 — 캐릭터 성장 + streak 알림 + 배지` (이미 존재, #1)
2. `[Engine] 1. Prisma 마이그레이션 — User.streakRiskNotify / BadgeDefinition / UserBadge`
3. `[Engine] 2. BadgeService — checkAndAward + 배지 수여 훅 연결`
4. `[Engine] 3. CharacterStageService — streak→stage 매핑 + GET /users/me/character-stage`
5. `[Engine] 4. GET /users/me/badges + POST /users/me/badges/mark-seen`
6. `[Engine] 5. 신규 streakRiskScheduler Lambda + EventBridge cron(KST 21:00)`
7. `[Engine] 6. push.ts — streakRisk 다국어 문구 추가`
8. `[Engine] 7. BadgeDefinition seed 스크립트 (6개)`
9. `[UI] 1. iOS — MongleSceneView sizeMultiplier 주입 + HomeFeature stage 통합`
10. `[UI] 2. iOS — BadgesFeature + BadgesView + Settings 진입점`
11. `[UI] 3. iOS — 배지 획득 팝업 + stage 업 토스트 + 로컬라이즈`
12. `[UI] 4. iOS — Settings 알림 토글 (streakRiskNotify)`
13. `[UI] 5. Android — MongleSceneView size 주입 + HomeViewModel stage 통합`
14. `[UI] 6. Android — BadgesScreen/ViewModel + Settings 진입점 + strings`
15. `[UI] 7. Android — 배지 팝업 + stage 업 토스트 + 알림 토글`
16. `[QA] 1. v2 전체 회귀 + 신규 기능 검증 시나리오` (이미 존재, #10)
17. `[Docs] 4. v2 릴리즈 노트 (ko/en/ja)`

---

## 11. 확정 사항 / 리스크

원래 오픈 이슈 10개 전부 planner 추천안을 그대로 수용. 본 섹션은 기록용으로 남기며, 이후 구현은 이 확정값을 단일 진실로 삼는다.

1. **스테이지 임계값**: `0 / 3 / 7 / 14 / 30 / 100` 확정. (§2.2 권장안)
2. **스테이지 수**: **5단계 확정** (0=씨앗 포함 총 6개 레벨, streak 0은 stage 0). 3/7 대안 모두 기각.
3. **리셋 정책**: **streak 0으로 떨어지면 stage 0으로 초기화**. 배지는 **영구 보관**. 이중 구조 유지.
4. **배지 초기 세트**: `STREAK_3 / STREAK_7 / STREAK_30 / STREAK_100 / ANSWERS_10 / ANSWERS_50` 6개 그대로. 추가 배지 없음.
5. **streak 위험 알림 시각**: **KST 21:00 고정**. 사용자별 시간 선택지 제공하지 않음.
6. **글로벌 타임존 대응**: **v2에서는 KST 고정**. locale/디바이스 tz 분기는 v2.1 이후 과제로 이연.
7. **가족 멤버 캐릭터 크기**: **내 캐릭터만 stage 반영**. 다른 가족 멤버는 v1과 동일하게 56pt 고정. 가족 streak 노출 확장 없음.
8. **스테이지별 비주얼**: **크기 변화만**. 장식/의상/오버레이 등 추가 아트웍 작업 없음. 에셋 추가 티켓 불필요.
9. **배지 수여 푸시**: **기본 ON**. 설정 → 알림 화면에 streakRisk 토글과 **별개의 독립 토글** '배지 획득 알림' 추가. 즉 설정 화면에 푸시 관련 신규 토글 **2개** (`streakRiskNotify`, `badgeEarnedNotify`). 둘 다 기본값 true.
10. **애널리틱스 이벤트**: **v2 범위 외**. stage_up / badge_awarded / streak_risk_pushed 등 추적 이벤트 포함하지 않음.

### 확정 사항에 따른 PRD 내부 후속 수정점

- §3.3 옵트아웃: `User.streakRiskNotify` 외에 `User.badgeEarnedNotify BOOLEAN NOT NULL DEFAULT TRUE` 컬럼 1개 더 추가. 마이그레이션 이름은 그대로(`v2_character_growth_and_badges`).
- §4.3 획득 UX: 푸시 발송 전 `user.badgeEarnedNotify` 조건 체크 후 APNs/FCM 호출. 인앱 팝업(`MonglePopupView`)은 이 토글과 무관하게 계속 표시 (사용자가 “푸시는 꺼도 앱 안에서는 본다”는 명확한 UX).
- §7 iOS / §8 Android 구현 영향: Settings 알림 화면에 토글 2개 추가로 확장 (기존 PRD는 1개만 언급).
- §2.2·§2.5·§4.2 권장안 표기는 그대로 유지하되 이제 **확정값**임.

### 리스크 (존치)

- TCA + 새 Feature 증가로 iOS 빌드 시간/모듈 복잡도 상승. `BadgesFeature`는 최소 표면적으로 설계.
- 배지 수여 훅이 답변 생성 경로에 들어가면서 `Answer` 생성 응답 지연 가능. 수여 로직은 try/catch + fire-and-warn.
- KST 고정 알림은 해외 거주 사용자에게 새벽/점심에 울림. 이미 `reminderScheduler`가 동일 제약이므로 v2에서 확장 않음. v2.1 이후 검토 대상.
- 스테이지 리셋이 감정적 부정 자극이 될 수 있음. 사용성 테스트 없이 결정. 필요 시 v2.1에서 “유예권 1회” 도입.
- `UserService.ts:173` streak 계산이 UTC 기준이라 KST 심야 답변이 1일 어긋날 수 있는 기존 결함은 v2에서 수정하지 않음.

---

_끝._
