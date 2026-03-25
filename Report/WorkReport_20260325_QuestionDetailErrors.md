# 작업 보고서 - 마음남기기 화면 에러 2건 수정

**날짜:** 2026-03-25

---

## 에러 1: iOS forEach missing element

### 증상
```
A "forEach" received an action for a missing element.
Action: MainTabFeature.Path.Action.questionDetail(.dismissErrorTapped)
```

### 원인
`mongleErrorToast`는 `.task(id: error)` 모디파이어로 3초 타이머 후 `onDismiss()` 콜백을 실행합니다.

재현 흐름:
1. `QuestionDetailView` 진입 → `onAppear` → 서버 500 에러 발생 → `appError` 설정 → 토스트 3초 타이머 시작
2. 유저가 3초 내에 뒤로가기 → `closeTapped` → `delegate(.closed)` → `path.removeLast()`로 element 제거
3. 3초 후 타이머 완료 → `dismissErrorTapped` 전송 → 이미 제거된 element에 action 도달 → 경고 발생

### 수정 내용
**파일:** `QuestionDetailFeature.swift`

`closeTapped` 처리 시 `state.appError = nil` 먼저 설정:
```swift
case .closeTapped:
    state.appError = nil  // 추가: 인플라이트 토스트 타이머 취소
    return .send(.delegate(.closed))
```

`appError`가 nil로 변경되면 `.task(id: error)`가 취소되어 `Task.sleep`에 `CancellationError`가 던져지고 `onDismiss()`가 호출되지 않음 → `dismissErrorTapped` 전송 없음.

---

## 에러 2: 서버 answers.mood_id 컬럼 없음

### 증상
```
serverError(statusCode: 500)
The column `answers.mood_id` does not exist in the current database.
```

### 원인
`prisma/schema.prisma`의 `Answer` 모델에 `moodId String? @map("mood_id")`가 정의되어 있으나 `prisma db push`가 실행되지 않아 실제 DB에 컬럼이 없는 상태였습니다.

### 수정 내용
```bash
cd /Users/yong/Desktop/FamTreeServer
npm run db:push
# → Your database is now in sync with your Prisma schema.
```

`answers` 테이블에 `mood_id` 컬럼이 추가되어 `QuestionService.ts`의 `prisma.dailyQuestion.findMany()` 정상 실행됩니다.

---

## 수정 파일

| 파일 | 변경 내용 |
|------|----------|
| `MongleFeatures/.../QuestionDetailFeature.swift` | `closeTapped`에서 `state.appError = nil` 추가 |
| DB (`answers` 테이블) | `mood_id` 컬럼 추가 (`prisma db push`) |
