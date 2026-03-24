# 버그 수정 보고서 (3건)

**날짜**: 2026-03-24

---

## 이슈 1: 답변 시 캐릭터 색상 불일치

### 원인 분석

사용자가 답변 시 선택한 캐릭터 색상(moodId)이 서버로 전달되지 않아 발생.

**데이터 흐름 (수정 전)**:
1. iOS: 사용자가 파란색(sad) 선택 → `selectedMoodIndex = 3`
2. iOS: `AnswerEndpoint.create` 호출 시 moodId **누락** (questionId, content, imageUrl만 전송)
3. 서버: moodId 없이 Answer 저장, `FamilyMembership.colorId` 미업데이트
4. HistoryView: `colorMap`에서 기존 `colorId`("loved", 기본 핑크) 사용 → 잘못된 색상 표시

### 수정 내용

**서버 (`FamTreeServer`)**:
- `models/index.ts`: `CreateAnswerRequest`에 `moodId?: string` 추가
- `AnswerService.createAnswer()`: moodId가 있으면 `FamilyMembership.colorId` 업데이트
- `AnswerService.getFamilyAnswers()`: membership `colorId` 기반 `colorMap` 추가, 가족 답변 조회 시 정확한 색상 반환

**iOS (`FamTree`)**:
- `Domain/AnswerRepositoryProtocol.swift`: `create(_ answer:, moodId:)` 시그니처 추가, 기존 호환을 위한 기본 구현 extension 제공
- `APIEndpoint.swift`: `AnswerEndpoint.create` case에 `moodId: String?` 파라미터 추가, request body에 포함
- `AnswerRepository.swift`: `create()` 함수에 moodId 파라미터 추가 및 endpoint에 전달
- `QuestionDetailFeature.swift`: 답변 제출 시 `selectedMoodId` 추출하여 `create(_, moodId:)` 호출

### 효과
- 답변 시 선택한 캐릭터 색상이 `FamilyMembership.colorId`에 저장됨
- HistoryView와 가족 답변 화면 모두 정확한 색상으로 표시

---

## 이슈 2: 재촉하기 404 NOT_FOUND 에러

### 원인 분석

```
[API Error] 404 NOT_FOUND: 대상 가족 구성원을(를) 찾을 수 없습니다.
```

`NudgeService`가 대상 유저를 `User.familyId`(활성 가족) 기준으로 조회했기 때문.

**문제**: 같은 그룹에 속해 있더라도 대상 유저의 `User.familyId`가 다른 그룹을 가리키고 있으면 `findFirst({ where: { id, familyId: sender.familyId } })` 조건 실패 → 404 발생.

예시:
- 발신자: `User.familyId = family_A` (활성 가족 A)
- 수신자: `User.familyId = family_B` (활성 가족 B로 전환된 상태)
- 두 사람 모두 `FamilyMembership`에 family_A 레코드 존재 → 같은 그룹이지만 404

### 수정 내용

**서버 `NudgeService.ts`**:

```typescript
// 수정 전: User.familyId로 검색 (활성 가족이 다르면 실패)
const target = await prisma.user.findFirst({
  where: { id: targetUserId.toLowerCase(), familyId: sender.familyId },
});

// 수정 후: FamilyMembership으로 검색 (그룹 멤버십 기준)
const targetMembership = await prisma.familyMembership.findUnique({
  where: {
    userId_familyId: {
      userId: targetUserId.toLowerCase(),
      familyId: sender.familyId,
    },
  },
  include: { user: true },
});
const target = targetMembership.user;
```

### 효과
- 대상 유저의 활성 가족 설정에 관계없이, 같은 그룹 멤버이면 재촉 가능

---

## 이슈 3: 마이페이지 접속 시 WebKit 로그

### 원인 분석

```
WebKit::WebFramePolicyListenerProxy::ignore(WebKit::WasNavigationIntercepted)
...
GADMRAIDEnvironmentScript
```

Google AdMob SDK가 MRAID(Mobile Rich Media Ad Interface) 배너를 렌더링할 때 내부 WKWebView에서 발생하는 **SDK 내부 로그**. 앱 크래시 아님.

- MRAID 스크립트가 WKWebView 내부에서 URL 네비게이션 시도
- WebKit의 기본 네비게이션 정책이 이를 차단하고 `ignore` 처리
- 이는 AdMob SDK의 정상적인 MRAID 환경 동작이며, 앱 기능에는 영향 없음

### 조치 사항

- **앱 크래시/기능 오류 아님**: 배너 광고는 정상 로드 및 표시됨
- AdMob SDK 최신 버전으로 업데이트 시 개선될 수 있음
- 현재 코드 레벨에서 SDK 내부 WKWebView 동작을 제어할 수 없음

---

## 수정 파일 목록

### 서버 (`FamTreeServer`)
| 파일 | 변경 내용 |
|------|----------|
| `src/models/index.ts` | `CreateAnswerRequest.moodId?: string` 추가 |
| `src/services/AnswerService.ts` | createAnswer moodId→colorId 업데이트, getFamilyAnswers colorMap 추가 |
| `src/services/NudgeService.ts` | 대상 유저 조회를 FamilyMembership 기준으로 변경 |

### iOS (`FamTree`)
| 파일 | 변경 내용 |
|------|----------|
| `Domain/.../AnswerRepositoryProtocol.swift` | `create(_, moodId:)` 시그니처 추가 + extension 기본 구현 |
| `MongleData/.../APIEndpoint.swift` | `AnswerEndpoint.create`에 moodId 파라미터 추가 |
| `MongleData/.../AnswerRepository.swift` | `create(_, moodId:)` 구현 |
| `MongleFeatures/.../QuestionDetailFeature.swift` | 답변 제출 시 selectedMoodId 전달 |
