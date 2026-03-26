# 작업 보고서 - SupportScreen 컴파일 오류 수정

**날짜:** 2026-03-26

---

## 수정한 오류

### 1. Root+Reducer.swift:236 - `supportScreen` 멤버 없음

**원인:**
`ProfileEditFeature.State`에 `supportScreen` 프로퍼티가 없는데 logout 케이스에서 `state.mainTab?.profile.supportScreen = nil`을 참조.

**수정:**
해당 줄 제거. `state.mainTab = nil`(238번 줄)이 이후 즉시 실행되어 모든 상태를 초기화하므로 해당 줄은 불필요.

```swift
// 제거된 줄 (Root+Reducer.swift)
state.mainTab?.profile.supportScreen = nil
```

---

### 2. SupportScreenView.swift:19 - switch case 실행문 없음

**원인:**
`SupportScreenView.swift` 파일이 존재하지 않았음. `SupportScreenFeature`도 미구현 상태.

**수정:**
두 파일 신규 생성.

---

## 신규 생성 파일

### SupportScreenFeature.swift
`/MongleFeatures/Sources/MongleFeatures/Presentation/Support/SupportScreenFeature.swift`

- `State.Destination` 열거형: `historyCalendar` 케이스
- `HistoryCalendarFeature`를 `Scope`로 임베드
- delegate `.close` 처리

### SupportScreenView.swift
`/MongleFeatures/Sources/MongleFeatures/Presentation/Support/SupportScreenView.swift`

- `store.destination` 기반 `@ViewBuilder switch`
- `case .historyCalendar:` → `HistoryCalendarView` 렌더링

---

## 참고사항

- `SupportScreenView`는 현재 `ProfileEditFeature`와 미연결 상태 (프레젠테이션 트리거 없음)
- 필요 시 `ProfileEditFeature.State`에 `@Presents var supportScreen: SupportScreenFeature.State?` 추가 및 `ProfileEditView`에 `.navigationDestination(item:)` 연결 필요
