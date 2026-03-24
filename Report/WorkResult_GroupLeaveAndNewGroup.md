# 작업 결과 보고

## 작업 일자
2026-03-21

---

## Issue 1: 그룹나가기 시 ifLet 경고

### 원인
`ProfileEditFeature`에서 `.supportScreen(.presented(.delegate(.groupLeft)))` 처리 시,
`state.supportScreen = nil`로 먼저 설정한 뒤 `.delegate(.groupLeft)`를 상위로 전달하는 순서가 문제.

`state.supportScreen = nil`로 설정 후 내비게이션 팝(pop) 애니메이션 중 SwiftUI가
`SupportScreenView.onAppear`를 재호출 → `supportScreen(.presented(.onAppear))` 액션 도착 →
이미 `state.supportScreen == nil`이라 TCA `ifLet` 경고 발생.

### 수정 내용

**파일 1**: `MongleFeatures/.../Profile/ProfileEditFeature.swift`

`groupLeft` 핸들러에서 `state.supportScreen = nil` 제거:
```swift
// Before
case .supportScreen(.presented(.delegate(.groupLeft))):
    state.supportScreen = nil   // ← 제거
    return .send(.delegate(.groupLeft))

// After
case .supportScreen(.presented(.delegate(.groupLeft))):
    return .send(.delegate(.groupLeft))
```

**파일 2**: `MongleFeatures/.../Root/Ext/Root+Reducer.swift`

`navigateToGroupSelect` 핸들러에서 프로필 modal 상태를 일괄 초기화
(화면 전환 후 정리 → 애니메이션 중 onAppear 문제 없음):
```swift
case .mainTab(.delegate(.navigateToGroupSelect(let fromGroupLeft))):
    // ... 기존 코드 ...
    // 프로필 modal 상태 초기화 (그룹나가기 시 남아있는 supportScreen 정리)
    state.mainTab?.profile.supportScreen = nil
    state.mainTab?.profile.mongleCardEdit = nil
    state.mainTab?.profile.accountManagement = nil
    state.appState = .groupSelection
```

---

## Issue 2: 새 그룹 생성 후 HomeView로 시작

### 원인
그룹 선택 화면(GroupSelect)에서 새 그룹을 만들고 돌아올 때,
`mainTab` 상태가 유지되어 이전에 보고 있던 탭(예: Profile)이 그대로 표시됨.

### 수정 내용

**파일**: `MongleFeatures/.../Root/Ext/Root+Reducer.swift`

`loadDataResponse(.success)` 핸들러에서
GroupSelect → Authenticated 전환 시 selectedTab을 `.home`으로 리셋:

```swift
let wasOnGroupSelect = state.appState == .groupSelection
let newAppState: RootFeature.State.AppState = ...
// 그룹 선택 화면에서 인증 완료 전환 시 HomeTab으로 리셋
if wasOnGroupSelect && newAppState == .authenticated {
    state.mainTab?.selectedTab = .home
    state.mainTab?.path.removeAll()
}
state.appState = newAppState
```

`path.removeAll()`도 함께 호출하여 navigation stack도 초기화.
