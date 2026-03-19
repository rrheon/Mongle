# 작업 결과 보고 (2026-03-16)

## 문제 요약
GroupSelect 화면에서 그룹 생성 시 "서버에 문제가 발생했어요 (500)" 에러 발생

---

## 원인 분석

### 서버 500 에러 원인
`node dist/app.js`로 실행 중이던 **구 컴파일된 서버**가 문제였음.

- 구 서버 (PID 79328, `node dist/app.js`)는 이전에 존재했던 `TreeService`가 포함된 **구 Prisma 클라이언트**를 메모리에 로드한 상태
- `dist/` 폴더에 `TreeService.js`가 남아 있었고, 구 Prisma 클라이언트는 `treeProgress` 모델을 알고 있었음
- 실제 DB에는 `tree_progress` 테이블이 없어서 → **500 에러** 발생
- 즉, 서버 코드와 DB 스키마가 불일치하는 구 빌드가 계속 실행 중이었음

### 자동 로그인 (정상 동작 확인)
"로그인을 거치지 않고 GroupSelect 화면으로 이동" → **정상적인 자동 로그인 동작**

- 카카오 로그인 후 JWT 토큰이 iOS 키체인에 저장됨
- 앱 재시작 시 `GET /users/me`로 자동 인증 → 사용자 정보 확인 → GroupSelect 화면으로 이동
- JWT 토큰은 정상적으로 서버에 전달되고 있음

---

## 수정 사항

### 서버 (FamTreeServer)
1. `dist/` 폴더 완전 삭제 후 새로 빌드
   - `npx tsoa spec-and-routes` → tsoa 라우트/스펙 재생성
   - `npx tsc` → TypeScript 컴파일 (구 TreeService.js 등 제거됨)
2. 구 서버 (PID 79328) 종료, 새 서버 포트 3000 에서 재시작

### iOS (FamTree) — 이전 세션에서 수정 완료
- `FamilyEndpoint.create` body: `{ role: "creator" }` → `{ name: ..., creatorRole: "OTHER" }` (서버 필드명 일치)
- `FamilyEndpoint.join` body: `{ invite_code }` → `{ inviteCode, role: "OTHER" }` (서버 필드명 일치)
- `FamilyRepository.create/joinFamily`: `FamilyDTO` → `FamilyResponseDTO` 디코딩 (서버 응답 형식 일치)
- `UserEndpoint.updateUser` 경로: `/users/{id}` → `/users/me` (서버 실제 경로 일치)
- 닉네임 입력값: `PUT /users/me` 호출로 사용자 이름 업데이트

---

## API 테스트 결과

| 엔드포인트 | 상태 |
|---|---|
| `GET /users/me` (자동 로그인) | ✅ 정상 |
| `POST /families` (그룹 생성) | ✅ 정상 |
| `POST /families/join` (초대코드 참여) | ✅ 정상 |
| `GET /families/all` (내 그룹 목록) | ✅ 정상 |
| `GET /families/my` (현재 활성 그룹) | ✅ 정상 |
| `PUT /users/me` (닉네임 업데이트) | ✅ 정상 |
| `POST /families/{id}/select` (그룹 전환) | ✅ 정상 |

---

## 향후 주의사항
- **서버 재시작 시**: `npm run dev` (nodemon) 또는 `npm start` (dist) 사용 전 `npm run build`로 빌드 필수
- 스키마 변경 시 `npx prisma db push` + `npx prisma generate` 실행 후 서버 재시작 필요
