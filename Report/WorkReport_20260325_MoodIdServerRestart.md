# 작업 보고서 - answers.mood_id 에러 재발 수정

**날짜:** 2026-03-25

---

## 증상
```
The column `answers.mood_id` does not exist in the current database.
PrismaClientKnownRequestError: code P2022
at QuestionService.getQuestionHistory (QuestionService.ts:160)
```
기록(History) 조회 및 검색 시 500 에러 발생.

---

## 원인 분석

이전 세션에서 `prisma db push`를 실행해 DB에 `mood_id` 컬럼을 추가했으나, 서버 프로세스가 그 이전에 시작되어 있었습니다.

| 항목 | 상태 |
|------|------|
| DB `answers.mood_id` 컬럼 | ✅ 존재 (이전 세션에서 추가됨) |
| `node_modules/@prisma/client` 생성 코드 | ✅ 최신 (prisma generate 완료) |
| 실행 중인 서버 프로세스 메모리 | ❌ 구버전 클라이언트 로드 상태 |

Node.js는 모듈을 캐시합니다. `prisma generate`가 `node_modules/@prisma/client`를 업데이트해도 이미 실행 중인 프로세스는 시작 시점에 로드된 구버전 클라이언트를 계속 사용합니다.

---

## 수정 내용

`src/app.ts`를 touch해 nodemon 재시작 트리거:
```bash
touch /Users/yong/Desktop/FamTreeServer/src/app.ts
```

서버가 새 PID(31915)로 재시작되어 최신 Prisma 클라이언트를 로드. `/health` 응답 200 확인.

---

## 재발 방지

`prisma db push` 또는 `prisma generate` 실행 후에는 반드시 서버를 재시작해야 합니다. nodemon 환경에서는 임의 파일 touch로 재시작 가능.
