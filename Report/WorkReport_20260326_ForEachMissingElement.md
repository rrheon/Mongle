# 작업 보고서 — 2026-03-26 forEach Missing Element 오류 수정

## 오류 내용

```
A "forEach" at "ComposableArchitecture/CaseReducer.swift:52" received an action for a missing element.
Action: MainTabFeature.Path.Action.questionDetail(.answerTextChanged)
```

## 원인 분석

**발생 시나리오**:
1. `QuestionDetailView`에서 TextField에 답변을 입력 중 (`isSubmitting = false`)
2. 뒤로가기 버튼 탭 → `closeTapped` 액션 전송
3. `MainTabFeature` 에서 `.delegate(.closed)` 수신 → `state.path.removeLast()` 호출
4. `questionDetail` 요소가 path에서 제거됨
5. SwiftUI가 뷰 해제 애니메이션 도중 TextField 바인딩이 한 번 더 `.answerTextChanged` 를 발생
6. 이미 path에서 제거된 요소이므로 TCA `forEach`가 해당 element를 찾지 못해 오류 발생

**기존 방어 코드와 한계**:
- `QuestionDetailFeature.swift` 308번 라인 주석:
  > `isSubmitting을 false로 초기화하지 않음: dismiss 중 TextField가 answerTextChanged를 재전송하는 것을 방지`
- 답변 제출 후 dismiss 케이스는 `guard !store.isSubmitting` 조건으로 이미 방어됨
- 하지만 **뒤로가기만 하고 제출하지 않는 케이스**는 `isSubmitting = false` 상태이므로 방어 불가

## 수정 내용

**파일**: `QuestionDetailView.swift`

### 변경 1: 뷰 로컬 플래그 추가
```swift
@State private var isClosing = false
```

### 변경 2: 뒤로가기 버튼에서 플래그 설정
```swift
MongleBackButton {
    isClosing = true       // 먼저 플래그 설정
    store.send(.closeTapped)
}
```

### 변경 3: TextField 바인딩 setter에 가드 추가
```swift
set: { newValue in
    guard !store.isSubmitting, !isClosing else { return }
    store.send(.answerTextChanged(newValue))
}
```

## 동작 원리

1. 사용자가 뒤로가기 탭
2. `isClosing = true` 로컬 상태 즉시 업데이트 (SwiftUI @State는 동기적)
3. `store.send(.closeTapped)` → path에서 요소 제거 시작
4. 뷰 해제 애니메이션 도중 TextField 바인딩 setter 재호출 시 `isClosing = true` 확인 → 조기 반환
5. `.answerTextChanged` 액션 미발송 → TCA 오류 미발생

## 참고

- Feature 쪽 변경 없음 (View 로컬 상태로 해결)
- 스와이프 백 제스처의 경우, 제스처 진행 중에는 path 요소가 여전히 존재하고 완료 시점에는 키보드가 이미 내려가 있으므로 TextField 바인딩이 재호출되지 않아 문제없음
