# 서버 배포 분석 보고서
**날짜**: 2026-03-26

---

## 서버 스택 파악

| 항목 | 내용 |
|------|------|
| 런타임 | Node.js 20, TypeScript |
| 프레임워크 | Express |
| DB | PostgreSQL (Prisma ORM) |
| 인증 | AWS Cognito + 커스텀 JWT |
| 배포 구성 | Serverless Framework (AWS Lambda + API Gateway) |
| 리전 | ap-northeast-2 (서울) |

현재 `serverless.yml`이 이미 구성되어 있어 **AWS Lambda 기반 배포가 기본 설계**입니다.

---

## AWS vs Render 비교

### AWS (Lambda + API Gateway) — 현재 설계 방향

| 항목 | 내용 |
|------|------|
| 비용 | 요청 수 기반 과금 (월 100만 건 무료, 이후 $0.20/백만) |
| 확장성 | 자동 스케일링 (트래픽 급증 대응 우수) |
| 콜드 스타트 | 있음 (첫 요청 수백ms 지연) |
| 리전 | 서울(ap-northeast-2) 가능 → 국내 앱에 유리 |
| Cognito 연동 | 네이티브 통합 |
| DB | RDS(Aurora Serverless) 또는 외부 PG |
| 스케줄러 | **Lambda에서 setInterval 미작동** → EventBridge 별도 구성 필요 |
| 설정 난이도 | 높음 (IAM, VPC, CloudFormation 등) |
| 현재 코드 호환성 | 높음 (`serverless.yml` 이미 구성됨) |

**중요**: `app.ts`에 있는 `startDailyQuestionScheduler()`의 `setInterval`은 `require.main === module` 조건으로 감싸져 있어 Lambda 환경에서는 실행되지 않습니다. Lambda에서 매일 자정 질문 배정을 실행하려면 **AWS EventBridge 규칙 + 별도 Lambda 함수**로 분리해야 합니다.

---

### Render — 대안

| 항목 | 내용 |
|------|------|
| 비용 | 무료(15분 비활성 시 슬립) / $7/월(항상 켜짐) / DB 무료(90일 후 삭제) |
| 확장성 | 수동 스케일링, 트래픽 급증 대응 약함 |
| 콜드 스타트 | 무료 플랜은 슬립 후 재시작 지연(~30초) 있음 |
| 리전 | 한국 없음 (싱가포르가 가장 가까움) |
| Cognito 연동 | AWS SDK로 가능하나 추가 설정 필요 |
| DB | PostgreSQL 제공 (무료: 1GB, 90일 후 삭제) |
| 스케줄러 | **상시 서버 → setInterval 정상 작동** |
| 설정 난이도 | 낮음 (GitHub 연동 → 자동 배포) |
| 현재 코드 호환성 | 중간 (Express 코드 자체는 호환, Lambda 엔트리 제거 필요) |

---

### 결론: 무엇을 선택할까?

| 상황 | 권장 |
|------|------|
| 현재 구조 유지, 프로덕션 운영 | **AWS Lambda** (이미 설정됨, 서울 리전, 저비용) |
| 빠른 프로토타입/개발 단계 | **Render** (설정 간단, 무료 티어) |
| 스케줄러가 핵심 기능인 경우 | AWS (EventBridge), 또는 Render $7/월 플랜 |

**현재 프로젝트 권장: AWS Lambda**
- serverless.yml이 이미 준비됨
- 서울 리전으로 국내 앱 레이턴시 최적화
- 소규모 앱 기준 무료 티어로 충분
- 단, EventBridge 스케줄러 설정은 추가 필요

---

## 보안 문제 분석

### 🔴 Critical

#### 1. JWT_SECRET 하드코딩 폴백 (`src/utils/jwt.ts`)
```typescript
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-prod';
```
- 프로덕션 환경에서 `JWT_SECRET` 환경변수가 누락되면 알려진 시크릿으로 JWT 발급/검증
- 공격자가 임의 토큰을 만들어 인증 우회 가능
- **수정 필요**: 환경변수 없으면 서버 시작 실패하도록 강제

```typescript
// 권장 방식
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) throw new Error('JWT_SECRET environment variable is required');
```

---

### 🟠 High

#### 2. CORS 전체 개방 (`src/app.ts` + `serverless.yml`)
```typescript
app.use(cors()); // 모든 origin 허용
```
```yaml
allowedOrigins:
  - '*'  # 모든 도메인 허용
```
- 모바일 앱이기 때문에 브라우저 CORS 제한이 적용되지 않으므로 큰 위험은 아니지만, 웹 클라이언트가 추가되거나 Swagger UI에 접근 시 CSRF 위험 존재
- **권장**: 필요한 origin만 명시 (또는 현 구조 유지 시 문서화)

#### 3. IAM 권한 과다 (`serverless.yml`)
```yaml
- Action:
    - cognito-idp:*
  Resource: '*'
- Action:
    - rds:*
  Resource: '*'
```
- Lambda가 Cognito와 RDS의 모든 작업 수행 가능
- **권장**: 실제 사용하는 액션만 허용 (예: `cognito-idp:AdminGetUser`, `cognito-idp:ListUsers`)

---

### 🟡 Medium

#### 4. Helmet CSP 비활성화 (`src/app.ts`)
```typescript
app.use(helmet({
  contentSecurityPolicy: false, // Swagger UI를 위해 비활성화
}));
```
- `NODE_ENV=production`에서도 CSP 비활성화 상태
- **권장**: production에서는 CSP 활성화, Swagger는 개발 환경에서만 제공

```typescript
app.use(helmet({
  contentSecurityPolicy: process.env.NODE_ENV === 'production',
}));
```

#### 5. Lambda 환경에서 스케줄러 미작동
- `startDailyQuestionScheduler()`가 Lambda에서 실행되지 않으므로 **매일 자정 질문 배정이 누락됨**
- **권장**: AWS EventBridge Scheduler 또는 EventBridge Rules → 별도 Lambda 함수로 스케줄러 분리

```yaml
# serverless.yml에 추가 필요
functions:
  dailyQuestionAssigner:
    handler: src/scheduler.handler
    events:
      - schedule: cron(0 15 * * ? *)  # KST 자정 = UTC 15:00
```

---

### 🟢 Low

#### 6. 개발 환경 request body 전체 로깅
```typescript
console.log(`... ${req.method} ${req.path}`, req.body ...)
```
- 로그인 요청 시 비밀번호 등 민감 정보가 CloudWatch에 남을 수 있음
- **권장**: body 로깅 제외 또는 민감 필드 마스킹

#### 7. Swagger UI 노출 조건
- `NODE_ENV !== 'production'` 조건으로만 비활성화
- serverless.yml에서 stage가 `dev`이면 `NODE_ENV=dev`로 설정되어 외부에서 `/docs` 접근 가능
- **권장**: `stage=prod` 배포 시 Swagger UI 완전 비활성화 확인

---

## 요약

| 구분 | 권장 사항 |
|------|----------|
| 배포 플랫폼 | **AWS Lambda** 유지 (이미 구성됨) |
| 스케줄러 | **EventBridge** + 별도 Lambda로 분리 필요 |
| JWT_SECRET | 환경변수 없으면 **서버 시작 실패** 처리 |
| CORS | 현재 구조 유지 가능하나 문서화 |
| IAM | 사용 액션만 명시하도록 좁히기 |
| CSP | Production에서 Helmet CSP 활성화 |
