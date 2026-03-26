# 버그 수정 보고서: copiedToastDismissed TCA 오류

**날짜:** 2026-03-26
**작업자:** Claude

---

## 문제

```
An "ifLet" at "MongleFeatures/ProfileEditFeature.swift:209" received a presentation action when destination state was absent.

  Action:
    ProfileEditFeature.Action.groupManagement(.presented(.copiedToastDismissed))
```

TCA의 `ifLet`이 `groupManagement` state가 nil인 상태에서 `copiedToastDismissed` 액션을 받아 발생하는 오류.

---

## 원인 분석

**문제 흐름:**
1. 유저가 초대 코드 복사 버튼 탭 → `inviteCodeCopyTapped` 처리 → `showCopiedToast = true`
2. `GroupManagementView`의 `.task(id: store.showCopiedToast)`에서 2초 타이머 시작
3. 유저가 2초 이내에 뒤로 가기 → `closeTapped` → `delegate(.close)` 발생
4. `ProfileEditFeature`에서 `state.groupManagement = nil` 처리
5. 2초 후 View의 `.task`에서 `store.send(.copiedToastDismissed)` 발생
6. 이미 `groupManagement` state가 nil이므로 TCA 오류

**핵심:** 타이머 라이프사이클이 Reducer가 아닌 View에 있어서, View 해제 시 타이머 취소가 보장되지 않음.

---

## 수정 내용

### 1. `GroupManagementFeature.swift`

**타이머를 Reducer로 이동하고 취소 가능하게 변경:**

- `CancelID.copiedToast` 추가
- `inviteCodeCopyTapped`: 기존에는 `UIPasteboard` 복사만 했지만, 이제 2초 후 `copiedToastDismissed`를 발송하는 취소 가능한 effect 반환
- `closeTapped`: 타이머 effect 취소 후 delegate 발송

### 2. `GroupManagementView.swift`

- `.task(id: store.showCopiedToast)` 블록 제거 (Reducer가 담당하므로 불필요)

---

## 결과

- `closeTapped` 시 타이머가 Reducer 레벨에서 즉시 취소됨
- `state.groupManagement = nil` 이후 `copiedToastDismissed` 액션이 발송되지 않음
- TCA 오류 해소
