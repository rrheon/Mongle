# 작업 보고서 - 마음남기기 후 발생하는 버그 2건 수정

**날짜:** 2026-03-25

---

## 버그 1: forEach missing element (answerTextChanged)

### 증상
```
A "forEach" received an action for a missing element.
Action: MainTabFeature.Path.Action.questionDetail(.answerTextChanged)
```
마음남기기 제출 후 발생.

### 원인
`submitAnswerResponse(.success)` 처리 시:
1. `state.isSubmitting = false` → `state.myAnswer = answer` → `delegate(.answerSubmitted)` 전송
2. 부모(MainTabFeature)가 `path.removeLast()` → element 제거
3. NavigationStack dismiss 애니메이션 중 `TextField` binding의 `set` 클로저가 한 번 더 실행됨
4. 이미 제거된 element에 `answerTextChanged` 전송 → 경고

### 수정 내용

**파일:** `QuestionDetailFeature.swift`

1. `submitAnswerResponse(.success)`에서 `state.isSubmitting = false` 제거 — element 제거 직전이므로 reset 불필요
2. `answerTextChanged`에 guard 추가:

```swift
case .answerTextChanged(let text):
    guard !state.isSubmitting else { return .none }  // 추가
    state.answerText = text
    state.appError = nil
    return .none
```

제출 중(`isSubmitting = true`) 상태에서 오는 `answerTextChanged`는 무시되므로 stale action 전송 차단.

---

## 버그 2: 기록 화면 몽글 캐릭터 색상 오염

### 증상
마음남기기 후 기록(History)에서 모든 날짜의 모든 멤버 캐릭터 색상이 방금 선택한 몽글 색상으로 변경됨.

### 원인
**흐름:**
1. `AnswerService.createAnswer` → 답변 저장 + `FamilyMembership.colorId = moodId` 업데이트
2. `MainTabFeature` → `history.forceReload` 호출
3. `QuestionService.getQuestionHistory` → 과거 답변 조회
4. 과거 답변의 `answer.moodId = null` (컬럼이 최근 추가되어 기존 데이터 없음)
5. fallback: `colorMap.get(a.userId)` → 현재 사용자의 **방금 업데이트된** `colorId` 반환
6. 결과: 모든 과거 답변이 오늘 선택한 색상으로 표시됨

**문제 코드 (`QuestionService.ts`)**:
```typescript
// 수정 전
moodId: (a as any).moodId ?? colorMap.get(a.userId) ?? null,
//                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
//                            현재 colorId를 fallback으로 사용 → 오염 발생
```

### 수정 내용

**파일:** `QuestionService.ts`

```typescript
// 수정 후
moodId: (a as any).moodId ?? null,
```

`colorMap` fallback 제거. 과거 답변에 기록된 `moodId`가 없으면 `null`을 반환하고, iOS 클라이언트의 `colorIndexFromMoodId(null)` → index 2(pink/loved) 기본값으로 표시.

새로 제출되는 답변은 `answer.moodId`가 저장되므로 정확한 색상이 표시됨.

---

## 수정 파일 요약

| 파일 | 수정 내용 |
|------|----------|
| `QuestionDetailFeature.swift` | `isSubmitting` 유지로 stale `answerTextChanged` 차단 |
| `QuestionService.ts` | 히스토리 moodId fallback에서 colorMap 제거 |
