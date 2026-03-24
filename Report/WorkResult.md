# 작업 결과 보고

## 수정 완료 항목 (iOS)

---

### Bug 1: GroupSelect 화면에서 각 그룹을 눌러도 화면이동이 안됨

**원인**: `MongleCardGroup` 컴포넌트 내부에 `Button { onTap?() }` 가 있음. `GroupSelectView`에서 `onTap` 파라미터를 넘기지 않고 외부에 `.onTapGesture`를 붙였는데, `Button`이 탭 이벤트를 소비해버려 `.onTapGesture`가 발동되지 않음.

**수정 파일**: `MongleFeatures/Sources/MongleFeatures/Presentation/Group/GroupSelectView.swift`

```swift
// 수정 전
MongleCardGroup(
    groupName: group.name,
    memberColors: memberColors(for: group),
    streakDays: 0
)
.onTapGesture {
    store.send(.groupTapped(group))
}

// 수정 후
MongleCardGroup(
    groupName: group.name,
    memberColors: memberColors(for: group),
    streakDays: 0,
    onTap: { store.send(.groupTapped(group)) }
)
```

---

### Bug 2: 알림버튼을 눌렀을 때 알림화면이 아니라 HomeView로 이동되는 문제

**원인**: `Root+Reducer.swift`에서 `groupSelect(.delegate(.notificationTapped))` 처리 시 `appState = .authenticated`만 설정하고 알림 화면으로의 navigation을 추가하지 않음.

**수정 파일**: `MongleFeatures/Sources/MongleFeatures/Presentation/Root/Ext/Root+Reducer.swift`

```swift
// 수정 전
case .groupSelect(.delegate(.notificationTapped)):
    if state.mainTab != nil {
        state.appState = .authenticated
    }
    return .none

// 수정 후
case .groupSelect(.delegate(.notificationTapped)):
    if state.mainTab != nil {
        state.appState = .authenticated
        state.mainTab?.path.append(.notification(NotificationFeature.State()))
    }
    return .none
```

---

### Bug 3: 그룹 전환 시 몽글캐릭터가 이전 그룹 데이터를 그대로 보여줌

**원인**: `MongleSceneView`에서 `@State private var mongles`를 초기화(`initMongles`)할 때 `mongles.isEmpty`인 경우에만 초기화함. 그룹 전환 후 `members` 파라미터가 변경되어도 `mongles`가 비어있지 않으므로 재초기화되지 않아 이전 그룹의 캐릭터가 그대로 남아있음.

**수정 파일**: `MongleFeatures/Sources/MongleFeatures/Design/Components.swift`

```swift
// 추가된 코드 (onChange(of: geo.size) 다음에 추가)
.onChange(of: members.map { $0.name }) { _, _ in
    guard geo.size.width > 0, geo.size.height > 0 else { return }
    initMongles(size: geo.size)
}
```

`members`의 이름 배열이 변경될 때(그룹 전환 시) `mongles`를 새 멤버 데이터로 재초기화.
