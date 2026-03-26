# 작업 보고서 — 2026-03-26

## 작업 내용 (Work.md 기준)

---

### 1. PopupView → MonglePopupView 변환

**대상**: 로그아웃, 계정탈퇴, 그룹나가기, 프로필 편집 저장 시

**변경 파일**:
- `AccountManagementView.swift`: 로그아웃·계정탈퇴 `.alert` → `.overlay { MonglePopupView(...) }`
- `GroupManagementView.swift`: 그룹 나가기 `.alert` → `.overlay { MonglePopupView(...) }`
- `ProfileEditView.swift`: 게스트 로그인 안내 `.alert` → `.overlay { MonglePopupView(...) }`
- `MongleCardEditView.swift`: 프로필 편집 저장 실패 `.alert` → `.overlay { MonglePopupView(...) }`
- `MainTabView.swift`: HomeView 내 게스트 로그인 `.alert` → `.overlay { MonglePopupView(...) }`

**방식**: 기존 SwiftUI `.alert`를 제거하고, `.overlay { if condition { MonglePopupView(...) } }` 패턴으로 통일. `MonglePopupView`는 이미 배경 dimming과 커스텀 아이콘·버튼을 지원하는 컴포넌트였으므로 별도 신규 컴포넌트 없이 교체.

---

### 2. HomeView 그룹 드롭다운 외부 터치 시 닫기

**변경 파일**: `HomeView.swift`

**문제**: 기존 코드에서 배경 dimming(`Color.black.opacity(0.3)`)에 `.zIndex(-1)`을 붙여 ZStack 내 순서를 역전시켰으나, 이 때문에 탭 이벤트가 상위 레이어에 차단되어 실제로 드롭다운 외부 터치 시 닫히지 않는 문제가 있었음.

**수정**: `.zIndex(-1)` 제거 후 ZStack 내 렌더링 순서를 변경.
- (Before) GroupDropdownView → Color.black(zIndex: -1)
- (After) Color.black → GroupDropdownView

이제 배경이 아래 레이어에, 드롭다운이 위 레이어에 위치하여 드롭다운 외부 영역 터치 시 배경이 탭 이벤트를 정상적으로 수신함.

---

### 3. 그룹 이름 최대 10자 제한

**변경 파일**:
- `GroupSelectFeature.swift`: `groupNameChanged` 케이스에서 `prefix(15)` → `prefix(10)`
- `GroupSelectView+CreateGroup.swift`:
  - 공간 이름 레이블 옆에 글자수 카운터 `"\(count)/10"` 추가 (10자 도달 시 빨간색 표시)
  - 힌트 텍스트를 `"가족, 친한 친구, 커플 등 자유롭게! (최대 10자)"`로 업데이트

그룹명 수정 화면은 별도 Feature/View가 있을 경우 해당 Feature에도 동일한 제한이 필요할 수 있음. 현재 생성 플로우(`GroupSelectFeature`)에만 적용함.

---

### 4. 알림 허용 타이밍 변경 — 그룹 첫 접속 시, 그룹별 관리

**기존 흐름**: 그룹 생성/참여 완료 직후 알림 허용 → 방해 금지 시간 설정 → 홈으로 이동

**변경 후 흐름**: 그룹 생성/참여 완료 시 알림 단계 없이 바로 홈으로 이동. 홈 화면 진입(`onAppear`) 시 해당 그룹에 대한 알림 설정 여부를 확인해 미설정이면 팝업 표시.

**변경 파일**:

`GroupSelectFeature.swift`:
- `setInviteCode`: 기존 `mongle.didShowNotificationSetup` 체크 + 알림 단계 분기 제거 → 무조건 `.groupCreated` 이동
- `setJoinSuccess`: 기존 알림 단계 분기 제거 → 무조건 `.delegate(.completed)` 호출

`HomeFeature.swift`:
- `UserNotifications`, `UIKit` import 추가
- `State`에 `showNotificationPermission: Bool` 추가
- `Action`에 `notificationPermissionAllowed`, `notificationPermissionSkipped` 추가
- `onAppear` 케이스: 현재 그룹 ID 기반 UserDefaults 키(`mongle.notifSetup.<groupId>`) 확인 → 미설정이면 `showNotificationPermission = true`
- `notificationPermissionAllowed`: UNUserNotificationCenter 권한 요청 + APNs 등록 + 해당 그룹 키 저장
- `notificationPermissionSkipped`: 해당 그룹 키 저장(다시 묻지 않음) + 팝업 닫기

`HomeView.swift`:
- `HomeViewActions`에 `onNotificationPermissionAllowed`, `onNotificationPermissionSkipped` 추가
- `showNotificationPermission: Bool` 프로퍼티 추가
- `body`에 `.overlay { if showNotificationPermission { MonglePopupView(...) } }` 추가

`MainTabView.swift`:
- `homeViewSection`에서 HomeView 생성 시 `showNotificationPermission`과 알림 액션 연결

**그룹별 관리**: UserDefaults 키를 `mongle.notifSetup.<UUID>` 형태로 각 그룹마다 독립 저장하여, 그룹을 전환하더라도 해당 그룹에 처음 접속하면 다시 알림 허용 팝업이 표시됨.

---

## 이슈 / 참고사항

- `GroupSelectFeature.State`의 `isFromJoin` 프로퍼티는 알림 단계 제거로 인해 사용되지 않게 됨. 추후 정리 가능.
- `mongle.didShowNotificationSetup` UserDefaults 키도 더 이상 사용되지 않음. 추후 정리 가능.
- SourceKit 빌드 오류(`No such module 'ComposableArchitecture'`)는 편집기 인덱스 문제로 실제 빌드에는 영향 없음.
