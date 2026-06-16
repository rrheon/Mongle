# HomeFeature — 큰 State + 많은 Action을 가진 thin Reducer

## State 관련 질문 및 궁금증
todayQuestion과 yesterdayQuestion 2개를 둔 이유?
- 하나로 관리해도 괜찮지않나?

hasAnsweredYesterday
hasAnsweredToday
- 이 두개는 왜 따로인지?

hasSkippedToday - 왜 따로인지? 위에 hasAnsweredToday를 hasAnsweredToday를 Bool로 두지말고 enum으로 관리하면 되지않나?

hasFamily - 이건 왜 있는지?

familyAnswerCount - 왜 있지
streakDays - 왜 있는건지
allFamilies - 이게 왜 있지?

## Action 관련 질문 및 궁금증
- Action이 너무 많음 -> mark로 나누긴 했으나 이걸 action을 나누면 어떨지
- onApper -> 오늘 어제 질문이 없을 때 요청새로고침을 보내는데 오늘질문과 내일 질문을 받는 변수를 하나로 통일하면 어떤지
- questionTapped -> 이거 또한 오늘 내일 질문을 나눈 이유를 모르겠음
- 게스트 여부를 확인해서 각 액션마다 화면이동을 달리하는걸 하나로 묶고 스위치로 나누는게 낫지않나?
- 노티피케이션 허가에서 cancellable을 단 이유와 mainactor로 메인스레드에서 돌린 이유를 모르겠음
    - 스킵이랑 합치면 안되나? 

---

## 위 질문들에 대한 답 (코드 검증 후)

### State 관련

#### Q1·Q2. todayQuestion / yesterdayQuestion (그리고 hasAnsweredToday / hasAnsweredYesterday) 분리
**합칠 수 없는 이유가 도메인에 있음.** State 라인 27 주석 + body 라인 169, 195을 보면:

> "오전 11시 이전엔 어제 질문이 **답변 수정 가능**한 상태로 살아있음"

즉 **오전 11시 이전 시점엔 어제 질문과 오늘 질문이 동시에 의미를 가짐**. `myMonggleTapped`에서 분기되는 게 그 증거:
```swift
let hasAnswered = state.todayQuestion != nil 
    ? state.hasAnsweredToday : state.hasAnsweredYesterday
```
오늘 질문이 있으면 "오늘 답했나?", 아직 안 떴으면 "어제 답했나?"를 봐야 함. 둘이 다른 데이터.

**다만 더 좋은 모델링은 가능.** 지금 구조는 (todayQ, yesterdayQ) 조합이 4가지 다 가능한데, 실제 유효 상태는 일부뿐. enum으로 묶으면 컴파일러가 invalid state를 차단:
```swift
enum ActiveQuestion {
    case today(Question, hasAnswered: Bool, hasSkipped: Bool)
    case yesterdayEditable(Question, hasAnswered: Bool)  // 오전 11시 이전
    case none
}
```
이게 "**Make illegal states unrepresentable**" 원칙. State 필드 4~5개가 1개로 줄고 분기도 명확해짐. 직관 자체는 맞는데, 단순 통일이 아니라 **enum으로 묶기**가 정답.

#### Q3. hasSkippedToday를 enum으로 — **이건 100% 맞음**
지금 가능한 조합:

| hasAnsweredToday | hasSkippedToday | 의미 |
|---|---|---|
| true | true | **모순(불가능)** |
| true | false | 답변함 |
| false | true | 패스함 |
| false | false | 아직 안 함 |

4분의 1이 invalid state. 두 Bool로 표현할 이유가 없음:
```swift
enum TodayStatus: Equatable {
    case notYet
    case answered
    case skipped
}
```
이게 **대수적 데이터 타입(ADT)** 활용. "답변과 패스는 상호배타적"이라는 도메인 규칙이 타입에 박힘 → 컴파일러가 강제. 지금처럼 두 Bool이면 누가 실수로 둘 다 true로 만들면 런타임에 이상해짐.

#### Q4. hasFamily 왜 있음?
```swift
public var hasFamily: Bool { family != nil }
```
저장이 아니라 **computed property** — 매번 `family != nil` 계산. 의미 있는 이름으로 추상화한 것뿐 비용 0.

다만 Reducer body 안에선 `state.family`로 옵셔널 바인딩(`if let family = state.family`)만 쓰고 `hasFamily`는 직접 호출 안 함. View 쪽에서 쓸 가능성. **어디에서도 안 쓰이면 dead code**니까 grep 한 번 해보면 됨.

#### Q5. familyAnswerCount / streakDays / allFamilies
- **familyAnswerCount**: 가족 중 몇 명 답했는지 (대시보드 카운터) ok 이해
- **streakDays**: 연속 답변일 (게이미피케이션 위젯) 필요없을 듯
- **allFamilies**: 사용자가 속한 그룹 목록 (그룹 전환 드롭다운) ok

셋 다 **화면이 보여줘야 할 정보**라 State에 있어야 함. "왜 있지?"의 답은 "**홈 대시보드 UI 요소**". 다만 본문에서 지적한 것처럼 State가 20여개로 큰 건 사실 — `HomeStreakFeature`, `HomeFamilyListFeature` 같이 쪼개는 게 옵션. 단, **쪼개면 부모(MainTab)에서 합성 비용**이 생기니까 트레이드오프.

---

### Action 관련

#### Q1. Action 너무 많음 → mark 말고 enum 중첩
지금은 주석 mark로만 카테고리 분리. Point-Free(TCA 메인테이너) 권장 패턴은 **중첩 enum**:
```swift
public enum Action {
    case view(View)
    case `internal`(Internal)
    case delegate(Delegate)
    
    public enum View: Equatable { 
        case onAppear, questionTapped, ... 
    }
    public enum Internal: Equatable { 
        case setLoading(Bool), ... 
    }
    public enum Delegate: Equatable { ... }
}
```
**장점**: 호출 측이 `store.send(.view(.onAppear))` — 의도가 타입에 박힘. View가 실수로 `.setLoading(false)` 발사하는 걸 막을 수 있음(Internal은 외부에서 만들면 안 되는 액션).

#### Q2. onAppear에서 today/yesterday 변수 통일
Q1·Q2 답변과 연결. 별개 변수로 두는 게 도메인 요구. 다만 **`ActiveQuestion` enum으로 묶으면** `state.activeQuestion == .none && !state.isLoading` 한 줄로 깔끔.

#### Q3. questionTapped의 today/yesterday 분기
사실 `questionTapped` 자체는 분기 안 함:
```swift
let activeQuestion = state.todayQuestion ?? state.yesterdayQuestion
```
**옵셔널 체인 한 줄로 끝.** 분기는 `myMonggleTapped`에 있는데, 거기도 같은 이유(오전 11시 이전 어제 질문 활성화)라 어쩔 수 없음.

#### Q4. 게스트 체크 반복 — **방향성은 맞고 구체화만 하면 됨**
8개 액션에서 같은 `if state.isGuest { ... return .none }` 반복. 본인 답("switch로 처리하는 함수")의 의도는 맞는데, 가장 깔끔한 구현은 **헬퍼 함수 + guard**:
```swift
private func requireAuth(_ state: inout State) -> Bool {
    if state.isGuest {
        state.showGuestLoginPrompt = true
        return false
    }
    return true
}

case .questionTapped:
    guard requireAuth(&state) else { return .none }
    let activeQuestion = state.todayQuestion ?? state.yesterdayQuestion
    guard let question = activeQuestion else { return .none }
    return .send(.delegate(.showQuestionSheet(question)))
```
참고로 Swift `switch`에서 **여러 case + where 절을 한 줄로 묶는 건 불가능**(case 패턴 매칭 제약). 그래서 switch 통합이 아니라 헬퍼 추출이 정답.

더 적극적으로 가면, **guest 가드 전용 Reducer를 분리**해서 합성:
```swift
Reduce { state, action in /* guest gate */ }
Reduce { state, action in /* 본 로직 */ }
```
근데 이건 과해 보임. 헬퍼로 충분.

#### Q5. cancellable + MainActor

**cancellable 이유**: 본인 답이 맞음. 빠른 더블탭 → `requestAuthorization` + `registerForRemoteNotifications`가 두 번 fire → device token callback 중복(race). `cancelInFlight: true`로 같은 ID가 이미 실행 중이면 취소하고 새로 시작.

**MainActor 이유**: 
- `.run { _ in ... }` 클로저는 **임의 actor**에서 실행됨(보장 X — Sendable 클로저로 background thread에서 돌 수도)
- `UIApplication.shared.registerForRemoteNotifications()`는 **UIKit API**
- UIKit은 메인 스레드 호출이 안전한 디폴트. iOS 17+부터 `UIApplication`이 `@MainActor` 격리되어서 Swift 6에선 컴파일 에러가 날 수도 있음
- 그래서 `await MainActor.run { ... }`로 강제

진짜로 메인이 필수인지 Apple 문서엔 명시 안 되어 있지만, **UIKit 호출은 메인** 규칙을 따른 안전한 선택.

**스킵과 합치자 — 합리적**:
```swift
case .notificationPermission(allow: Bool):
    if let family = state.family {
        UserDefaults.standard.set(true, forKey: "mongle.notifSetup.\(family.id.uuidString)")
    }
    state.showNotificationPermission = false
    guard allow else { return .none }
    return .run { _ in
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    .cancellable(id: CancelID.requestNotifAuth, cancelInFlight: true)
```
공통 로직(UserDefaults 마킹 + UI 닫기) 중복 제거, 분기는 `guard allow`로 한 줄. **권장.**

---

### 종합 평가

직관이 매우 정확. 특히:
- **Q3 enum 묶기**: 정석. invalid state 제거.
- **Q4 게스트 체크 추출**: 헬퍼 함수로 정확히 그 방향.
- **Q5 스킵 합치기**: 합리적인 리팩토링.

도메인 이해가 필요했던 것:
- **Q1·Q2 today/yesterday 분리**: 오전 11시 이전 어제 질문 수정 가능 규칙 때문. 단순 통일은 X, **enum으로 묶기**가 답.

가장 큰 개선 한 방을 꼽으라면 **State를 ADT(enum)로 모델링**. 4~5개 Bool 필드가 enum 하나로 줄고, "답변+패스 동시 true" 같은 모순 상태가 컴파일러에 의해 차단됨.

---

**파일 위치**: `MongleFeatures/Sources/MongleFeatures/Presentation/Home/HomeFeature.swift`
**줄수**: 327줄
**위치 의미**: Stage 2의 세 번째 읽기 대상. **가장 큰 단일 Reducer**지만 구조는 의외로 단순.

---

## 한 눈에 본 요약

> "**홈 화면의 대시보드** Reducer. State 필드 20여개, Action 30여개. 그러나 본문은 대부분 'guest 체크 + delegate 발송'의 반복으로 의외로 단순. **Scope/ifLet 같은 child composition은 없음** — child composition은 MainTabFeature(부모)에서 처리."

### QuestionSheet · Write와 비교

| | QuestionSheetFeature | WriteQuestionFeature | **HomeFeature** |
|---|---|---|---|
| State 필드 | 3개 | 3개 | **20여개** (큰 dashboard state) |
| Action 종류 | UI 입력 + delegate | UI 입력 + Effect + delegate | **UI + Internal + delegate 3종류로 분리** |
| `@Dependency` | 없음 | `questionRepository`, `errorHandler` | **없음** (의외!) |
| Effect 복잡도 | `.send`, `.none` | `.run` (네트워크) | `.run` + **`.cancellable`** (취소 가능 effect) |
| 새 개념 | delegate | `@Dependency`, `.run`, `Result` 페이로드 | **CancelID, `.cancellable`, `MainActor.run`** |

→ **"많아 보여도 본문은 단순"** — TCA의 단방향 흐름이 큰 화면을 어떻게 다루는지 보여주는 좋은 예.

### 왜 `@Dependency`가 없는가?

이게 가장 흥미로운 관찰: HomeFeature는 **Repository를 직접 호출하지 않음**. 데이터는 어떻게 들어오나?

```swift
case .onAppear:
    if state.todayQuestion == nil && state.yesterdayQuestion == nil && !state.isLoading {
        state.isLoading = true
        return .send(.delegate(.requestRefresh))   // ← 부모에게 "데이터 가져와줘" 신호
    }
```

→ **데이터 fetching은 부모(MainTabFeature)에게 위임**. HomeFeature는 "**보여줄 데이터를 받아 화면 상태를 관리**"하는 역할만. WriteQuestionFeature가 자기 데이터를 직접 가져오는 것과 정반대 패턴.

이게 좋은 설계인지는 별도 논의가 필요하지만 (각 Feature가 자기 데이터 책임을 갖는 게 일반적), Mongle은 **중앙 집중식 데이터 관리** 스타일을 선택. 9-A1.
-> 그럼 MainFeature가 HomeFeature , HistoryFeature, SearchFeature, SettingFeature등 데이터를 받아오는 호출을 담당하고 있는건가?
---

## 새로 등장하는 3가지 개념

### 1. `CancelID` enum + `.cancellable(id:, cancelInFlight:)` — Effect 취소 패턴

```swift
private enum CancelID: Hashable {
    case requestNotifAuth
}

// ... body 안에서:
return .run { _ in
    _ = try? await UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .badge, .sound])
    await MainActor.run {
        UIApplication.shared.registerForRemoteNotifications()
    }
}
.cancellable(id: CancelID.requestNotifAuth, cancelInFlight: true)
//          └────────── 이 ID로 Effect 식별 ──────────┘  └ 이미 실행 중이면 취소하고 새로 시작 ┘
```

**문제 시나리오**: 사용자가 알림 허용 버튼을 빠르게 두 번 탭 → `requestAuthorization` + `registerForRemoteNotifications`가 두 번 fire → device token callback이 중복 발생 → race condition.

**해결 메커니즘**:
- `CancelID.requestNotifAuth`라는 식별자를 부여한 Effect
- 같은 ID의 Effect가 이미 실행 중이면 → `cancelInFlight: true` 덕분에 **기존 것을 취소하고 새로 시작**
- = "**같은 ID의 Effect는 한 번에 하나만 실행 보장**"

이건 TokenRefreshCoordinator(7-A2)와 **다른 패턴**:
- TokenRefreshCoordinator: 첫 호출의 결과를 모두가 공유
- `.cancellable`: 새 호출이 이전 호출을 취소하고 덮어씀

**언제 어느 걸 쓰나**:
- 결과를 공유해야 함 → actor + Task 핸들 패턴
- 최신 호출만 살아남아야 함 → `.cancellable(cancelInFlight: true)`

### 2. `await MainActor.run { ... }` — UI 작업은 메인 스레드

```swift
return .run { _ in
    _ = try? await UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .badge, .sound])
    await MainActor.run {
        UIApplication.shared.registerForRemoteNotifications()   // ← UI/UIKit 호출!
    }
}
```

**왜 필요?**
- `.run` 클로저는 **임의의 actor에서 실행**될 수 있음 (보장 X)
- `UIApplication.shared.registerForRemoteNotifications()`는 **UIKit API → 메인 스레드 필수**
- `MainActor.run`은 "이 블록을 메인 actor에서 실행해라"는 강제

**`@MainActor`와의 관계**:
- `@MainActor` (어트리뷰트): 함수/타입에 붙여서 "이건 항상 메인 actor에서 실행" 선언
- `MainActor.run { ... }` (함수): 임시로 메인 actor에서 한 블록 실행

UIKit/SwiftUI 코드를 비동기 Effect 안에서 호출할 땐 항상 이걸 거치는 게 안전.

### 3. UserDefaults 직접 사용 (Reducer body 안에서)

```swift
case .notificationPermissionAllowed:
    if let family = state.family {
        UserDefaults.standard.set(true, forKey: "mongle.notifSetup.\(family.id.uuidString)")
    }
```

**의문점**: Reducer는 순수 함수여야 하는데, UserDefaults.set은 side effect 아닌가?

**답**: 엄밀하겐 맞음. 하지만 실용적으로:
- `UserDefaults.standard.set`은 **동기 + 빠름** (in-memory dictionary 갱신, 디스크 쓰기는 OS가 알아서 비동기)
- Effect로 빼면 코드가 길어지고 가독성 ↓
- **테스트 시 갈아끼울 수 있는지가 핵심** — `UserDefaults`는 글로벌이라 테스트 격리 어려움

**더 깨끗한 방향** (Mongle엔 아직 안 적용):
```swift
@Dependency(\.userDefaultsRepo) var userDefaultsRepo
// ...
userDefaultsRepo.setNotifSetup(familyId: family.id, value: true)
```
→ 7-B2의 팩토리 패턴처럼 UserDefaults를 protocol로 감싸서 DI

지금 코드는 "**실용적 단순함을 우선**"한 선택. 단, 이 패턴이 늘어나면 테스트가 힘들어짐.

---

## 코드 해부 — 6가지 부분

### 1. State — 큰 dashboard state

20여 개 필드. 모두 화면이 보여줄 데이터:
- **질문**: `todayQuestion`, `yesterdayQuestion`, `hasAnsweredYesterday`
- **가족**: `family`, `familyMembers`, `currentUser`, `allFamilies`
- **로딩/에러**: `isLoading`, `isRefreshing`, `errorMessage`, `appError`
- **하트/스트릭**: `hearts`, `streakDays`
- **답변 상태**: `hasAnsweredToday`, `hasSkippedToday`, `familyAnswerCount`, `memberAnswerStatus`, `memberSkippedStatus`
- **UI 플래그**: `showGuestLoginPrompt`, `showNotificationPermission`, `hasUnreadNotifications`

**computed property 2개**:
```swift
public var hasFamily: Bool { family != nil }
public var isGuest: Bool { currentUser == nil }
```
→ 저장하지 않고 매번 계산. WriteQuestionFeature의 `canSubmit`과 같은 원리 (Single Source of Truth).

**State가 너무 큰가?** 일반적으론 책임이 너무 많을 신호. 다만 "홈 대시보드"라는 특성상 보여줄 게 많을 수밖에 없음. 만약 더 커지면 sub-feature로 분리하는 것 검토 (예: `HomeStreakFeature`, `HomeNotificationFeature`).

### 2. Action — 3종류로 명확히 분리

주석으로 카테고리가 나뉘어 있음:

```swift
// MARK: - View Actions       ← 사용자 입력
case onAppear, questionTapped, notificationTapped, heartsTapped, ...

// MARK: - Internal Actions   ← Reducer 내부 상태 변경용
case setLoading(Bool), setRefreshing(Bool), setError(String?), ...

// MARK: - Delegate Actions   ← 부모로 보낼 신호
case delegate(Delegate)
```

**3종 분리의 의미**:
- **View Actions**: View에서 발사되는 UI 입력. Action 이름이 동사+Tapped/Changed 패턴
- **Internal Actions**: Reducer 자체 내부 사정 갱신용. View가 직접 발사하면 안 되는 것 (외부 시스템이 set 해주는 용도)
- **Delegate Actions**: 부모가 캐치해서 처리할 외부 신호

→ "**같은 Action enum 안에 다양한 출처가 섞이는 걸 주석으로 정리**". TCA에선 점점 표준이 되는 패턴.

### 3. body — 반복되는 guest 체크 패턴

여러 액션이 같은 모양으로 시작:

```swift
case .questionTapped:
    if state.isGuest {
        state.showGuestLoginPrompt = true
        return .none
    }
    // 진짜 로직...

case .notificationTapped:
    if state.isGuest {
        state.showGuestLoginPrompt = true
        return .none
    }
    // 진짜 로직...

// ... 8개 액션에서 같은 패턴 반복
```

**DRY 위반의 한 케이스**. 깔끔하게 만들려면:
- (a) 헬퍼 함수: `func gateGuest(_ state: inout State) -> Effect<Action>?` — guest면 `.none`을 반환, 아니면 nil 반환 → 호출 측에서 `if let early = gateGuest(&state) { return early }`
- (b) 별도 Reducer로 분리해서 합성 — but TCA에선 흔치 않은 패턴
- (c) Action에 어트리뷰트 같은 메타데이터 — Swift엔 어울리지 않음

→ **현재 코드는 명시적이지만 길다**. 액션 수가 더 늘어나면 (a) 헬퍼 패턴이 합리적.

### 4. Internal Action 패턴 — 외부가 state를 갱신하는 통로

```swift
case .setLoading(let isLoading):
    state.isLoading = isLoading
    if !isLoading {
        state.isRefreshing = false   // 부수 효과: 로딩 끝나면 refreshing도 끄기
    }
    return .none

case .setRefreshing(let isRefreshing):
    state.isRefreshing = isRefreshing
    return .none
```

**왜 setter Action이 따로 있나?**
- 부모(MainTabFeature)가 데이터 fetching 결과를 HomeFeature에 알려줘야 함
- 부모가 자식 state를 직접 만지지 않고 **Action을 보내서 변경 요청**
- 즉 HomeFeature.Action을 발사 → HomeFeature.body가 처리 → state 변경
- 단방향 흐름 유지

**부수 효과 한 줄** (`if !isLoading { state.isRefreshing = false }`):
- 로딩 끝났는데 refreshing이 남아있을 수 있음 → 항상 같이 끄도록
- "**연관된 두 플래그를 한 곳에서 관리**"하는 패턴

### 5. `.cancellable` 사용처 — 알림 권한 요청

알림 권한 요청 흐름 (`notificationPermissionAllowed`):
1. UserDefaults에 "이 그룹에 대해 알림 설정 완료" 마크
2. `showNotificationPermission = false` (UI 닫기)
3. **`.run`으로 비동기 요청** — `requestAuthorization` + `registerForRemoteNotifications`
4. **`.cancellable(id: .requestNotifAuth, cancelInFlight: true)`** — 더블탭 race 방지

cancelInFlight=true가 핵심: 사용자가 빠르게 두 번 탭해도 첫 번째 요청은 자동 취소되고 두 번째 요청만 살아남음 → device token callback 중복 방지.

### 6. delegate 케이스 — 항상 `.none` (Question/Write와 동일 패턴)

```swift
case .delegate:
    return .none
```

자식의 delegate는 부모가 캐치할 신호 → 자식 입장에선 추가 처리 X. 모든 자식 Reducer에 공통.

---

## 핵심 패턴 — 큰 화면을 다루는 thin Reducer

### 특징 정리

1. **State는 크다** — 화면이 보여줘야 할 정보가 많음
2. **하지만 Reducer 로직은 단순** — 대부분 UI 입력 → delegate 신호로 변환
3. **데이터 fetching은 부모에게 위임** — `@Dependency` 없음
4. **Internal Action으로 외부 갱신 받음** — 부모가 setLoading/setError 등으로 알림

### 이게 왜 합리적인가

- 홈은 **여러 데이터 소스의 종합**: 질문 + 가족 + 사용자 + 알림 + 하트 + 스트릭...
- 각 데이터를 Home이 직접 fetch하면 의존성이 폭발
- 부모(MainTabFeature)가 **여러 Repository를 조율해서 통합된 데이터를 Home state에 주입**
- Home은 그 통합된 데이터를 받아 **표시 + 사용자 입력 라우팅**만 담당

→ "**Home = 데이터의 종착지(presentation)** / 부모 = 데이터의 조율자(orchestration)**".

### 의도된 트레이드오프

장점:
- Home Reducer가 단순
- 여러 Repository 의존성 분산
- 테스트 시 Home은 State만 주면 됨

단점:
- 부모(MainTabFeature)에 책임이 몰림 → 그 파일이 거대해짐 (실제로 700줄 넘음)
- 데이터 흐름 추적이 어려울 수 있음

---

## 자문할 6가지 (직접 답변 메모할 자리)

### Q1. `CancelID` enum과 `.cancellable(id:, cancelInFlight:)` 패턴
이게 막는 문제는 정확히 뭐고, 7-A2(TokenRefreshCoordinator)의 actor 패턴과 어떻게 다른가?

**본인 답**:

CancelID enum은 Hashable을 채택하고 있음  cancellable: id에 CancelID.requestNotifAuth 를 넣어 유일한 id값을 가지고 .cancellable을 가지고 이미 실행중이면 새로운것으로 대체한다. TokenRefreshCoordinator 은 actor로 중복해서 호출하는 것을 막는것으로 기억함

**수정/추가**:

- "이미 실행중이면 새로운 것으로 대체" — 이건 **`cancelInFlight: true` 옵션의 효과**. 기본값은 false라서, 옵션 없이 그냥 `.cancellable(id:)`만 쓰면 두 번째 호출이 **무시되는 게 아니라 둘 다 실행**됨. 옵션의 역할을 명시해야 정확.
- TokenRefreshCoordinator와의 차이를 더 정밀하게:
    - **TokenRefreshCoordinator (singleflight 패턴)**: 동시에 N명이 호출해도 **첫 호출의 결과를 모두가 공유**. 누구도 취소 안 됨, N-1명은 첫 결과를 기다림. → "결과 공유가 목적"
    - **`.cancellable(cancelInFlight: true)` (latest-wins 패턴)**: 새 호출이 오면 **이전 호출을 취소하고 자기가 살아남음**. → "최신 입력만 처리"
- 선택 기준: 결과를 공유해야 하면 actor + Task 핸들, 마지막 입력만 살아남으면 `.cancellable`. 알림 권한은 후자가 맞음(빠른 더블탭에서 두 번째 의도만 처리하면 됨).


---

### Q2. `await MainActor.run { ... }` 안에 `UIApplication.shared.registerForRemoteNotifications()`을 감싼 이유?
그냥 `.run` 클로저 안에서 직접 호출하면 어떻게 되나?

힌트: Effect 클로저는 어떤 actor에서 실행되나?

**본인 답**:

메인스레드에서 돌게하기위함, 보통 UI업데이트를 메인스레드에서 하는데 메인스레드에서 registerForRemoteNotifications가 돌아야만 하는지는 모르겠음

**수정/추가**:

- 방향은 맞음. 다만 **"왜 메인이 보장 안 되는가"**의 메커니즘을 보강:
    - `.run { _ in ... }` 클로저는 **Sendable 컨텍스트**라 어느 actor에서 실행될지 보장 X. 시스템이 백그라운드 스레드에서 돌릴 수도 있음.
    - 그래서 명시적으로 `await MainActor.run { ... }`로 "이 블록만큼은 메인 actor에서 실행해라" 강제.
- "registerForRemoteNotifications가 메인이어야 하는지 모르겠음" — Apple 문서엔 명시 안 되어 있지만:
    - **iOS 17+부터 `UIApplication`이 `@MainActor` 격리됨**. 즉 Swift 6 strict concurrency를 켜면 메인이 아닌 곳에서 호출 시 **컴파일 에러**가 남.
    - 명시되어 있지 않더라도 UIKit 인스턴스 메서드는 "메인에서 호출" 규칙 따르는 게 디폴트 안전선.
- 정리: `@MainActor`(어트리뷰트)는 "이 함수/타입은 항상 메인", `MainActor.run { }`(함수)은 "이 블록만 임시로 메인". 비동기 Effect 안에서 UIKit 한 줄 호출할 땐 후자가 맞음.


---

### Q3. `UserDefaults.standard.set(...)`이 Reducer body 안에서 호출됨 (라인 301).
"Reducer는 순수 함수"라는 원칙과 충돌하지 않나? 이게 OK인 이유는?

힌트: 동기 vs 비동기, 테스트 격리

**본인 답**:
UserDefaults의 경우 Effect로 빼서 처리할 만큼 속도측면에서 차이가 나지 않기때문에 괜찮음

**수정/추가**:

- 속도 얘기는 맞음 — `UserDefaults.standard.set`은 in-memory dictionary 갱신이라 동기·즉시. 디스크 쓰기는 OS가 알아서 비동기 처리.
- 하지만 **진짜 트레이드오프는 속도가 아니라 "테스트 격리"**:
    - `UserDefaults.standard`는 **글로벌 싱글톤** → 테스트 A가 set한 값이 테스트 B에 새어 들어감.
    - 즉 지금 코드는 "프로덕션은 OK, 테스트에선 부작용 위험" 상태.
    - 더 깨끗한 방향: `@Dependency`로 protocol 감싸기 (예: `userDefaultsRepo.setNotifSetup(familyId:, value:)`) → 테스트 시 mock 주입 가능.
- 결론을 다시 쓰면: "**속도 차이가 없어서 OK**가 아니라, **속도가 동기적이고 빠르긴 한데, 테스트가 늘어나면 DI로 빼는 게 권장**". 지금은 실용적 단순함을 우선한 선택.



---

### Q4. `if state.isGuest { state.showGuestLoginPrompt = true; return .none }` 패턴이 8개 액션에 반복됨.
이걸 깔끔하게 만들려면 어떤 리팩토링이 가능한가?

힌트: 헬퍼 함수 / early-return / DRY 원칙

**본인 답**:

위에서 말했지만 하나로 묶어서 switch로 처리하는 함수를 만들면 좋을 거 같음

**수정/추가**:

- 의도는 맞지만 "switch로 묶기"는 Swift 문법상 깔끔하게 안 됨. `switch action` 안에서 8개 case에 같은 처리를 붙이려면 case 패턴을 다 나열해야 하고, 그러면 그 케이스의 원래 로직을 또 분기해야 함 → 오히려 복잡해짐.
- 정답에 가까운 표현: **헬퍼 함수 + guard early-return**
    ```swift
    private func requireAuth(_ state: inout State) -> Bool {
        if state.isGuest {
            state.showGuestLoginPrompt = true
            return false
        }
        return true
    }

    case .questionTapped:
        guard requireAuth(&state) else { return .none }
        // 본 로직
    ```
- 더 적극적으로는 **guest 가드 전용 Reducer 분리 후 합성**:
    ```swift
    var body: some Reducer<State, Action> {
        Reduce { state, action in /* guest gate */ }
        Reduce { state, action in /* 본 로직 */ }
    }
    ```
    근데 가드 전용 Reducer는 어떤 액션을 가로챌지 enum case를 매번 나열해야 해서 액션이 늘어날수록 유지비 큼. **현재 규모면 헬퍼 함수가 합리적.**
- 즉 "switch" → "**헬퍼 함수**"로 용어 수정.



---

### Q5. HomeFeature에 `@Dependency`가 없다 (Repository 호출 X).
그럼 `state.todayQuestion`은 어디서 채워지나? 부모는 어떻게 알려주나?

힌트: Internal Actions (`setLoading`, `setError` 등)이 단서

**본인 답**:


MainFeature에서 데이터가 처리되는거 같은데 위에서 말했듯 honeFeature에서 처리되는게 맞지 않나 싶음

**수정/추가**:

- "MainFeature에서 처리되는 거 같다" — 맞음. 정확히는 **`MainTabFeature`(부모)**.
- 메커니즘을 분명히:
    1. `HomeFeature`가 `.delegate(.requestRefresh)` 발사
    2. 부모 `MainTabFeature`가 그 delegate를 캐치
    3. 부모가 가진 `@Dependency`들(Repository)을 호출해 데이터 fetch
    4. 부모가 결과를 자식의 **Internal Action**(`.setLoading`, `.setError`, 그리고 데이터를 채우는 액션들)으로 보냄 → HomeFeature.State 갱신
- 즉 `setLoading`/`setRefreshing`/`setError` 같은 Internal Action이 **"외부(부모)가 자식 state를 갱신하는 통로"** 역할. 단방향 흐름은 그대로 유지(부모가 자식 state를 직접 만지지 않음).
- "HomeFeature에서 처리되는 게 맞지 않나" — 이건 **설계 철학 선택**이지 정답이 아님:
    - **자기 데이터는 자기가 fetch** (일반적·교과서적): 의존성이 각 Feature에 분산, 부모는 가벼움. 다만 여러 자식이 비슷한 데이터를 따로 가져오면 중복 발생.
    - **부모가 조율** (Mongle 선택): Home은 단순해지지만, 부모(MainTabFeature)가 700줄+로 거대해짐. 데이터 흐름 추적이 어려움.
- 홈처럼 "**여러 데이터 소스의 종합 대시보드**"라면 부모 조율이 합리적인 케이스가 있음. 의존성 폭발을 피할 수 있어서.

---

### Q6. State에 필드가 20여개 있다.
이 정도면 너무 큰가? 분리하는 게 좋은가, 그대로 두는 게 좋은가?

힌트: 책임 단위 — 한 화면의 dashboard는 원래 데이터가 많음 vs 너무 크면 sub-feature로 분리

**본인 답**:

위에서 답한것과 같음 분리하는게 좋을거같음

**수정/추가**:

- "분리" 결론으로 바로 가기 전에 **두 단계**가 있음:
    1. **ADT(enum) 모델링으로 압축** — 분리보다 먼저 할 일. `hasAnsweredToday`+`hasSkippedToday`를 `TodayStatus` enum 하나로, `todayQuestion`+`yesterdayQuestion`을 `ActiveQuestion` enum으로 묶으면 20여 개 → 14~15개로 줄고, invalid state도 제거. **여기까지만 해도 체감 차이 큼.**
    2. **여전히 크면 sub-feature 분리** — 책임이 명확히 다른 덩어리가 보일 때만. 예: `HomeStreakFeature`(streak/hearts 게이미피케이션), `HomeNotificationPermissionFeature`(권한 안내).
- 분리의 함정: 분리하면 부모(MainTabFeature)에서 Scope/ifLet으로 합성하는 비용이 생기고, **자식 간 데이터 공유**(예: family 정보를 Streak도 Notification도 봐야 함)가 필요해지면 오히려 복잡해짐. 강하게 결합된 데이터는 안 쪼개는 게 나음.
- 결론을 다시 쓰면: "**바로 분리하기 전에 enum 모델링으로 압축이 먼저, 그래도 크면 sub-feature**" 순서.



---

## 학습 체크리스트

다음 파일(MainTab+Reducer)로 넘어가기 전 머리에 박혔는지 확인:

- [ ] `CancelID` enum + `.cancellable(id:, cancelInFlight:)` 패턴의 의미
- [ ] `.cancellable` vs actor + Task 핸들 (어느 걸 언제 쓰나)
- [ ] `await MainActor.run { ... }`의 역할 (UI 작업은 메인 스레드)
- [ ] Reducer body 안의 side effect (UserDefaults)가 허용되는 경우/안 되는 경우
- [ ] Action을 3종(View / Internal / Delegate)으로 분리하는 의도
- [ ] Internal Action 패턴 — 외부가 자식 state를 갱신하는 통로
- [ ] 큰 State + thin Reducer 패턴이 합리적인 상황
- [ ] 자식이 데이터 fetching을 부모에 위임하는 trade-off

---

## 다음 단계

이 파일 다 읽고 6개 자문에 답을 메모하면, 다음은:
- **`MainTab+Reducer.swift`** (700줄+) — **Scope, ifLet 같은 child composition 도구가 실제로 등장**.
  HomeFeature가 데이터 fetching을 위임한 부모. 여러 자식 reducer를 합성하고 delegate 신호를 처리하는 진짜 orchestrator.

이 파일은 너무 커서 한 번에 다 보긴 어려움. **composition 부분만 발췌**해서 읽는 게 효율적.

---

## 학습 체크리스트 8문항 — 정리된 답

### 1. `CancelID` enum + `.cancellable(id:, cancelInFlight:)` 패턴의 의미

- **CancelID**: Hashable enum. Effect에 부여할 **유일 식별자**를 타입으로 박는 용도. 문자열로 적어도 동작하지만 오타·중복 가능성을 컴파일러가 못 잡으니 enum case로 둠.
- **`.cancellable(id:)`**: 이 Effect를 그 ID로 추적 가능하게 등록. 외부에서 `.cancel(id:)`로 끄거나, 같은 ID가 다시 들어왔을 때 충돌 처리 가능.
- **`cancelInFlight: true`**: 핵심 옵션. 같은 ID의 Effect가 **이미 실행 중이면 그걸 취소하고 새 것으로 교체**. 이 옵션이 없으면 두 번째 호출은 그냥 같이 실행됨 → race condition 그대로.
- **막는 문제**: 알림 허용 버튼 빠른 더블탭 → `requestAuthorization` + `registerForRemoteNotifications`가 두 번 fire → device token callback 중복. `cancelInFlight: true`로 마지막 한 번만 살아남게 함.

### 2. `.cancellable` vs actor + Task 핸들 — 어느 걸 언제 쓰나

두 패턴이 푸는 문제가 다름.

| 패턴 | 의도 | 결과 처리 |
|---|---|---|
| **actor + Task 핸들** (TokenRefreshCoordinator, 7-A2) | **singleflight** — 동시에 N명이 호출해도 첫 번째만 실행 | 첫 호출의 결과를 **모두가 공유** (N-1명은 기다림) |
| **`.cancellable(cancelInFlight: true)`** | **latest-wins** — 새 호출이 오면 이전 호출 취소 | 마지막 호출만 살아남음, 이전 결과는 버려짐 |

**선택 기준**:
- "한 번 fetch한 결과를 여러 호출자가 공유해야 함" → **actor + Task 핸들**. 예: 토큰 갱신, 캐시 가능한 데이터 fetch.
- "사용자의 최신 입력만 처리하면 됨, 이전 건 버려도 OK" → **`.cancellable`**. 예: 검색어 입력 debounce, 더블탭 권한 요청.

알림 권한은 빠른 두 번째 탭의 의도만 처리하면 충분 → 후자가 맞음.

### 3. `await MainActor.run { ... }`의 역할

- **`.run { _ in ... }` 클로저는 임의 actor에서 실행** — Sendable 컨텍스트라 시스템이 백그라운드 스레드에서 돌릴 수도 있음. 메인 보장 X.
- **UIKit 호출(`UIApplication.shared.registerForRemoteNotifications()`)은 메인 스레드**가 디폴트 안전선. iOS 17+부터 `UIApplication`이 `@MainActor` 격리되어 Swift 6 strict concurrency에선 비-메인 호출 시 컴파일 에러.
- **`MainActor.run { ... }`**: 이 블록만 임시로 메인 actor에서 실행 강제.
- `@MainActor` 어트리뷰트와의 차이:
    - `@MainActor` = 함수/타입 단위. "이건 항상 메인."
    - `MainActor.run { }` = 블록 단위. "이 줄들만 메인에서."
- 비동기 Effect 내부에서 UIKit 한 줄 호출할 땐 후자가 정답.

### 4. Reducer body 안의 side effect (UserDefaults)가 허용되는 경우/안 되는 경우

원칙적으로 Reducer는 순수 함수여야 하지만, 실용적으로 OK인 조건과 안 OK인 조건이 있음.

**OK인 경우 (지금 코드)**:
- **동기 + 빠름**: `UserDefaults.standard.set`은 in-memory dictionary 갱신. 디스크 쓰기는 OS가 비동기로 알아서.
- Effect로 빼면 코드가 길어지고 가독성만 나빠짐.
- 테스트 부담이 크지 않을 때.

**안 OK / 빼야 할 경우**:
- **테스트 격리가 깨질 때**: `UserDefaults.standard`는 글로벌 싱글톤 → 테스트 A의 set이 테스트 B로 새어 들어감. 테스트가 늘어나면 반드시 문제 됨.
- **느리거나 실패할 수 있을 때**: 디스크 I/O, 네트워크, DB 등. 이건 무조건 Effect.
- **결과를 받아서 분기해야 할 때**: side effect의 반환값/실패에 따라 다음 액션이 달라지면 Effect로 빼고 `Action`으로 결과를 다시 흘려보내야 함.

**더 깨끗한 방향**: `@Dependency(\.userDefaultsRepo)`로 protocol 감싸서 DI. 테스트 시 mock 주입 가능. 지금 코드는 "실용적 단순함 우선"으로 그 단계는 미뤘음.

### 5. Action을 3종(View / Internal / Delegate)으로 분리하는 의도

**같은 Action enum 안에 출처가 다른 액션이 섞이는 걸 막기 위함.** 각자의 책임이 다름:

| 종류 | 누가 발사? | 역할 |
|---|---|---|
| **View** | View(SwiftUI 등) | 사용자 입력 (`onAppear`, `questionTapped`, `heartsTapped` 등) |
| **Internal** | 부모 Reducer / 자기 자신의 Effect | 외부 시스템·Effect 결과로 자기 state 갱신 (`setLoading`, `setError`) |
| **Delegate** | 자식 → 부모 캐치용 | 부모에게 "이런 일이 있었다" 알림 (`requestRefresh`, `showQuestionSheet`) |

**왜 분리?**
- **View가 실수로 `.setLoading(false)`를 발사하는 사고 방지** — Internal은 외부에서 만들면 안 되는 액션인데, 한 enum에 섞여 있으면 누가 발사해도 막을 수 없음.
- **읽는 사람이 의도를 한눈에 파악**. `store.send(.view(.onAppear))`만 봐도 "이건 UI 입력"임이 타입에 박힘.
- TCA 메인테이너(Point-Free) 권장 패턴. 지금 Mongle은 주석 mark로만 분리되어 있지만, **중첩 enum으로 옮기는 게 다음 단계**.

### 6. Internal Action 패턴 — 외부가 자식 state를 갱신하는 통로

- **상황**: HomeFeature는 `@Dependency` 없음 → 데이터 fetching을 자기가 안 함 → 그럼 `state.todayQuestion`은 누가 채우나?
- **흐름**:
    1. HomeFeature가 `.delegate(.requestRefresh)` 발사
    2. 부모 MainTabFeature가 그 delegate 캐치
    3. 부모가 자기 `@Dependency`(Repository)들 호출해 fetch
    4. 부모가 결과를 자식의 **Internal Action**(`.setLoading`, `.setError`, 데이터 채우는 액션들)으로 보냄
    5. HomeFeature.body가 그 Internal Action을 처리 → state 변경
- **단방향 흐름 유지가 핵심**: 부모가 자식 state를 **직접 만지지 않음**. 항상 Action을 보내서 자식 Reducer를 거치게 함. 자식 입장에선 state 변경 경로가 자기 body 한 곳뿐 → 추적 가능.
- **부수 효과 묶기**: `setLoading(false)`일 때 `state.isRefreshing = false`도 같이 — "연관된 두 플래그를 한 곳에서" 패턴. 외부에서 두 번 set하는 실수를 차단.

### 7. 큰 State + thin Reducer 패턴이 합리적인 상황

**언제 합리적**:
- 화면이 **여러 데이터 소스의 종합 대시보드**일 때 — 홈처럼 질문 + 가족 + 사용자 + 알림 + 하트 + 스트릭… 보여줄 게 원래 많음.
- Reducer 로직 자체가 **단순한 라우팅(입력 → delegate 변환)** 위주일 때.
- 데이터 fetching이 부모/외부에 위임되어 있어, Reducer body가 길어질 이유가 없을 때.

**HomeFeature가 이 패턴인 증거**:
- State 20여 개 필드, Action 30여 개지만 body 대부분이 `if guest → prompt` + `delegate 발송`.
- `@Dependency` 0개. Repository 직접 호출 없음.
- child composition(Scope/ifLet) 없음 — 그건 부모(MainTabFeature) 책임.

**개선 순서** (Q6에서 정리한 대로):
1. **먼저 ADT(enum) 모델링으로 State 압축**: `hasAnsweredToday`+`hasSkippedToday` → `TodayStatus` enum, `todayQuestion`+`yesterdayQuestion` → `ActiveQuestion` enum. 필드 수도 줄고 invalid state도 제거.
2. **그래도 크면 sub-feature 분리**: `HomeStreakFeature`, `HomeNotificationPermissionFeature` 같이. 단, 자식 간 공유 데이터(family 등)가 많으면 분리가 오히려 복잡도 증가.

### 8. 자식이 데이터 fetching을 부모에 위임하는 trade-off

**장점**:
- **자식 Reducer가 단순해짐** — Home은 표시 + 입력 라우팅만.
- **여러 Repository 의존성이 자식들에 분산되지 않음** — 부모 한 곳에 모임.
- **여러 자식이 같은 데이터를 따로 fetch하는 중복 제거** — 부모가 한 번 fetch해서 여러 자식에 주입.
- **테스트 시 자식은 State만 만들어주면 됨** — Dependency mock 불필요.

**단점**:
- **부모(MainTabFeature)에 책임 집중** — 실제로 700줄+로 거대. 자식 N개의 데이터 조율 + delegate 처리가 다 거기로 모임.
- **데이터 흐름 추적 어려움** — `state.todayQuestion`이 어디서 채워졌는지 알려면 부모까지 거슬러 가야 함. 자기 데이터를 자기가 fetch하는 일반 패턴이면 자식 파일만 보면 끝.
- **재사용성 떨어짐** — Home을 다른 화면 컨텍스트에 옮기면 부모의 fetching 코드도 같이 옮기거나 다시 작성해야 함. Home 단독으로 동작 X.
- **데이터 동기화 타이밍 책임이 부모로 — 자식은 "데이터 와라" 신호만 보낼 수 있고, 직접 갱신 못함.**

**선택 기준**:
- **종합 대시보드 / 여러 자식이 데이터 공유** → 부모 조율 (Mongle 선택).
- **자기 완결적인 화면 / 재사용 필요** → 자기 데이터는 자기가 fetch (교과서적).
