# WriteQuestionFeature — Effect와 @Dependency가 처음 등장

**파일 위치**: `MongleFeatures/Sources/MongleFeatures/Presentation/Question/WriteQuestionFeature.swift`
**줄수**: 87줄
**위치 의미**: Stage 2의 두 번째 읽기 대상. **`@Dependency` + `.run` Effect + async repository 호출**이 처음 등장.

---

## 한 눈에 본 요약

> "사용자가 직접 질문을 작성해서 서버에 제출하는 화면의 Reducer. **텍스트 입력 → 제출 버튼 → 서버 호출 → 결과 처리 → 부모에게 신호**의 전형적인 'form submission' 흐름."

QuestionSheetFeature와 비교했을 때 **새로 등장한 4가지**:

| | QuestionSheetFeature | WriteQuestionFeature |
|---|---|---|
| State 변화 | 없음 (UI 신호만 전달) | `questionText`, `isSubmitting`, `appError` 변경 |
| 의존성 | 없음 | `@Dependency(\.questionRepository)`, `@Dependency(\.errorHandler)` |
| Effect 종류 | `.send`, `.none` | `.send`, `.none`, **`.run { ... }`** (async!) |
| Action 종류 | UI 입력 + delegate | UI 입력 + **응답 액션(`submitResponse`)** + delegate |

→ 이 4가지가 **"진짜 화면 Reducer"의 표준 모양**. TCA를 본격적으로 쓰는 시작점.

---

## 코드 해부 — 6가지 부분

### 1. State — computed property 처음 등장

```swift
public struct State: Equatable {
    public var questionText: String = ""
    public var isSubmitting: Bool = false
    public var appError: AppError?

    public var canSubmit: Bool {
        !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
```

- **저장 프로퍼티 3개**: 텍스트 / 제출 중인가 / 에러
- **`canSubmit` computed property**: 텍스트가 비어있지 않을 때만 제출 가능. **derived state(파생 상태)** — State 자체에 저장하지 않고 매번 계산. View가 `store.canSubmit`을 보고 버튼 활성화 결정.

→ "**State에 저장할 가치가 있는가, 다른 값에서 계산할 수 있는가?**"를 자문하는 게 중요.
`canSubmit`은 `questionText`에서 항상 도출 가능하므로 저장 X → computed로.

### 2. SubmitSuccess — Effect 결과를 묶는 구조체

```swift
public struct SubmitSuccess: Equatable, Sendable {
    public let question: Question
    public let heartsRemaining: Int
}
```

서버 응답이 두 가지 값을 가져옴 (질문 + 남은 하트 수) → **튜플 대신 구조체**로 묶음. Action enum에 페이로드로 넣기 위해 `Equatable + Sendable` 필수.

### 3. Action — Result 타입 등장

```swift
public enum Action: Sendable, Equatable {
    case closeTapped                                       // ① UI 입력
    case questionTextChanged(String)                       // ② UI 입력 (텍스트 바인딩)
    case submitTapped                                      // ③ UI 입력
    case submitResponse(Result<SubmitSuccess, AppError>)   // ④ ★ 비동기 응답
    case setAppError(AppError?)                            // ⑤ 에러 설정
    case delegate(Delegate)                                // ⑥ 부모로 신호

    public enum Delegate: Sendable, Equatable {
        case close
        case questionSubmitted(Question, heartsRemaining: Int)
    }
}
```

**핵심 — `submitResponse(Result<...>)` 패턴**:
- async 작업의 결과를 받기 위한 **별도 Action**
- `Result<Success, Failure>` 타입을 페이로드로 → 성공/실패 한 case로 표현
- "**비동기 작업의 결과는 항상 새 Action으로 돌아온다**" — TCA의 핵심 단방향 흐름

### 4. `@Dependency` — DI가 처음 등장

```swift
@Dependency(\.questionRepository) var questionRepository
@Dependency(\.errorHandler) var errorHandler
```

- **`@Dependency`**: TCA의 DI 매크로. KeyPath(`\.questionRepository`)로 의존성 시스템에서 객체를 꺼냄
- 이 KeyPath는 어디 등록? → `AppDependencies.swift`에 정의된 `DependencyValues` 확장
- 결과적으로 `questionRepository`는 **`any QuestionRepositoryInterface`** 타입 → 7-B2에서 본 팩토리(`makeQuestionRepository()`) 결과
- 테스트할 땐 `withDependencies { $0.questionRepository = MockQuestionRepository() } operation: { ... }`로 갈아끼움

→ TCA의 의존성 주입은 **"Reducer가 직접 Repository를 만들지 않고, 시스템에서 꺼낸다"**는 분리.

### 5. body — 비동기 흐름의 정석 모양

```swift
public var body: some Reducer<State, Action> {
    Reduce { state, action in
        switch action {
        case .closeTapped:
            return .send(.delegate(.close))

        case .questionTextChanged(let text):
            state.questionText = text
            return .none

        case .submitTapped:
            guard state.canSubmit, !state.isSubmitting else { return .none }
            state.isSubmitting = true
            state.appError = nil
            let content = state.questionText.trimmingCharacters(in: .whitespacesAndNewlines)
            return .run { [questionRepository] send in
                do {
                    let (question, heartsRemaining) = try await questionRepository.createCustomQuestion(content: content)
                    await send(.submitResponse(.success(SubmitSuccess(question: question, heartsRemaining: heartsRemaining))))
                } catch {
                    await send(.submitResponse(.failure(AppError.from(error))))
                }
            }

        case .submitResponse(.success(let result)):
            state.isSubmitting = false
            return .send(.delegate(.questionSubmitted(result.question, heartsRemaining: result.heartsRemaining)))

        case .submitResponse(.failure(let error)):
            state.isSubmitting = false
            state.appError = error
            return .none

        case .setAppError(let error):
            state.appError = error
            return .none

        case .delegate:
            return .none
        }
    }
}
```

### 6. `.run { [questionRepository] send in ... }` — async 작업의 표준 모양

세 가지 디테일이 들어 있음:

**(1) `.run { send in ... }`**: async 작업을 시작하는 Effect. 클로저 안에서 `await`로 비동기 호출 가능. 결과는 **`send(액션)`** 으로 Reducer에 되돌려보냄.

**(2) `[questionRepository]` 캡처 리스트**: 클로저에 캡처할 값을 명시. **왜 필요?** Reducer는 struct고 `self`를 통째로 캡처하면 Sendable 위반 위험. 필요한 의존성만 명시적으로 가져옴.

**(3) `await send(...)`**: send 자체가 async 함수. Action을 Reducer로 다시 던지는 행위. 단방향 흐름의 핵심.

---

## 핵심 패턴 — 비동기 작업의 3단 흐름

```
사용자 입력 → State 갱신 + Effect 발사 → 결과 도착 시 새 Action으로 돌아옴 → State 갱신 + 후속 Action

[submitTapped]                        [submitResponse(.success)]
  ↓                                     ↓
state.isSubmitting = true              state.isSubmitting = false
state.appError = nil                   .send(.delegate(.questionSubmitted))
                                        ↑
.run { send in                          │
  let result = try await ...            │
  await send(.submitResponse(...))  ────┘  결과를 새 Action으로 돌려보냄
}
```

**핵심 원칙**: "Reducer는 절대 await 하지 않는다. 비동기 작업은 Effect로 던지고, **결과는 새 Action으로 돌아온다**."

### 왜 이런 모양인가

1. **Reducer는 순수 함수 유지**: (State, Action) → State 변환만. 외부 세계와의 통신은 Effect에 격리
2. **State 변경은 항상 한 곳에서**: switch 분기 안에서 직접 변경하는 코드만 → 추적/테스트 쉬움
3. **모든 상태 변화가 Action을 통해 일어남**: 시간선이 Action 시퀀스로 표현됨 → 시간여행 디버깅 가능

### 흐름 한 줄

> "사용자 액션 → Reducer가 State 미리 갱신 + Effect 발사 → 외부 작업 완료 → 결과 Action 발송 → Reducer가 다시 호출되어 최종 State + 후속 Action."

---

## 자문할 5가지 (직접 답변 메모할 자리)

### Q1. `.run { ... }` Effect와 `.send(...)` Effect의 차이는?
언제 어느 걸 쓰는가?

**본인 답**:

.run { ... } Efftect는 async로 실행되며 클로져 안에서 await 로 비동기 호출이 가능하다 .send(...) Effect는 async로 실행되지 않고 action을 reducer로 다시 던진다.

**보강**: ⭕ 정확

핵심 두 개 모두 잡음. 한 줄 정리:

| Effect | 의미 | 사용 시점 |
|---|---|---|
| `.send(action)` | "다음 액션을 즉시 발송" — 동기, async 작업 X | UI 입력을 delegate로 단순 전달 / 후속 액션이 결정되어 있는 경우 |
| `.run { send in ... }` | "async 작업 시작, 완료 시 send로 결과 액션 발송" | 네트워크 호출 / 파일 IO / 타이머 / 외부 세계와의 통신 |
| `.none` | "아무것도 안 함" | 후속 작업이 필요 없는 경우 |

추가 강조: `.run` 안에서 결과를 다시 `send(...)`로 던진다는 점이 **단방향 흐름의 핵심**.



---

### Q2. `[questionRepository]` 캡처 리스트가 왜 필요한가?
없으면 어떻게 되나?

힌트: closure가 캡처하는 것 + Sendable + Reducer는 struct

**본인 답**:

캡쳐하지 않으면 self 자체를 가지고 가고 retain count가 증가하게 되며 Sendable하지 않을 수 있음.

**보강**: △ 핵심 잡음, 표현 한 군데 보정

**잡은 두 가지 정확** ✅:
- "self 자체를 가지고 감" — 명시 안 하면 클로저가 Reducer struct의 self를 통째로 캡처
- "Sendable하지 않을 수 있음" — 핵심 정확

**보정 필요**: "retain count가 증가" 표현
- Swift **struct는 값 타입**이라 ARC retain count가 직접 적용 안 됨
- 다만 struct 안의 class 프로퍼티(예: questionRepository가 class라면)는 retain 됨
- 더 정확: "self 캡처는 retain 문제보단 **Sendable 위반 + 의도치 않은 캡처**가 본질"

**정확한 메커니즘 3가지**:

1. **명시성**: `[questionRepository]` 적으면 "이 클로저가 무엇을 캡처하는지 한눈에 보임". 코드 리뷰/디버깅 유리.
2. **Sendable 안전성**: Swift 6에서 `.run` 클로저는 `@Sendable`이어야 함. self를 통째 캡처 = struct 안의 모든 프로퍼티가 다 Sendable이어야 함. 명시 캡처로 필요한 것(Sendable한 의존성)만 가져옴.
3. **Reducer는 잠시 살았다 사라지는 struct**: Reducer 인스턴스는 매 액션마다 컴파일러가 short-lived하게 다룸. 클로저가 self 통째를 캡처하면 self 수명 문제 복잡. 의존성만 명시 캡처 = 클로저가 자기 데이터를 직접 들고 다님.

**한 줄 보정**: "**retain count 증가가 핵심이 아니라 Sendable 위반 + 의도 명시**가 진짜 이유. 클로저가 무엇을 들고 가는지 한눈에 보이게 + 컴파일러가 동시성 안전을 검증할 수 있게."



---

### Q3. `guard state.canSubmit, !state.isSubmitting else { return .none }` — 가드 두 개의 의미는?
`!state.isSubmitting`을 안 체크하면 어떤 버그가 발생하나?

힌트: 사용자가 빠르게 두 번 탭

**본인 답**:

isSubmitting을 체크하지 않으면 사용자가 빠르게 두 번 탭하면 요청을 두번보낼 수 있음

**보강**: ⭕ 정확

더블 탭 시나리오 정확히 짚음. 보너스로 짚어둘 한 가지:

**두 가드는 다른 축**:
- `state.canSubmit` — **데이터 유효성** (텍스트 비어있나)
- `!state.isSubmitting` — **동시성 보호** (이미 요청 중인가)

두 axis가 다름. 둘 중 하나만 있으면:
- canSubmit만 있으면: 빈 텍스트 막지만 중복 요청 가능
- isSubmitting만 있으면: 빈 텍스트로도 요청 시도 가능 (서버에서 거절되겠지만 트래픽 낭비)

**한 줄**: "가드는 항상 **'무엇을 막는지'** 축을 분리해서 생각. 유효성과 동시성은 별개."


---

### Q4. `submitResponse`라는 Action이 왜 따로 있어야 하나?
submitTapped 안에서 결과를 받아 바로 처리하면 안 되나?

힌트: Reducer는 순수 함수. async 작업의 결과는 어떻게 돌려받아야 하나?

**본인 답**:

reducer는 순수함수이기에 async 작업 결과는 단방향으로 이루어져야함 action -> reducer -> state -> action 의 한 방향으로 진행되어야 한다.

**보강**: ⭕ 정확

TCA 핵심 원리(단방향)를 정확히 짚음.

**한 발 더 — 만약 submitTapped 안에서 직접 await 하면?**

```swift
// ❌ 가설 (실제로 컴파일 안 됨 — Reduce 클로저는 async가 아니므로)
case .submitTapped:
    let result = try await questionRepository.createCustomQuestion(...)  // ⚠
    state.isSubmitting = false
    state.savedQuestion = result
    return .none
```

문제들:
1. **Reduce 클로저는 async가 아님** — Swift 타입 시스템 차원에서 await 못 적음
2. **Reducer 비순수성** — 외부 시간/서버 응답에 의존 → 테스트 불가능 (같은 입력에 다른 출력)
3. **state 동결** — await 동안 Reducer가 안 끝남 → 다른 액션이 들어와도 처리 못 함 → UI freeze

**Reducer를 "순간적인 변환 함수"로 유지하기 위해 외부 작업은 Effect로 격리**. 본인이 잡은 그대로.


---

### Q5. `submitTapped` → `submitResponse(.success)` → `delegate(.questionSubmitted)` 3단 흐름
왜 이 모양인가? submit 성공하자마자 바로 delegate를 보내면 안 되나?

힌트: State 갱신과 delegate 발송이 같은 곳에서 일어나면 무슨 문제?

**본인 답**:

State갱신과 delegate 발송이 같은 곳에서 일어나게 되면 성공여부에 따라 성공값 실패값이 같은 곳에서 처리될 수 있음

**보강**: △ 절반 맞음, 더 깊은 이유 보강

본인 답("성공/실패 분기")도 맞지만 3단 흐름의 **더 결정적인 이유 3가지**가 따로 있음.

#### 이유 1 (가장 결정적) — submitTapped에선 결과를 아직 모름

```swift
case .submitTapped:
    state.isSubmitting = true
    // ← 이 시점에 question, heartsRemaining이 없음!
    //   네트워크 응답이 아직 안 왔으니까.
    return .run { send in ... }
```

`delegate(.questionSubmitted(Question, heartsRemaining: Int))`의 페이로드 두 개 — 서버 응답을
받아야 알 수 있는 값들. **submitTapped 시점엔 아직 모름**. 그래서 결과를 받는 별도 단계
(`submitResponse(.success)`)가 필요한 거고, 거기서야 delegate에 페이로드 채워 보낼 수 있음.

#### 이유 2 — UI 로딩 표시를 위한 즉시 state 갱신

```swift
case .submitTapped:
    state.isSubmitting = true   // ← 1단계: 즉시 로딩 인디케이터 켜기
    return .run { ... }
```

이 한 줄 갱신 후 Reducer가 즉시 끝남 → View가 다시 그려짐 → 로딩 스피너 표시.
그 다음에 async 작업이 진행. 만약 한 곳에 다 묶었다면:
- submitTapped 한 번에 isSubmitting + 결과까지 처리 → 사용자는 **로딩 인디케이터를 못 봄**
  (이미 끝나 있음)
- 사용자 입장에선 "버튼 눌렀는데 잠시 멈춘 듯한 느낌"

**state 갱신은 단계마다 일어나야 사용자에게 진행 상황이 보임**.

#### 이유 3 — 책임 분리 (state 갱신 vs 외부 신호)

```swift
case .submitResponse(.success(let result)):
    state.isSubmitting = false                                    // ← 내부 정리
    return .send(.delegate(.questionSubmitted(result.question,
                                              heartsRemaining: result.heartsRemaining)))  // ← 외부 신호
```

이 두 줄이 의미적으로 다른 일:
- `state.isSubmitting = false` — **이 화면 내부 사정**. UI 잠금 해제
- `.delegate(...)` — **부모에게 보내는 외부 신호**. 화면 닫기/다음 화면 전환 결정은 부모가 함

이 둘을 submitTapped에 묶으면 **자식이 외부 신호와 내부 갱신을 동시에 책임지게 됨**.
분리해서:
- submitTapped: state 갱신 (로딩 시작) + Effect 발사
- submitResponse: state 갱신 (로딩 해제) + delegate (외부 신호)

**각 단계가 자기 책임만 짊**.

#### 정리

| 이유 | 한 줄 |
|---|---|
| ① 페이로드 미존재 | submitTapped 시점엔 question/heartsRemaining 모름 — async 결과 필요 |
| ② UI 단계별 표시 | 로딩 스피너 → 결과 처리, 두 단계로 분리해야 사용자 인지 가능 |
| ③ 책임 분리 | 내부 state 갱신 vs 외부 delegate는 다른 책임. 단계마다 한 가지씩 |
| (본인 답) 성공/실패 분기 | submitResponse가 Result로 받으니 .success/.failure가 자연스럽게 갈라짐 |

본인 답은 ④에 해당. 더 결정적인 ①·②·③을 추가하면 완성.

**한 줄 격언**: "**비동기 작업은 시작·진행·종료 3단계가 있고, 각 단계마다 state 갱신 +
다음 단계 신호가 다름**. 한 곳에 묶으면 단계가 사라지고, UI는 멈춘 듯 보이고, 책임이 섞임."



---

## 학습 체크리스트 — 답안

다음 파일(HomeFeature)로 넘어가기 전 머리에 박혔는지 확인.

### ✅ State에 저장 프로퍼티 vs computed property 구분 (`canSubmit`이 왜 computed인지)

- **저장 프로퍼티**: 외부 입력으로 직접 받거나 Reducer가 명시적으로 갱신하는 값
  → `questionText`, `isSubmitting`, `appError`
- **computed property**: 다른 저장 프로퍼티에서 **항상 도출 가능한 값**
  → `canSubmit = !questionText.trimmed.isEmpty`
- **canSubmit을 저장하면 안 되는 이유**: 같은 진실이 두 곳에 생김 (questionText와 canSubmit)
  → 동기화 버그 위험 (텍스트 바꿨는데 canSubmit 갱신 잊으면 어긋남)
- **원칙**: **Single Source of Truth** — 같은 정보를 두 군데 저장하지 말 것.
  derived 값은 매번 계산.

### ✅ `@Dependency`의 역할 (KeyPath로 DI 시스템에서 꺼냄)

- TCA의 DI 매크로. KeyPath(`\.questionRepository`)로 `DependencyValues`에서 객체 꺼냄
- 등록 위치: **`AppDependencies.swift`** — 키 정의 + `makeQuestionRepository()` 팩토리 연결
- Reducer가 **직접 만들지 않고** 시스템에서 받음 → 결합도 낮음
- 테스트 시 `withDependencies { $0.questionRepository = MockX() } operation: { ... }`로 갈아끼움
  → Reducer 코드는 한 줄도 안 바뀌고 가짜 응답으로 테스트 가능

### ✅ `.run { send in ... }` Effect의 사용법

- **async 작업을 시작하는 Effect**
- 클로저 타입: `@Sendable @escaping (Send<Action>) async throws -> Void`
- 내부에서 `await` 사용 가능 (네트워크/파일/타이머 호출)
- 결과는 `await send(newAction)` 으로 Reducer에 되돌려보냄
- capture list (`[questionRepository]`)로 의존성 명시 캡처

### ✅ async 작업 결과를 `await send(...)`로 새 Action 발송하는 패턴

- `send` 자체가 async 함수 — actor 경계를 안전하게 넘기 위해
- 결과를 새 Action으로 던지면 **Reducer가 다시 호출됨** → 거기서 state 갱신
- **단방향 흐름의 핵심**: `Action → Reducer → State → Action`
- Reducer는 직접 await 하지 않음. async 작업은 Effect 안으로 격리.

### ✅ `Result<Success, Failure>` 페이로드로 성공/실패 한 Action에 담는 패턴

- 성공과 실패 두 경우를 **한 Action case**로 묶음: `submitResponse(Result<SubmitSuccess, AppError>)`
- Reducer에서 `.success(let data)` / `.failure(let error)` 패턴 매칭으로 자연스럽게 분기
- **장점**: Action enum이 폭발적으로 늘어나는 걸 막음
  (submitSuccess / submitFailure 두 케이스 따로 안 만들어도 됨)
- 페이로드 타입은 `Equatable + Sendable` 필수

### ✅ 중복 호출 방지 가드 (`!isSubmitting`)

- **동시성 보호** — 더블탭/빠른 연속 입력에서 동일 요청 중복 발사 방지
- `state.canSubmit` (데이터 유효성)과 **다른 축**임:
  - canSubmit → 빈 텍스트 막기
  - !isSubmitting → 진행 중 요청 막기
- 동시 요청 막는 패턴: 시작 시 플래그 켜고 → 응답 도착 시 끄기
  ```
  submitTapped → state.isSubmitting = true → Effect 발사
  submitResponse → state.isSubmitting = false
  ```

### ✅ capture list `[questionRepository]`의 의미

- 명시 안 하면 클로저가 **self(Reducer struct) 통째**를 캡처
- 진짜 문제: **Sendable 위반 가능성 + 의도치 않은 캡처** (retain count 아님 — struct는 값 타입)
- 명시 캡처의 세 가지 이득:
  1. **명시성**: 클로저가 무엇을 들고 가는지 한눈에 보임
  2. **Sendable 안전**: Swift 6에서 `.run` 클로저는 `@Sendable`이어야 함. 필요한 것만 캡처해야 위반 방지
  3. **수명 관리**: 클로저가 부모(Reducer)보다 오래 살 수 있음. 의존성을 직접 들고 감

### ✅ Reducer는 순수 함수, 외부 세계는 Effect로 격리

- **Reducer 시그니처**: `(inout State, Action) -> Effect<Action>` — 순수 변환
- **순수**의 의미: 같은 입력에 항상 같은 출력. 외부 시간/네트워크/파일에 의존 X
- 네트워크/파일/타이머/푸시/UI 알림 같은 **외부 세계와의 통신은 모두 Effect로 격리**
- 이게 보장하는 것:
  - **테스트 가능성**: TestStore로 Action 시퀀스 결정론적 검증
  - **시간여행 디버깅**: Action 로그를 재생하면 같은 State 도달
  - **단방향 흐름**: 모든 상태 변화의 원인이 Action 하나로 환원됨

### 한 줄 종합

> "TCA Reducer = **State 변환 규칙(순수 함수) + 외부 작업 명세(Effect)**.
>  의존성은 시스템에서 받고, derived 값은 계산하고, 동시성은 플래그로 막고,
>  결과는 항상 새 Action으로 되돌아온다."

---

## 5개 자문 종합 평가

| Q | 평가 | 핵심 |
|---|---|---|
| Q1 | ⭕ 정확 | `.run` = async work / `.send` = 즉시 다음 액션 |
| Q2 | △ 표현 보정 | "self 캡처"·"Sendable" 핵심 ✅ / "retain count"는 struct에 직접 적용 X |
| Q3 | ⭕ 정확 | 더블탭 중복 요청 정확. 보너스: 두 가드는 유효성/동시성 다른 축 |
| Q4 | ⭕ 정확 | 단방향 흐름 원리 정확 |
| Q5 | △ 절반 | 본인 답(성공/실패)도 맞지만 더 깊은 3가지(페이로드/UI 단계/책임 분리)가 있음 |

전반적으로 **TCA의 단방향 흐름 원리를 잘 잡음**. Q1·Q3·Q4가 정확한 게 좋은 신호 —
Reducer가 어떻게 작동하는지 모델이 박혔다는 뜻. Q2·Q5만 한 번 더 다듬으면 완성.

---

## 다음 단계

이 파일 다 읽고 5개 자문에 답을 메모하면, 다음은:
- **`HomeFeature.swift`** (327줄) — 가장 큰 Reducer. 여러 Action·Effect·child feature 합성. **`Scope`, `ifLet` 같은 reducer composition 도구**가 처음 등장.
