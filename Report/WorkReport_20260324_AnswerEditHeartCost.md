# 작업 보고서: 답변 수정 하트 소모 및 UX 개선

**날짜**: 2026-03-24

---

## 작업 내용

### 1. 답변 수정 시 하트 1개 소모 + 팝업 표시

**변경 파일**:
- `HeartCostPopupFeature.swift` — `editAnswer` case 추가 (하트 1개)
- `QuestionDetailFeature.swift` — 수정 시 팝업 표시로 전환
- `QuestionDetailView.swift` — `.fullScreenCover`로 팝업 연결
- `MainTab+Reducer.swift` — answerEdited 시 `state.home.hearts -= 1`

**흐름**:
1. 사용자가 "답변 수정하기" 버튼 탭
2. `submitAnswerTapped`에서 `hasMyAnswer`이면 `editCostPopup` 팝업 표시 (하트 1개 안내)
3. 사용자가 "수정하기" 확인 → 편집 API 호출
4. 성공 시 `answerEdited` delegate → `MainTabFeature`에서 `hearts - 1`

**하트 부족 시**: 팝업 내 "광고 보고 하트 받기" 버튼으로 광고 시청 후 하트 1개 지급, 팝업 재표시

### 2. 수정 화면 진입 시 기존 답변의 몽글 색상 선택 복원

**변경 파일**: `QuestionDetailFeature.swift`

두 곳에서 처리:
- `State.init`: `myAnswer`가 전달된 경우 `currentUser.moodId`로 `selectedMoodIndex` 초기화
- `loadDataResponse`: 서버에서 답변 로드 후 `currentUser.moodId`로 `selectedMoodIndex` 설정

`currentUser.moodId`는 사용자가 마지막으로 답변할 때 선택한 기분이므로 기존 답변의 색상에 가장 근접합니다.

### 3. 답변 작성/수정 시 HistoryView 몽글 색상 반영

**변경 파일**: `MainTab+Reducer.swift`

기존 `answerEdited` 핸들러의 `isTodayQuestion` 체크를 제거하여, 과거 답변 수정 시에도 사용자의 `moodId`가 업데이트되도록 변경.

- 변경 전: 오늘의 질문 수정 시에만 사용자 moodId 업데이트
- 변경 후: 모든 답변 수정 시 사용자 moodId 업데이트 → HistoryView 캐시 무효화 후 재로드 시 새 색상 반영

---

## 구조 변경 요약

### `QuestionDetailFeature`에 추가된 것
| 항목 | 내용 |
|------|------|
| `State.hearts: Int` | 팝업에 보여줄 하트 잔액 (navigationDetail push 시 전달) |
| `State.editCostPopup: HeartCostPopupFeature.State?` | `@PresentationState` 팝업 상태 |
| `Action.editCostPopup` | `PresentationAction<HeartCostPopupFeature.Action>` |
| `Action.adHeartGranted(Int)` | 광고 시청 후 하트 업데이트 |
| `@Dependency(\.adClient)` | 광고 시청 |
| `@Dependency(\.userRepository)` | 광고 보상 지급 |

### `MainTabFeature` 변경
| 항목 | 내용 |
|------|------|
| questionDetail push 시 `hearts` 전달 | 3곳 (history, home delegate, notification delegate) |
| `answerEdited` 핸들러 | `isTodayQuestion` 체크 제거, 하트 1개 차감 추가 |

---

## 한계 사항

현재 구조에서 "기존 답변의 moodId"는 서버의 `Answer` 테이블에 저장되지 않습니다. `FamilyMembership.moodId` (사용자의 현재 기분)로 근사치를 사용합니다. 사용자가 여러 번 답변을 수정한 경우 최신 기분이 표시됩니다.

완전한 구현을 원한다면:
- 서버 `Answer` 테이블에 `moodId` 컬럼 추가 (Prisma 마이그레이션 필요)
- `PUT /answers/:id` 엔드포인트에 `moodId` 파라미터 추가
- 히스토리 API에서 `FamilyMembership.moodId` 대신 `Answer.moodId` 반환
