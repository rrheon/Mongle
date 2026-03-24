# 작업 보고서 - 질문 히스토리 버그 수정 (2026-03-24)

## 작업 배경

`Work.md` 기반 이슈:
- HomeView 질문과 HistoryView 기록 질문 불일치
- 과거 질문이 오늘의 질문으로 표시됨
- 오전 12시 이전에도 오늘의 질문이 HistoryView에 표시됨
- 커스텀 질문 입력 시 HistoryView 반영 및 이후 API fetch 중단 필요

---

## 발견된 버그

### 버그 1: 날짜 파싱 실패 → 과거 질문이 오늘 날짜로 매핑 (핵심 버그)

**위치**: `MongleData/Sources/MongleData/Repositories/QuestionRepository.swift` - `getHistory()`

**원인**: 서버는 `"YYYY-MM-DD"` 형식의 날짜 문자열을 반환하는데, iOS에서 아래 코드로 파싱:

```swift
// 기존 (버그 있음)
let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
let date = formatter.date(from: dto.date + "T00:00:00Z") ?? fallback.date(from: dto.date) ?? Date()
```

- `withFractionalSeconds` 옵션이 설정된 `ISO8601DateFormatter`는 `"2026-03-24T00:00:00Z"` (소수점 없음) 파싱 실패
- fallback `ISO8601DateFormatter`도 날짜만 있는 `"2026-03-24"` 파싱 실패
- 최종 fallback `Date()` (현재 시각) 반환 → **모든 과거 질문이 오늘 날짜로 매핑됨**

이로 인해:
- HomeView의 오늘 질문(`GET /questions/today`) ≠ HistoryView에 "오늘"로 표시되는 질문
- 달력에 과거 날짜 대신 오늘에 점이 모두 몰림

### 버그 2: 오전 12시 이전 오늘의 질문 미필터링

**위치**: `MongleFeatures/.../History/HistoryFeature.swift` - `onAppear`

**원인**: 서버 히스토리 API(`GET /questions?...`)는 오늘을 포함한 모든 날짜의 질문을 반환하지만, 클라이언트에서 시간 기반 필터링 로직이 없었음.

### 버그 3: 커스텀 질문 여부 판별 불가

**원인**: 서버 `QuestionResponse`에 `isCustom` 필드가 없어서 클라이언트에서 일반 질문과 커스텀 질문 구분 불가.

---

## 수정 내용

### 1. 서버: `QuestionResponse`에 `isCustom` 추가

**파일**: `FamTreeServer/src/models/index.ts`
```typescript
export interface QuestionResponse {
  ...
  isCustom: boolean;  // 추가
}
```

**파일**: `FamTreeServer/src/services/QuestionService.ts`
- `toQuestionResponse()` 메서드의 파라미터 타입과 반환값에 `isCustom` 추가
- `toDailyQuestionResponse()` 메서드의 question 타입에 `isCustom: boolean` 포함
- Prisma의 `question: true` include로 이미 필드가 조회되므로 쿼리 변경 불필요

### 2. iOS: `Question` 도메인 모델에 `isCustom` 추가

**파일**: `Domain/Sources/Domain/Entities/Question.swift`
- `public let isCustom: Bool` 프로퍼티 추가
- `init`에 `isCustom: Bool = false` 파라미터 추가 (기존 코드 호환 유지)

**파일**: `MongleData/Sources/MongleData/DTOs/QuestionDTO.swift`
- `QuestionResponseDTO`에 `isCustom: Bool?` 추가 (구버전 서버 응답 호환을 위해 optional)

**파일**: `MongleData/Sources/MongleData/Mappers/QuestionMapper.swift`
- `toDomain(DailyQuestionResponseDTO)` → `isCustom: q.isCustom ?? false` 매핑 추가

### 3. iOS: 날짜 파싱 수정

**파일**: `MongleData/Sources/MongleData/Repositories/QuestionRepository.swift`

```swift
// 수정 후
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"
dateFormatter.timeZone = TimeZone(abbreviation: "UTC")  // 서버가 UTC 자정 기준으로 저장
let date = dateFormatter.date(from: dto.date) ?? Date()
```

서버가 반환하는 `"YYYY-MM-DD"` 형식을 `DateFormatter`로 안정적으로 파싱.

### 4. iOS: HistoryFeature 오전 12시 필터링

**파일**: `MongleFeatures/Sources/MongleFeatures/Presentation/History/HistoryFeature.swift`

```swift
let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
let isBeforeNoon = now < noon

for hq in historyQuestions {
    let isToday = calendar.isDateInToday(hq.date)
    // 오전이고, 오늘 날짜이고, 커스텀 질문이 아니면 히스토리에 포함하지 않음
    if isBeforeNoon && isToday && !hq.question.isCustom {
        continue
    }
    ...
}
```

### 5. iOS: HistoryView 오전 메시지 변경

**파일**: `MongleFeatures/Sources/MongleFeatures/Presentation/History/HistoryView.swift`

`emptyDateCard`에서 오늘 날짜이고 오전이면 "아직 질문을 받아오지 않았어요" + 시계 아이콘 표시. 그 외에는 기존 "이 날의 기록이 없어요" 표시.

---

## 커스텀 질문 처리 흐름 (기존 코드로 이미 동작)

1. 사용자가 `WriteQuestionView`에서 커스텀 질문 입력 → `createCustomQuestion` API 호출
2. 성공 시 `MainTab+Reducer`에서:
   - `state.home.todayQuestion = question` (커스텀 질문으로 교체)
   - `state.history.historyItems = [:]` (히스토리 캐시 무효화)
3. 사용자가 히스토리 탭 이동 → `onAppear` → API 재호출
4. 서버에서 오늘의 커스텀 질문(`isCustom = true`) 포함 반환
5. 필터 조건 `!hq.question.isCustom` 덕분에 **오전이라도 커스텀 질문은 HistoryView에 표시됨**

---

## 수정된 파일 목록

| 파일 | 변경 내용 |
|------|-----------|
| `FamTreeServer/src/models/index.ts` | `QuestionResponse`에 `isCustom` 추가 |
| `FamTreeServer/src/services/QuestionService.ts` | `toQuestionResponse()`, `toDailyQuestionResponse()` isCustom 반영 |
| `Domain/Sources/Domain/Entities/Question.swift` | `isCustom: Bool` 프로퍼티 추가 |
| `MongleData/.../DTOs/QuestionDTO.swift` | `QuestionResponseDTO.isCustom` 추가 |
| `MongleData/.../Mappers/QuestionMapper.swift` | isCustom 매핑 추가 |
| `MongleData/.../Repositories/QuestionRepository.swift` | 날짜 파싱 `DateFormatter`로 교체 |
| `MongleFeatures/.../History/HistoryFeature.swift` | 오전 12시 이전 오늘 질문 필터링 |
| `MongleFeatures/.../History/HistoryView.swift` | 오전 빈 날짜 메시지 변경 |
