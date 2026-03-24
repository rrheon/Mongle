# 작업 보고서 - HomeView 오전 플레이스홀더 카드 추가 (2026-03-24)

## 작업 배경

이전 수정에서 오전에 질문 카드를 완전히 숨겼으나,
요구사항 변경: 카드는 유지하되 "오후 12시에 다시 질문을 받을 수 있어요" 문구로 표시하고 탭 이벤트는 받지 않음.

---

## 수정 내용

**파일**: `MongleFeatures/Sources/MongleFeatures/Presentation/Home/HomeView.swift`

### 1. `TopBarView` — 오전 플레이스홀더 카드 표시

```swift
} else if isBeforeNoon {
    let placeholder = TopBarQuestion(
        id: UUID(),
        text: "오후 12시에 다시 질문을 받을 수 있어요",
        isAnswered: false
    )
    TodayQuestionCard(question: placeholder, onTap: nil)  // nil = 탭 비활성
}

private var isBeforeNoon: Bool {
    let cal = Calendar.current
    let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    return Date() < noon
}
```

### 2. `TodayQuestionCard` — `onTap` optional 처리

```swift
var onTap: (() -> Void)?  // nil이면 비활성 카드
```

- `onTap != nil` → `Button`으로 감싸서 탭 가능, chevron 표시
- `onTap == nil` → 일반 `View`로 렌더링, chevron 숨김, 텍스트 색상 `.secondary`로 구분

---

## 동작 흐름

| 시간대 | 카드 표시 | 텍스트 | 탭 가능 |
|--------|-----------|--------|---------|
| 오전 12시 이전 | ✅ 표시 | "오후 12시에 다시 질문을 받을 수 있어요" | ❌ 비활성 |
| 오후 12시 이후 | ✅ 표시 | 실제 질문 내용 | ✅ 활성 |
