# 버그 수정 결과 보고

## 1. 데일리 접속 하트 팝업 — GroupSelect에서 제거

### 원인
`RootView.swift`의 하트 팝업 overlay가 `appState`와 무관하게 항상 표시됨.
`loadDataResponse(.success)` 처리 시 `showHeartGrantedPopup = true`로 설정되는데,
이 시점에 `appState`가 `.groupSelection`(GroupSelect 화면)이어도 팝업이 뜨는 버그.

### 수정 — `RootView.swift`
```swift
// 변경 전
if store.showHeartGrantedPopup {

// 변경 후
if store.showHeartGrantedPopup && store.appState == .authenticated {
```
- `.authenticated`(HomeView가 있는 상태)일 때만 팝업 표시
- GroupSelect 화면(`.groupSelection`)에서는 표시되지 않음
- 각 그룹 진입 시 HomeView에서는 여전히 정상 표시

---

## 2. 질문 날짜 오류 — HomeView / HistoryView 불일치

### 원인 1: HistoryView 캐시가 날짜 변경 시 무효화되지 않음

`Root+Reducer.swift`에서 히스토리 캐시 무효화가 **그룹 변경 시에만** 동작.
날짜가 바뀌어 새 DailyQuestion이 생성되어도 기존 캐시를 그대로 사용하여
HistoryView에서 오늘 날짜 셀의 새 질문이 표시되지 않는 문제.

### 수정 — `Root+Reducer.swift`
```swift
// 변경 전
if state.mainTab?.history.familyId != familyId {
    state.mainTab?.history.historyItems = [:]
    state.mainTab?.history.loadedMonths = []
}

// 변경 후
let today = Calendar.current.startOfDay(for: Date())
let isTodayMissing = state.mainTab?.history.historyItems[today] == nil
if state.mainTab?.history.familyId != familyId || isTodayMissing {
    state.mainTab?.history.historyItems = [:]
    state.mainTab?.history.loadedMonths = []
}
```
- 그룹 변경 시 OR 오늘 날짜 데이터가 캐시에 없을 때 히스토리 재로드
- 날짜가 바뀌면 `loadDataResponse` 호출 시 자동으로 캐시 무효화 → 최신 질문 반영

### 원인 2: `toDailyQuestionResponse`에서 날짜 필터 없이 답변 조회

서버 `QuestionService.ts`의 `toDailyQuestionResponse`에서 `hasMyAnswer` / `familyAnswerCount` 계산 시 날짜 범위 필터가 없었음.
`getHistory`는 KST 날짜 범위로 필터링하는데 `getTodayQuestion`은 그렇지 않아 불일치 발생.
(동일 질문이 다른 날짜에 배정된 경우 다른 날의 답변까지 포함될 수 있음)

### 수정 — `QuestionService.ts`
```typescript
// 변경 전
const answers = await prisma.answer.findMany({
  where: { questionId: dailyQuestion.question.id, userId: { in: memberIds } },
  select: { userId: true },
});

// 변경 후
const kstDayStart = new Date(dailyQuestion.date.getTime() - 9 * 60 * 60 * 1000);
const kstDayEnd = new Date(dailyQuestion.date.getTime() + 15 * 60 * 60 * 1000);
const answers = await prisma.answer.findMany({
  where: {
    questionId: dailyQuestion.question.id,
    userId: { in: memberIds },
    createdAt: { gte: kstDayStart, lt: kstDayEnd },
  },
  select: { userId: true },
});
```
- `getHistory`와 동일한 KST 날짜 범위 필터 적용
- HomeView의 `hasAnsweredToday` / `familyAnswerCount`와 HistoryView의 값이 일관성 있게 유지됨

---

## 수정 파일 목록

| 파일 | 변경 내용 |
|------|-----------|
| `MongleFeatures/.../RootView.swift` | 하트 팝업 `.authenticated` 상태에서만 표시 |
| `MongleFeatures/.../Root+Reducer.swift` | 오늘 날짜 히스토리 없을 때 캐시 무효화 추가 |
| `FamTreeServer/src/services/QuestionService.ts` | `toDailyQuestionResponse`에 KST 날짜 필터 추가 |
