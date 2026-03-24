# 작업 결과 — Work.md 나머지 3가지 작업

---

## Task 2: 답변완료 시 몽글 색 변경

### 분석 결과
이미 동작하고 있었음. 수정 불필요.

**흐름:**
1. `QuestionDetailFeature` → `submitAnswerResponse(.success)` → `delegate(.answerSubmitted(answer, moodId: moodId))` 전송
2. `MainTab+Reducer` 수신 → `state.currentUserMoodId = moodId` 설정
3. `MainTabView`의 `homeViewSection` 에서 `memberData` 구성 시 현재 유저는 `store.currentUserMoodId` 우선 사용
4. `monggleColor(for:)` 로 색상 결정 → MongleSceneView에 color 전달 → 색상 즉시 변경

결론: 답변 제출 시 `currentUserMoodId`가 이미 업데이트되고 있었으므로 별도 수정 없이 색상이 반영됨.

---

## Task 3: 답변완료 시 태그 즉시 변경

### 문제
`MongleSceneView`의 `@State var mongles: [MongleCharacter]`는 `.onChange(of: members.map { $0.name })` 만 감시하고 있어서 멤버 이름이 바뀔 때만 몽글 목록을 재초기화했음.

답변 제출 후 `members[i].hasAnswered`가 `true`로 바뀌어도 `mongles`의 `hasAnswered`는 갱신되지 않아 태그가 "답변하기" 에서 "답변완료"로 바뀌지 않았음.

### 수정
**파일:** `MongleFeatures/Sources/MongleFeatures/Design/Components.swift`

`MongleSceneView.body` 안 `GeometryReader` 블록에 `onChange` 추가:

```swift
.onChange(of: members.map { $0.hasAnswered }) { _, _ in
    for i in mongles.indices {
        if let member = members.first(where: { $0.name == mongles[i].name }) {
            mongles[i].hasAnswered = member.hasAnswered
        }
    }
}
```

위치를 재초기화(`initMongles`)하지 않고, 기존 몽글의 `hasAnswered` 값만 교체 → 애니메이션(이동, 호핑) 중단 없이 태그만 즉시 갱신됨.

### 동작 흐름 (수정 후)
```
답변 제출
  ↓
MainTab+Reducer: state.memberAnswerStatus[userId] = true
  ↓
MainTabView: memberData[i].hasAnswered = true 로 MongleSceneView 전달
  ↓
MongleSceneView onChange(of: members.map { $0.hasAnswered }) 트리거
  ↓
mongles[i].hasAnswered = true 갱신
  ↓
MongleView.statusBadge: "답변완료" + checkmark 즉시 표시
```

---

## Task 4: 자동 로그인 시 GroupSelect 화면으로 이동

### 문제
`Root+Reducer.swift`의 `loadDataResponse(.success)` 핸들러:

```swift
// 수정 전
let newAppState: RootFeature.State.AppState = data.family == nil ? .groupSelection : .authenticated
```

소속 가족이 있는 경우(`data.family != nil`) 무조건 `.authenticated`로 전환 → 자동 로그인 시 첫 번째 그룹 홈으로 바로 진입했음.

`loadDataResponse`는 자동 로그인 외에도 아래 상황에서도 호출됨:
- 그룹 전환 (`switchFamily` → `refreshHomeData`)
- 답변 제출 후 새로고침 (`mainTab(.delegate(.requestRefresh))`)
- 기타 수동 새로고침

따라서 "항상 GroupSelect"로 바꾸면 매 새로고침마다 GroupSelect로 튀어나오는 문제가 생김.

### 수정
**파일:** `MongleFeatures/Sources/MongleFeatures/Presentation/Root/Ext/Root+Reducer.swift`

`state.appState == .loading` 을 초기 로딩 여부의 판별 조건으로 사용:
- `onAppear` → `checkAuthResponse` → `state.appState = .loading` → `refreshHomeData`
- 이 경로에서만 `appState`가 `.loading` 상태로 `loadDataResponse`에 진입
- 그룹 전환, 답변 후 새로고침 등은 `appState == .authenticated` 상태에서 `refreshHomeData` 호출

```swift
// 수정 후
let isInitialLoad = state.appState == .loading
let newAppState: RootFeature.State.AppState = (data.family == nil || isInitialLoad) ? .groupSelection : .authenticated
```

추가로 GroupSelect 진입 시 `data.allFamilies`를 즉시 사전 로드하여 그룹 목록이 로딩 없이 표시되도록 함:

```swift
if newAppState == .groupSelection {
    state.groupSelect.groups = data.allFamilies  // 즉시 표시
    return .run { [familyRepository] send in
        await send(.loadGroupsResponse(
            Result { try await familyRepository.getMyFamilies() }  // 최신 동기화
        ))
    }
}
```

### 동작 흐름 (수정 후)
```
앱 시작 (자동 로그인)
  ↓
onAppear → state.appState = .loading → refreshHomeData
  ↓
loadDataResponse(.success): isInitialLoad = true → newAppState = .groupSelection
  ↓
GroupSelect 화면 표시 (그룹 목록 즉시 사전 로드됨)
  ↓
사용자가 그룹 선택 → selectFamily API → refreshHomeData
  ↓
loadDataResponse(.success): isInitialLoad = false, data.family != nil → newAppState = .authenticated
  ↓
홈 화면 진입
```
