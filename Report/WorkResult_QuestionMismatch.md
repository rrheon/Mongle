# 작업 결과 보고

## 작업 일자
2026-03-21

---

## Issue 1: HomeView와 HistoryView 질문 불일치

### 원인
`HistoryFeature`의 `goToToday` 액션이 `selectedDate`만 오늘로 업데이트하고 `selectedItem`은 업데이트하지 않아 발생.

예: 사용자가 3/19를 선택(selectedItem = 3/19 질문) → "오늘로 이동" 탭 → selectedDate = 3/21으로 변경되지만 selectedItem은 3/19 상태 유지 → 날짜 라벨은 "3월 21일"이지만 질문 카드는 3/19 질문을 표시.

추가로 `historyLoaded` 액션도 오늘 항목이 없을 때 `selectedItem`을 nil로 초기화하지 않아 스테일 데이터가 남아있는 문제도 있었음.

### 수정 내용
**파일**: `MongleFeatures/.../History/HistoryFeature.swift`

1. `goToToday` 액션에 `selectedItem` 업데이트 추가:
```swift
case .goToToday:
    state.currentMonth = Date()
    state.selectedDate = Date()
    state.selectedItem = state.historyItems[Calendar.current.startOfDay(for: Date())]
    return .none
```

2. `historyLoaded` 액션에서 `if let` 제거 → 항목이 없으면 nil로 초기화:
```swift
case .historyLoaded(let items):
    state.historyItems = items
    state.isLoading = false
    state.selectedItem = items[Calendar.current.startOfDay(for: state.selectedDate)]
    return .none
```

---

## Issue 2: HistoryView에서 3333 유저의 허위 기록

### 원인
서버의 `getQuestionHistory`에서 답변을 가져올 때 날짜 필터 없이 `question.answers`를 조회함. `Answer`는 전역 `Question.id`에 연결되어 있어서, 같은 질문이 다른 날짜나 다른 가족에서 사용되는 경우 다른 날 작성된 답변이 현재 DailyQuestion의 답변 목록에 포함되는 문제.

### 수정 내용
**파일**: `FamTreeServer/src/services/QuestionService.ts`

`getQuestionHistory`의 answers 처리 부분에 KST 기준 날짜 범위 필터 추가:

```typescript
// 해당 DailyQuestion의 KST 날짜 범위 내에 작성된 답변만 포함
const kstDayStart = new Date(dq.date.getTime() - 9 * 60 * 60 * 1000);
const kstDayEnd = new Date(dq.date.getTime() + 15 * 60 * 60 * 1000);
const answers = dq.question.answers.filter(
  (a) => a.createdAt >= kstDayStart && a.createdAt < kstDayEnd
);
```

날짜 범위 계산 근거:
- 서버의 `getToday()`는 KST 날짜를 UTC 자정으로 저장 (예: KST 3/21 → `2026-03-21T00:00:00Z`)
- KST 3/21의 실제 UTC 범위: `[2026-03-20T15:00:00Z, 2026-03-21T15:00:00Z)`
- 따라서: `dq.date - 9시간` ~ `dq.date + 15시간` 이 KST 하루를 커버

---

## 빌드 확인
- 서버: `npm run build` 성공
- iOS: HistoryFeature.swift 수정 완료 (컴파일 오류 없음)
