# 알림 그룹화 작업 결과 보고

## 작업 내용

### 1. GroupSelect에서 알림 진입 시 → 그룹별 섹션 표시

**`GroupSelectFeature.swift`** — `.notificationTapped` 핸들러 수정
```swift
case .notificationTapped:
    let groupNameMap = Dictionary(uniqueKeysWithValues: state.groups.map { ($0.id, $0.name) })
    state.path.append(.notification(NotificationFeature.State(mode: .grouped, groupNameMap: groupNameMap)))
    return .none
```
- `state.groups`에서 `{ UUID: 그룹명 }` 딕셔너리를 만들어 `NotificationFeature`에 전달
- `mode: .grouped`로 진입 → 알림이 그룹명 섹션으로 묶여 표시됨

### 2. 그룹별 알림 터치 시 해당 그룹으로 이동

**`GroupSelectFeature.swift`** — path 핸들러 추가
```swift
case .path(.element(id: _, action: .notification(.delegate(.navigateToGroup(let familyId))))):
    state.path.removeAll()
    if let group = state.groups.first(where: { $0.id == familyId }) {
        return .send(.delegate(.groupSelected(group)))
    }
    return .none
```
- 알림 터치 → 알림 화면 닫기 → 해당 familyId의 그룹 선택

### 3. HomeView에서 알림 진입 시 → 현재 그룹 알림만 표시

**`MainTab+Reducer.swift`** — `.home(.delegate(.navigateToNotifications))` 핸들러 수정
```swift
case .home(.delegate(.navigateToNotifications)):
    if let familyId = state.home.family?.id,
       let familyName = state.home.family?.name {
        state.path.append(.notification(NotificationFeature.State(
            mode: .filtered(familyId: familyId, familyName: familyName)
        )))
    } else {
        state.path.append(.notification(NotificationFeature.State()))
    }
    return .none
```
- `mode: .filtered(familyId:familyName:)`로 진입 → 해당 가족 알림만 필터링, 날짜별(오늘/이번 주/이전) 섹션으로 표시

## 핵심 구조

```
NotificationFeature.Mode
├── .filtered(familyId:familyName:)  ← HomeView 진입: 해당 그룹 알림만 날짜별 섹션
├── .grouped                          ← GroupSelect 진입: 모든 그룹 알림을 그룹명 섹션으로
└── .all                              ← 기본 (하위 호환): 전체 알림 날짜별 섹션
```

## 데이터 흐름

- 서버 `NotificationService.ts`: `familyId` 필드 포함하여 반환
- `NotificationRepository.swift` (iOS): `familyId` 파싱, `ISO8601DateFormatter`에 `.withFractionalSeconds` 적용
- `groupedNotifications` computed property: Mode에 따라 섹션 구성
  - `.grouped` → `groupNameMap[familyId]`로 그룹명 표시, 미매핑 시 "기타 그룹"

## 반영 확인

| 파일 | 변경 사항 | 상태 |
|------|-----------|------|
| `GroupSelectFeature.swift` | `.notificationTapped` — grouped 모드 + groupNameMap 전달 | ✅ |
| `GroupSelectFeature.swift` | `.navigateToGroup` path 핸들러 추가 | ✅ |
| `MainTab+Reducer.swift` | `.navigateToNotifications` — filtered 모드 전달 | ✅ |
| `NotificationFeature.swift` | Mode enum + groupedNotifications 로직 | ✅ |
| `NotificationRepository.swift` | familyId 파싱 + fractionalSeconds | ✅ |
| `NotificationService.ts` (서버) | familyId 필드 포함 | ✅ |
| `schema.prisma` | Notification.familyId 컬럼 | ✅ |
