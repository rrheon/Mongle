# 작업 보고서 — 2026-03-27 (Work.md 8차)

## 작업 항목

### 마음남기기 화면 — 답변 200자 제한

**요구사항:**
- `QuestionDetailView` (마음남기기 화면)의 답변 입력 필드를 200자로 제한

**변경 파일:**

#### 1. `QuestionDetailFeature.swift`
- `answerTextChanged` 케이스에서 `String(text.prefix(200))` 적용하여 입력값을 200자로 클램핑

```swift
case .answerTextChanged(let text):
    guard !state.isSubmitting else { return .none }
    state.answerText = String(text.prefix(200))  // 200자 제한
    state.appError = nil
    return .none
```

#### 2. `QuestionDetailView.swift`
- `answerInputSection`을 `VStack(alignment: .trailing)`으로 래핑하여 character counter 추가
- 200자 도달 시 카운터 색상을 `MongleColor.error`로 변경

```swift
private var answerInputSection: some View {
    VStack(alignment: .trailing, spacing: 6) {
        TextField(...)
            // ...기존 모디파이어 유지...

        Text("\(store.answerText.count)/200")
            .font(MongleFont.caption())
            .foregroundColor(store.answerText.count >= 200 ? MongleColor.error : MongleColor.textHint)
    }
}
```

**결과:**
- 입력값이 200자를 초과하면 자동으로 잘림 (Feature 레벨 강제)
- 우측 하단에 `N/200` 형태의 카운터 표시
- 200자 도달 시 카운터 색상이 에러 색상으로 전환
