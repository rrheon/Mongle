# 코드 효율성 분석 결과

## 작업 일시
2026-03-19

---

## 문제 분석: HomeView 프로퍼티 과다

**개선 전 HomeView init 파라미터: 12개**

```swift
// Before: 콜백 8개가 낱개로 노출
HomeView(
    topBarState: ...,
    hasCurrentUserAnswered: ...,
    members: ...,
    currentUserName: ...,
    onQuestionTap: { ... },
    onNotificationTap: { ... },
    onHeartsTap: { ... },
    onPeerAnswerTap: { ... },
    onPeerNudgeTap: { ... },
    onMyMonggleTap: { ... },
    onGroupSelected: { ... },
    onNavigateToGroupSelect: { ... }
)
```

---

## 적용 패턴: Actions 구조체 분리

관련 콜백을 단일 `Actions` 구조체로 묶어 View의 책임을 명확히 분리.

```swift
// HomeViewActions: 콜백만 담당
struct HomeViewActions {
    var onQuestionTap: () -> Void = {}
    var onNotificationTap: () -> Void = {}
    var onHeartsTap: () -> Void = {}
    var onPeerAnswerTap: (String) -> Void = { _ in }
    var onPeerNudgeTap: (String) -> Void = { _ in }
    var onMyMonggleTap: () -> Void = {}
    var onGroupSelected: (MongleGroup) -> Void = { _ in }
    var onNavigateToGroupSelect: () -> Void = {}
}

// HomeView: 상태 4개 + 액션 1개 = 5개로 축소
struct HomeView: View {
    let topBarState: HomeTopBarState
    let hasCurrentUserAnswered: Bool
    let members: [(name: String, color: Color, hasAnswered: Bool)]
    var currentUserName: String?
    var actions: HomeViewActions
}
```

**개선 후 파라미터: 5개 (12 → 5, -58%)**

```swift
// After: 명확하게 데이터/액션 분리
HomeView(
    topBarState: ...,
    hasCurrentUserAnswered: ...,
    members: ...,
    currentUserName: ...,
    actions: HomeViewActions(
        onQuestionTap: { ... },
        onNotificationTap: { ... },
        ...
    )
)
```

---

## 변경 파일

| 파일 | 변경 내용 |
|------|-----------|
| `Presentation/Home/HomeView.swift` | `HomeViewActions` 구조체 추가, `HomeView` init 파라미터 12→5개로 축소 |
| `Presentation/MainTab/MainTabView.swift` | `HomeViewActions(...)` 방식으로 호출부 업데이트 |

---

## 전체 프로젝트 적용 가능성 검토

프로젝트 전체 Presentation 레이어의 View를 분석한 결과:

| View | 콜백 수 | 적용 여부 |
|------|---------|-----------|
| `HomeView` | 8개 | ✅ 적용 완료 |
| `MongleSceneView` | 3개 | ⬜ 불필요 (3개 이하는 허용 범위) |
| `MongleView` | 3개 | ⬜ 불필요 |
| `MonglePopupView` | 2개 | ⬜ 불필요 |
| `TopBarView` | 3개 | ⬜ 불필요 |
| 나머지 View들 | 0~1개 | ⬜ 불필요 (TCA Store 기반) |

### 결론

프로젝트의 대다수 View는 TCA의 `StoreOf<Feature>` 단일 파라미터 패턴을 사용하고 있어 **이미 효율적으로 설계**되어 있음.

`HomeView`는 TCA Store 없이 순수 SwiftUI로 작성된 렌더링 전용 컴포넌트로, 유일하게 콜백 과다 문제가 있었음. 나머지 View는 콜백 3개 이하로 별도 Actions 구조체 도입이 오히려 복잡도를 높임.

---

## 패턴 가이드라인 (향후 적용 기준)

> View에 콜백이 **4개 이상** 필요한 경우 `XxxViewActions` 구조체를 분리하여 관리할 것.

```swift
// 적용 기준
struct SomeViewActions {
    var onFoo: () -> Void = {}
    var onBar: (T) -> Void = { _ in }
    // ...
}

struct SomeView: View {
    // 상태 데이터
    let state: SomeViewState
    // 액션 묶음
    var actions: SomeViewActions
}
```
