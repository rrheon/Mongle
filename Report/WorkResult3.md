# 작업 결과 — 그룹별 독립 데이터

## 문제 분석

서버 로그 `PUT /users/me { name: 'ㅁㅁㅁㅁ', role: '기타', ... }` 에서 확인된 4가지 원인:

| # | 위치 | 문제 | 영향 |
|---|------|------|------|
| 1 | 서버 `GET /users/me` | 글로벌 `User.name`, `User.hearts`, `User.role` 반환 | 그룹 전환 후에도 이전 그룹 이름/하트 표시 |
| 2 | 서버 `PUT /users/me` | 글로벌 `User.name`, `User.role` 업데이트 | 닉네임 변경이 모든 그룹에 공유됨 |
| 3 | 서버 `recordAccess` | 글로벌 `User.hearts` 증가 | 일일 하트 지급이 그룹별로 반영 안 됨 |
| 4 | iOS `UserMapper.toDTO` | `role` rawValue가 한글(`"기타"`)로 전송 | 서버 enum 불일치, role 업데이트 실패 |

---

## 수정 내용

### 서버: `FamTreeServer/src/services/UserService.ts`

**1. `getUserByUserId` — 그룹별 데이터 반환**
- 활성 `familyId`가 있으면 `FamilyMembership` 조회
- `name` → `membership.nickname ?? User.name`
- `hearts` → `membership.hearts`
- `role` → `membership.role`
- 가족 없거나 멤버십 없으면 기존 글로벌 데이터 반환

**2. `updateUser` — 그룹별/글로벌 분리 업데이트**
- `name` → 활성 가족의 `FamilyMembership.nickname` 업데이트 (가족 없으면 `User.name`)
- `role` → 활성 가족의 `FamilyMembership.role` 업데이트
- `moodId`, `profileImageUrl` → 글로벌 `User` 업데이트 (기존 유지)

**3. `recordAccess` — 그룹별 하트 지급**
- `User.lastHeartGrantedAt` 업데이트 (타이밍 추적용으로 유지)
- 하트 증가: `User.hearts` → `FamilyMembership.updateMany` (활성 가족)

### iOS: `MongleData/Sources/MongleData/Mappers/UserMapper.swift`

**4. `toDTO` — role 서버 영문 enum 매핑**
- `domain.role.rawValue` (한글: `"기타"`) 대신 `serverRole(from:)` 메서드 사용
- `FamilyRole.other` → `"OTHER"`, `.father` → `"FATHER"` 등 서버 enum과 일치

---

## 데이터 흐름 (수정 후)

```
그룹 A 전환
  ↓
selectFamily API → User.familyId = 그룹A.id
  ↓
refreshHomeData
  ├── GET /users/me → FamilyMembership(그룹A).nickname, hearts, role 반환
  └── GET /families/my → 그룹A 멤버들의 per-group 데이터
  ↓
HomeView: 그룹A의 이름/하트/답변여부 표시

그룹 B 전환
  ↓
(동일 흐름, FamilyMembership(그룹B) 데이터로)
```

---

## 서버 컴파일

```
npx tsc --noEmit → PASS (에러 없음)
```
