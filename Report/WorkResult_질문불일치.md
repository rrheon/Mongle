# 작업 결과 보고: 오늘의 질문 불일치 오류

## 발견된 버그 및 수정 내역

### 버그 1: 나만의 질문 등록 시 원자성 결여 (서버)

**파일**: `/Users/yong/Desktop/FamTreeServer/src/services/QuestionService.ts`
**함수**: `createCustomQuestion`

**원인**
`dailyQuestion.update` (오늘의 질문 교체)가 `$transaction` 바깥에 위치해 있어,
질문 생성과 하트 차감은 성공했지만 DailyQuestion 교체는 실패할 수 있었음.
→ DB 상태 불일치로 HomeView와 HistoryView에서 서로 다른 질문이 표시되는 현상 발생 가능.

**수정**
`question.create`, `familyMembership.updateMany`, `dailyQuestion.update` 세 작업을
인터랙티브 `$transaction`으로 묶어 원자적으로 처리.

---

### 버그 2: 특정 날짜 질문 조회 시 타임존 오파싱 (서버)

**파일**: `/Users/yong/Desktop/FamTreeServer/src/services/QuestionService.ts`
**함수**: `getQuestionByDate`

**원인**
`new Date(dateStr)` 파싱 시 서버 로컬 타임존에 의존.
서버가 UTC 환경이 아닐 경우 날짜가 하루 밀려서 DB 조회 실패 → null 반환.
→ HistoryView에서 특정 날짜의 질문이 표시되지 않거나 다른 날짜 질문이 노출되는 현상.

**수정**
`new Date(dateStr + 'T00:00:00.000Z')`로 명시적으로 UTC 자정 파싱.
`getToday()`와 동일한 방식으로 통일.

---

### 버그 3: 일일 질문 스케줄러 타임존 오류 (서버)

**파일**: `/Users/yong/Desktop/FamTreeServer/src/app.ts`
**함수**: `startDailyQuestionScheduler`

**원인**
`new Date().setHours(0,0,0,0)` → 서버 로컬 타임존 기준 자정으로 설정.
KST 자정(UTC 15:00)에 실행되어야 하는 스케줄러가 서버 타임존에 따라 잘못된 시각에 실행되거나
`getToday()`가 반환하는 날짜와 불일치 → 해당 날짜 질문이 배정되지 않아 이전 날 질문이 노출.

**수정**
- `getKstToday()` 헬퍼 함수 추가 (`QuestionService.getToday()`와 동일 로직)
- 실행 조건을 `getUTCHours() !== 15`로 변경 (KST 자정 = UTC 15:00)
- 오늘 날짜 계산을 `setHours(0,0,0,0)` → `getKstToday()`로 교체

---

## 수정 파일 목록

| 파일 | 변경 내용 |
|------|-----------|
| `FamTreeServer/src/services/QuestionService.ts` | createCustomQuestion 트랜잭션 원자화, getQuestionByDate UTC 파싱 |
| `FamTreeServer/src/app.ts` | 스케줄러 KST 기준 수정, getKstToday() 추가 |

## iOS 측 변경사항

없음. iOS 앱은 나만의 질문 제출 후 history 캐시를 올바르게 무효화하고 있어 추가 수정 불필요.
