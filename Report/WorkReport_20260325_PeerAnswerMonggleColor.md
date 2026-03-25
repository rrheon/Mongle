# 작업 보고서 - HomeView 몽글캐릭터 색상 반영

**날짜:** 2026-03-25

---

## 문제

HomeView에서 상대방 몽글캐릭터를 클릭해 답변을 볼 때, 나타나는 몽글캐릭터 색상이 항상 노란색(monggleYellow)으로 고정되어 있었음.

**원인:**
- `PeerAnswerFeature.State`의 `monggleColor` 기본값이 `monggleYellow`로 하드코딩
- `MainTab+Reducer.swift`의 `navigateToPeerAnswerSelfAnswered` 처리 시 `targetUser.moodId`를 색상으로 변환하지 않고 `showPeerAnswer` 액션에 전달하지 않았음

---

## 수정 내용

### 1. `MainTab+Action.swift`
- `import SwiftUI` 추가
- `showPeerAnswer` 액션에 `monggleColor: Color` 파라미터 추가

```swift
// 수정 전
case showPeerAnswer(memberName: String, questionText: String, peerAnswer: String, myAnswer: String)

// 수정 후
case showPeerAnswer(memberName: String, questionText: String, peerAnswer: String, myAnswer: String, monggleColor: Color)
```

### 2. `MainTab+Reducer.swift`
- `import SwiftUI` 추가
- `moodId → Color` 변환 free function `monggleColor(for:)` 추가
- `navigateToPeerAnswerSelfAnswered` 처리 시 `targetUser.moodId`로 색상 계산 후 `showPeerAnswer`에 전달
- `showPeerAnswer` 케이스에서 `PeerAnswerFeature.State` 생성 시 `monggleColor` 전달

**추가된 moodId → Color 변환 함수:**
```swift
private func monggleColor(for moodId: String?) -> Color {
    switch moodId {
    case "happy":  return MongleColor.monggleYellow
    case "calm":   return MongleColor.monggleGreen
    case "loved":  return MongleColor.mongglePink
    case "sad":    return MongleColor.monggleBlue
    case "tired":  return MongleColor.monggleOrange
    default:       return MongleColor.monggleYellow
    }
}
```

---

## 동작 방식

1. HomeView에서 상대방 몽글캐릭터 클릭
2. `HomeFeature` → `navigateToPeerAnswerSelfAnswered(memberName)` 델리게이트 액션 발생
3. `MainTab+Reducer`에서 `familyMembers`에서 해당 유저를 찾아 `moodId` 추출
4. `moodId`를 `Color`로 변환 (happy→yellow, calm→green, loved→pink, sad→blue, tired→orange)
5. `showPeerAnswer` 액션으로 색상 전달 → `PeerAnswerFeature.State.monggleColor` 설정
6. `PeerAnswerView`에서 해당 멤버의 실제 무드 색상으로 몽글캐릭터 표시

---

## 변경 파일 요약

| 파일 | 변경 내용 |
|------|----------|
| `MainTab+Action.swift` | `showPeerAnswer`에 `monggleColor: Color` 파라미터 추가, `import SwiftUI` 추가 |
| `MainTab+Reducer.swift` | `monggleColor(for:)` 헬퍼 함수 추가, 색상 계산 및 전달 로직 추가 |
