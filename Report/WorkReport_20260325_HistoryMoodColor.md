# 작업 보고서: HistoryView 몽글 색상 수정

**날짜**: 2026-03-25

---

## 작업 내용

### 1. 문제 원인 분석

**문제 1**: 답변 수정 시 HistoryView의 몽글 캐릭터 색상이 변경되지 않음
**문제 2**: HistoryView의 답변 카드에서 표시되는 몽글 색상이 실제 답변 시 선택한 색상과 다를 수 있음

**근본 원인**:
- 서버 `Answer` 테이블에 `moodId` 컬럼이 없어, 답변별 색상이 저장되지 않았음
- `updateAnswer` API가 `moodId`를 받지 않아 `FamilyMembership.colorId`가 업데이트되지 않았음
- iOS `answerRepository.update`가 `moodId`를 전달하지 않았음
- iOS TabView 특성상 탭 전환 시 `onAppear`가 재실행되지 않아 캐시 무효화 후 reload가 보장되지 않았음

---

## 변경 내역

### 서버 변경

#### `prisma/schema.prisma`
- `Answer` 모델에 `moodId String? @map("mood_id")` 컬럼 추가
- **적용 방법**: `prisma db push` 실행 필요

#### `src/models/index.ts`
- `UpdateAnswerRequest`에 `moodId?: string` 필드 추가

#### `src/services/AnswerService.ts`
- `createAnswer`: `answer.create`에 `moodId: data.moodId` 추가 → 답변 생성 시 DB에 moodId 저장
- `updateAnswer`:
  - `answer.update`에 `moodId: data.moodId` 추가
  - 수정 시 `FamilyMembership.colorId`도 업데이트 (즉시 반영용)
- `toAnswerResponse`: 우선순위 변경
  - 변경 전: `colorMap.get(userId) ?? user.moodId` (사용자의 현재 moodId)
  - 변경 후: `answer.moodId ?? colorMap.get(userId) ?? user.moodId` (**답변 자체의 moodId 우선**)

#### `src/services/QuestionService.ts`
- `getQuestionHistory`의 `answerSummaries`: `moodId` 소스 변경
  - 변경 전: `colorMap.get(userId)` (사용자 현재 색상)
  - 변경 후: `a.moodId ?? colorMap.get(userId)` (**답변별 색상 우선, 없으면 사용자 현재 색상**)
- 참고: `prisma generate` 실행 전까지 `a.moodId`는 `(a as any).moodId`로 접근

### iOS 변경

#### `MongleData/.../APIEndpoint.swift`
- `AnswerEndpoint.update` case에 `moodId: String?` 파라미터 추가
- `body` 계산 시 `moodId`가 있으면 요청 body에 포함

#### `Domain/.../AnswerRepositoryProtocol.swift`
- `update(_ answer: Answer, moodId: String?) async throws -> Answer` 시그니처 변경
- 하위 호환을 위해 `update(_ answer: Answer)` 기본 구현 추가 (moodId: nil 전달)

#### `MongleData/.../AnswerRepository.swift`
- `update(_ answer:, moodId:)` 구현 - `AnswerEndpoint.update`에 moodId 전달

#### `MongleFeatures/.../QuestionDetailFeature.swift`
- `editCostPopup.confirmed` 핸들러에서 `selectedMoodIndex`로 `editMoodId` 계산 후
  `answerRepository.update(updated, moodId: editMoodId)` 호출

#### `MongleFeatures/.../HistoryFeature.swift`
- `Action`에 `forceReload` case 추가
- `forceReload` 핸들러: `historyItems = [:]`, `loadedMonths = []` 초기화 후 서버에서 재로드
- `onAppear`: 내부 로직을 `forceReload`로 위임 → 코드 중복 제거

#### `MongleFeatures/.../MainTab+Reducer.swift`
- `answerSubmitted` 핸들러: `state.history.historyItems = [:]` 직접 조작 → `.send(.history(.forceReload))`로 교체
- `answerEdited` 핸들러: 동일하게 `forceReload` 사용

---

## 데이터 흐름 (수정 후)

```
사용자가 답변 수정 시 "행복(😊)" 선택
    ↓
iOS: answerRepository.update(answer, moodId: "happy")
    ↓
서버 PUT /answers/:id { content, moodId: "happy" }
    ↓
DB: answers.mood_id = "happy"
DB: family_membership.color_id = "happy"
    ↓
iOS: answerEdited delegate → MainTab.forceReload
    ↓
서버 GET /questions/history
    ↓
각 answer에서 answer.moodId("happy") 반환
    ↓
HistoryView: colorIndex = 0 (yellow) → MongleMonggle 노란색 표시
```

---

## 서버 적용 방법

```bash
cd /Users/yong/Desktop/FamTreeServer
npx prisma db push        # DB 스키마 업데이트
npx prisma generate       # 타입 재생성 (TypeScript 타입 오류 해소)
```

---

## 기존 데이터 호환성

- 기존 답변들은 `answers.mood_id = null`로 저장됨
- `toAnswerResponse`에서 `answer.moodId ?? colorMap.get(userId) ?? user.moodId` 로직으로
  기존 답변은 자동으로 사용자의 현재 `colorId`를 폴백으로 사용 → **하위 호환 유지**
