# 서버 배포 오류 수정

**날짜**: 2026-03-27
**작업 범위**: Server (`src/lambda.ts`)

---

## 원인

`serverless-plugin-typescript`는 배포 시 TypeScript를 컴파일합니다.
`src/lambda.ts`에서 TypeScript 컴파일 오류가 있어 배포가 실패하고 있었습니다.

```
src/lambda.ts(19,10): error TS2554: Expected 3 arguments, but got 2.
```

### 상세

`@codegenie/serverless-express`가 반환하는 핸들러의 타입 시그니처:
```typescript
Handler<TEvent, TResult> = (event, context, callback) => void | Promise<TResult>
```

기존 코드는 `callback`을 누락하고 호출:
```typescript
return serverlessHandler(event, context);  // ❌ 인수 2개
```

---

## 수정 내용

**`src/lambda.ts`**: 빈 callback 추가

```typescript
// 수정 전
return serverlessHandler(event, context);

// 수정 후
return serverlessHandler(event, context, () => {});
```

async Lambda에서는 Promise 반환값이 사용되므로 빈 callback은 동작에 영향 없음.

---

## 배포 방법

```bash
cd /Users/yong/Desktop/MongleServer
npx serverless deploy --stage dev
```
