# 작업 보고서 — 2026-03-26 (Work.md 4차)

## 작업 항목

### 서버 TypeScript 컴파일 오류 수정

**변경 파일:** `MongleServer/src/services/FamilyService.ts`

**오류 내용:**
```
src/services/FamilyService.ts:449:61 - error TS2322: Type 'string | null' is not assignable to type 'string'.
src/services/FamilyService.ts:455:56 - error TS2322: Type 'string | null' is not assignable to type 'string | NestedStringFilter<...> | undefined'.
```

**원인:**
`admin.familyId`는 Prisma 모델에서 `string | null` 타입. `if (!admin.familyId)` 가드로 null이 아님을 확인했지만, 트랜잭션 클로저(`async (tx) => { ... }`) 내부에서는 TypeScript 타입 내로잉이 전파되지 않아 여전히 `string | null`로 인식.

**수정:**
null 가드 직후 `const familyId = admin.familyId`로 별도 변수에 추출. 해당 변수는 `string`으로 타입이 고정되어 이후 트랜잭션 클로저 내에서도 정상적으로 사용 가능.
