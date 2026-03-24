# 작업 보고 - 2026-03-19

## 수정 항목

### 1. 몽글캐릭터 색상 그룹별 반영
**파일**: `MongleFeatures/.../Presentation/MainTab/Ext/MainTab+Reducer.swift`

**문제**: 그룹 전환 시 `currentUserMoodId`가 초기화되지 않아 이전 그룹의 색상이 그대로 유지됨.
- 예: 그룹 A에서 답변 후 "행복(노랑)" 색상으로 변경 → 그룹 B로 전환해도 노랑색이 남아있음

**수정**: `groupSelected` 처리 시 `state.currentUserMoodId = nil` 추가
- 그룹 전환 시 색상이 초기화되어 해당 그룹의 멤버 데이터(moodId) 기준으로 색상이 표시됨
- 답변 시(`answerSubmitted`) 및 프로필 수정 시(`profileUpdated`) 색상 즉시 반영은 기존 코드에서 이미 동작함

---

### 2. HomeView 그룹 드롭다운 클릭 영역 확장
**파일**: `MongleFeatures/.../Presentation/Home/HomeView.swift`

**문제**: `GroupDropdownView`에서 각 그룹 셀의 버튼이 텍스트/아이콘 부분에만 응답하고 빈 공간(Spacer)은 클릭 안 됨.
- `.buttonStyle(.plain)` 사용 시 SwiftUI는 보이는 컨텐츠 영역만 터치 허용

**수정**: 버튼 label HStack에 `.contentShape(Rectangle())` 추가
- 셀 전체 영역이 터치 가능해짐

---

### 3. GroupSelect 알림 화면 뒤로가기 수정
**파일**: `MongleFeatures/.../Presentation/Group/GroupSelectFeature.swift`

**문제**: `GroupSelectFeature`의 path 핸들러가 `notification(.delegate(.close))` 액션을 처리하지 않아 뒤로가기 버튼을 눌러도 화면이 닫히지 않음.
- `NotificationFeature.backTapped` → `.delegate(.close)` 발송 → 처리 없이 `.none` 반환

**수정**: path 케이스에 notification 뒤로가기 핸들러 추가
```swift
case .path(.element(id: _, action: .notification(.delegate(.close)))):
    state.path.removeLast()
    return .none
```

---

### 4. History - 답변/수정 후 즉시 반영
**파일**: `MongleFeatures/.../Presentation/MainTab/Ext/MainTab+Reducer.swift`

**문제**: `HistoryFeature.onAppear`에 `guard state.historyItems.isEmpty else { return .none }` 조건이 있어 한 번 로드된 히스토리는 재로드되지 않음.
- 질문에 답변하거나 답변을 수정해도 History 탭에 반영되지 않음

**수정**: `answerSubmitted` 및 `answerEdited` 처리 시 히스토리 캐시 초기화
```swift
state.history.historyItems = [:]
state.history.loadedMonths = []
```
- 다음번 History 탭 진입 시(`onAppear`) 자동으로 최신 데이터를 다시 로드함

---

### 5. 그룹 생성/참여 시 몽글 색상 선택 (colorId)

**iOS 파일**:
- `Domain/.../FamilyRepositoryProtocol.swift` — `create`, `joinFamily`에 `colorId: String?` 파라미터 추가
- `MongleData/.../FamilyRepository.swift` — `FamilyEndpoint.create/join` 호출 시 `colorId` 전달
- `MongleFeatures/.../GroupSelectFeature.swift` — `selectedColorId: String = "loved"` 상태, `colorChanged(String)` 액션, 델리게이트 `createFamily/joinFamily`에 `colorId` 추가
- `MongleFeatures/.../GroupSelectView.swift` — 5가지 색상 원형 선택 UI (`monggleColorPicker()`) 추가 (createGroup, joinWithCode 모두)
- `MongleFeatures/.../Root+Reducer.swift` — 델리게이트 처리 시 `colorId`를 repository에 전달

**서버 파일**:
- `prisma/schema.prisma` — `FamilyMembership`에 `colorId String? @default("loved") @map("color_id")` 추가
- `src/services/FamilyService.ts` — `createFamily`, `joinFamily` 시 `colorId` 저장
- `src/services/QuestionService.ts` — 히스토리 조회 시 `colorMap`(userId→colorId) 생성 후 각 답변의 `moodId` 필드에 그룹별 색상 주입
- `src/models/index.ts` — `HistoryAnswerSummary`에 `moodId: string | null` 추가

---

### 6. 서버 TypeScript 컴파일 에러 수정 (이번 세션)

**에러 내용**:
```
src/services/QuestionService.ts:175:31 - error TS2353: colorId does not exist in type FamilyMembershipSelect
src/services/QuestionService.ts:179:49 - error TS2339: Property colorId does not exist
src/services/QuestionService.ts:179:62 - error TS2339: Property user does not exist
```

**원인**: `schema.prisma`에 `colorId` 추가 후 `prisma generate`가 실행되지 않아 생성된 Prisma 클라이언트 타입에 해당 필드가 없었음.

**수정**:
```bash
npx prisma db push
```
- `family_memberships` 테이블에 `color_id` 컬럼 추가 (DB 반영)
- Prisma Client (v5.22.0) 재생성

**결과**: TypeScript 컴파일 오류 0개, 서버 정상 기동 가능

---

## 세션 3 추가 작업 (2026-03-19 이후)

### 7. 몽글 색상 그룹별 완전 반영 (서버 + iOS)

**문제 진단 결과:**

| 항목 | 이전 상태 | 문제 |
|------|-----------|------|
| `GET /users/me` 응답 moodId | `User.moodId` | 그룹별 colorId 무시 |
| 프로필 편집 시 | `User.moodId`만 업데이트 | `FamilyMembership.colorId` 미업데이트 |
| 답변(마음남기기) 시 | 로컬 상태만 변경 | 서버에 moodId 저장 안 됨 |

**수정 내용:**

#### 서버: `src/services/UserService.ts`

1. **`getUserByUserId`** — `moodId` 반환 수정:
   ```typescript
   // 이전
   moodId: user.moodId ?? null
   // 이후
   moodId: membership.colorId ?? user.moodId ?? null
   ```
   → `GET /users/me`가 현재 활성 가족의 그룹별 색상을 반환

2. **`updateUser`** — `moodId` 변경 시 `FamilyMembership.colorId` 동기화:
   ```typescript
   // 이전
   if (user.familyId && (data.name || data.role)) {
   // 이후
   if (user.familyId && (data.name || data.role || data.moodId !== undefined)) {
     data: {
       ...(data.moodId !== undefined && { colorId: data.moodId }),  // 추가
       ...
   ```
   → 프로필 편집 또는 답변 후 색상 변경 시 그룹별 `colorId` 함께 업데이트

#### iOS: `MainTabFeature.swift`

```swift
@Dependency(\.userRepository) var userRepository  // 추가
```

#### iOS: `MainTab+Reducer.swift`

답변 제출 후 선택한 moodId를 서버에 저장 (fire-and-forget):
```swift
case .path(.element(id: _, action: .questionDetail(.delegate(.answerSubmitted(_, let moodId))))):
    // ... 기존 로컬 상태 업데이트 ...
    return .merge(
        .run { [userRepository] _ in
            guard let user = updatedUser else { return }
            _ = try? await userRepository.update(user)  // colorId 서버 저장
        },
        .run { send in
            // 토스트 타이머 (기존)
        }
    )
```

**결과:**
- 프로필 편집에서 색상 변경 → 즉시 서버 반영 (다른 그룹엔 영향 없음)
- 답변 시 선택한 색상 → 서버 저장 → 히스토리에서 해당 색상으로 표시
- `GET /users/me`가 그룹별 colorId 반환 → 앱 재시작 후에도 색상 유지

---

## 세션 4 추가 작업

### 8. 답변/수정 시 HomeView 및 프로필 화면 색상 즉시 반영

**문제 진단:**

| 항목 | 이전 상태 | 문제 |
|------|-----------|------|
| 답변 후 HomeView 색상 | `currentUserMoodId` 설정됨 ✅ | 동작 |
| 답변 후 프로필 화면 색상 | `state.profile.user.moodId` 미갱신 | 프로필 탭에서 이전 색상 표시 ❌ |
| 답변 후 `familyMembers[idx].moodId` | 미갱신 | HomeView 내부 멤버 데이터와 불일치 ❌ |
| 답변 수정(answerEdited) | moodId delegate에 없음 | 수정 후 색상 변경 불가 ❌ |
| History → QuestionDetail 내비게이션 | MainTab+Reducer 미처리 | 히스토리에서 수정 불가 ❌ |

**수정 내용:**

#### 1. `QuestionDetailFeature.swift`

`answerEdited` delegate에 `moodId` 추가:
```swift
// 이전
case answerEdited(Answer)
// 이후
case answerEdited(Answer, moodId: String?)

// submitAnswerResponse에서도 moodId 전달
.delegate(.answerEdited(answer, moodId: moodId))
```

#### 2. `MainTab+Reducer.swift` — `answerSubmitted` 핸들러

`currentUserMoodId`만 설정하던 것을 → 관련 상태 모두 갱신:
```swift
if let updated = updatedUser {
    state.currentUserMoodId = updated.moodId       // HomeView 색상
    state.home.currentUser = updated               // currentUser 객체 동기화
    state.home.familyMembers[idx] = updated        // 멤버 목록 동기화
    state.profile.user = updated                   // 프로필 화면 즉시 반영
}
```

#### 3. `MainTab+Reducer.swift` — `answerEdited` 핸들러 (신규)

오늘 질문 수정인 경우에만 색상 업데이트:
```swift
let isTodayQuestion = answer.dailyQuestionId == state.home.todayQuestion?.id
// isTodayQuestion이고 moodId가 있을 때만 위와 동일하게 상태 갱신 + 서버 저장
```

#### 4. `MainTab+Reducer.swift` — History → QuestionDetail 내비게이션 (신규)

`HistoryFeature.Delegate.navigateToQuestionDetail`이 MainTab+Reducer에서 처리되지 않던 문제 수정:
```swift
case .history(.delegate(.navigateToQuestionDetail(let question, _))):
    state.path.append(.questionDetail(QuestionDetailFeature.State(question: question, ...)))
    return .none
```

**결과:**
- 답변 시 HomeView + 프로필 탭 모두 즉시 색상 반영
- 프로필 편집 시 HomeView 색상 반영 (기존 `profileUpdated` 핸들러로 동작)
- 히스토리에서 오늘 질문 수정 → HomeView 색상 업데이트
- 히스토리에서 과거 질문 수정 → HomeView 색상 미변경 (오늘 질문만)
- 히스토리 아이템 탭 → QuestionDetail 화면으로 이동 가능

---

## 세션 5 추가 작업

### 9. HomeView vs HistoryView 오늘의 질문 불일치 수정

**원인 분석:**

| 항목 | 이전 상태 | 문제 |
|------|-----------|------|
| 서버 `getToday()` | `new Date()` + `setHours(0,0,0,0)` | 서버 UTC 기준 자정 → KST 사용자는 00:00~09:00에 날짜 어긋남 |
| DailyQuestion.date 저장 | UTC 날짜로 저장 | KST 새벽 1시 = 서버 UTC 어제 날짜로 저장 |
| iOS 히스토리 날짜 파싱 | `dto.date + "T00:00:00Z"` | 서버 날짜를 UTC 자정으로 파싱 → 정상 |

**시나리오**: KST 2026-03-20 01:00 (새벽 1시)에 질문에 답변
- 서버 UTC 기준 = 2026-03-19 16:00 → `getToday()` = 2026-03-19
- HomeView: "오늘 질문"으로 표시 (서버가 2026-03-19 질문 반환)
- HistoryView: 2026-03-19로 표시 (한국 달력상 3월 19일)
- **불일치**: 사용자는 3월 20일로 인식하지만 히스토리는 3월 19일에 표시

**수정 내용:**

**파일**: `FamTreeServer/src/services/QuestionService.ts`

```typescript
// 이전
private getToday(): Date {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return today;
}

// 이후
private getToday(): Date {
  const now = new Date();
  // 한국 표준시(KST, UTC+9) 기준 날짜 문자열 획득
  const kstDateStr = now.toLocaleDateString('en-CA', { timeZone: 'Asia/Seoul' }); // "YYYY-MM-DD"
  // Prisma @db.Date는 UTC 기준으로 저장하므로, KST 날짜를 UTC 자정으로 생성
  return new Date(kstDateStr + 'T00:00:00.000Z');
}
```

**동작 흐름 (수정 후)**:
- KST 2026-03-20 01:00 → `kstDateStr` = "2026-03-20" → DB 저장 = 2026-03-20
- HomeView: 서버가 2026-03-20 질문 반환 → 사용자 인식 날짜와 일치
- HistoryView: 서버 날짜 "2026-03-20" → iOS 파싱 "2026-03-20T00:00:00Z" → KST 3월 20일 표시
- **일치**: HomeView와 HistoryView 모두 KST 날짜 기준으로 표시됨

**iOS 측 변경 없음**: `QuestionRepository.swift`의 `dto.date + "T00:00:00Z"` 파싱은 서버가 KST 날짜를 반환하면 그대로 올바르게 동작함.

**주의**: 기존에 UTC 기준으로 저장된 DailyQuestion 데이터는 날짜가 하루 어긋날 수 있음. 신규 생성 질문부터 KST 기준 적용됨.

---

## 미해결 사항

없음
