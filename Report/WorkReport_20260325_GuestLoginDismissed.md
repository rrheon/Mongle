# 작업 보고서 - ifLet guestLoginDismissed 경고 수정

**날짜:** 2026-03-25

---

## 증상
```
An "ifLet" at "MongleFeatures/Root+Reducer.swift:469" received a child action when child state was "nil".
Action: RootFeature.Action.mainTab(.home(.guestLoginDismissed))
```

## 원인 분석

**재현 흐름:**
1. 게스트 상태에서 로그인 필요 기능 탭 → `showGuestLoginPrompt = true` → alert 표시
2. "로그인하기" 버튼 탭 → `guestLoginTapped` → HomeFeature: `showGuestLoginPrompt = false` + `delegate(.requestLogin)` 전송
3. Root: `mainTab(.delegate(.requestLogin))` → `showLoginScreen` → **`state.mainTab = nil`**
4. SwiftUI가 `showGuestLoginPrompt = false` 변화를 감지 → alert Binding의 `set` 클로저 실행 → `store.send(.home(.guestLoginDismissed))` 전송
5. `ifLet(\.mainTab, action: \.mainTab)` 실행 → `mainTab = nil` 상태에서 action 도달 → 경고

**문제 코드 (`MainTabView.swift`)**:
```swift
.alert("로그인이 필요해요", isPresented: Binding(
    get: { store.home.showGuestLoginPrompt },
    set: { if !$0 { store.send(.home(.guestLoginDismissed)) } }  // ← 문제
)) { ... }
```

SwiftUI alert Binding의 `set` 클로저는 `showGuestLoginPrompt`가 `false`로 바뀔 때마다 실행됩니다. 유저가 "취소"를 탭할 때뿐 아니라 `guestLoginTapped`가 프로그래밍적으로 값을 변경할 때도 실행됩니다.

## 수정 내용

**파일:** `MainTabView.swift`

```swift
// 수정 전
set: { if !$0 { store.send(.home(.guestLoginDismissed)) } }

// 수정 후
set: { _ in }
```

`Binding.set`을 no-op으로 변경. iOS `.alert`는 스와이프 dismiss가 없으므로 버튼 탭으로만 dismiss됩니다. "취소" 버튼이 이미 명시적으로 `guestLoginDismissed`를 전송하므로 `Binding.set`이 없어도 기능 동작에 영향 없음.
