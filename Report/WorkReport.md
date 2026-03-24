# 작업 결과 보고서

## 완료된 작업

### 1. 답변완료 시 하트 1개 지급 팝업

서버는 이미 답변 시 하트 +1을 지급하고 있었으나 iOS에 팝업이 없었습니다.

**수정 파일:**
- `MainTab+State.swift` — `showAnswerHeartPopup: Bool = false` 추가
- `MainTab+Action.swift` — `dismissAnswerHeartPopup` 액션 추가
- `MainTab+Reducer.swift` — `answerSubmitted` 처리 시 `state.home.hearts += 1`, `state.showAnswerHeartPopup = true` 추가
- `MainTabView.swift` — 기존 하트 팝업과 동일한 스타일로 오버레이 추가

팝업 문구: `"오늘의 질문에 답변하셨네요!\n하트 1개를 드렸어요 ❤️"`

---

### 2. 답변 시 선택한 mood 색상으로 내 캐릭터 색상 변경

QuestionDetailFeature에서 선택한 기분(mood)의 색상이 HomeView의 내 캐릭터에 반영됩니다.

**수정 파일:**
- `QuestionDetailFeature.swift` — `Delegate.answerSubmitted(Answer, moodId: String?)` 로 변경, 답변 제출 시 선택한 `selectedMoodIndex` → moodId 변환 후 전달
- `MainTab+State.swift` — `currentUserMoodId: String? = nil` 추가
- `MainTab+Reducer.swift` — `answerSubmitted` 처리 시 `state.currentUserMoodId = moodId` 업데이트
- `MainTabView.swift` — `homeViewSection`에서 현재 사용자 캐릭터 색상 결정 시 `currentUserMoodId` 우선 적용

mood → 색상 매핑:
| moodId | 색상 |
|--------|------|
| happy | 노란색 |
| calm | 초록색 |
| loved | 분홍색 |
| sad | 파란색 |
| tired | 주황색 |

---

### 3. 몽글캐릭터 답변상태 텍스트

이미 구현되어 있었으며 `MainTab+Reducer.swift`에서 `answerSubmitted` 처리 시 `state.home.memberAnswerStatus[userId] = true`가 설정되어 자동으로 반영됩니다.

- 내 캐릭터: `hasAnsweredToday` → "답변완료" / "답변하기"
- 상대 캐릭터: `memberAnswerStatus[user.id]` → "답변완료" / "미답변"

---

### 4. 캐릭터 터치 시 답변 내용 표시

상대 캐릭터 터치 시 실제 답변 내용을 서버에서 조회하도록 수정했습니다.

기존: `peerAnswer: ""`, `myAnswer: ""` 하드코딩
수정: `GET /answers/family/{questionId}` API 호출 후 실제 내용 표시

**수정 파일:**
- `MainTab+Action.swift` — `showPeerAnswer(memberName:questionText:peerAnswer:myAnswer:)` 액션 추가
- `MainTab+Reducer.swift` — `navigateToPeerAnswerSelfAnswered` 처리 시 API 호출 후 답변 내용 조회, `showPeerAnswer` 액션 처리 추가

---

## 수정된 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `QuestionDetailFeature.swift` | `answerSubmitted` 델리게이트에 `moodId` 추가 |
| `MainTab+State.swift` | `showAnswerHeartPopup`, `currentUserMoodId` 추가 |
| `MainTab+Action.swift` | `dismissAnswerHeartPopup`, `showPeerAnswer` 추가 |
| `MainTab+Reducer.swift` | answerSubmitted 처리 개선, 상대 답변 조회 API 호출, 팝업/mood 처리 추가 |
| `MainTabView.swift` | 하트 팝업 오버레이 추가, 캐릭터 색상에 moodId 오버라이드 적용 |
| `Root+Reducer.swift` | `answerSubmitted` 패턴 매칭 업데이트 |
