# iOS 테스트 계획

> 프레임워크: Swift Testing (iOS 17+) 또는 XCTest
> TCA 리듀서 테스트: `ComposableArchitecture.TestStore` 활용

---

## 1. 리듀서 테스트 (Reducer Tests) — TCA Feature

TCA의 `TestStore`를 사용하면 액션을 보내고 상태 변화를 단계별로 검증할 수 있습니다.
부수효과(Effect)도 시간 제어가 가능해 비동기 로직 테스트가 용이합니다.

### 1-1. GroupSelectFeature 테스트
**파일**: `MongleFeatures/Tests/GroupSelectFeatureTests.swift`

그룹 선택 플로우는 최근 여러 차례 수정된 영역으로 회귀 위험이 높습니다.

```swift
// 테스트 케이스:

// 그룹 생성 플로우
test("그룹명 미입력 시 createNextTapped → groupNameError가 true가 된다")
test("닉네임 미입력 시 createNextTapped → nicknameError가 true가 된다")
test("컬러 미선택 시 createNextTapped → 랜덤 컬러가 자동 선택된다")
test("colorChanged 액션 → isColorExplicitlySelected가 true가 된다")
test("createBackTapped → step이 .select로 돌아간다")

// 그룹 참여 플로우
test("초대코드 미입력 시 joinTapped → joinCodeError가 true가 된다")
test("닉네임 미입력 시 joinTapped → nicknameError가 true가 된다")
test("joinBackTapped → step이 .select로 돌아간다")

// 그룹 한도 제한
test("groups가 3개일 때 newSpaceButtonTapped → showActionSheet가 열린다")
test("groups가 3개일 때 actionSheetNewSpaceTapped → showMaxGroupsToast가 true가 된다")
test("groups가 3개일 때 actionSheetJoinSpaceTapped → showMaxGroupsToast가 true가 된다")
test("maxGroupsToastDismissed → showMaxGroupsToast가 false가 된다")

// 그룹 탈퇴 플로우
test("leaveGroupTapped → showLeaveConfirmation이 true가 된다")
test("cancelLeaveConfirmation → showLeaveConfirmation이 false가 된다")

// 알림 배지
test("onAppear → notificationRepository를 호출해 hasUnreadNotifications를 설정한다")
test("unreadNotificationsLoaded(true) → hasUnreadNotifications가 true가 된다")
test("unreadNotificationsLoaded(false) → hasUnreadNotifications가 false가 된다")
```

### 1-2. NotificationFeature 테스트
**파일**: `MongleFeatures/Tests/NotificationFeatureTests.swift`

```swift
test("onAppear → 알림 목록이 로드된다")
test("markAsRead(id:) → 해당 알림의 isRead가 true가 된다 (낙관적 업데이트)")
test("markAllAsRead → 모든 알림의 isRead가 true가 된다")
test("deleteNotification(id:) → 해당 알림이 목록에서 제거된다 (낙관적 업데이트)")
test("deleteAll → 알림 목록이 빈 배열이 된다")
test("hasUnread → 읽지 않은 알림이 있으면 true를 반환한다")
test("hasUnread → 모든 알림을 읽으면 false를 반환한다")
```

### 1-3. HomeFeature 테스트
**파일**: `MongleFeatures/Tests/HomeFeatureTests.swift`

```swift
test("onAppear → todayQuestion이 없으면 delegate(.requestRefresh)를 보낸다")
test("onAppear → todayQuestion이 있으면 아무 효과도 없다")
test("notificationTapped → delegate(.navigateToNotifications)를 보낸다")
test("questionTapped → 게스트이면 showGuestLoginPrompt가 true가 된다")
test("questionTapped → todayQuestion이 있으면 delegate(.showQuestionSheet)를 보낸다")
test("myMonggleTapped → 답변 완료 상태이면 delegate(.navigateToMyAnswer)를 보낸다")
test("unreadNotificationsLoaded(true) → hasUnreadNotifications가 true가 된다")
test("refreshData → isRefreshing이 true가 된다")
```

### 1-4. MainTabFeature 알림 배지 통합 테스트
**파일**: `MongleFeatures/Tests/MainTabNotificationTests.swift`

```swift
test("알림 화면 close 시 notifState.hasUnread = false → home.hasUnreadNotifications가 false가 된다")
test("알림 화면 close 시 notifState.hasUnread = true → home.hasUnreadNotifications가 true가 된다")
```

---

## 2. 도메인 모델 테스트 (Domain Tests)

### 2-1. Notification 모델
**파일**: `Domain/Tests/DomainTests/NotificationTests.swift`

```swift
test("hasUnread 계산 프로퍼티 → isRead = false인 항목이 있으면 true")
test("hasUnread 계산 프로퍼티 → 모두 isRead = true이면 false")
test("빈 배열에서 hasUnread → false")
```

### 2-2. MongleGroup 모델
**파일**: `Domain/Tests/DomainTests/MongleGroupTests.swift`

```swift
test("memberIds.count가 한도를 초과하는지 확인하는 로직")
```

---

## 3. 데이터 레이어 테스트 (MongleData Tests)

### 3-1. DTO 매퍼 테스트
**파일**: `MongleData/Tests/MongleDataTests/Mappers/`

매퍼는 순수 함수여서 테스트 비용이 낮고 효과가 큽니다.

```swift
// NotificationMapper
test("NotificationDTO → Notification 변환이 올바르다")
test("isRead 필드가 정확히 매핑된다")
test("createdAt 날짜 파싱이 정확하다")

// UserMapper
test("UserDTO → User 변환이 올바르다")
test("hearts 기본값이 적용된다")

// QuestionMapper
test("QuestionDTO → Question 변환이 올바르다")
test("hasMyAnswer 필드가 정확히 매핑된다")
```

### 3-2. APIEndpoint 테스트
**파일**: `MongleData/Tests/MongleDataTests/APIEndpointTests.swift`

```swift
test("NotificationEndpoint.delete(id:) → DELETE 메서드와 올바른 경로를 생성한다")
test("NotificationEndpoint.deleteAll → DELETE 메서드와 올바른 경로를 생성한다")
test("FamilyEndpoint.join → POST 메서드와 올바른 경로를 생성한다")
```

---

## 4. 구현 방법

### 테스트 타겟 추가 (Xcode)

```
1. Xcode → File → New → Target → Unit Testing Bundle
   - MongleFeaturesTests (MongleFeatures 패키지 대상)
   - MongleDataTests (MongleData 패키지 대상)
   - DomainTests는 이미 존재 (내용 보강 필요)

2. Package.swift에 testTarget 추가:
   .testTarget(
       name: "MongleFeaturesTests",
       dependencies: [
           "MongleFeatures",
           .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
       ]
   )
```

### TCA TestStore 사용 패턴

```swift
import ComposableArchitecture
import XCTest

@MainActor
final class GroupSelectFeatureTests: XCTestCase {

    func test_그룹명_미입력시_에러표시() async {
        let store = TestStore(
            initialState: GroupSelectFeature.State(step: .createGroup)
        ) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = .mock  // 의존성 Mock 교체
            $0.familyRepository = .mock
        }

        await store.send(.createNextTapped) {
            $0.groupNameError = true
        }
    }

    func test_3개_그룹_한도_초과시_토스트() async {
        let groups = (0..<3).map { _ in MongleGroup.mock }
        let store = TestStore(
            initialState: GroupSelectFeature.State(
                step: .select,
                groups: groups
            )
        ) {
            GroupSelectFeature()
        }

        await store.send(.actionSheetNewSpaceTapped) {
            $0.showMaxGroupsToast = true
            $0.showActionSheet = false
        }
    }
}
```

### Mock 의존성 패턴

```swift
// DependencyValues Extension
extension NotificationRepositoryProtocol {
    static var mock: Self {
        Self(
            getNotifications: { _ in [] },
            markAsRead: { _ in },
            markAllAsRead: { },
            delete: { _ in },
            deleteAll: { 0 }
        )
    }

    static var withUnread: Self {
        Self(
            getNotifications: { _ in
                [Notification(id: UUID(), isRead: false, ...)]
            },
            // ...
        )
    }
}
```

---

## 5. 진행 순서 (우선순위)

| 순서 | 대상 | 이유 |
|------|------|------|
| 1 | GroupSelectFeature 리듀서 | 최근 빈번한 수정, 회귀 위험 높음 |
| 2 | NotificationFeature 리듀서 | 낙관적 업데이트 로직 검증 필요 |
| 3 | DTO 매퍼 | 순수 함수, 빠르게 커버 가능 |
| 4 | HomeFeature 리듀서 | 알림 배지 로직 포함 |
| 5 | MainTab 알림 배지 통합 | 이번에 수정한 영역 |
| 6 | Domain 모델 | 상대적으로 단순 |
| 7 | APIEndpoint | 빠른 커버리지 확보 |

---

## 6. CI 연동 (선택)

테스트가 충분히 갖춰지면 GitHub Actions로 PR마다 자동 실행 권장:

```yaml
# .github/workflows/ios-test.yml
- name: Run Tests
  run: xcodebuild test
    -scheme FamTree
    -destination 'platform=iOS Simulator,name=iPhone 16'
    -only-testing:MongleFeaturesTests
    -only-testing:MongleDataTests
    -only-testing:DomainTests
```
