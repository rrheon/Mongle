# 작업 보고 - 그룹 나가기 기능

## 구현 내용

### 흐름 요약

**일반 멤버**:
1. 그룹 화면에서 그룹 카드 길게 누름 → "그룹 나가기" 선택
2. 확인 알림 → "나가기" 버튼
3. `DELETE /families/leave` 호출 → 완료 후 그룹 선택 화면 갱신

**방장**:
1. 그룹 카드 길게 누름 → "그룹 나가기" 선택
2. 서버에서 그룹 멤버 목록 조회
3. 위임 시트 표시 → 멤버 선택
4. "위임하고 나가기" 버튼
5. `PATCH /families/transfer-creator` → `DELETE /families/leave` 순차 호출
6. 완료 후 그룹 선택 화면 갱신

---

## 변경 파일

### 서버

#### `src/models/index.ts`
- `TransferCreatorRequest` 인터페이스 추가: `{ newCreatorId: string }`

#### `src/services/FamilyService.ts`
- `transferCreator(userId, newCreatorId)` 메서드 추가
  - 현재 방장인지 검증
  - 대상이 같은 가족 멤버인지 검증
  - `Family.createdById`를 새 방장으로 업데이트

#### `src/controllers/FamilyController.ts`
- `Patch` 데코레이터 import 추가
- `TransferCreatorRequest` import 추가
- `PATCH /families/transfer-creator` 엔드포인트 추가

#### `src/routes/routes.ts` (tsoa 자동 생성)
- `PATCH /families/transfer-creator` 라우트 자동 추가됨

---

### iOS

#### `Domain/Sources/Domain/Repositories/FamilyRepositoryProtocol.swift`
- `leaveFamily() async throws` 추가
- `transferCreator(newCreatorId: UUID) async throws` 추가
- `getGroupWithMembers(id: UUID) async throws -> (MongleGroup, [User])` 추가

#### `MongleData/Sources/MongleData/Repositories/FamilyRepository.swift`
- 위 3개 메서드 구현

#### `MongleData/Sources/MongleData/DataSources/Remote/API/APIEndpoint.swift`
- `FamilyEndpoint.transferCreator(newCreatorId: String)` 케이스 추가
  - path: `PATCH /families/transfer-creator`
  - body: `{ newCreatorId: String }`

#### `MongleFeatures/.../Group/GroupSelectFeature.swift`
- State에 추가:
  - `currentUserId: UUID?` — 방장 여부 판단용
  - `groupToLeave: MongleGroup?`, `showLeaveConfirmation: Bool`
  - `transferCandidates: [User]`, `showTransferSheet: Bool`
  - `selectedTransferMemberId: UUID?`, `isProcessingLeave: Bool`
- Action에 추가:
  - `leaveGroupTapped(MongleGroup)`, `confirmLeave`, `cancelLeaveConfirmation`
  - `setTransferCandidates([User])`, `transferMemberSelected(UUID)`
  - `confirmTransferAndLeave`, `dismissTransferSheet`
- Delegate에 추가:
  - `leaveGroup(MongleGroup)`, `transferCreatorAndLeave(newCreatorId:group:)`
  - `requestMembersForGroup(MongleGroup)`
- Reducer 로직:
  - 방장이면 멤버 목록 요청 → 위임 시트 표시
  - 일반 멤버면 확인 알림 표시

#### `MongleFeatures/.../Group/GroupSelectView.swift`
- 그룹 카드에 `.contextMenu` 추가 — 길게 누르면 "그룹 나가기" 메뉴 표시
- 일반 멤버용 확인 `.alert` 추가
- 방장용 위임 `.sheet` 추가 (`transferCreatorSheet` 뷰)
  - 멤버 목록 표시, 선택 후 "위임하고 나가기" 버튼

#### `MongleFeatures/.../Root/Ext/Root+Reducer.swift`
- `groupSelect.currentUserId` 설정 위치 추가:
  - `loadDataResponse` (그룹 선택 화면 진입 시)
  - `mainTab(.delegate(.navigateToGroupSelect))` (홈에서 그룹 전환 시)
- 새 delegate 핸들러 추가:
  - `.requestMembersForGroup` → `getGroupWithMembers` 호출 → `setTransferCandidates` 피드백
  - `.leaveGroup` → `leaveFamily()` 호출 → `.completed`
  - `.transferCreatorAndLeave` → `transferCreator()` + `leaveFamily()` 순차 호출 → `.completed`

---

## 제약 사항 (Work.md 요구사항 반영)

| 요구사항 | 구현 |
|---------|------|
| 방장인 경우 위임 후 나가기 | ✅ 위임 시트 → transferCreator → leaveFamily |
| 멤버 데이터 삭제 | ✅ FamilyMembership 삭제 (서버 기존 leaveFamily 로직) |
| 답변 데이터 유지 | ✅ Answer 삭제 없음 (Answer.questionId는 그대로 유지) |
