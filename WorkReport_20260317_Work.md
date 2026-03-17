# 작업 보고 (2026-03-17 Work.md 기반)

## 완료된 작업

---

### 1. 나의 몽글 캐릭터 클릭 - 답변한 경우 내 답변 보기

**변경 파일:**
- `MongleFeatures/.../Home/HomeFeature.swift`
- `MongleFeatures/.../MainTab/MainTabView.swift`
- `MongleFeatures/.../MainTab/MainTabFeature.swift`
- `MongleFeatures/.../MainTab/Ext/MainTab+Action.swift`
- `MongleFeatures/.../MainTab/Ext/MainTab+Reducer.swift`

**내용:**
- `HomeFeature`에 `myMonggleTapped` 액션 추가
  - 게스트 → 로그인 유도 팝업
  - 답변 완료(`hasAnsweredToday == true`) → `navigateToMyAnswer` delegate 전송
  - 미답변 → 기존 `showQuestionSheet` 흐름 유지
- `HomeFeature.Delegate`에 `navigateToMyAnswer` 케이스 추가
- `MainTabFeature`에 `answerRepository` 의존성 추가
- `MainTab+Action`에 `showMyAnswer(memberName:questionText:answerText:)` 추가
- `MainTab+Reducer`에서 `navigateToMyAnswer` 처리:
  - `answerRepository.getByUserAndDailyQuestion()`으로 나의 답변 텍스트 fetch
  - fetch 완료 후 `PeerAnswerView`를 내 이름 + 내 답변으로 표시 (다른 멤버 답변 보기와 동일한 화면)
- `MainTabView`에서 `onMyMonggleTap`을 `questionTapped` → `myMonggleTapped`로 변경

---

### 2. 하트 지급 팝업 커스텀화

**변경 파일:**
- `MongleFeatures/.../Root/RootView.swift`

**내용:**
- 기존 기본 `.alert("🎁 하트 +1", ...)` 제거
- 프로젝트 내 `MonglePopupView`를 사용한 커스텀 팝업으로 교체
  - 아이콘: `heart.fill` (빨간색, 연한 빨간 배경)
  - 타이틀: "하트 +1"
  - 설명: "오늘 처음 접속하셨네요!\n하트 1개를 드렸어요 ❤️"
  - 버튼: "확인" / "닫기" (둘 다 `dismissHeartPopup` 처리)
- `.overlay` + `.animation(.none, ...)` 패턴으로 다른 커스텀 팝업(HeartCostPopup, AnswerFirstPopup 등)과 동일한 방식 적용
