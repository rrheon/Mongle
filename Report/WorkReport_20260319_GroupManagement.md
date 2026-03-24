# 작업 보고 - 그룹관리화면 데이터 연동

## 구현 내용

그룹관리화면(`SupportScreenFeature` / `SupportScreenView`)이 하드코딩된 더미 데이터로 표시되던 문제를 수정하여 실제 서버 데이터와 연동했습니다.

### 문제점
- `groupName`, `inviteCode`, `members` 모두 하드코딩된 목 데이터
- "그룹 나가기" 버튼이 `removeMember()` (내보내기 API)를 잘못 호출
- 방장인 경우 위임 없이 나갈 수 없음에도 위임 플로우 없음
- 나간 후 그룹 선택 화면으로 돌아가지 않음

---

## 변경 파일

### `MongleFeatures/.../Support/SupportScreenFeature.swift`

- `init()` 내 하드코딩 데이터 제거: `groupName = ""`, `inviteCode = ""`, `members = []`
- State에 추가:
  - `transferCandidates: [GroupMember]` — 위임 대상 목록
  - `showTransferSheet: Bool` — 위임 시트 표시 여부
  - `selectedTransferMemberId: UUID?` — 선택한 위임 대상
- Action에 추가:
  - `groupDataLoaded(MongleGroup, [User])` — 서버 데이터 수신
  - `transferMemberSelected(UUID)` — 위임 멤버 선택
  - `confirmTransferAndLeave` — 위임 후 나가기 확정
  - `dismissTransferSheet` — 위임 시트 닫기
- Delegate에 추가: `groupLeft` — 나가기 완료 후 상위에 알림
- `onAppear`:
  - 화면이 `.groupManagement`인 경우 `familyRepository.getGroupWithMembers(id:)` 호출
  - 응답 → `groupDataLoaded` 전송
- `groupDataLoaded`:
  - `groupName`, `inviteCode` 업데이트
  - `members` 실제 사용자 목록으로 업데이트 (방장 여부 판별, 가입 날짜 표시)
- `leaveGroupConfirmed` 수정:
  - 기존: `removeMember()` (잘못된 API)
  - 수정: 방장이면 위임 시트 표시, 일반 멤버면 `leaveFamily()` 호출
  - 완료 후 `delegate(.groupLeft)` 전송
- `confirmTransferAndLeave`:
  - `transferCreator()` → `leaveFamily()` 순차 호출
  - 완료 후 `delegate(.groupLeft)` 전송

### `MongleFeatures/.../Support/SupportScreenView.swift`

- 방장 위임 시트 (`transferCreatorSheet`) 추가:
  - 멤버 목록 표시 및 선택
  - "위임하고 나가기" 버튼 (멤버 선택 전 비활성화)
  - "취소" 버튼으로 `dismissTransferSheet` 전송

### `MongleFeatures/.../Profile/ProfileEditFeature.swift`

- `Delegate`에 `groupLeft` 추가
- `supportScreen(.presented(.delegate(.groupLeft)))` 핸들러 추가:
  - 서포트 화면 닫고 `delegate(.groupLeft)` 버블업

### `MongleFeatures/.../MainTab/Ext/MainTab+Reducer.swift`

- `profile(.delegate(.groupLeft))` 핸들러 추가:
  - `delegate(.navigateToGroupSelect)` 전송 → Root에서 그룹 선택 화면으로 전환

---

## 데이터 흐름

| 단계 | 흐름 |
|------|------|
| 화면 진입 | `onAppear` → `getGroupWithMembers()` → `groupDataLoaded` → 실제 이름/코드/멤버 표시 |
| 일반 멤버 나가기 | 확인 → `leaveFamily()` → `delegate(.groupLeft)` → Profile → MainTab → GroupSelect 화면 |
| 방장 나가기 | 확인 → 위임 시트 → 멤버 선택 → `transferCreator()` + `leaveFamily()` → GroupSelect 화면 |
| 초대 코드 복사 | `inviteTapped` → 클립보드에 실제 코드 복사 |

---

## 제약 사항 (Work.md 요구사항 반영)

| 요구사항 | 구현 |
|---------|------|
| 실제 있는 인원 표시 | ✅ `getGroupWithMembers` API로 실제 멤버 로드 |
| 실제 그룹 이름, 코드 연결 | ✅ `MongleGroup.name`, `MongleGroup.inviteCode` 바인딩 |
| 그룹 나가기 기능 연결 | ✅ `leaveFamily()` + 방장 위임 플로우 + GroupSelect 화면 이동 |
