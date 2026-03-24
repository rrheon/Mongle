# 서버 테스트 계획

> 프레임워크: Jest + ts-jest (이미 package.json에 설정됨)
> 추가 필요: supertest (HTTP 통합 테스트용)

---

## 1. 단위 테스트 (Unit Tests) — 서비스 레이어

서비스 레이어는 비즈니스 로직이 집중된 곳입니다.
Prisma Client를 `jest.mock`으로 가짜(Mock)로 교체하여 DB 없이 테스트합니다.

### 1-1. QuestionService 테스트
**파일**: `src/services/__tests__/QuestionService.test.ts`

복잡한 질문 배정 로직이 있어 가장 우선순위가 높습니다.

```
테스트 케이스:
- assignDailyQuestion()
  ✓ 가족에게 오늘 질문이 없을 때 새 질문을 배정한다
  ✓ 이미 오늘 질문이 있으면 기존 질문을 반환한다
  ✓ 이전에 사용한 질문은 다시 배정하지 않는다
  ✓ 모든 질문을 소진하면 가장 오래된 질문부터 재사용한다

- createCustomQuestion()
  ✓ familyId가 null이면 에러를 던진다 (null-safe 검증)
  ✓ 하트가 부족하면 에러를 던진다
  ✓ 성공 시 하트를 차감하고 질문을 생성한다

- skipTodayQuestion()
  ✓ 하트가 부족하면 에러를 던진다
  ✓ 성공 시 하트를 차감하고 새 질문을 배정한다
  ✓ 이미 패스한 경우 중복 차감하지 않는다
```

### 1-2. FamilyService 테스트
**파일**: `src/services/__tests__/FamilyService.test.ts`

그룹 로직은 사용자 경험에 직결되며 버그 발생 시 파급이 큽니다.

```
테스트 케이스:
- createFamily()
  ✓ 이미 3개 그룹에 참여 중이면 에러를 던진다
  ✓ 유효한 초대코드가 생성된다 (MONG-XXXX 형식)
  ✓ 생성자가 자동으로 멤버로 등록된다

- joinFamily()
  ✓ 유효하지 않은 초대코드면 에러를 던진다
  ✓ 이미 참여 중인 그룹이면 에러를 던진다
  ✓ 3개 그룹 한도를 초과하면 에러를 던진다
  ✓ 성공 시 멤버십이 생성된다

- leaveFamily()
  ✓ 방장이 나갈 때 다른 멤버가 없으면 그룹이 삭제된다
  ✓ 방장이 나갈 때 위임 대상 없이 요청하면 에러를 던진다
  ✓ 방장 위임 후 나가기가 정상 처리된다
  ✓ 일반 멤버 탈퇴 시 멤버십만 삭제된다
```

### 1-3. AuthService 테스트
**파일**: `src/services/__tests__/AuthService.test.ts`

```
테스트 케이스:
- generateTokens()
  ✓ accessToken과 refreshToken이 모두 반환된다
  ✓ accessToken payload에 userId가 포함된다

- verifyAccessToken()
  ✓ 유효한 토큰은 payload를 반환한다
  ✓ 만료된 토큰은 에러를 던진다
  ✓ 변조된 토큰은 에러를 던진다

- refreshAccessToken()
  ✓ 유효한 refreshToken으로 새 accessToken을 발급한다
  ✓ 무효한 refreshToken은 에러를 던진다
```

### 1-4. AnswerService 테스트
**파일**: `src/services/__tests__/AnswerService.test.ts`

```
테스트 케이스:
- submitAnswer()
  ✓ 이미 답변한 경우 중복 제출을 막는다
  ✓ 첫 답변 시 하트 +1이 지급된다
  ✓ 하루 최대 하트 지급 한도를 초과하지 않는다

- getByDailyQuestion()
  ✓ 해당 가족 멤버의 답변만 반환된다
  ✓ 다른 가족 답변은 포함되지 않는다
```

### 1-5. NotificationService 테스트
**파일**: `src/services/__tests__/NotificationService.test.ts`

```
테스트 케이스:
- getNotifications()
  ✓ 해당 유저의 알림만 반환된다
  ✓ limit 파라미터가 적용된다
  ✓ isRead 필터가 적용된다

- markAllAsRead()
  ✓ 해당 유저의 모든 알림이 읽음 처리된다
  ✓ 다른 유저의 알림은 영향받지 않는다

- deleteAllNotifications()
  ✓ 해당 유저의 모든 알림이 삭제된다
  ✓ 삭제된 건수를 반환한다
```

---

## 2. 통합 테스트 (Integration Tests) — API 엔드포인트

supertest를 사용하여 HTTP 레이어부터 서비스까지 통합 테스트합니다.
실제 DB 대신 테스트 DB 또는 Prisma Mock을 사용합니다.

### 2-1. 인증 API
**파일**: `src/controllers/__tests__/AuthController.test.ts`

```
테스트 케이스:
POST /auth/refresh
  ✓ 유효한 refreshToken → 200 + 새 accessToken
  ✓ 무효한 refreshToken → 401

POST /auth/logout
  ✓ 인증 없이 요청 → 401
  ✓ 인증 후 요청 → 200
```

### 2-2. 가족 그룹 API
**파일**: `src/controllers/__tests__/FamilyController.test.ts`

```
테스트 케이스:
POST /families
  ✓ 인증 없이 → 401
  ✓ 인증 후 정상 생성 → 201 + 그룹 정보 + 초대코드

POST /families/join
  ✓ 잘못된 초대코드 → 400/404
  ✓ 정상 참여 → 200

DELETE /families/:id/leave
  ✓ 마지막 멤버 탈퇴 → 200 + 그룹 삭제됨
```

### 2-3. 질문 API
**파일**: `src/controllers/__tests__/QuestionController.test.ts`

```
테스트 케이스:
GET /questions/today
  ✓ 인증 없이 → 401
  ✓ 인증 후 → 200 + 오늘의 질문

POST /questions/skip
  ✓ 하트 부족 → 400
  ✓ 정상 패스 → 200 + 새 질문 + 남은 하트
```

---

## 3. 유틸리티 테스트

### 3-1. inviteCode 유틸리티
**파일**: `src/utils/__tests__/inviteCode.test.ts`

```
테스트 케이스:
generateInviteCode()
  ✓ 생성된 코드가 MONG-XXXX 형식을 따른다
  ✓ 동일 코드가 중복 생성되지 않는다 (100회 샘플)
  ✓ 대문자와 숫자만 포함된다
```

### 3-2. JWT 유틸리티
**파일**: `src/utils/__tests__/jwt.test.ts`

```
테스트 케이스:
  ✓ 생성 → 검증 왕복이 정상 동작한다
  ✓ 만료 시간이 올바르게 적용된다
```

---

## 4. 구현 방법

### 환경 설정

```bash
# supertest 추가
npm install --save-dev supertest @types/supertest

# jest 설정 확인 (package.json)
# ts-jest는 이미 설치됨
```

### Prisma Mock 패턴

```typescript
// __mocks__/prisma.ts
import { PrismaClient } from '@prisma/client';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';

export type Context = {
  prisma: PrismaClient;
};

export type MockContext = {
  prisma: DeepMockProxy<PrismaClient>;
};

export const createMockContext = (): MockContext => ({
  prisma: mockDeep<PrismaClient>(),
});
```

### 테스트 파일 위치 규칙

```
src/
  services/
    __tests__/
      QuestionService.test.ts
      FamilyService.test.ts
      AuthService.test.ts
      AnswerService.test.ts
      NotificationService.test.ts
  controllers/
    __tests__/
      AuthController.test.ts
      FamilyController.test.ts
      QuestionController.test.ts
  utils/
    __tests__/
      inviteCode.test.ts
      jwt.test.ts
```

---

## 5. 진행 순서 (우선순위)

| 순서 | 대상 | 이유 |
|------|------|------|
| 1 | QuestionService | 가장 복잡한 비즈니스 로직, 질문 배정 버그 시 서비스 전체 영향 |
| 2 | FamilyService | 그룹 한도/초대코드 로직, 실제 버그 발생 이력 |
| 3 | AuthService (JWT) | 보안 핵심 영역 |
| 4 | AnswerService | 하트 지급 로직 |
| 5 | NotificationService | 상대적으로 단순, 빠르게 커버 가능 |
| 6 | API 통합 테스트 | 단위 테스트 안정화 후 진행 |
