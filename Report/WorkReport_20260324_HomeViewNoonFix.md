# 작업 보고서 - HomeView 오전 12시 이전 질문 표시 수정 (2026-03-24)

## 작업 배경

HomeView에서 오전 12시(정오) 이전에 오늘의 질문을 가져오고 표시하는 문제 수정.

---

## 원인

`RootFeature.refreshHomeData`에서 시간에 관계없이 항상 `getTodayQuestion()` API를 호출하고 있었음.

서버의 `getTodayQuestion()`은 오늘 질문이 없으면 즉시 생성하므로, 오전에 앱을 열면 그 시점에 질문이 DB에 생성되고 HomeView에도 표시됨.

---

## 수정 내용

**파일**: `MongleFeatures/Sources/MongleFeatures/Presentation/Root/Ext/Root+Reducer.swift`

`refreshHomeData` 실행 시 현재 시각이 오전 12시 이전이면 `getTodayQuestion()` 호출을 건너뛰고 `nil`을 사용:

```swift
// 오전 12시(정오) 이전에는 오늘의 질문을 가져오지 않음
let calendar = Calendar.current
let now = Date()
let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
let todayQuestion: Question? = now >= noon
    ? try await questionRepository.getTodayQuestion()
    : nil
```

`HomeFeature.State.todayQuestion`이 `nil`이 되면 `TopBarView`에서 질문 카드를 렌더링하지 않음:

```swift
// TopBarView (HomeView.swift)
if let question = state.todayQuestion {
    TodayQuestionCard(...)  // nil이면 이 블록이 실행되지 않음
}
```

---

## 동작 흐름

| 시간대 | getTodayQuestion 호출 | HomeView 질문 카드 |
|--------|----------------------|-------------------|
| 오전 12시 이전 | 호출 안 함 | 표시 안 됨 |
| 오후 12시 이후 | 정상 호출 | 표시됨 |

- 오전에는 질문 DB 생성도 없으므로 HistoryView에도 오늘 날짜 기록 없음 (이전 작업에서 클라이언트 필터도 적용됨)
- 오후 12시 이후 앱 갱신(foreground 진입, 수동 refresh 등) 시 자동으로 질문 fetch 및 표시

---

## 수정된 파일

| 파일 | 변경 내용 |
|------|-----------|
| `MongleFeatures/.../Root/Ext/Root+Reducer.swift` | `refreshHomeData`에 정오 이전 질문 fetch 차단 로직 추가 |
