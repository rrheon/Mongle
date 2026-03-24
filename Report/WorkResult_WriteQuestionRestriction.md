# 작업 결과 보고

## 작업 일자
2026-03-21

---

## Issue 1: 그룹나가기 ifLet 경고 재수정

### 원인 재분석
이전 수정(navigateToGroupSelect에서 supportScreen = nil 설정)이 여전히 같은 문제를 발생시킴.
`state.mainTab?.profile.supportScreen = nil`을 설정할 때 `MainTabView`가 아직
화면에 표시 중이므로, SwiftUI가 navigationDestination pop 애니메이션 중
`SupportScreenView.onAppear`를 재호출 → ifLet 경고 재발생.

### 수정 내용
**파일**: `MongleFeatures/.../Root/Ext/Root+Reducer.swift`

**navigateToGroupSelect에서 개별 modal nil 설정 제거**:
```swift
// 제거된 코드
state.mainTab?.profile.supportScreen = nil
state.mainTab?.profile.mongleCardEdit = nil
state.mainTab?.profile.accountManagement = nil
```

**loadDataResponse(.success) 업데이트 경로에서 profile 전체 재생성**:
```swift
// Before (개별 필드 업데이트)
state.mainTab?.profile.user = data.user
state.mainTab?.profile.familyId = data.family?.id
state.mainTab?.profile.familyCreatedById = data.family?.createdBy

// After (전체 재생성)
state.mainTab?.profile = ProfileEditFeature.State(
    user: data.user,
    familyId: data.family?.id,
    familyCreatedById: data.family?.createdBy
)
```

**이유**: `loadDataResponse`가 실행될 때는 `appState = .groupSelection` 상태
(GroupSelectView 표시 중)이므로 `MainTabView`/`SupportScreenView`가 화면에 없음.
이 시점에 profile을 재생성하면 supportScreen이 nil로 초기화되어도
SwiftUI onAppear가 절대 트리거되지 않음.

---

## Issue 2: 나만의 질문 작성하기 제한

### 제한 조건
1. 그룹 내 누군가가 이미 오늘 답변한 경우 → 작성 불가
2. 이미 나만의 질문이 등록된 경우 → 작성 불가 (기존 체크 유지)

### 수정 내용
**파일**: `FamTreeServer/src/services/QuestionService.ts`

`createCustomQuestion`에 답변 여부 체크 추가:
```typescript
// 그룹 내 누군가가 이미 답변한 경우 거부
const familyMemberIds = await prisma.familyMembership.findMany({
  where: { familyId: user.familyId },
  select: { userId: true },
});
const memberUserIds = familyMemberIds.map((m) => m.userId);
const kstDayStart = new Date(today.getTime() - 9 * 60 * 60 * 1000);
const kstDayEnd = new Date(today.getTime() + 15 * 60 * 60 * 1000);
const existingAnswerCount = await prisma.answer.count({
  where: {
    questionId: current.questionId,
    userId: { in: memberUserIds },
    createdAt: { gte: kstDayStart, lt: kstDayEnd },
  },
});
if (existingAnswerCount > 0) {
  throw Errors.conflict('이미 가족 중 누군가가 답변했습니다. 답변이 없을 때만 나만의 질문을 작성할 수 있습니다.');
}
```

**iOS 영향 없음**: `WriteQuestionFeature`의 `.submitResponse(.failure)` → `state.appError`
→ `WriteQuestionView.mongleErrorBanner`로 에러 메시지가 자동 표시됨.

### 적용 순서 (createCustomQuestion 체크 순서)
1. 하트 잔액 확인 (3개 미만 → 거부)
2. 오늘의 DailyQuestion 존재 확인
3. 이미 나만의 질문 등록 여부 확인 (isCustom)
4. **[신규]** 그룹 내 답변 존재 여부 확인
5. 질문 내용 유효성 검사
6. 나만의 질문 생성 + DailyQuestion 교체 + 하트 차감

---

## 빌드 확인
- 서버: `npm run build` 성공
