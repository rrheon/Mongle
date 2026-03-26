# 작업 보고서 — 오늘의 질문 노출 필터

**날짜:** 2026-03-26

---

## 1. SearchView — 오늘의 질문 필터 (이전 세션에서 적용 완료)

**파일:** `SearchHistoryFeature.swift`

`performSearch`에서 오늘 날짜 항목 건너뜀:
```swift
if Calendar.current.isDateInToday(hq.date) { continue }
```

---

## 2. HistoryView — 오늘 날짜는 내가 답변한 경우에만 노출

### 문제
오늘 날짜의 질문이 답변 여부와 무관하게 캘린더와 답변 카드에 노출됨.

### 원인
기존 조건: `if isBeforeNoon && isToday && !hq.question.isCustom` → 정오 이후에는 오늘 질문이 항상 포함됨.

### 수정
**파일:** `HistoryFeature.swift` — `forceReload` 케이스

```swift
// 변경 전
let now = Date()
let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
let isBeforeNoon = now < noon
...
if isBeforeNoon && isToday && !hq.question.isCustom { continue }

// 변경 후
if isToday && !hq.hasMyAnswer { continue }
```

### 결과
- 내가 오늘 답변하지 않은 경우: 캘린더에 오늘 점(●) 미표시, 탭 시 "이 날의 기록이 없어요" 표시
- 내가 오늘 답변한 경우: 정상 노출, `memberAnswers`는 실제 답변한 사람만 포함 (API 응답 기반)
