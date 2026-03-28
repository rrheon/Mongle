# 작업 보고서 - 공통 네비게이션 헤더 컴포넌트

**날짜:** 2026-03-26

---

## 작업 내용

각 화면에서 개별적으로 구현하던 헤더 뷰를 `MongleNavigationHeader` 공통 컴포넌트로 통합.

---

## 생성된 파일

### `Presentation/Common/MongleNavigationHeader.swift`

- **`MongleNavigationHeader<Left, Right>`**: 공통 네비게이션 헤더 뷰
  - 기본 구조: 왼쪽버튼 | 가운데 타이틀(ZStack 중앙 정렬) | 오른쪽버튼
  - `@ViewBuilder left:`, `right:` 파라미터로 각 화면에 맞게 커스텀
  - 높이 56pt, 가로 패딩 8pt(`MongleSpacing.xs`), 흰색 배경 고정

- **`MongleBackButton`**: 공통 뒤로가기 버튼 (chevron.left 아이콘, 44x44 터치 영역)

---

## 수정된 파일 (6개)

| 파일 | 화면 | 헤더 패턴 |
|------|------|---------|
| `Profile/AccountManagementView.swift` | 계정 관리 | Back + "계정 관리" |
| `Profile/MongleCardEditView.swift` | 프로필 편집 | Back + "프로필 편집" + 저장버튼 |
| `Notification/NotificationView.swift` | 알림 | Back + "알림" + 조건부 액션버튼 |
| `Question/QuestionDetailView.swift` | 마음 남기기 | Back + "마음 남기기" |
| `Question/WriteQuestionView.swift` | 질문 작성하기 | Back + "질문 작성하기" |
| `Peer/PeerNudgeView.swift` | 답변 재촉하기 | Back + "답변 재촉하기" |

---

## 수정하지 않은 파일

아래 화면들은 네비게이션 헤더 패턴과 다른 구조라 유지:

- `Profile/ProfileEditView.swift` - "MY" 좌측 정렬 탭 헤더 (뒤로가기 없음)
- `History/HistoryView.swift` - "기록" + 월 네비게이션 탭 헤더
- `Search/SearchHistoryView.swift` - 검색바 형태
- `Peer/PeerAnswerView.swift` - xmark 단일 버튼 (모달)

---

## 사용 예시

```swift
// 기본: 뒤로가기 + 타이틀
MongleNavigationHeader(title: "계정 관리") {
    MongleBackButton { store.send(.backTapped) }
} right: {
    EmptyView()
}

// 뒤로가기 + 타이틀 + 오른쪽 액션
MongleNavigationHeader(title: "프로필 편집") {
    MongleBackButton { store.send(.backTapped) }
} right: {
    Button { store.send(.saveTapped) } label: {
        Text("저장")
            .font(MongleFont.body1Bold())
            .foregroundColor(isValid ? MongleColor.primarySoft : MongleColor.textHint)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }
    .buttonStyle(MongleScaleButtonStyle())
    .disabled(!isValid)
}
```
