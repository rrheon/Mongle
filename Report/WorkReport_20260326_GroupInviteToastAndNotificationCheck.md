# 작업 보고서 - GroupManagementView 토스트 및 알림설정 확인

**날짜**: 2026-03-26
**작업 파일**:
- `MongleFeatures/Sources/MongleFeatures/Presentation/Common/MongleToastView.swift`
- `MongleFeatures/Sources/MongleFeatures/Presentation/Support/GroupManagementFeature.swift`
- `MongleFeatures/Sources/MongleFeatures/Presentation/Support/GroupManagementView.swift`

---

## 1. GroupManagementView - groupInfoSection 개선

### 변경 사항

#### (1) 초대 코드 복사 시 토스트 메세지 추가

**문제**: 초대 코드 복사 버튼 클릭 시 클립보드에 복사는 되었으나 사용자에게 피드백이 없었음.
주석으로 `store.send(.toastMessage(...))` 가 있었으나 해당 Action이 Feature에 정의되어 있지 않아 비활성 상태였음.

**해결**:
- `ToastType`에 `inviteCodeCopied` 케이스 추가 (icon: `doc.on.doc.fill`, message: "초대 코드가 복사되었습니다")
- `GroupManagementFeature.State`에 `showCopiedToast: Bool = false` 추가
- `Action`에 `inviteCodeCopyTapped`, `copiedToastDismissed` 추가
- 기존에 View에서 직접 `UIPasteboard`를 호출하던 방식을 Feature로 이동 (TCA 패턴 준수)
- View에 `overlay(alignment: .bottom)` + `.task(id:)` 패턴으로 2초 후 자동 해제 토스트 추가

#### (2) 링크 유효성 확인

**확인 결과**: `inviteCode`는 `onAppear` 시 API에서 로드됨.
로드 전(`inviteCode == ""`)일 때 ShareLink가 `https://mongle.app/invite/` (유효하지 않은 링크)를 공유하는 문제가 있었음.

**해결**:
- 복사 버튼과 공유 버튼 모두 `inviteCode.isEmpty`일 때 `.disabled(true)` 처리
- value 표시도 로딩 중일 때 `"불러오는 중..."` 플레이스홀더 표시

---

## 2. 알림설정화면 - 토글 저장 확인

### 확인 결과

`NotificationSettingsFeature.swift` 분석:

```swift
// 저장
case .toggleChanged(let id, let isOn):
    state.notificationItems[index].isOn = isOn
    UserDefaults.standard.set(isOn, forKey: "notification.\(id)")

// 로드 (init)
isOn: ud.object(forKey: "notification.r1") as? Bool ?? true
```

**결론: UserDefaults 저장/불러오기는 정상 동작함.**

### 이슈 사항 (별도 작업 필요)

현재 알림 설정은 **로컬(UserDefaults)에만 저장**되며, 서버나 APNs에는 전달되지 않음.

이는 다음 경우에 문제가 될 수 있음:
- 앱 재설치 시 설정 초기화
- 서버에서 직접 푸시를 보내는 경우 (r1: 답변 알림, r3: 재촉 알림, r5: 새 질문 알림) 클라이언트의 설정을 서버가 알 수 없음

**현재 작동 방식**: 클라이언트에서 알림을 수신한 후 UserDefaults 값에 따라 **화면 표시 여부만 제어**하는 로컬 필터링 방식으로 추정됨.

서버 연동이 필요한 경우 별도 API 작업이 필요함. 현재 작업 범위에서는 코드 변경 없이 확인만 완료함.
