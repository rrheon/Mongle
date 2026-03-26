# 작업 보고서 — 알림 설정 개선 (2026-03-26)

## 작업 내용

---

### 1. 방해 금지 시간 Toggle 추가

**문제:** 방해 금지 시간이 단순 텍스트+chevron으로만 표시되어 on/off 제어 불가

**변경 파일:**
- `Support/SupportScreenFeature.swift`
- `Support/SupportScreenView.swift`

**내용:**
- `State`에 `quietHoursEnabled: Bool` 추가 (UserDefaults `"notification.quietHours"` 로 초기화, 기본값 `true`)
- `Action.quietHoursToggleChanged(Bool)` 추가 → reducer에서 state 및 UserDefaults 업데이트
- `notificationSettingsView` 방해 금지 시간 row를 toggle UI로 교체
  - ON: 오후 10:00~오전 8:00 사이 알림 차단
  - OFF: 시간 관계없이 알림 전송
- 알림 섹션 그루핑도 함께 수정: `prefix(1)`, `dropFirst(1).prefix(1)`, `dropFirst(2)` — 각 섹션에 항목 1개씩 정확히 배분

---

### 2. GroupSelect 알림 허용 플로우 추가

**문제:** 최초 그룹 생성/참여 시 알림 설정 UI가 없었고, Root에서 OS 다이얼로그 하나만 표시됨

**변경 파일:**
- `Group/GroupSelectFeature.swift`
- `Group/GroupSelectView.swift`
- `Group/GroupSelectView+NotificationPermission.swift` (신규)
- `Root/Ext/Root+Reducer.swift`

**플로우 (최초 1회, `mongle.didShowNotificationSetup` 키로 관리):**

```
그룹 생성/참여 성공
    ↓
[notificationPermission] 알림 허용 단계
  - 허용하기 → iOS 알림 권한 요청 + APNs 등록 → quietHoursPermission
  - 나중에   → quietHoursPermission
    ↓
[quietHoursPermission] 방해 금지 시간 단계
  - 사용하기   → notification.quietHours = true  → 완료
  - 건너뛰기   → notification.quietHours = false → 완료
    ↓
그룹 생성: groupCreated 화면 표시
그룹 참여: 홈으로 이동
```

**Step enum 추가:**
```swift
case notificationPermission
case quietHoursPermission
```

**Action 추가:**
```swift
case setJoinSuccess
case notificationPermissionAllowed
case notificationPermissionSkipped
case quietHoursPermissionEnabled
case quietHoursPermissionSkipped
```

**Root+Reducer 변경:**
- join 성공 시 `delegate(.completed)` 대신 `setJoinSuccess` 전송
- `setJoinSuccess`: `didShowNotificationSetup` 확인 후 알림 설정 or 바로 완료

**공통 설정:** `mongle.didShowNotificationSetup` UserDefaults 키로 앱 전체 1회만 표시 (그룹별 개별 설정 없음)

---

### UI 진행 표시 (Progress Bar)

| Step | 1번 | 2번 | 3번 |
|------|-----|-----|-----|
| notificationPermission | 색상 | 색상 | 회색 |
| quietHoursPermission   | 색상 | 색상 | 색상 |

---

### 이슈 없음
- xcodebuild CLI의 SwiftSyntax 매크로 오류는 사전 존재 이슈로, 작업 변경과 무관
