# 작업 보고서 — 2026-03-27 (Work.md 9차)

## 작업 항목

### 마음남기기 화면 — 200자 초과 입력 차단

**요구사항:**
- 200자 이상이 되면 더 이상 입력이 불가능하게 처리

**변경 파일:**

#### `QuestionDetailView.swift`

`answerInputSection`의 `TextField` Binding setter에서 200자 초과 입력을 즉시 차단:

```swift
set: { newValue in
    guard !store.isSubmitting, !isClosing else { return }
    if newValue.count > 200 { return }  // 200자 초과 시 입력 차단
    store.send(.answerTextChanged(newValue))
}
```

**동작:**
- 200자 미만: 정상 입력
- 200자 도달 후 추가 입력 시도: `return`으로 상태 업데이트 자체를 막아 TextFied가 변경되지 않음
- Feature의 `String(text.prefix(200))`은 서버 전송 직전 안전망으로 유지

**기존 구현 대비 차이:**
- 기존: 입력은 받되 200자로 잘라서 저장 → 타이핑 자체는 허용됨
- 변경: 200자 초과 입력 자체를 Binding 레벨에서 차단 → 커서가 더 이상 움직이지 않음
