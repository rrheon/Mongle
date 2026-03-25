# 작업 보고서 - 뒤로가기 버튼 통일

**날짜:** 2026-03-25
**작업:** 모든 화면의 뒤로가기 버튼을 마음남기기(QuestionDetailView) 기준으로 통일

---

## 기준 버튼 스타일

`QuestionDetailView`의 커스텀 헤더에서 사용하는 버튼:

```swift
Button { ... } label: {
    Image(systemName: "chevron.left")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(MongleColor.textPrimary)
        .frame(width: 44, height: 44)
}
.buttonStyle(MongleScaleButtonStyle())
```

---

## 변경 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `SupportScreenView.swift` | font/frame 추가, `MongleScaleButtonStyle()` 적용 |
| `GroupSelectView.swift` | size 17→18, weight semibold→medium, frame 없음→44×44, `MongleScaleButtonStyle()` 추가 |
| `AccountManagementView.swift` | `.buttonStyle(.plain)` → `.buttonStyle(MongleScaleButtonStyle())` |
| `PeerNudgeView.swift` | `chevron.backward`→`chevron.left`, size 17→18, weight semibold→medium, frame 24×24→44×44, `MongleScaleButtonStyle()` 추가 |
| `WriteQuestionView.swift` | `chevron.backward`→`chevron.left`, size 17→18, weight semibold→medium, frame 24×24→44×44, `MongleScaleButtonStyle()` 추가 |
| `MongleCardEditView.swift` | `arrow.left`→`chevron.left`, size 20→18 |

---

## 변경하지 않은 화면

- `NotificationView.swift` - 이미 기준과 동일 (chevron.left, size 18, frame 44×44, MongleScaleButtonStyle)
- `QuestionDetailView.swift` - 기준 화면
- `PeerAnswerView.swift` - xmark(닫기) 버튼, 뒤로가기 아님
- `QuestionSheetView.swift` - xmark(닫기) 버튼, 뒤로가기 아님
- `HistoryView.swift` - chevron.left는 달력 이전달 이동 버튼
- `SupportScreenView.swift` line 308 - chevron.left는 달력 이전달 이동 버튼
- `PenPlaceholderView.swift` - 뒤로가기 버튼 없음
