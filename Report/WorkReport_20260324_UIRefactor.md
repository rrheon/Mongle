# UI 스타일 개선 보고서

**날짜**: 2026-03-24

---

## 작업 개요

`Design.md`에 기술된 상용 앱 수준의 UI 스타일 개선을 전체 화면에 걸쳐 적용했습니다.

---

## 변경 파일 목록

### `Design/Components.swift`

| 항목 | 내용 |
|------|------|
| `MongleScaleButtonStyle` 추가 | 버튼 누를 때 0.96 스케일 + 0.9 opacity spring 애니메이션 |
| `MongleRowButtonStyle` 추가 | 리스트 셀 누를 때 연한 회색 배경 하이라이트 |
| `MongleSheetAnswer` 레거시 제거 | `.cornerRadius(24, corners:)` + `UIBezierPath` → iOS 16 네이티브 `.clipShape(.rect(...))` |
| `RoundedCorner` Shape 구조체 삭제 | `UIBezierPath` 기반 helper 제거 |

### `Presentation/Question/QuestionDetailView.swift`

| 항목 | 내용 |
|------|------|
| `familyAnswersSection` 제거 | 답변 시 다른 그룹 멤버 답변 노출은 의도하지 않은 기능 |
| `answerInputSection` 개선 | ZStack + GeometryReader 높이 핵 → `TextField(axis: .vertical)` |
| `monglePanel` 적용 | questionSection, moodPickerSection 카드 스타일 통일 |
| `MongleScaleButtonStyle` 적용 | 뒤로가기 버튼, CTA 버튼 |

### `Presentation/Home/HomeView.swift`

| 항목 | 내용 |
|------|------|
| 드롭다운 위치 수정 | 하드코딩 `.padding(.top, 116)` → `TopBarView.headerView.overlay(alignment: .bottomLeading)` |
| `TopBarView` 콜백 추가 | `onGroupSelected`, `onNavigateToGroupSelect` 파라미터 추가, `.zIndex(1)` 설정 |
| `MongleScaleButtonStyle` 적용 | HeartsButtonView, NotificationButtonView |
| `TodayQuestionCard` 개선 | `let cardContent =` ViewBuilder 패턴 → `private var cardBody`, `.green` → `MongleColor.primary`, `MongleScaleButtonStyle` 적용, `monglePanel` 적용 |
| `GroupDropdownView` `monglePanel` 적용 | 수동 background/clipShape/shadow 교체 |

### `Presentation/History/HistoryView.swift`

| 항목 | 내용 |
|------|------|
| 카드 전체 `monglePanel` 통일 | questionCard, answerCard, emptyDateCard, emptyAnswersCard, moodTimelineSection |
| `MongleScaleButtonStyle` 적용 | 이전/다음 달 버튼, 날짜 셀 버튼 |
| 하드코딩 폰트 교체 | `.custom("Outfit", ...)` → `MongleFont.body2Bold()` |
| `DateFormatter` static 전환 | `dayFormatter`, `selectedDateFormatter` static let으로 분리 → 스크롤 성능 개선 |

### `Presentation/Home/QuestionSheetView.swift`

| 항목 | 내용 |
|------|------|
| `questionCard` `monglePanel` 적용 | |
| `actionRow` `monglePanel` 적용 | background/clipShape/overlay 교체 |
| `actionRow` `MongleScaleButtonStyle` 적용 | `.plain` 교체 |
| close 버튼 터치 영역 확보 | `.frame(width: 44, height: 44)` + `.contentShape(Rectangle())` 추가 |

### `Presentation/Notification/NotificationView.swift`

| 항목 | 내용 |
|------|------|
| `RelativeDateTimeFormatter` static 전환 | 카드 렌더링마다 생성 → static let 재사용으로 스크롤 버벅임 방지 |
| 헤더 버튼 `MongleScaleButtonStyle` 적용 | 뒤로가기, 모두 읽음, 모두 제거 |

### `Presentation/Profile/ProfileEditView.swift`

| 항목 | 내용 |
|------|------|
| `MongleRowButtonStyle` 적용 | settingsSection 버튼 `.PlainButtonStyle()` 교체 |
| `profileCard` `monglePanel` 적용 | `.ultraThinMaterial` + 수동 clipShape/overlay/shadow 교체 |
| settingsSection 컨테이너 `monglePanel` 적용 | 은은한 테두리 + 깊이감 추가 |

### `Presentation/Profile/MongleCardEditView.swift`

| 항목 | 내용 |
|------|------|
| `@State selectedMood` 안티패턴 제거 | `.onAppear`, `.onChange` 동기화 로직 삭제 |
| 커스텀 Binding 적용 | `moodSection`에서 `Binding<MoodOption?>` 직접 생성 → TCA 상태와 직결 |
| `MongleInputText` 재사용 | `nameSection` 수동 HStack 코드 → 공통 컴포넌트 |
| 하드코딩 폰트 교체 | `.custom("Outfit", ...)` → `MongleFont` |
| 헤더 버튼 터치 영역 확보 | 뒤로가기, 저장 버튼에 `.frame(width: 44, height: 44)` + `MongleScaleButtonStyle` |

### `Presentation/Support/SupportScreenView.swift`

| 항목 | 내용 |
|------|------|
| 초대 코드 복사 버튼 추가 | `Text("코드: ...")` → 터치 시 클립보드 복사 pill 버튼 |
| `ShareLink` 추가 | iOS 16 네이티브 공유 시트 연동, `MongleButtonSecondary("새 멤버 초대하기")` 제거 |
| 카드 전체 `monglePanel` 통일 | historyCalendarView, notificationSettingsView, groupManagementView, moodHistoryView 내 모든 카드 |
| `DateFormatter` static 전환 | `monthFormatter`, `selectedDateFormatter`, `moodSummaryFormatter` static let으로 분리 |

---

## 주요 패턴 변경 요약

| 이전 패턴 | 개선 후 |
|----------|---------|
| `.background(C).cornerRadius(R).overlay(RoundedRectangle(...).stroke(...))` | `.monglePanel(background: C, cornerRadius: R, borderColor: B)` |
| `.buttonStyle(.plain)` | `.buttonStyle(MongleScaleButtonStyle())` |
| `PlainButtonStyle()` (리스트) | `MongleRowButtonStyle()` |
| 매 호출마다 `DateFormatter()` 생성 | `private static let` 재사용 |
| `@State` 로컬 변수로 TCA 상태 복사 + `.onChange` 동기화 | TCA 상태 기반 커스텀 `Binding` 직접 생성 |
| `TextEditor` + `GeometryReader` 높이 핵 | `TextField(axis: .vertical)` |
| `UIBezierPath` 기반 비대칭 코너 | iOS 16 네이티브 `.clipShape(.rect(...))` |

---

## 미완료 사항

- **HistoryView `moodFrequency14Days` 계산**: Reducer로 이동 권장 (Design.md §HistoryView 3번) — 뷰 렌더링 성능 개선 여지 있음. Reducer 파일 수정이 필요하여 이번 작업에서 제외.
