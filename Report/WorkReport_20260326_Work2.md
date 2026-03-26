# 작업 보고서

**날짜:** 2026-03-26 (2차)

---

## 1. SearchView - 오늘의 질문 검색 결과 노출 이슈

### 문제
오늘의 질문에 답변하지 않았어도 검색 시 결과에 노출됨.

### 수정
**`SearchHistoryFeature.swift`** - `performSearch` 케이스에서 오늘 날짜 항목 건너뜀:
```swift
if Calendar.current.isDateInToday(hq.date) { continue }
```

---

## 2. 커스텀 팝업 - 기본 alert → MonglePopupView 전환

모든 SwiftUI `.alert` 를 `MonglePopupView` overlay 방식으로 변경.

| 파일 | 전환된 alert |
|------|-------------|
| `SettingsTabView.swift` | 로그아웃, 회원탈퇴 |
| `GroupManagementView.swift` | 멤버 내보내기 |
| `GroupSelectView+Select.swift` | 그룹 한도 초과, 그룹 나가기, 그룹 해제 불가 |
| `QuestionDetailView.swift` | 오늘의 몽글 선택 요청 |

### MongleView 로컬 alert 구조 개선

기존에 `MongleView`에서 `@State`로 처리하던 팝업 2개를 콜백 방식으로 전환하여 `AnswerFirstPopupView` (커스텀 팝업)로 표시되도록 변경.

변경 흐름:
```
MongleView
  → MongleSceneView (onAnswerFirstToView, onAnswerFirstToNudge 콜백 추가)
  → HomeViewActions (onAnswerRequiredTap, onNudgeUnavailableTap 추가)
  → MainTabView → HomeFeature (answerRequiredTapped, nudgeUnavailableTapped)
  → MainTabFeature → AnswerFirstPopupFeature (.viewAnswer / .nudge)
```

`MainTab+Reducer.swift`: `showNudgeUnavailablePopup`이 기존 `.none` (로컬 alert 의존)에서 `AnswerFirstPopupFeature(.nudge)` 표시로 수정.

---

## 3. 몽글 캐릭터 선택 시 이모지 → 텍스트 변경

### MoodOption 순서 변경 (평온 → 행복 → 사랑 → 우울 → 지침)
**`Components.swift`** - `MoodOption.defaults` 재정렬 및 색상 `monggle*` 컬러로 통일:
- 기존: 행복, 평온, 사랑, 우울, 지침
- 변경: 평온, 행복, 사랑, 우울, 지침

### 이모지 → 텍스트 변경
- **`QuestionDetailView.swift`**: 로컬 `moods` 배열 제거 → `MoodOption.defaults` 직접 사용, `Text(mood.emoji)` → `Text(mood.label)`
- **`ProfileEditView.swift`**: 프로필 카드의 `Text(mood.emoji)` 제거 (label만 표시)
- **`SettingsTabView.swift`**: 하드코딩된 `"오늘의 기분: 🥰 사랑"` → `"오늘의 기분: 사랑"`
