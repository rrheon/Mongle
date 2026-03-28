# 작업 보고서 — 2026-03-27 (Work.md 10차)

## 작업 항목

### 서버 프로젝트 unstaged 변경사항 커밋

**서버 경로:** `/Users/yong/Desktop/MongleServer`

**커밋 내역:**

| 커밋 해시 | 메시지 | 변경 파일 |
|-----------|--------|-----------|
| `c0d0fa0` | `fix: kickMember가 FamilyMembership 기준으로 구성원을 내보내도록 수정` | `src/services/FamilyService.ts` |

**변경 내용 요약:**
- `user.findFirst({ familyId })` → `familyMembership.findUnique` 기준으로 대상 구성원 조회
- `user.update({ familyId: null })` → `familyMembership.delete()` 트랜잭션으로 처리
- 내보낸 멤버의 활성 가족을 다음 멤버십으로 자동 전환 (없으면 null)
- TypeScript 타입 내로잉: `const familyId = admin.familyId`

**결과:** 작업 트리 클린, origin/main보다 1 커밋 앞선 상태 (push 대기)
