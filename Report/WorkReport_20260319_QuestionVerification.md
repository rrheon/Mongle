# 조사 보고 - HomeView vs HistoryView 질문 일치 여부

## 결론 요약

**HomeView와 HistoryView는 같은 날짜에 대해 동일한 질문 내용을 보여줍니다.**

두 뷰 모두 DB의 동일한 `DailyQuestion` 레코드를 참조하므로 질문 텍스트는 같습니다.

---

## 데이터 흐름 비교

### HomeView — 오늘의 질문

```
HomeFeature.onAppear
  → delegate(.requestRefresh)
  → Root+Reducer.refreshHomeData
  → QuestionRepository.getTodayQuestion()
  → GET /questions/today
  → QuestionService.getTodayQuestion()
      → DailyQuestion(familyId, date=KST today) 조회
      → 없으면 랜덤 배정(assignQuestionToFamily)
      → toDailyQuestionResponse() 반환
  → QuestionMapper.toDomain(dto)
      → Question.id = dto.question.id (Question 테이블 ID)
      → Question.dailyQuestionId = dto.id (DailyQuestion 테이블 ID)
```

### HistoryView — 날짜별 질문

```
HistoryFeature.onAppear (historyItems 비어있을 때만)
  → QuestionRepository.getHistory(page: 1, limit: 60)
  → GET /questions/history
  → QuestionService.getQuestionHistory()
      → DailyQuestion(familyId, date ≤ KST today) 전체 조회
      → 각 DailyQuestion의 question 포함
  → QuestionMapper.toDomain(dto) (동일한 매퍼 사용)
```

---

## 동일성 확인

| 항목 | HomeView | HistoryView | 일치 여부 |
|------|----------|-------------|-----------|
| 질문 내용 (content) | `dq.question.content` | `dq.question.content` | ✅ 동일 |
| 질문 ID (Question.id) | `dto.question.id` | `dto.question.id` | ✅ 동일 |
| DailyQuestion ID | `dto.id` | `dto.id` | ✅ 동일 |
| 날짜 기준 | KST (`getToday()`) | KST (`getToday()`) | ✅ 동일 |
| 답변 수 집계 | `User.familyId` 기준 멤버 | `FamilyMembership` 기준 멤버 | ⚠️ 미세 차이 가능 |

---

## 발견된 차이점 (질문 내용에는 영향 없음)

### 1. 답변 수 집계 방식 불일치

**HomeView** (`toDailyQuestionResponse`):
```typescript
const familyMembers = await prisma.user.findMany({
  where: { familyId },  // User.familyId 기준 (현재 활성 멤버만)
});
```

**HistoryView** (`getQuestionHistory`):
```typescript
const familyMemberships = await prisma.familyMembership.findMany({
  where: { familyId: user.familyId },  // FamilyMembership 기준 (전/현 멤버 포함)
});
```

→ 그룹을 탈퇴한 멤버가 있으면 `familyAnswerCount`가 다를 수 있음. 실제 서비스에서 멤버 탈퇴 기능이 없다면 무관.

### 2. `getQuestionByDate` 미수정

`QuestionService.getQuestionByDate()`는 아직 UTC 기준 날짜를 사용:
```typescript
const date = new Date(dateStr);
date.setHours(0, 0, 0, 0);  // UTC 자정 (KST 미적용)
```
→ 현재 iOS에서 이 엔드포인트를 호출하는 곳은 없음. 문제 없음.

### 3. 스킵(새로고침) 후 캐시 불일치 가능성

질문을 스킵하면 `DailyQuestion.questionId`가 변경됨. HomeView는 즉시 새 질문 반영되지만, HistoryView는 `historyItems` 캐시가 남아있어 구 질문이 표시될 수 있음.

→ 현재 `skipQuestionResponse` 처리 시 히스토리 캐시 초기화가 없음. 단, 스킵 후 답변이 없는 상태이므로 HistoryView에 표시되는 경우가 드뭄.

---

## 최종 판단

**질문 내용 자체는 동일합니다.** 이전 세션에서 수정한 KST 기준 날짜 처리 덕분에 날짜 불일치 문제도 해소되었습니다.

만약 여전히 두 뷰에서 다른 질문이 보인다면, 원인은 **히스토리 캐시**일 가능성이 높습니다:
- 앱을 완전히 재시작하거나 그룹 전환 후 다시 확인하면 일치할 것
- 그룹 전환 시 히스토리 캐시 초기화는 이미 이전 세션에서 적용됨
