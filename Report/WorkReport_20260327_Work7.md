# 작업 보고서 — 2026-03-27 (Work.md 7차)

## 작업 항목

### QuestionDetailView 컴파일 오류 수정

**오류 메시지:**
```
QuestionDetailView.swift:83:43 Cannot convert value of type
'Store<HeartCostPopupFeature.State, PresentationAction<HeartCostPopupFeature.Action>>'
to expected argument type 'StoreOf<HeartCostPopupFeature>'
```

**원인:**
- `QuestionDetailView`의 overlay에서 `store.scope(state: \.editCostPopup, action: \.editCostPopup)` 호출 시, `editCostPopup`이 `@Presents`로 선언되어 있어 TCA가 자동으로 `PresentationAction<ChildAction>` 으로 래핑된 스토어를 반환함
- 기존 `HeartCostPopupView`는 래핑 없는 `StoreOf<HeartCostPopupFeature>`만 허용하여 타입 불일치 발생

**해결:**
- `QuestionDetailView.swift`는 수정하지 않음 (작업 조건)
- `HeartCostPopupView.swift`에 convenience init 추가:
  ```swift
  public init(store: Store<HeartCostPopupFeature.State, PresentationAction<HeartCostPopupFeature.Action>>) {
      self.store = store.scope(state: \.self, action: \.presented)
  }
  ```
- `store.scope(state: \.self, action: \.presented)`로 `PresentationAction` 래핑을 벗겨 내부적으로 `StoreOf<HeartCostPopupFeature>`로 변환
- 기존 `init(store: StoreOf<HeartCostPopupFeature>)` 는 유지되어 다른 호출부에 영향 없음
