# QuestionSheetFeature — TCA 입문 첫 Reducer

**파일 위치**: `MongleFeatures/Sources/MongleFeatures/Presentation/Home/QuestionSheetFeature.swift`
**줄수**: 52줄
**위치 의미**: Stage 2 (Features/TCA) 첫 읽기 대상. 가장 단순한 형태의 Reducer.

---

## 한 눈에 본 요약

> "오늘의 질문을 보여주는 시트에서 사용자 입력을 받아 **'어떤 의도가 발생했다'는 신호만 부모에게 전달**하는, 가장 단순한 형태의 TCA Reducer."

- **State 3개** (`questionText`, `isAnswered`, `isSkipped`)
- **Action 4개 + delegate sub-enum 4개**
- **의존성 0개** (`@Dependency` 없음)
- **State를 한 번도 안 건드림** — 그저 UI 입력 → delegate 신호로 변환만

→ TCA 입문 첫 파일로 최적. State/Action/Reducer/Delegate 패턴이 한 화면에 다 보임.

---

## 코드 해부 — 5가지 부분

### 1. 매크로 두 개

```swift
@Reducer
public struct QuestionSheetFeature {
    @ObservableState
    public struct State: Equatable { ... }
```

- **`@Reducer`**: TCA의 매크로. 컴파일 시점에 boilerplate(`Reducer` protocol 준수, Action/State 타입 매칭 등)를 자동 생성. 이게 없으면 Reducer protocol에 맞춰 직접 채워 넣어야 할 코드가 많음.
- **`@ObservableState`**: SwiftUI의 `@Observable`과 비슷한 역할. State의 변화를 View가 자동 감지하도록 만들어줌. TCA 1.x 이후 도입된 새 방식 (기존엔 `WithViewStore` + `ViewState` 패턴이 필요했음).

→ 이 두 매크로가 붙어 있으면 "**아, TCA의 최신 스타일 Reducer구나**" 라고 인식.

### 2. State — 화면이 들고 있는 데이터

```swift
public struct State: Equatable {
    public var questionText: String     // 화면에 보여줄 질문 텍스트
    public var isAnswered: Bool          // 이미 답변했나? (버튼 활성/비활성 분기)
    public var isSkipped: Bool           // 스킵된 질문인가? (UI 분기)
}
```

세 변수가 전부. **시트 화면이 보여줘야 할 모든 정보가 여기 다 들어 있음**. View는 이 State만 보고 그림.

`Equatable` 채택은 **TCA의 표준 요구사항** — 상태 변화 감지/diff에 사용.

### 3. Action — 일어날 수 있는 모든 사건

```swift
public enum Action: Sendable, Equatable {
    case closeTapped              // ① 사용자: 닫기 버튼 탭
    case answerTapped             // ② 사용자: 답변하기 버튼 탭
    case writeQuestionTapped      // ③ 사용자: 질문 작성하기 버튼 탭
    case refreshQuestionTapped    // ④ 사용자: 질문 새로고침 버튼 탭
    case delegate(Delegate)       // ⑤ 부모로 보낼 신호 (Delegate 패턴)

    public enum Delegate: Sendable, Equatable {
        case close
        case navigateToAnswer
        case showWriteQuestionCost
        case showRefreshQuestionCost
    }
}
```

**4개의 UI 입력 + 1개의 delegate**. delegate는 **"이 시트가 부모에게 보내는 신호"** 의 enum.

> `Sendable`은 Swift 6 동시성에서 본 그 키워드 — actor/Task 경계를 안전하게 건너갈 수 있다는 약속. TCA Action은 항상 Sendable.

### 4. body — Reducer 본체

```swift
public var body: some Reducer<State, Action> {
    Reduce { _, action in
        switch action {
        case .closeTapped:
            return .send(.delegate(.close))
        case .answerTapped:
            return .send(.delegate(.navigateToAnswer))
        case .writeQuestionTapped:
            return .send(.delegate(.showWriteQuestionCost))
        case .refreshQuestionTapped:
            return .send(.delegate(.showRefreshQuestionCost))
        case .delegate:
            return .none
        }
    }
}
```

**State를 안 건드림** (`_, action in` — 첫 인자 state 자리에 underscore). 그저 각 UI 입력을 그에 대응되는 **delegate action으로 변환해서 즉시 발송**.

- `.send(.delegate(.close))` = "이 Reducer가 끝나면 곧바로 `.delegate(.close)` 액션을 다시 보내라"
- `.none` = "Effect 없음" — delegate 자체는 그냥 신호용이라 후속 처리 없음

### 5. `some Reducer<State, Action>` 반환 타입

Phase 2.4에서 만날 **opaque type** (`some P`). "이 프로퍼티는 어떤 구체적인 Reducer 타입을 반환하는데, 외부엔 'State=State, Action=Action을 가진 Reducer'라는 사실만 노출한다"는 의미. TCA가 내부적으로 합성한 복잡한 Reducer 타입을 숨기는 도구.

---

## 핵심 패턴 — Delegate (TCA의 가장 중요한 idiom 중 하나)

### 왜 그냥 부모를 직접 호출하지 않고 delegate를 거치나

```
[QuestionSheetView]   →   .answerTapped
                          │
                          ▼
[QuestionSheetFeature]    .send(.delegate(.navigateToAnswer))
                          │
                          ▼
[HomeFeature]             ← 부모가 .questionSheet(.delegate(.navigateToAnswer))를 캐치
                          │  진짜 라우팅/팝업/상태 변경 수행
                          ▼
[화면 전환 실행]
```

**핵심 원칙**: "시트 자체는 화면 전환이나 비즈니스 결정을 내리지 않는다. 그저 **'사용자가 답변하기를 눌렀다'는 사실만 신호**로 부모에게 알린다. 진짜 결정은 부모가 한다."

### 이게 왜 좋나

1. **재사용성**: QuestionSheetFeature를 다른 화면에서 띄워도 동작이 깨지지 않음. 부모마다 다르게 라우팅 가능
2. **테스트 가능성**: 시트의 동작은 "delegate를 emit 했는가"만 검증. 화면 전환은 부모 테스트에서 검증
3. **관심사 분리**: 시트는 UI 입력 → 의도 변환만, 부모는 의도 → 실제 동작 결정만

### 같은 패턴 한 줄 정리

> "**Delegate action = 자식이 부모에게 보내는 '의도 신호'**. 자식은 '뭘 할지' 모름. 부모만 안다."

---

## 자문할 4가지 (직접 답변 메모할 자리)

### Q1. `.send(.delegate(.close))`와 `.none`의 차이는?
Effect의 두 가지 모양인데 의미가 어떻게 다른가?

**본인 답**: .send(.delegate(.close))의 경우 사용자가 닫기를 눌렀을 때 closeTapped를 실행시킴. 부모로 .close를 전달해 사용자가 닫는 버튼을 눌렀다는 것을 알려줌. .none은 부모로 전달하는 것이 없는 상태

**보강**: △ 방향 ✅ / 표현 두 군데 정정

**정정 1**: "closeTapped를 실행시킴" → ❌. `closeTapped`는 **이미 처리 중인 액션**.
`.send(.delegate(.close))`가 하는 일은 "지금 처리 중인 closeTapped가 끝나면 그 직후
**새 액션 `.delegate(.close)`을 자동 발송**"하는 것.

**정정 2**: "부모로 전달" → ⚠️ 미묘하게 어긋남.
`.send`는 그저 **같은 Reducer 안으로 다음 액션을 다시 던지는 것**. 부모로 직접 보내는 게 아님.
그 던져진 `.delegate(...)` 액션이 결과적으로 부모 Reducer까지 흘러가는 건
**TCA의 자동 액션 전파** 덕분 (자식 Action이 부모 Action enum의 case로 wrap돼서 부모도 그걸 봄).

**정확한 정의 — Effect의 기본 3종**:

| Effect | 의미 |
|---|---|
| `.send(action)` | "다음 액션을 발송하라" — 같은 Reducer가 다시 호출되고, wrap된 액션은 부모 Reducer도 봄 |
| `.none` | "아무것도 안 함" — 후속 액션도 없고, async 작업도 없음 |
| `.run { send in ... }` | "async 작업 시작, 완료 시 send로 결과 액션 발송" (WriteQuestionFeature에서 등장) |

한 줄: ".send는 '다음 액션 발송'이지 '부모로 직접 전달'이 아님. TCA의 자동 전파 덕에 부모가 결과적으로 받게 되는 것."




---

### Q2. `case .delegate: return .none` — 왜 이게 필요한가?
빼면 어떻게 되나?

힌트: switch는 exhaustive

**본인 답**: switch는 모든 경우에 대응되어야 하므로 case .delegate: return .none이 필요하다

**보강**: ⭕ 정확

Swift switch는 모든 case를 처리해야 컴파일됨. `.delegate`도 Action enum의 case 중 하나니 처리 필요. 정확히 짚음.

**한 가지 더**: 왜 `.delegate`에서 `.none`을 반환하는가?
**delegate action은 "부모가 캐치할 신호"라서 자식 Reducer 입장에선 더 할 일이 없음**.
자식이 자기 신호를 자기가 다시 처리하면 패턴이 깨짐 (delegate 의도가 무의미해짐).
→ **자식의 delegate 케이스는 항상 `.none`이 정석**.




---

### Q3. State에 `questionText`가 들어 있는데 Reducer 안에서 한 번도 안 건드린다
그럼 누가 이 값을 채우나?

힌트: 부모가 시트를 띄울 때

**본인 답**: 부모가 시트를 띄울 때 bindable을 이용해서 양방향으로 연결할 수 있을 듯 그럼 부모측에서 값을 받을 수 있다. -> Reducer 자체가 ObservableState 매크로를 가지고 있기에 가능함

**보강**: △ 방향 좋고 좋은 추측, 메커니즘 정정

"부모가 띄울 때 값을 채운다" — **이 직관은 정확** ✅. 다만 메커니즘이 미묘하게 섞임.

**정확한 메커니즘 — TCA Composition**:

```swift
// 부모 (HomeFeature 또는 MainTabFeature) State
@ObservableState
struct State {
    var todayQuestion: Question?
    @Presents var modal: Modal.State?    // ← 시트는 여기에 옵셔널로 존재
}

// 부모 Reducer가 시트 띄울 때
case .questionCardTapped:
    state.modal = .questionSheet(
        QuestionSheetFeature.State(           // ← 여기서 값을 채움!
            questionText: question.text,
            isAnswered: question.isAnswered,
            isSkipped: question.isSkipped
        )
    )
    return .none
```

**핵심**: 자식 State는 **부모 State의 한 프로퍼티로 포함**됨 (composition).
부모가 시트를 띄우는 순간에 `QuestionSheetFeature.State(...)`로 **초기값을 직접 채워서 부모 state에 대입**.
그게 자식 시트의 시작 데이터.

**`@Bindable`과 `@ObservableState`의 정확한 역할 — 헷갈리기 쉬운 두 단어**:

| | 역할 |
|---|---|
| `@ObservableState` | **State 변화 추적**. View가 State 일부만 봐도 그 일부가 바뀔 때 자동 재렌더링. SwiftUI의 `@Observable` 호환 |
| `@Bindable` (`@Bindable var store: ...`) | **양방향 바인딩용 View 어트리뷰트**. TextField($store.text) 같은 식으로 store의 값을 양방향 연결 |

→ "부모가 자식에게 초기값을 채우는 메커니즘"은 **composition (State 안에 State 보유)**이고,
ObservableState/Bindable과는 다른 축. 둘 다 TCA의 도구지만 책임이 다름.

**한 줄**: "**자식 State는 부모 State의 일부로 들어가 있고, 부모가 띄우는 순간 초기화 시점에 값을 채워 넣는다.**
ObservableState는 변화 추적용, Bindable은 양방향 바인딩용으로 별개 축."




---

### Q4. 사용자가 "답변하기"를 누르면 "답변 화면으로 이동"이라는 실제 동작은 어디서 일어나는가?
이 파일을 grep해도 답이 없을 텐데, 그럼 어디 봐야 할까?

힌트: `case .questionSheet(.delegate(.navigateToAnswer))`를 grep

**본인 답**: case .questionSheet(.delegate(.navigateToAnswer))`를 하게되면 실제 동작은 부모에서 일어난다 (HomeView) 아마 바텀시트를 내리고 답변하기 화면으로 이동시킬 것

**보강**: △ 본인 추측한 위치보다 **한 단계 위**에 진짜 답이 있음 — 흥미로운 발견

**정정 1 — 위치**: HomeView가 아니라 **MainTab+Reducer.swift** (한 단계 더 위 부모).
실제로는 시트가 **modal 시스템을 통해 MainTab 레벨**에서 띄워지고 있음.

**정정 2 — 코드 위치**: 라우팅은 **View가 아니라 Reducer**에서 결정.
TCA에선 항상 **Feature(=Reducer)**에서 라우팅 처리.

**실제 코드 (grep으로 찾음)** — `MainTab+Reducer.swift` 285-292줄:

```swift
case .modal(.presented(.questionSheet(.delegate(.navigateToAnswer)))):
    state.modal = nil                                              // ① 시트 닫기
    guard let question = state.home.todayQuestion else { return .none }
    return .run { send in
        // 시트 dismiss 애니메이션 완료 후 push
        try await Task.sleep(nanoseconds: 350_000_000)              // ② 0.35초 대기
        await send(.delegate(.navigateToQuestionDetail(question)))  // ③ 답변 화면 이동 신호
    }
```

본인이 추측한 동작이 **정확히 그대로** 구현됨:
- "바텀시트를 내리고" → `state.modal = nil` ✅
- "답변하기 화면으로 이동" → `.delegate(.navigateToQuestionDetail(question))` ✅

심지어 **본인이 안 말한 디테일**까지 있음:
- **`Task.sleep(350_000_000)`** = 350ms 대기. 시트가 닫히는 애니메이션이 끝난 뒤에야
  다음 화면을 push해야 자연스러움. 안 그러면 시트 닫힘 + 화면 전환이 동시에 일어나 깜빡임 발생.

→ **MainTabFeature도 자기 delegate로 한 단계 더 위로 신호를 던짐**
   (`.delegate(.navigateToQuestionDetail(question))`).
   즉 **delegate 패턴이 계층 전체에 일관되게 적용**되어 있음.
   시트(자식) → MainTab(중간) → RootFeature(최종)으로 신호가 거슬러 올라감.

**한 줄**: "라우팅 결정은 **Reducer**가 한다. 그리고 시트는 직접 부모가 Home이 아니라
**MainTab(modal 시스템 안)**이라는 한 단계 더 위. delegate 패턴이 계층 전체에 일관적으로 흐름."




---

## 학습 체크리스트

다음 파일(WriteQuestionFeature)로 넘어가기 전 머리에 박혔는지 확인:

- [ ] `@Reducer` / `@ObservableState` 매크로의 역할
- [ ] State / Action / Reducer 3종 세트의 분담
- [ ] Action enum이 "일어날 수 있는 모든 사건의 카탈로그"라는 의미
- [ ] Delegate sub-enum이 "자식 → 부모 신호"라는 의도
- [ ] `.send(...)` 와 `.none`의 차이
- [ ] `some Reducer<State, Action>` opaque return type의 의미

---

## 4개 자문 종합 평가

| Q | 평가 | 정정 한 줄 |
|---|---|---|
| Q1 | △ 방향 ✅ | `.send`는 "다음 액션 발송" — 부모로 직접 전달 X. TCA의 자동 전파 덕분에 부모도 봄 |
| Q2 | ⭕ 정확 | exhaustive switch 정확히 짚음. 자식 delegate 케이스는 항상 `.none`이 정석 |
| Q3 | △ 방향 ✅ | 부모 State에 자식 State 포함(composition). ObservableState/Bindable과 다른 축 |
| Q4 | △ 위치 정정 | 부모는 HomeFeature가 아니라 **MainTab+Reducer**. View가 아니라 Reducer가 라우팅 결정 |

---

## 보너스 학습 — delegate 사슬 (3계층 신호 전파)

Q4에서 발견한 패턴을 한 단계 더 확장하면:

```
QuestionSheetFeature.delegate(.navigateToAnswer)
   ↓ (자동 전파)
MainTabFeature가 캐치 (MainTab+Reducer.swift 285줄)
   ↓
state.modal = nil  + 0.35초 대기  +  .delegate(.navigateToQuestionDetail(question)) 발송
   ↓ (자동 전파)
RootFeature가 캐치 (아마 path.append로 답변 화면 push)
```

**같은 delegate 패턴이 3계층을 거쳐 신호가 위로 위로 올라감**.
각 계층은 자기 책임만 처리하고 더 큰 결정은 위로 위임.

**계층별 책임 분담**:
- **QuestionSheetFeature** (자식, 가장 작은 단위)
  → "사용자가 답변하기 눌렀다"만 신호
- **MainTabFeature** (중간, modal 관리)
  → 시트 닫기 + 애니메이션 대기 + 다음 신호 발송
- **RootFeature** (최상위, 전체 라우팅)
  → 실제 화면 push (NavigationStack의 path 변경)

**이게 TCA의 단방향 데이터 흐름이 가져다주는 가장 큰 가치**.
신호는 항상 자식 → 부모로 흐르고, 각 계층은 자기 추상화 수준에 맞는 일만 함.

> "**delegate 사슬은 TCA에서 컴포넌트 간 통신의 표준 모양**. 직접 호출이 아니라 신호의 연쇄 → 계층 분리 + 테스트 가능성 + 재사용성을 동시에 얻음."

---

## 심화 — Wrap과 부모-자식 State 관계

자문 외에 따로 짚고 갈 두 가지 깊은 질문.

### A. "Wrap"의 정확한 개념

**어원**: wrap = "감싸다, 포장하다". 컴퓨터 과학에선 "한 값을 다른 타입 안에 담는다"는 뜻.

#### Swift enum의 associated value

```swift
enum Wrapper {
    case foo(Int)        // ← Int를 wrap
    case bar(String)     // ← String을 wrap
}

let x = Wrapper.foo(42)    // 42가 .foo 안에 wrap됨

if case .foo(let value) = x {
    print(value)  // 42 — unwrap됨
}
```

→ `Wrapper.foo(42)` = "Int 42를 .foo라는 라벨로 포장한 것". 패턴 매칭으로 꺼냄.

#### TCA에서의 wrap — 실제 코드 (MainTab+Modal.swift)

```swift
extension MainTabFeature {
    @Reducer
    public struct Modal {
        public enum Action: Equatable {
            case peerAnswer(PeerAnswerFeature.Action)
            case answerFirstPopup(AnswerFirstPopupFeature.Action)
            case questionSheet(QuestionSheetFeature.Action)    // ← 여기서 wrap!
            case heartCostPopup(HeartCostPopupFeature.Action)
            case heartInfoPopup(HeartInfoPopupFeature.Action)
        }

        public var body: some Reducer<State, Action> {
            Scope(state: \.questionSheet, action: \.questionSheet) {
                QuestionSheetFeature()
            }
            // ...
        }
    }
}
```

각 case가 **자식 Feature의 Action을 통째로 associated value로 wrap**.
같은 액션 한 개가 계층을 거치며 점점 더 깊게 포장됨 — 양파처럼.

#### 시각적으로 — 4겹 wrap

```
QuestionSheetFeature.Action.delegate(.close)   ← 자식 입장의 액션
   ↓ (Scope가 자동으로 wrap)
Modal.Action.questionSheet(.delegate(.close))   ← Modal 입장에서 본 액션
   ↓ (다시 wrap)
MainTabFeature.Action.modal(.presented(.questionSheet(.delegate(.close))))
```

MainTab+Reducer.swift 285줄의 패턴 매칭:
```swift
case .modal(.presented(.questionSheet(.delegate(.navigateToAnswer)))):
//    └─1─┘└──2────┘└──────3───────┘└──────4─────────┘
//     겹1   겹2     겹3 (Modal.Action)  자식 액션
```

이 4겹 매칭이 wrap의 결과. 부모가 자식의 액션을 자기 enum 안에 포장해 들고 있고,
처리할 때 양파 까듯 패턴 매칭으로 풀어내는 것.

#### Scope가 wrap을 자동화

```swift
Scope(state: \.questionSheet, action: \.questionSheet) {
    QuestionSheetFeature()
}
```

이 한 줄이 하는 일:
1. 부모 State에서 `\.questionSheet`로 자식 State를 꺼냄
2. 부모 Action에서 `\.questionSheet` 케이스로 자식 Action을 꺼냄 (wrap 해제)
3. 자식 Reducer 실행
4. 자식이 새 Action 발송하면 다시 부모 Action 케이스로 wrap

→ 개발자는 wrap/unwrap을 안 적어도 됨. Scope가 KeyPath 두 개로 wrap 매크로를 가져다 줌.

#### 한 줄 정리

> "**Wrap = Swift enum의 associated value로 한 값을 다른 타입에 담는 것**.
>  TCA에선 부모 Action enum의 case가 자식 Action을 wrap. 계층마다 한 번씩 더 wrap되어
>  양파 모양이 되고, Scope가 wrap/unwrap을 자동화."

---

### A2. Wrap을 하는 이유 — 왜 굳이?

핵심 한 줄:
> "**자식 액션이 부모 State 트리 어디서 왔는지 컴파일러가 알게 하기 위해**.
>  Wrap은 액션의 '주소(어느 자식에서 발사됐는지)'를 타입에 박아두는 메커니즘."

4가지 구체적 이유로 풀어 설명.

#### 이유 1: 라우팅 — 어느 자식의 액션인지 구분

부모가 자식을 여럿 가질 수 있음. modal 시스템만 봐도:

```swift
public enum Action: Equatable {
    case peerAnswer(PeerAnswerFeature.Action)
    case answerFirstPopup(AnswerFirstPopupFeature.Action)
    case questionSheet(QuestionSheetFeature.Action)
    case heartCostPopup(HeartCostPopupFeature.Action)
    case heartInfoPopup(HeartInfoPopupFeature.Action)
}
```

5개 자식이 다 자기 Action enum을 가짐. 그 안에 `.closeTapped` 같은 case가 우연히 겹칠 수 있음.

**Wrap 안 하면** (가설):
```swift
public enum Action {
    case closeTapped       // PeerAnswer? QuestionSheet? HeartCost? 어느 것?
    case dismissTapped
    case submitTapped
}
```
→ "**누가 닫기를 눌렀나**" 구분 불가. 부모는 어느 자식에 라우팅할지 모름.

**Wrap이 해결**:
```swift
case questionSheet(.closeTapped)    // QuestionSheet의 닫기
case heartCostPopup(.closeTapped)   // HeartCostPopup의 닫기
```
같은 `.closeTapped`라도 어느 자식에서 왔는지가 **타입에 박혀 있음**. 패턴 매칭으로 정확히 갈라낼 수 있음.

#### 이유 2: 컴파일러 보장 — exhaustive switch

Swift switch는 모든 case 처리 강제. 이게 wrap과 결합하면:

```swift
switch action {
case .modal(.presented(.questionSheet(.delegate(.close)))):
    state.modal = nil
case .modal(.presented(.questionSheet(.delegate(.navigateToAnswer)))):
    // ...
case .modal(.presented(.questionSheet(.delegate(.showWriteQuestionCost)))):
    // ...
// 자식 delegate에 새 case 추가하면? → 컴파일 에러로 "처리 안 한 case 있음" 경고
}
```

→ **자식이 새 delegate 추가 = 부모 코드가 컴파일 실패**. 새 신호를 부모가 다뤄야 한다는 강제.
**잊어버릴 수 없음** — 타입 시스템이 강요.

Wrap 안 하면 이 보장 없음. 자식이 새 사건 추가해도 부모는 모름.

#### 이유 3: Single dispatch — 모든 액션이 한 통로로

TCA의 Store는 **단 하나의 진입점**으로 모든 액션을 받음:

```
사용자 입력 → Store.send(Action) → Reducer → 새 State → View 다시 그림
```

수십 개의 자식이 있어도 결국 **단 하나의 최상위 Action enum**으로 모든 액션이 표현돼야 함:

```
QuestionSheetFeature.Action.delegate(.close)
  ↓ wrap
Modal.Action.questionSheet(.delegate(.close))
  ↓ wrap
MainTabFeature.Action.modal(.presented(.questionSheet(.delegate(.close))))
  ↓ wrap
RootFeature.Action.mainTab(.modal(.presented(.questionSheet(.delegate(.close)))))
```

**같은 액션이 계층 깊이만큼 wrap되어 최상위 한 타입으로 표현됨**. Store는 모든 액션을 같은
통로로 받지만, wrap 덕에 어느 자식에서 왔는지 추적 가능.

이게 가능하니까:
- **시간선 로깅**: 모든 액션을 한 줄로 기록 가능 → 디버깅
- **TestStore**: 테스트에서 액션 시퀀스를 통째로 검증
- **DevTools 같은 도구**: 액션 흐름을 시각화 가능

#### 이유 4: Scope 합성 — 부모와 자식을 잇는 다리

```swift
Scope(
    state:  \.questionSheet,    // 부모 State의 자식 자리 KeyPath
    action: \.questionSheet     // 부모 Action의 자식 wrap 케이스 KeyPath ← 이게 wrap!
) {
    QuestionSheetFeature()
}
```

Scope가 하는 일:
1. 부모 액션이 들어오면 → `\.questionSheet` 케이스인지 확인
2. 맞으면 → 자식 액션을 unwrap해서 꺼냄
3. 자식 Reducer 호출 → 자식 액션 발송됨
4. 자식 액션을 다시 `\.questionSheet` 케이스로 wrap → 부모 액션으로 변환

**wrap이 없으면 이 unwrap/wrap 자동화 자체가 불가능**. KeyPath가 가리킬 자리가 없으니까.

#### "Wrap 안 하면 어떻게 될까" — 가설 시나리오

```swift
// 가설: wrap 없음
public enum MainTabAction {
    case selectTab(Int)
    // 자식들 액션들을 한 통에 다 펴서 담음
    case closeTapped      // QuestionSheet?
    case answerTapped     // QuestionSheet?
    case submitTapped     // PeerAnswer? Write?
}
```

이러면 문제가 줄줄이:
- **case 이름 충돌**: 자식들끼리 같은 case 이름이 우연히 겹칠 수 있음
- **출처 불명**: closeTapped가 어느 자식에서 왔는지 알 수 없음
- **자식 한 명만 빌려 쓰는 게 불가능**: 자식 Action import = 부모 Action 전체에 영향
- **컴파일러 도움 끊김**: 자식 새 액션 추가해도 부모는 알 수 없음
- **테스트 어려움**: 액션 시퀀스를 봐도 무엇이 어디서 발생했는지 추적 불가

→ wrap은 자식 액션 enum 전체를 **부모 enum 안의 한 case에 통째로 묶어** 충돌·혼동·라우팅
손실을 모두 방지.

#### 큰 그림 — Sum Type의 합성

함수형 프로그래밍의 **algebraic data type** 개념과 직결:
- enum = sum type ("이거 또는 저거 또는 ...")
- struct = product type ("이거 그리고 저거 그리고 ...")

자식 enum을 부모 enum에 wrap하는 건 **sum type을 중첩**시키는 행위. 이걸로:
- 자식들의 모든 가능한 액션 + 부모 자신의 액션 = 하나의 큰 sum type
- 컴파일러가 전체 가능성을 추적
- 패턴 매칭으로 어떤 분기든 안전하게 처리

수학적으로 깔끔한 합성이고, 실용적으론 위 4가지 이득.

#### 한 줄 격언

> "**Wrap = '액션이 어디서 왔는지' 출처를 타입에 박는 것**.
>  컴파일러 도움 + 라우팅 + 합성 + 단방향 디스패치, 이 네 가지를 한꺼번에 얻으려면 wrap이 필수.
>  자식 액션을 그냥 부모 enum에 펴 담으면 위 네 가지가 모두 깨짐."

---

### B. 부모가 `question.text`를 넣고 "실시간 감지"하는가?

본인 표현을 두 부분으로 분해해서 풀이:

#### (B1) "부모가 시트를 띄울 때 question.text를 넣고" — ⭕ 정확

부모 Reducer가 시트 띄울 때 자식 State를 직접 초기화하면서 값을 채움:

```swift
// MainTab+Reducer 어딘가 (가설):
case .home(.delegate(.showQuestionSheet(let question))):
    state.modal = .questionSheet(
        QuestionSheetFeature.State(
            questionText: question.text,         // ← 여기서 채움
            isAnswered: question.isAnswered,
            isSkipped: question.isSkipped
        )
    )
    return .none
```

이게 **composition의 핵심**. 자식 State는 부모 State의 한 가지에 포함되어 있고,
부모가 그 자리를 새 State 인스턴스로 채워 넣음.

#### (B2) "실시간 감지"라는 표현은 ⚠️ 정정 필요

**감지가 아니라 같은 메모리 공유**.

자식 State는 부모 State의 한 프로퍼티 — 둘이 같은 메모리 위치를 가리킴:

```
부모 State {
    todayQuestion: Question?
    modal: Modal.State? = .questionSheet(QuestionSheetFeature.State {
        questionText: "오늘의 질문",   ← 이 자리가 자식 State이자 부모 State의 일부
        isAnswered: false,
        isSkipped: false
    })
}
```

자식이 `state.questionText = "변경"`을 하면:
- 그건 부모 State 트리 안의 같은 자리를 직접 수정하는 것
- 부모가 따로 "감지"하거나 "구독"할 필요 없음 — 둘이 같은 메모리이기 때문

**비유**: 책장이 부모, 책이 자식. 책의 한 페이지를 누가 고쳤다면:
- "책장이 책의 변화를 감지" — ❌ (아님)
- "책장 안의 책의 페이지가 직접 바뀐 것" — ⭕ (이게 맞음)

책장과 책이 한 몸이기 때문. 분리된 두 객체 사이의 "감지/구독" 모델이 아니라
**하나의 통합된 State 트리**.

#### (B3) QuestionSheetFeature는 특수 케이스

위 일반 원리를 알아둔 상태에서, 이 시트의 특수성:

```swift
public var body: some Reducer<State, Action> {
    Reduce { _, action in       // ← state 자리에 _ (underscore)
```

이 Reducer는 **State를 한 번도 안 건드림**. 그래서:
- `questionText`는 부모가 띄울 때 한 번 채워지고 → 그대로 유지됨
- 자식 내부에서 텍스트가 변하지 않음
- 사용자가 닫기/답변하기 같은 버튼만 누르고, 텍스트 자체는 읽기 전용

→ 이 시트에선 "실시간 감지"가 필요 없음. 텍스트가 변하지 않으니까. 부모가 한 번 채운 그
값을 시트가 그대로 보여줄 뿐.

#### (B4) 진짜 "양방향" 패턴은 WriteQuestionFeature에서

다음에 볼 WriteQuestionFeature는 다름:

```swift
case .questionTextChanged(let text):
    state.questionText = text   // ← 사용자가 타이핑할 때마다 state 갱신
    return .none
```

여기선 사용자가 타이핑할 때마다 state가 갱신됨. 그리고 그 state는 부모 State의 일부라서
부모도 같은 값을 보게 됨 — "감지"가 아니라 **같은 메모리를 공유하기 때문**.

View에서는 `@Bindable var store` + `TextField($store.questionText)` 같은 식으로 양방향
바인딩 — 사용자 타이핑이 자동으로 `.questionTextChanged(text)` 액션을 발사하게 만들어줌.
이게 SwiftUI의 binding 메커니즘.

#### 두 부분 한 줄로 답

| | 본인 표현 | 정확한 모델 |
|---|---|---|
| 부모가 값 넣음 | ⭕ "시트 띄울 때 question.text 넣음" | 부모 Reducer가 자식 State.init에서 값을 채워 넣음 — composition |
| 실시간 감지 | ⚠️ "감지" 표현 | 감지 X, 같은 메모리 공유. 자식이 자기 state를 바꾸면 그게 곧 부모 state 트리의 일부가 바뀌는 것 |

#### 큰 그림 격언

> "**부모와 자식은 분리된 객체가 아니라 하나의 State 트리에서 다른 위치를 차지하는 두 부분**.
>  부모가 자식을 '감지'하는 게 아니라, 둘이 같은 메모리를 공유하기에 자식의 변화가 자동으로
>  부모에게도 보임. 'Wrap'은 이 위계를 표현하는 Swift 메커니즘일 뿐."

이게 박히면 다음 파일들(특히 HomeFeature의 복잡한 composition)이 훨씬 쉽게 읽힘.

---

## 다음 단계

이 파일 다 읽고 4개 자문에 답을 메모하면, 다음은:
- **`WriteQuestionFeature.swift`** (87줄) — Effect와 `@Dependency`가 처음 등장. async repository 호출이 등장하는 첫 Reducer
