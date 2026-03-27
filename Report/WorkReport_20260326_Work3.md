# 작업 보고서 — 2026-03-26 (Work.md 3차)

## 작업 항목

### 1. GroupSelectView — "몇일 연속" UI 및 기능 제거

**변경 파일:**
- `MongleFeatures/.../Design/Components.swift`
- `MongleFeatures/.../Presentation/Group/GroupSelectView+Select.swift`

**내용:**
- `MongleCardGroup` 컴포넌트에서 `streakDays: Int?` 프로퍼티, init 파라미터, `"N일 연속"` 뱃지 UI 블록 전체 제거
- `GroupSelectView+Select.swift`에서 `MongleCardGroup` 생성 시 `streakDays:` 인자 제거

**참고:**
- `MongleHeaderHome`의 `streakDays` (홈 화면 헤더 배지)는 별도 컴포넌트로 이번 작업 범위에 해당하지 않아 유지
- 서버 `streakDays` 계산 로직(`getFamilyStreakDays`) 및 도메인 엔티티 필드는 홈 화면에서 계속 사용하므로 유지

---

### 2. 그룹관리View — 내보내기 버튼 수정

#### 2-1. 일반 유저 ellipsis 버튼 제거
**변경 파일:** `MongleFeatures/.../Presentation/Support/GroupManagementView.swift`

**내용:**
- 기존 코드에 `else if !member.isOwner { Image(systemName: "ellipsis") }` 블록이 있어 일반 유저도 각 멤버 셀에 `...` 아이콘이 표시됨
- 해당 블록 제거 → 방장만 "내보내기" 버튼 노출, 일반 유저는 버튼 없음

#### 2-2. 서버 kickMember 버그 수정
**변경 파일:** `MongleServer/src/services/FamilyService.ts`

**발견된 버그:**
1. 대상 멤버를 `prisma.user.findFirst({ where: { id, familyId } })`로 조회 → `user.familyId`는 현재 활성 가족만 나타내므로, 대상 멤버가 다른 그룹을 활성 그룹으로 선택했을 경우 조회 실패 → "대상 가족 구성원을 찾을 수 없음" 오류 발생
2. 내보내기 처리 시 `user.familyId`만 null로 설정 → `FamilyMembership` 레코드가 그대로 남아, 다음 데이터 로드 시 멤버가 다시 표시되는 문제

**수정 내용:**
- 대상 멤버 조회를 `FamilyMembership` 테이블 기준으로 변경 (`userId_familyId` 복합키로 정확하게 조회)
- 내보내기 시 트랜잭션 내에서 `FamilyMembership` 레코드 삭제
- 대상 멤버의 활성 가족이 해당 가족이었을 경우 다른 그룹으로 전환(없으면 null)

---

## 서버 재시작 필요
`MongleServer` 코드 수정 사항 반영을 위해 서버 재시작 필요
