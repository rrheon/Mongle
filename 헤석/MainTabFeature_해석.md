# MainTabFeature — Scope/forEach/ifLet이 다 등장하는 진짜 orchestrator

**파일 위치**: `MongleFeatures/Sources/MongleFeatures/Presentation/MainTab/`
**총 줄수**: 950줄 (6개 파일로 분리)
**위치 의미**: TCA의 **child composition 3대 도구**(Scope, .forEach, .ifLet)가 모두 등장. 거대한 reducer를 extension으로 쪼개는 패턴까지 같이 학습.

---

## 파일 구조 한눈에

```
MainTabFeature.swift   (27줄)   ← 진입점. @Dependency 6개 + body = reducer
└── Ext/
    ├── +State.swift       (73줄)   ← 자식 State들 + tab/path/modal/toast
    ├── +Action.swift      (72줄)   ← @CasePathable, 자식 Action 래핑
    ├── +Modal.swift       (58줄)   ← @Reducer Modal (5개 popup/sheet 합성)
    ├── +Navigation.swift  (22줄)   ← @Reducer enum Path (4개 destination)
    └── +Reducer.swift    (698줄)   ← body 본체 + 동기화 헬퍼
```

**왜 쪼갰나?** 한 파일에 다 넣으면 900줄+. Xcode의 jump-to-definition은 파일 단위로 잘려서 길수록 탐색이 힘듦. `extension MainTabFeature { ... }` 패턴으로 같은 타입을 여러 파일에 분산. **이건 Swift 언어 기능**(extension)이지 TCA 특수 기능 아님.

---

## HomeFeature와 비교

| | HomeFeature | **MainTabFeature** |
|---|---|---|
| 파일 구성 | 단일 327줄 | **6개 파일 950줄** |
| State 필드 | 20여 개 | **자식 5개 + path + modal + 6개 toast** |
| `@Dependency` | 0개 | **6개** (Repository 4 + errorHandler + adClient) |
| child composition | 없음 | **Scope ×5 + .forEach + .ifLet** |
| Effect 종류 | `.run`, `.send`, `.cancellable` | `.run`, `.merge`, `Task.sleep`(애니메이션 wait) |
| 새 개념 | CancelID, MainActor.run | **StackState, @Presents, PresentationAction, @Reducer enum** |

→ HomeFeature가 "**큰 State + thin Reducer**"였다면, MainTab은 "**작은 자체 State + 거대한 child composition**". 자기 데이터는 거의 없고 자식들 사이를 조율하는 게 본업.

---

## 새로 등장하는 5가지 개념

### 1. `Scope(state:action:) { ChildFeature() }` — 항상 살아있는 자식

```swift
Scope(state: \.home, action: \.home) { HomeFeature() }
Scope(state: \.history, action: \.history) { HistoryFeature() }
// ... 5개 자식
```

**의미**: 부모 State 안에 **non-optional**로 들어있는 자식을 reducer에도 끼움.
- State 측: `public var home = HomeFeature.State()` — 항상 존재
- KeyPath `\.home` + Action CasePath `\.home`로 자식 영역만 잘라서 자식 Reducer에 전달

**`@CasePathable`이 필요한 이유**: Action enum에서 `\.home` 같은 case keypath를 쓰려면 enum이 case별 추출/매칭 가능해야 함. `@CasePathable` 매크로가 `case path` 자동 생성.

### 2. `StackState<Path.State>` + `@Reducer enum Path` + `.forEach(\.path, action: \.path)` — push navigation

```swift
// State
public var path = StackState<Path.State>()

// Navigation
@Reducer(state: .equatable, action: .equatable)
public enum Path {
    case questionDetail(QuestionDetailFeature)
    case notification(NotificationFeature)
    case peerNudge(PeerNudgeFeature)
    case writeQuestion(WriteQuestionFeature)
}

// Reducer 본체 끝에:
.forEach(\.path, action: \.path)
```

**TCA 1.4+ navigation API**. 핵심 메커니즘:
- `StackState`는 ordered collection — `append`하면 push, `removeLast`하면 pop
- `@Reducer enum Path`는 **enum 자체가 Reducer가 됨**. 각 case가 destination feature. 매크로가 `enum State`/`enum Action`을 자동 합성
- `.forEach`는 stack 안 각 element에 해당 case의 Reducer를 매핑

**Action 패턴**: `.path(.element(id: _, action: .peerNudge(.delegate(.close))))`
- `.path` — path 액션
- `.element(id:, action:)` — stack 안 특정 element를 식별
- `.peerNudge(...)` — Path enum의 case
- `.delegate(.close)` — 그 안의 자식 액션

`state.path.append(.notification(...))` 하면 push, `state.path.removeLast()` 하면 pop.

View 측에선:
```swift
NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
    // root view
} destination: { store in
    switch store.case {
    case .notification(let s): NotificationView(store: s)
    // ...
    }
}
```

### 3. `@Presents` + `PresentationAction` + `.ifLet(\.$modal, action: \.modal)` — modal

```swift
// State
@Presents public var modal: Modal.State?

// Action
case modal(PresentationAction<Modal.Action>)

// Reducer 본체 끝에:
.ifLet(\.$modal, action: \.modal) { Modal() }
```

**핵심 메커니즘**:
- `@Presents`는 property wrapper. **dismiss 자동 처리**용. 자식이 `@Dependency(\.dismiss)`로 자기 dismiss를 부를 수 있게 해줌
- `PresentationAction<Modal.Action>`은 **단순 Modal.Action이 아니라** `.presented(Modal.Action)` + `.dismiss` 두 케이스로 래핑. 부모가 강제로 nil 하지 않아도 자식이 자기 dismiss 가능
- `.ifLet`은 **modal이 nil이 아닐 때만** 자식 Reducer 실행

**Modal이 또 하나의 `@Reducer`인 점**: `MainTab+Modal.swift`를 보면:
```swift
@Reducer
public struct Modal {
    public enum State: Equatable { case peerAnswer(...), questionSheet(...), ... }
    public enum Action: Equatable { ... }
    public var body: some Reducer<State, Action> {
        Scope(state: \.peerAnswer, action: \.peerAnswer) { PeerAnswerFeature() }
        // ... 5개 자식 Scope
    }
}
```
→ Modal 자체가 **destination enum + 합성 Reducer**. ifLet으로 옵셔널 처리 → enum case로 다중 modal 분기.

**Action 패턴**: `.modal(.presented(.questionSheet(.delegate(.close))))`
- `.modal` — modal 액션
- `.presented(...)` — PresentationAction 래퍼
- `.questionSheet(...)` — Modal.State enum case
- `.delegate(.close)` — 그 안 자식 delegate

### 4. `CombineReducers { ... }` — 여러 Reducer 묶어서 순차 실행

```swift
CombineReducers {
    Scope(state: \.home, action: \.home) { HomeFeature() }
    // ... 4개 더
    Reduce { state, action in /* delegate 처리 */ }
}
.forEach(\.path, action: \.path)
.ifLet(\.$modal, action: \.modal) { Modal() }
```

**왜 CombineReducers?** `body`는 단일 `some Reducer`를 반환해야 함. 여러 Scope + Reduce를 나란히 두려면 묶어줘야 함. **결과적으로 위에서 아래로 모든 reducer가 같은 action을 받아 처리**.

순서가 중요:
1. 자식 Scope들이 먼저 자기 영역 액션 처리 (자식 state 갱신)
2. 그 후 본체 Reduce가 delegate 캐치 (부모 state 갱신, 라우팅)

자식 액션이 먼저 자식에서 처리되고, **부모는 delegate만 신경 쓰면 되는 구조**.

### 5. `state.path[id: id]` 와 `case let .notification(notifState)` — stack 안 element 접근

```swift
case .path(.element(id: let id, action: .notification(.delegate(.close)))):
    if case let .notification(notifState) = state.path[id: id] {
        let currentFamilyId = state.home.family?.id
        state.home.hasUnreadNotifications = notifState.hasUnread(forFamily: currentFamilyId)
    }
    state.path.removeLast()
    return .none
```

**무엇을 하는가**: 알림 화면이 닫힐 때, **그 알림 화면의 최종 state를 읽어서** 부모 state에 반영. "pop 직전 자식 state 스냅샷 캡처" 패턴.

- `state.path[id: id]` — stack 안 특정 element의 Path.State 가져옴 (옵셔널)
- `if case let .notification(notifState) = ...` — Path.State enum에서 .notification 케이스만 추출
- 이걸로 자식이 들고 있던 unread 계산 메서드 호출 → 부모에 결과 반영

---

## 코드 해부 — 핵심 패턴 5가지

### 1. 동기화 헬퍼 (이중 저장된 state를 원자적으로 갱신)

라인 24-60에 3개 private 함수:
```swift
private func setCurrentUserAnswered(_ state: inout HomeFeature.State) {
    state.hasAnsweredToday = true
    state.hasSkippedToday = false      // skip 자동 해제
    if let userId = state.currentUser?.id {
        state.memberAnswerStatus[userId] = true
        state.memberSkippedStatus[userId] = nil
    }
}
```

**왜 필요한가**: HomeFeature.State에 "현재 사용자 답변 상태"가 **이중 저장**(설명 라인 26-29):
1. `hasAnsweredToday` / `hasSkippedToday` (본인 뱃지, 버튼 분기용)
2. `memberAnswerStatus[me]` / `memberSkippedStatus[me]` (다른 멤버 뷰 공통 렌더링용)

한 곳만 갱신하면 UI 불일치 → 4개 필드를 한 번에 갱신하는 헬퍼로 추상화.

**여기에 우리가 이전에 한 enum 리팩토링 제안과 충돌**: hasAnsweredToday/hasSkippedToday를 `TodayStatus` enum으로 묶으면 invariant는 enum 자체에 박힘. 하지만 **memberAnswerStatus도 enum 맵으로 같이 바꿔야 함** → 리팩토링 범위가 생각보다 큼.

### 2. 350ms `Task.sleep` 패턴 — 애니메이션 race 회피

3곳에서 같은 패턴:
- 라인 288-292: questionSheet dismiss → push navigation
- 라인 404-408: peerAnswer editAnswer → push navigation
- 라인 532-535: questionDetail pop → popup/toast 표시

가장 명확한 주석은 라인 521-525:
> "popup/toast 는 NavigationStack pop 애니메이션 (~350ms) 완료 후 표시. 같은 reduce 에서 즉시 켜면 popup overlay 가 pop 진행 중 mount 되어 이전 화면 hit-test 차단 + toast 가 popup 에 가려져 사용자가 못 봄."

**왜 이렇게?** SwiftUI의 sheet/navigation dismiss는 **비동기 애니메이션**인데 reducer는 즉시 실행. 그래서 같은 reduce 안에서 "dismiss + push"를 하면 push가 drop되거나 navigation bar가 깨짐.

**350ms는 SwiftUI 시트 dismiss 디폴트 애니메이션 시간**(대략). 매직 넘버.

### 3. 자식 delegate 캐치 패턴 — `.home(.delegate(...))`

거의 600줄의 본체 switch가 다 이런 모양:
```swift
case .home(.delegate(.showQuestionSheet(let question))):
    // modal 띄우기 또는 path push

case .home(.delegate(.requestRefresh)):
    return .send(.delegate(.requestRefresh))   // 더 위로 위임
```

자식 7개(Home, Profile, Modal의 5개 자식, Path의 4개 자식)에서 발생하는 delegate를 모두 여기서 캐치. → **부모가 자식들의 "라우팅 허브"** 역할.

### 4. `default: return .none` — 자식 본체 액션은 무시

라인 686-687:
```swift
default:
    return .none
```

자식의 **delegate가 아닌 일반 액션**(예: `.home(.setLoading(true))`)은 본체 Reduce에서 추가 처리 안 함. 이미 Scope에서 자식 reducer가 처리하고 끝남.

**원칙**: "**부모는 자식 delegate만 듣는다**". 자식 내부 사정엔 관여 X. 단방향 흐름 유지.

### 5. `.merge`로 여러 effect 묶기

라인 526-536, 575-585, 631-637 등:
```swift
return .merge(
    .send(.history(.forceReload)),
    .run { [userRepository] _ in
        guard let user = updatedUser else { return }
        _ = try? await userRepository.update(user)
    },
    .run { send in
        try await Task.sleep(nanoseconds: 350_000_000)
        await send(.showAnswerHeartAndToast)
    }
)
```

**의미**: 여러 effect를 **병렬로 실행**. `.send`(다른 자식에 액션 전파) + Repository 호출 + 지연 액션을 한 번에. 

`.run`이 두 개 이상이면 같은 reducer에서 발생한 효과들이 독립적으로 동시 진행 가능 — 순서 보장 없음.

---

## 6가지 자문 (직접 답변 메모할 자리)

### Q1. Scope / .forEach / .ifLet 셋의 역할 차이는?

**답**:

| 도구 | 자식 존재 모델 | State 표현 | 합성 시점 |
|---|---|---|---|
| **Scope** | 1:1 항상 | `var home = HomeFeature.State()` (non-optional) | reducer 시작부터 끝까지 |
| **.ifLet** | 0:1 옵셔널 | `@Presents var modal: Modal.State?` | nil이 아닐 때만 |
| **.forEach** | 0:N 동적 | `var path = StackState<Path.State>()` | stack 안 각 element마다 |

**핵심 차이**:
- **Scope**는 "**자식 Reducer를 부모 안에 인라인**". 자식이 항상 살아있고, 자식 액션이 오면 자식 reducer가 자동 실행.
- **.ifLet**은 "**modal/sheet/popover처럼 한 번에 0개 또는 1개**". `@Presents`와 짝. dismiss 신호 자동 처리.
- **.forEach**는 "**navigation stack처럼 0~N개의 destination**". 각 element가 고유 id를 가지고 독립적으로 reduce.

**메커니즘 측면**: 셋 다 **부모 State/Action에서 자식 영역을 잘라내 자식 Reducer로 라우팅**. 다만 자식의 **lifecycle**이 다름 (영구 / 옵셔널 / 동적).

**언제 무엇을 쓰나**:
- 탭의 각 화면 → Scope (탭 전환해도 살아있어야 함)
- modal/popup → .ifLet (열고 닫음)
- push navigation 스택 → .forEach (여러 화면 쌓임)

---

### Q2. `StackState` + `Path` enum + `.forEach(\.path, ...)`로 push navigation 구현하는 메커니즘?

**답**:

**3개 요소가 결합**된 API (TCA 1.4+):

1. **`StackState<Path.State>`**:
   - 내부적으로 ordered collection(배열 비슷). 각 element는 자동으로 unique id 부여.
   - `append`로 push, `removeLast` / `removeAll` / `removeAll(after:)`로 pop.
   - State가 `Equatable`이어야 Reducer가 동작.

2. **`@Reducer enum Path`**:
   - **enum 자체가 Reducer**. 매크로가 자동으로 `enum State`/`enum Action`을 합성.
   - 각 case가 한 destination feature: `case questionDetail(QuestionDetailFeature)`.
   - 합성된 State enum: `Path.State.questionDetail(QuestionDetailFeature.State)`.

3. **`.forEach(\.path, action: \.path)`**:
   - stack 안 각 element에 그 element의 case에 맞는 자식 Reducer 실행.
   - element가 push될 때 reducer가 자동 attach, pop될 때 detach.

**Action 흐름**:
```
사용자가 NotificationView에서 닫기 탭
  → 자식 NotificationFeature가 .delegate(.close) 발사
  → Path.Action.notification(.delegate(.close)) 로 래핑됨
  → MainTab.Action.path(.element(id: X, action: .notification(.delegate(.close)))) 로 한 번 더 래핑됨
  → MainTab의 body switch가 캐치 → state.path.removeLast()
```

**View 측 결합**:
```swift
NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
    HomeView(...)   // root
} destination: { store in
    switch store.case {
    case .questionDetail(let s): QuestionDetailView(store: s)
    case .notification(let s): NotificationView(store: s)
    // ...
    }
}
```

`$store.scope`가 StackState ↔ NavigationPath 양방향 바인딩 처리. SwiftUI가 path를 보고 navigation 결정.

**왜 이렇게 복잡한가**: SwiftUI의 `NavigationStack(path:)`이 type-erased path를 받는데, TCA는 **타입 안전 + 상태 보존 + reducer 합성**을 동시에 하려고 enum + StackState로 감쌈. 복잡한 대가로 **navigation도 reducer 합성의 일부**가 됨.

---

### Q3. `@Presents` + `PresentationAction` + `.ifLet`으로 modal 구현하는 메커니즘?

**답**:

**3개 요소가 결합**된 modal API:

1. **`@Presents` property wrapper**:
   - `@Presents var modal: Modal.State?` — 단순 옵셔널 + **dismiss 자동 처리**.
   - 자식이 `@Dependency(\.dismiss)`로 자기 dismiss 호출 가능 → 부모 state의 modal이 자동 nil.
   - **부모가 자식 dismiss 메커니즘을 일일이 작성 안 해도 됨**.

2. **`PresentationAction<Modal.Action>`**:
   - 단순 `Modal.Action`이 아니라 enum 래퍼:
     - `.presented(Modal.Action)` — 자식이 살아있는 동안의 액션
     - `.dismiss` — 자식이 dismiss될 때
   - 부모 Action에서: `case modal(PresentationAction<Modal.Action>)`.

3. **`.ifLet(\.$modal, action: \.modal) { Modal() }`**:
   - `\.$modal`은 `@Presents` projection — 그냥 `\.modal`이 아닌 `\.$modal`.
   - modal이 nil이 아닐 때만 Modal reducer 실행.
   - dismiss 시 자동으로 자식 Reducer 정리.

**전체 흐름**:
```
HomeFeature .delegate(.showQuestionSheet(question)) 발사
  → MainTab body가 캐치 → state.modal = .questionSheet(...)
  → SwiftUI가 .sheet(item:) 트리거 → 시트 표시

시트 안 자식이 .delegate(.close) 발사
  → MainTab body가 .modal(.presented(.questionSheet(.delegate(.close)))) 캐치
  → state.modal = nil
  → SwiftUI 시트 dismiss
```

**Modal이 자체 enum + Reducer인 점**: `Modal.State`가 enum이고(5개 case), Modal Reducer가 5개 Scope로 합성. → **ifLet은 옵셔널 1단계만 해결**, **enum 다중 case는 Modal 내부의 Scope들**이 처리. 두 도구가 같이 쓰임.

**View 측**:
```swift
.sheet(item: $store.scope(state: \.modal?.questionSheet, action: \.modal.presented.questionSheet)) { store in
    QuestionSheetView(store: store)
}
```

---

### Q4. `setCurrentUserAnswered` 같은 헬퍼가 부모 reducer body에 있는 게 적절한가?

**답**:

**현재 패턴의 문제**: HomeFeature.State의 invariant("hasAnsweredToday와 memberAnswerStatus[me]가 항상 일치")를 **부모(MainTab)가 알고 있어야 함**. 추상화 누수(leaky abstraction).

만약 미래에 HomeFeature.State에 답변 관련 필드가 추가되면 → MainTab의 헬퍼도 같이 갱신해야 함. **변경이 두 곳에 흩어짐**.

**더 깨끗한 방향 3가지**:

(a) **HomeFeature.Action에 답변 액션 추가**:
```swift
// HomeFeature
case currentUserAnswered
case currentUserSkipped
case dailyStateReset
```
MainTab은 `.send(.home(.currentUserAnswered))`만 호출 → invariant는 자식 안에 박힘.

(b) **HomeFeature.State를 enum으로 재모델링** (이전 노트 Q3와 연결):
```swift
enum TodayStatus { case notYet, answered, skipped }
```
저장 위치 1개로 줄면 동기화 자체가 필요 없음. 단 `memberAnswerStatus[me]`까지 같이 정리해야 함 — `memberStatus: [UUID: TodayStatus]` 같은 단일 source.

(c) **HomeFeature에 method 추가**:
```swift
extension HomeFeature.State {
    mutating func markCurrentUserAnswered() {
        // 모든 invariant 한 곳에서 관리
    }
}
```
부모는 `state.home.markCurrentUserAnswered()`. **헬퍼 위치만 옮긴 것**이지만 책임이 자식 타입에 박힘.

**현실적 선택**: (c)가 작은 변화로 가장 큰 효과. (a)는 액션 수 증가, (b)는 큰 리팩토링.

지금 코드는 **속도 우선**의 선택. State 동기화가 임시 상태고 곧 정리될 거라면 OK. 이런 헬퍼가 3개 이상 늘어나면 리팩토링 신호.

---

### Q5. 350ms `Task.sleep` 패턴을 어떻게 개선할 수 있나?

**답**:

**현재 문제**:
- 매직 넘버(350ms)가 SwiftUI 애니메이션 디폴트에 의존 → iOS 버전 바뀌면 깨질 수 있음
- 테스트 시 실제로 350ms 기다림 → 테스트 느림
- 의도가 코드에 안 보임 — "왜 350ms?"가 주석에만 있음

**개선안 4가지**:

(a) **View가 dismiss 콜백 발사** (가장 깔끔):
```swift
// View
.sheet(item: $store.scope(...)) { store in
    QuestionSheetView(store: store)
}
.onChange(of: store.modal) { _, new in
    if new == nil { store.send(.modalDidDismiss) }
}

// Reducer
case .modalDidDismiss:
    // 이때 push 해도 안전
```
**장점**: 매직 넘버 제거, 실제 dismiss 완료 후 정확한 시점에 실행.
**단점**: 의도가 View로 흩어짐, reducer만 봐선 흐름 추적 어려움.

(b) **`@Dependency(\.continuousClock)`로 sleep 추상화**:
```swift
@Dependency(\.continuousClock) var clock
// ...
try await clock.sleep(for: .milliseconds(350))
```
**장점**: 테스트 시 mock clock으로 0ms로 만들 수 있음 — 테스트 빨라짐.
**단점**: 매직 넘버는 그대로 남음.

(c) **상수 추출 + 의도 명시**:
```swift
private enum AnimationTiming {
    static let sheetDismiss = 350_000_000  // ns. SwiftUI sheet dismiss default
    static let navigationPop = 350_000_000
}
try await Task.sleep(nanoseconds: AnimationTiming.sheetDismiss)
```
**장점**: 가장 작은 변화, 의도가 코드에 드러남.
**단점**: 본질적으로 매직 넘버 그대로.

(d) **UIKit transition coordinator** — SwiftUI 환경에선 사실상 불가.

**가장 깔끔**: **(a)**가 정석. 단 reducer-view 왕복이 늘어남.
**가장 실용적**: **(b) + (c) 조합**. 매직 넘버는 상수로 빼고, clock dependency로 테스트 가능하게.

---

### Q6. MainTab도 데이터 fetch를 부모로 위임 — 진짜 fetch 주체는 어디?

**답**:

**답: `RootFeature`**.

라인 224-225에서:
```swift
case .home(.delegate(.requestRefresh)):
    return .send(.delegate(.requestRefresh))   // 더 위로 위임
```
즉 MainTab은 자기 `.delegate(.requestRefresh)`를 발사. 그걸 RootFeature가 받음 (`Root+Reducer.swift` 라인 455 `case .mainTab(.delegate(.requestRefresh))`).

**RootFeature가 진짜 fetch 주체** (Root+Reducer.swift 라인 70-160):
```swift
return .run { [authRepository, familyRepository, questionRepository,
              answerRepository, userRepository, notificationRepository] send in
    let currentUser = try? await authRepository.getCurrentUser(grantDailyHeart: true)
    let familyResult = try await familyRepository.getMyFamily()
    let todayDetails = try? await questionRepository.getTodayQuestionDetailed()
    let answers = try? await answerRepository.getByDailyQuestion(...)
    let streakDays = try? await userRepository.getMyStreak()
    let allFamilies = try? await familyRepository.getMyFamilies()
    let notifications = try? await notificationRepository.getNotifications(limit: 50)
    let unreadCountAllGroups = try? await notificationRepository.getUnreadCount()
    // 모두 한 번에 fetch 후 자식 state에 주입
}
```

**전체 데이터 계층 구조**:
```
RootFeature  ← 인증 + 글로벌 데이터 fetch (진짜 fetch 주체)
  └── MainTabFeature  ← 라우팅 허브, 일부 액션 트리거 Repository 호출
        ├── HomeFeature       ← 표시 전용 (fetch 없음)
        ├── HistoryFeature
        ├── SearchHistoryFeature
        ├── NotificationFeature
        └── ProfileEditFeature
```

**왜 이렇게?**:
- Home/History/Search 모두 같은 도메인 데이터(family, currentUser, todayQuestion)를 봐야 함
- 각자 fetch하면 **중복 호출 + 일관성 문제**
- Root에서 한 번 fetch → 자식들에 주입하면 모두 같은 데이터 봄

**트레이드오프**:
- 장점: 데이터 일관성, 의존성 분산, 자식 reducer 단순
- 단점: **delegate prop drilling** (자식 → 부모 → 조부모 위임 체인). Home → MainTab → Root 두 단계 위임은 그래도 견딜 만하지만, 더 깊어지면 Redux 진영의 같은 고질병.

**MainTab이 직접 호출하는 Repository는 따로 있음**:
- 라인 322: `questionRepository.skipTodayQuestion()` — 액션 트리거(스킵)
- 라인 352: `userRepository.grantAdHearts(amount:)` — 광고 시청 후 하트 지급
- 라인 185: `answerRepository.getByDailyQuestion(...)` — peer 답변 조회 (lazy)
- 라인 612: `notificationRepository.delete(id:)` — 알림 삭제

→ **초기/전체 refresh = Root, 사용자 액션 → 즉시 호출 = MainTab**의 분담.

---

## 학습 체크리스트

- [ ] **Scope / .forEach / .ifLet** 셋의 자식 lifecycle 차이
- [ ] **`@CasePathable`**이 case keypath(`\.home`)를 가능하게 한다는 점
- [ ] **`StackState` + `@Reducer enum Path` + `.forEach`** 조합으로 push navigation 구현
- [ ] **`@Presents` + `PresentationAction` + `.ifLet`** 조합으로 modal 구현
- [ ] **`CombineReducers`**로 여러 Reducer 묶기 (순서 중요: 자식 → 부모)
- [ ] **`default: return .none`** = "부모는 자식 delegate만 듣는다"
- [ ] **`.merge`**로 여러 effect 병렬 실행
- [ ] 350ms `Task.sleep` 패턴 — SwiftUI 애니메이션 race 회피 임시방편
- [ ] 동기화 헬퍼(`setCurrentUserAnswered`)가 부모에 있는 것의 트레이드오프
- [ ] **RootFeature가 진짜 fetch 주체**, MainTab은 액션 트리거 호출만

---

## 다음 단계

- **`Root+Reducer.swift`**: 진짜 fetch 주체. 초기 로딩 시 6개 Repository를 어떻게 조율하는지 / 인증 흐름과 어떻게 묶이는지.
- **`MainTabView.swift`**: View 측에서 `$store.scope`로 path/modal을 어떻게 바인딩하는지.
- **HomeFeature 리팩토링 시도**: 이전 노트의 enum 묶기 + 이번 노트의 동기화 헬퍼 흡수를 같이 해보기.
