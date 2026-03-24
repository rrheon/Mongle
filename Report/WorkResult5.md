# 작업 결과

---

## Task 1: HomeView init/deinit 확인

### 검증 결과: 정상 동작

GroupSelect → 그룹 선택 → HomeView 전환 흐름:

```
groupTapped(group)
  ↓
Root+Reducer: groupSelect(.delegate(.groupSelected))
  └── state.appState = .loading → LoadingView 표시 (GroupSelectView deinit ✓)
  └── selectFamily API 호출
  ↓
refreshHomeData → loadDataResponse(.success)
  ├── isInitialLoad = state.mainTab == nil → false (mainTab 이미 존재)
  ├── state.mainTab?.home = homeState (홈 데이터 업데이트)
  └── state.appState = .authenticated → MainTabView init ✓
```

**검증 포인트:**
| 항목 | 결과 |
|------|------|
| GroupSelectView deinit 시 타이머/비동기 잔존 작업 | 없음 (clean deinit) |
| `isInitialLoad` 오판 여부 | `state.mainTab == nil` 기준으로 정확히 구분 |
| MainTabView init 시 홈 데이터 정합성 | `state.mainTab?.home = homeState` 선처리 후 appState 전환 → 올바른 데이터로 init |
| HomeView onAppear 중복 API 호출 | `HomeView`에 `onAppear` 없음 → 중복 호출 없음 |
| RootView `.authenticated` 진입 시 mainTab nil 가능성 | `loadDataResponse`에서 mainTab이 항상 설정된 후 `.authenticated` 전환 → nil 불가 |

---

## Task 2: GroupSelect 몽글 캐릭터 색상 수정

### 문제

`GroupSelectView.memberColors(for:)` 가 index 기반 고정 색상을 사용:

```swift
// 수정 전 — 실제 moodId와 무관하게 index 순서로 색상 할당
return (0..<count).map { Self.monggleColors[$0 % Self.monggleColors.count] }
```

서버 `GET /families/all` 은 각 멤버의 `moodId` 를 포함해 반환하지만, iOS `getMyFamilies()` 에서 `FamilyMapper.toDomainWithMembers($0).0` 으로 `MongleGroup` 만 추출하고 멤버 데이터(`.1`)를 버렸음. `MongleGroup` 에는 `memberIds: [UUID]` 만 있어 `moodId` 정보 없음.

### 수정

**1. `Domain/Entities/FamilyGroup.swift` — `memberMoodIds` 필드 추가**

```swift
public struct MongleGroup: Equatable, Sendable {
    // ...
    public let memberMoodIds: [String]  // 추가

    public init(
        // ...
        memberMoodIds: [String] = []    // default [] → 기존 호출부 호환 유지
    )
}
```

**2. `MongleData/Mappers/FamilyMapper.swift` — `toDomainWithMembers` 에서 moodId 매핑**

```swift
let family = MongleGroup(
    // ...
    memberMoodIds: dto.members.map { $0.moodId ?? "loved" }
)
```

**3. `MongleFeatures/GroupSelectView.swift` — 실제 moodId 기반 색상 적용**

```swift
private static func monggleColor(for moodId: String) -> Color {
    switch moodId {
    case "happy":  return MongleColor.monggleYellow
    case "calm":   return MongleColor.monggleGreen
    case "loved":  return MongleColor.mongglePink
    case "sad":    return MongleColor.monggleBlue
    case "tired":  return MongleColor.monggleOrange
    default:       return MongleColor.mongglePink
    }
}

private func memberColors(for group: MongleGroup) -> [Color] {
    if !group.memberMoodIds.isEmpty {
        return group.memberMoodIds.map { Self.monggleColor(for: $0) }  // 실제 색상
    }
    // fallback: moodId 정보 없을 때 index 기반
    let count = max(group.memberIds.count, 1)
    return (0..<count).map { Self.monggleColors[$0 % Self.monggleColors.count] }
}
```

### 색상 매핑

| moodId | 색상 |
|--------|------|
| happy | monggleYellow |
| calm | monggleGreen |
| loved | mongglePink |
| sad | monggleBlue |
| tired | monggleOrange |
| 미설정 | mongglePink (기본값) |

### 데이터 흐름 (수정 후)

```
GET /families/all
  ↓ (서버: 각 멤버의 moodId 포함)
FamiliesListResponseDTO.families[].members[].moodId
  ↓
FamilyMapper.toDomainWithMembers
  └── MongleGroup.memberMoodIds = dto.members.map { $0.moodId ?? "loved" }
  ↓
GroupSelectFeature.State.groups = [MongleGroup]
  ↓
GroupSelectView.memberColors(for: group)
  └── group.memberMoodIds.map { monggleColor(for: $0) }
  ↓
MongleCardGroup(memberColors: [...실제 moodId 색상...])
```
