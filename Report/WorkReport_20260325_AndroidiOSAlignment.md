# Android ↔ iOS 정렬 작업 보고서
**날짜**: 2026-03-25

---

## 작업 개요

iOS 프로젝트 기준으로 Android 프로젝트에 누락된 기능과 UI 차이점을 분석하고 수정했습니다.

---

## 분석 결과: 주요 차이점

### iOS에만 있던 기능 (Android에 추가)

| 기능 | iOS | Android (이전) | Android (이후) |
|------|-----|---------------|----------------|
| 온보딩 화면 | ✅ | ❌ | ✅ 추가 |
| 나만의 질문 작성 | ✅ | ❌ | ✅ 추가 |
| 가족 답변 보기 | ✅ Sheet | ❌ (재촉만 가능) | ✅ BottomSheet 추가 |
| 홈 TopBar 그룹 드롭다운 | ✅ | ❌ | ✅ 추가 |
| 프로필 편집 UI | 전체 화면 | AlertDialog | ModalBottomSheet |
| 하트 설명 팝업 | Popover | ❌ | ✅ DropdownMenu 추가 |

---

## 구현 내용

### 1. 온보딩 화면 (신규)
**파일**: `ui/onboarding/OnboardingScreen.kt`

- 3페이지 수평 슬라이드 온보딩 (HorizontalPager)
- 페이지 인디케이터 (애니메이션 포함)
- "시작하기 / 다음 / 몽글 시작하기 🌿" 버튼 (페이지 따라 변경)
- "다시 보지않기" 버튼 → SharedPreferences에 저장

**수정 파일**:
- `ui/root/RootViewModel.kt`
  - `AppState.Onboarding` 추가
  - SharedPreferences로 온보딩 완료 여부 관리
  - `onOnboardingCompleted()`, `onOnboardingNeverShowAgain()` 추가
- `ui/navigation/MongleNavHost.kt`
  - `AppState.Onboarding` 케이스 처리

### 2. 나만의 질문 작성 화면 (신규)
**파일**:
- `ui/question/WriteQuestionScreen.kt`
- `ui/question/WriteQuestionViewModel.kt`

- 질문 텍스트 입력 폼
- 하트 3개 차감 안내
- 글자 수 표시
- 제출/로딩/에러 처리

**수정 파일**:
- `domain/repository/QuestionRepository.kt`
  - `createCustomQuestion(content: String): Question` 인터페이스 추가
- `data/remote/ApiQuestionRepository.kt`
  - 기존 `suspend fun`을 `override`로 변경
- `ui/navigation/MongleNavHost.kt`
  - `showWriteQuestion` 상태 변수 추가 및 WriteQuestionScreen 연결
- `ui/main/MainTabScreen.kt`
  - `onNavigateToWriteQuestion` 파라미터 추가
- `ui/home/HomeScreen.kt`
  - `onNavigateToWriteQuestion` 파라미터 추가
  - 하트 뱃지 탭 시 DropdownMenu에 "나만의 질문 작성하기" 항목 추가

### 3. 가족 답변 보기 (신규)
**파일**: `ui/home/PeerAnswerSheet.kt`

- `ModalBottomSheet` 형태
- 오늘의 질문 카드 표시
- 멤버 아바타 + 이름 + 답변 시간 표시
- 멤버의 답변 내용 표시

**수정 파일**:
- `ui/home/HomeViewModel.kt`
  - `AnswerRepository` 의존성 추가
  - `memberAnswerStatus: Map<UUID, Boolean>` 상태 추가
  - `memberAnswers: Map<UUID, Answer>` 상태 추가
  - `loadFamilyAnswers()` - 오늘의 질문 답변 목록 로드
  - `onMemberTapped()` 수정 - 답변 여부에 따라 PeerAnswer 또는 Nudge
  - `HomeEvent.ShowPeerAnswer` 이벤트 추가
- `ui/home/HomeScreen.kt`
  - `peerAnswerTarget` 상태 변수 추가
  - `ShowPeerAnswer` 이벤트 처리
  - `MongleSceneSection`에 `memberAnswerStatus` 전달
  - `hasAnswered` 값 올바르게 표시 (기존: 항상 false)

### 4. 홈 TopBar 그룹 드롭다운 (수정)
**수정 파일**: `ui/home/HomeScreen.kt`

- iOS와 동일하게 그룹명 탭 시 드롭다운 메뉴 표시
- 현재 그룹명 + "그룹 관리" 항목
- 화살표 아이콘 회전 애니메이션

### 5. 프로필 편집 BottomSheet 개선 (수정)
**수정 파일**: `ui/settings/SettingsScreen.kt`

- 기존: AlertDialog → 변경: ModalBottomSheet
- iOS의 전체 화면과 유사한 경험 제공
- 이름 필드, 역할 드롭다운, 저장/취소 버튼

---

## 미구현 항목 (우선순위 낮음)

| 기능 | 이유 |
|------|------|
| MongleCardEditView | 카드 이미지 편집 → 이미지 업로드 인프라 필요 |
| 기분 히스토리 (Support) | 별도 기분 기록 API 필요 |
| 게스트 모드 | 인증 구조 변경 필요 |
| 나만의 질문 제한 (하루 1회) | 서버 측 제한으로 이미 처리됨 |

---

## 이슈 및 특이사항

- Android SDK가 로컬 환경에 설치되지 않아 실제 빌드 검증 불가
  - 코드 작성 후 정적 분석으로 문제 없음 확인
  - 실제 기기 테스트 필요
- `HomeViewModel`에 `AnswerRepository` 추가로 생성자 변경됨
  - Hilt DI로 자동 주입되므로 별도 설정 불필요
- 온보딩은 첫 설치 또는 `has_seen_onboarding = false` 상태에서만 표시
