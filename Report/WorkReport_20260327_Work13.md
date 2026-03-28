# 작업 보고서 - 2026-03-27 (Work13)

## 작업 내용: 배포 서버 테스트 및 버그 수정

**Base URL**: `https://1cq1kfgvf1.execute-api.ap-northeast-2.amazonaws.com`

---

## 발견된 버그 및 수정 내역

### 버그 1: 모든 API가 `null` 반환 (치명적)

**원인**: `lambda.ts`의 핸들러가 `@codegenie/serverless-express`의 Promise를 반환하지 않음

`serverlessExpress`는 기본적으로 `PROMISE` 모드로 동작한다. 기존 코드는 callback 패턴으로 호출하면서 반환값을 버렸기 때문에, Lambda가 즉시 `null`로 완료됨.

```ts
// 수정 전 (버그)
export const handler = (...): void => {
  serverlessHandler(event, context, callback);  // Promise를 반환 안 함
};

// 수정 후
export const handler = async (event, context): Promise<unknown> => {
  return serverlessHandler(event, context);  // Promise 반환
};
```

---

### 버그 2: Lambda가 RDS에 접근 불가 (치명적)

**원인**: Lambda가 VPC 외부에서 실행되어 RDS 보안 그룹(`sg-0b7e5bb2b2e60c200`)에 막힘

RDS 보안 그룹은 특정 IP(`125.179.66.65/32`)와 같은 SG 내부 트래픽만 허용. Lambda가 VPC 외부에 있어 차단됨.

**수정**: `serverless.yml`에 VPC 설정 추가

```yaml
provider:
  vpc:
    securityGroupIds:
      - sg-0b7e5bb2b2e60c200   # RDS와 동일 보안 그룹 (자기 참조 규칙으로 통신 허용)
    subnetIds:
      - subnet-0118b6d526e51fea1
      - subnet-004ea2f0bd586e7c9
      - subnet-0fb66c2fd273d0320
      - subnet-0e28e7103a7f0f426
```

Lambda IAM에 ENI 생성 권한도 추가:
```yaml
- Effect: Allow
  Action:
    - ec2:CreateNetworkInterface
    - ec2:DescribeNetworkInterfaces
    - ec2:DeleteNetworkInterface
  Resource: '*'
```

---

### 버그 3: 로그인 실패 시 500 반환

**원인**: `AuthService`에서 인증 실패 시 `new Error(...)` (generic Error)를 throw → errorHandler가 500으로 처리

**수정**: `AuthService.ts`에서 적절한 에러 타입으로 변경

| 상황 | 수정 전 | 수정 후 |
|------|---------|---------|
| 로그인 실패 (이메일/비번 불일치) | `new Error(...)` → 500 | `Errors.unauthorized(...)` → 401 |
| 중복 이메일 회원가입 | `new Error(...)` → 500 | `Errors.conflict(...)` → 409 |
| 비밀번호 길이 미달 | `new Error(...)` → 500 | `Errors.badRequest(...)` → 400 |
| 만료된 리프레시 토큰 | `new Error(...)` → 500 | `Errors.unauthorized(...)` → 401 |

---

## 최종 테스트 결과

| 엔드포인트 | 결과 | HTTP |
|-----------|------|------|
| GET /health | ✅ 정상 | 200 |
| POST /auth/email/signup | ✅ 정상 | 201 |
| POST /auth/email/signup (중복) | ✅ 정상 | 409 |
| POST /auth/email/login | ✅ 정상 | 200 |
| POST /auth/email/login (실패) | ✅ 정상 | 401 |
| POST /auth/refresh | ✅ 정상 | 200 |
| DELETE /auth/account | ✅ 정상 | 204 |
| GET /users/me | ✅ 정상 | 200 |
| GET /users/me/streak | ✅ 정상 | 200 |
| POST /families (FATHER role) | ✅ 정상 | 201 |
| GET /families/my | ✅ 정상 | 200 |
| GET /families/:id | ✅ 정상 | 200 |
| GET /questions | ✅ 정상 | 200 |
| GET /questions/today (질문 없음) | ⚠️ 500 (DB에 질문 데이터 없음) | 500 |
| GET /notifications | ✅ 정상 | 200 |
| 없는 경로 | ✅ 정상 | 404 |
| 인증 없는 보호 엔드포인트 | ✅ 정상 | 401 |

---

## 잔여 이슈

### `GET /questions/today` 500 오류
- **원인**: DB에 질문(question) 데이터가 없어서 `assignQuestionToFamily`가 `Errors.internal('사용 가능한 질문이 없습니다.')` throw
- **해결 방법**: DB에 질문 시드 데이터 삽입 필요 (`npm run db:seed`)
- 코드 버그 아님 - 데이터 부재 이슈

---

## 수정 파일

- `src/lambda.ts` — async handler + Promise 반환으로 변경
- `src/services/AuthService.ts` — generic Error → ApiError로 수정
- `serverless.yml` — VPC 설정 및 IAM ENI 권한 추가
