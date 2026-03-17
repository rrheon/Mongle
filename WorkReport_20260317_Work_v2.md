# 작업 보고 (2026-03-17 Work.md v2)

## 완료된 작업

---

### 1. 오늘의 질문 카드가 안 뜨는 문제 (서버)

**원인:**
- DB에 `Question` 데이터가 없어서 `assignQuestionToFamily()`가 `'사용 가능한 질문이 없습니다.'` 에러를 throw
- iOS 클라이언트 `getTodayQuestion()`이 `try?`로 에러를 무시 → `nil` 반환 → 질문 카드 미표시

**수정:**
- `npm run db:seed` 실행 → 100개 질문 생성 완료 (DAILY 30, MEMORY 20, VALUE 15, DREAM 15, GRATITUDE 10, SPECIAL 10)
- 이후 `getTodayQuestion()` 호출 시 서버 lazy assignment가 정상 동작

---

### 2. 나의 몽글 - 답변 안한 경우 작동 안 함

**원인 1 (이전 세션, 이미 수정됨):**
- `onMyMonggleTap`이 `questionTapped` → 항상 QuestionSheet만 표시했음
- `myMonggleTapped` 액션 추가로 답변 여부에 따라 분기하도록 수정

**원인 2 (이번 세션):**
- `todayQuestion == nil`이면 `HomeFeature.myMonggleTapped`의 guard 문이 실패 → 아무것도 표시 안 됨
- Issue 1 (seed 실행)으로 함께 해결

**원인 3 (Components.swift 버그 수정):**
- `MongleView.init`에서 `self.hasCurrentUserAnswered = true` 하드코딩 → 파라미터 무시
- `self.hasCurrentUserAnswered = hasCurrentUserAnswered`로 수정
- 이 버그는 다른 멤버 캐릭터 탭 동작(답변 안 한 상태에서 상대 답변 보기 시도, 재촉하기 등)에 영향을 줬음

**변경 파일 (이전 세션 포함):**
- `MongleFeatures/.../Design/Components.swift` — `hasCurrentUserAnswered` 하드코딩 수정
- `MongleFeatures/.../Home/HomeFeature.swift` — `myMonggleTapped` 액션 + `navigateToMyAnswer` delegate 추가
- `MongleFeatures/.../MainTab/MainTabView.swift` — `onMyMonggleTap` → `myMonggleTapped`로 연결
- `MongleFeatures/.../MainTab/MainTabFeature.swift` — `answerRepository` 의존성 추가
- `MongleFeatures/.../MainTab/Ext/MainTab+Action.swift` — `showMyAnswer` 액션 추가
- `MongleFeatures/.../MainTab/Ext/MainTab+Reducer.swift` — `navigateToMyAnswer` 처리: 내 답변 fetch 후 PeerAnswerView 표시

---

### 3. 하트 팝업 커스텀 (이전 세션에서 수정됨)

**변경 파일:**
- `MongleFeatures/.../Root/RootView.swift`

**내용:**
- 기존 시스템 `.alert` 제거
- `MonglePopupView` (프로젝트 내 커스텀 팝업)로 교체
  - 하트 아이콘, "하트 +1" 타이틀, 확인/닫기 버튼
  - `.overlay` 패턴 (HeartCostPopup, AnswerFirstPopup과 동일 방식)
