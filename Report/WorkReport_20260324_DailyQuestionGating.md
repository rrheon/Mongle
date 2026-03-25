# 작업 보고서: 다음날 질문 배정 조건 검증 및 구현

**날짜**: 2026-03-24

---

## 작업 개요

Work.md 요청: "그룹별로 모든 참여자가 질문에 답하거나 패스하지 않은 경우 다음날 질문을 받지 않도록 설정되었는지 확인하기"

---

## 검증 결과

**해당 기능이 구현되어 있지 않았음.**

### 기존 스케줄러 동작 (`/src/app.ts`, `startDailyQuestionScheduler`)

- KST 자정(UTC 15:00)에 5분 간격 폴링으로 실행
- 오늘 날짜에 이미 질문이 배정된 가족은 건너뜀 (`if (existing) continue`)
- **전날 완료 여부와 무관하게 모든 가족에 무조건 질문 배정**

### 추가로 확인된 사항

| 항목 | 상태 |
|------|------|
| 개별 답변 기록 (`Answer` 모델) | ✅ 구현됨 |
| 개별 패스 기록 (`FamilyMembership.skippedDate`) | ✅ 구현됨 |
| KST 날짜 경계 기반 답변 필터 | ✅ 구현됨 |
| `ALL_ANSWERED` 알림 타입 (스키마) | ⚠️ 정의만 있고 미사용 |
| **전날 완료 여부 기반 배정 차단** | ❌ 미구현 → **이번에 구현** |

---

## 구현 내용

**변경 파일**: `/Users/yong/Desktop/FamTreeServer/src/app.ts`

스케줄러의 가족별 루프에 전날 완료 여부 검사 로직을 추가했습니다.

### 검사 로직

```
1. 어제 날짜의 DailyQuestion이 존재하는지 확인
   - 없으면 (신규 가족 or 첫 날) → 검사 생략, 정상 배정

2. 어제 DailyQuestion이 있으면:
   a. 해당 가족의 FamilyMembership 전체 조회 (userId, skippedDate)
   b. 어제 질문에 대한 답변자 목록 조회 (KST 날짜 범위 필터 적용)
   c. 각 멤버가 아래 중 하나에 해당하는지 검사:
      - answeredUserIds에 포함됨 (답변 완료)
      - skippedDate === yesterday (패스 완료)
   d. 한 명이라도 미완료면 → 배정 건너뜀 + 로그 출력
```

### KST 날짜 범위 (기존 QuestionService와 동일한 방식)

```
kstDayStart = yesterday - 9h (UTC)
kstDayEnd   = yesterday + 15h (UTC)
```

---

## 동작 예시

| 상황 | 결과 |
|------|------|
| 가족 A: 전원 답변 | ✅ 다음날 질문 배정 |
| 가족 B: 전원 패스 | ✅ 다음날 질문 배정 |
| 가족 C: 일부 답변 + 나머지 패스 | ✅ 다음날 질문 배정 |
| 가족 D: 한 명이라도 미완료 | ❌ 다음날 질문 미배정, 로그: `⏭️ [Scheduler] Skipped family ...` |
| 가족 E: 처음 등록 (어제 질문 없음) | ✅ 다음날 질문 배정 (검사 생략) |

---

## 참고: `getTodayQuestion`의 자동 배정과의 관계

`QuestionService.getTodayQuestion()`에는 오늘 질문이 없으면 즉시 랜덤 배정하는 폴백 로직이 있습니다:

```typescript
if (!dailyQuestion) {
  dailyQuestion = await this.assignQuestionToFamily(user.familyId, today);
}
```

이 폴백은 스케줄러가 배정하지 않은 경우에도 클라이언트 요청 시 즉시 질문을 생성합니다.
**따라서 스케줄러 단의 차단만으로는 완전히 막을 수 없습니다.**

### 권장 추가 조치 (이번 작업 범위 밖)

`QuestionService.getTodayQuestion()`에도 동일한 완료 검사를 추가해야 완전히 차단됩니다:

```typescript
// 전날 미완료 시 오늘 질문 반환 불가 처리 추가 필요
if (!dailyQuestion && !yesterdayCompleted) {
  throw Errors.badRequest('전날 질문에 모든 멤버가 참여해야 새 질문을 받을 수 있습니다.');
}
```

이 처리는 `QuestionService` 수정과 클라이언트 UI 처리(에러 메시지 표시)를 함께 요구하므로 별도 작업으로 진행 권장합니다.
