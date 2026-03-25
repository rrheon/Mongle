# 작업 보고서 - PeerAnswerView 색상·내용·타임스탬프 반영 + forEach 에러 수정

**날짜:** 2026-03-25

---

## 문제

### 1. forEach 에러 (`questionDetail(.answerTextChanged)`)
답변 수정 후 화면이 dismiss될 때, NavigationStack path에서 이미 제거된 `questionDetail` 상태에 대해 TextField 바인딩이 `answerTextChanged` 액션을 발생시켜 TCA `forEach` 에러 발생.

### 2. 몽글캐릭터 색상 미반영
- `showMyAnswer` 경로(내 답변 보기): `PeerAnswerFeature.State` 생성 시 `monggleColor` 미전달 → 항상 노란색
- `showPeerAnswer` 경로(타인 답변 보기): 이전 세션에서 수정했으나 `showMyAnswer`는 누락

### 3. 답변 수정 후 내용·시간 미반영
- 타임스탬프가 `"오늘 오전 9:23"` 등 하드코딩된 더미값으로 고정
- 답변 수정 시 `updatedAt`이 반영되지 않음

---

## 수정 내용

### 1. `QuestionDetailView.swift`
TextField Binding.set에 `isSubmitting` 가드 추가:

```swift
// 수정 전
set: { store.send(.answerTextChanged($0)) }

// 수정 후
set: { newValue in
    guard !store.isSubmitting else { return }
    store.send(.answerTextChanged(newValue))
}
```

dismiss 애니메이션 중 TextField가 action을 전송하기 전에 차단. `submitAnswerResponse(.success)` 이후 `isSubmitting`이 `true`로 유지되므로 효과적으로 차단됨.

### 2. `MainTab+Action.swift`
- `showMyAnswer`에 `monggleColor: Color`, `answerTime: String` 파라미터 추가
- `showPeerAnswer`에 `peerAnswerTime: String`, `myAnswerTime: String` 파라미터 추가

### 3. `MainTab+Reducer.swift`

#### 타임스탬프 포맷 헬퍼 함수 추가
```swift
private func formatAnswerTime(_ date: Date) -> String {
    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    if calendar.isDateInToday(date) {
        formatter.dateFormat = "오늘 a h:mm"
    } else if calendar.isDateInYesterday(date) {
        formatter.dateFormat = "어제 a h:mm"
    } else {
        formatter.dateFormat = "M월 d일 a h:mm"
    }
    return formatter.string(from: date)
}
```

#### `navigateToMyAnswer` 수정
- `state.home.currentUser?.moodId` → `monggleColor` 계산
- `getByUserAndDailyQuestion`으로 전체 Answer 객체 가져와 `updatedAt ?? createdAt` 포맷

#### `showMyAnswer` 수정
- `PeerAnswerFeature.State`에 `monggleColor`, `peerAnswerTime` 전달

#### `navigateToPeerAnswerSelfAnswered` 수정
- `getByDailyQuestion`으로 가져온 각 Answer의 `updatedAt ?? createdAt` 포맷
- `peerAnswerTime`, `myAnswerTime`을 `showPeerAnswer` 액션에 전달

#### `showPeerAnswer` 수정
- `PeerAnswerFeature.State`에 `peerAnswerTime`, `myAnswerTime` 전달

---

## 동작 방식

| 시나리오 | 전 | 후 |
|---------|----|----|
| 내 캐릭터 클릭 → 내 답변 보기 | 노란 몽글, 더미 시간 | 내 무드 색상, 실제 시간 |
| 타인 캐릭터 클릭 → 타인 답변 보기 | (색상 수정됨), 더미 시간 | 타인 무드 색상, 실제 시간 |
| 답변 수정 후 dismiss | forEach 에러 발생 | 에러 없음 (isSubmitting 가드) |
| 수정된 답변 재확인 | 이전 내용·이전 시간 | 수정된 내용, 수정된 시간 |

---

## 변경 파일 요약

| 파일 | 변경 내용 |
|------|----------|
| `QuestionDetailView.swift` | TextField Binding.set에 `isSubmitting` 가드 추가 |
| `MainTab+Action.swift` | `showMyAnswer`, `showPeerAnswer` 파라미터 추가 |
| `MainTab+Reducer.swift` | `formatAnswerTime` 헬퍼, 색상·시간 계산 및 전달 |
