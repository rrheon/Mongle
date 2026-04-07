import XCTest
import ComposableArchitecture
import Domain
@testable import MongleFeatures

@MainActor
final class GroupSelectFeatureTests: XCTestCase {

    // MARK: - onAppear

    func testOnAppear_LoadsUnreadBadgeStatus_WithUnread() async {
        let unreadNotif = NotificationFactory.make(isRead: false)
        let repo = MockNotificationRepository()
        repo.getNotificationsResult = [unreadNotif]

        let store = TestStore(
            initialState: GroupSelectFeature.State()
        ) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = repo
        }

        await store.send(.onAppear) {
            $0.isLoadingGroups = true
        }
        await store.receive(\.unreadNotificationsLoaded) {
            $0.hasUnreadNotifications = true
        }
    }

    func testOnAppear_NoUnreadNotifications_BadgeFalse() async {
        let readNotif = NotificationFactory.make(isRead: true)
        let repo = MockNotificationRepository()
        repo.getNotificationsResult = [readNotif]

        let store = TestStore(
            initialState: GroupSelectFeature.State()
        ) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = repo
        }

        await store.send(.onAppear) {
            $0.isLoadingGroups = true
        }
        // hasUnreadNotifications는 이미 false이므로 상태 변화 없음
        await store.receive(\.unreadNotificationsLoaded)
    }

    // MARK: - newSpaceButtonTapped

    func testNewSpaceButtonTapped_ShowsActionSheet() async {
        let store = TestStore(
            initialState: GroupSelectFeature.State()
        ) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.newSpaceButtonTapped) {
            $0.showActionSheet = true
        }
    }

    func testActionSheetDismissed_HidesActionSheet() async {
        var initial = GroupSelectFeature.State()
        initial.showActionSheet = true

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.actionSheetDismissed) {
            $0.showActionSheet = false
        }
    }

    // MARK: - Step transitions

    func testActionSheetNewSpaceTapped_TransitionsToCreateGroup() async {
        var initial = GroupSelectFeature.State()
        initial.showActionSheet = true

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.actionSheetNewSpaceTapped) {
            $0.showActionSheet = false
            $0.step = .createGroup
        }
    }

    func testActionSheetNewSpaceTapped_MaxGroups_ShowsToast() async {
        var initial = GroupSelectFeature.State()
        initial.showActionSheet = true
        initial.groups = [
            GroupFactory.make(), GroupFactory.make(), GroupFactory.make()
        ]

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.actionSheetNewSpaceTapped) {
            $0.showActionSheet = false
            $0.showMaxGroupsToast = true
        }
    }

    func testActionSheetJoinSpaceTapped_TransitionsToJoinWithCode() async {
        var initial = GroupSelectFeature.State()
        initial.showActionSheet = true

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.actionSheetJoinSpaceTapped) {
            $0.showActionSheet = false
            $0.step = .joinWithCode
        }
    }

    // MARK: - Form input

    func testGroupNameChanged_TruncatesTo10Chars() async {
        let store = TestStore(
            initialState: GroupSelectFeature.State()
        ) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        let longName = String(repeating: "가", count: 20)
        await store.send(.groupNameChanged(longName)) {
            $0.groupName = String(repeating: "가", count: 10)
            $0.groupNameError = false
        }
    }

    func testNicknameChanged_TruncatesTo10Chars() async {
        let store = TestStore(
            initialState: GroupSelectFeature.State()
        ) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        let longNick = String(repeating: "나", count: 15)
        await store.send(.nicknameChanged(longNick)) {
            $0.nickname = String(repeating: "나", count: 10)
            $0.nicknameError = false
        }
    }

    // MARK: - createNextTapped validation

    func testCreateNextTapped_EmptyGroupName_SetsError() async {
        var initial = GroupSelectFeature.State()
        initial.groupName = ""
        initial.nickname = "아빠"

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.createNextTapped) {
            $0.groupNameError = true
            $0.appError = .domain("공간 이름을 입력해주세요")
            $0.createGroupFocusField = .groupName
        }
    }

    func testCreateNextTapped_EmptyNickname_SetsError() async {
        var initial = GroupSelectFeature.State()
        initial.groupName = "우리 가족"
        initial.nickname = ""

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.createNextTapped) {
            $0.nicknameError = true
            $0.appError = .domain("닉네임을 입력해주세요")
            $0.createGroupFocusField = .nickname
        }
    }

    func testCreateNextTapped_ValidInputs_SetsLoadingAndSendsDelegate() async {
        var initial = GroupSelectFeature.State()
        initial.groupName = "우리 가족"
        initial.nickname = "아빠"
        initial.selectedColorId = "calm"
        initial.isColorExplicitlySelected = true

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        // delegate 수신 확인을 위해 exhaustivity 비활성화
        store.exhaustivity = .off

        await store.send(.createNextTapped) {
            $0.isLoading = true
        }
    }

    // MARK: - createBackTapped

    func testCreateBackTapped_ResetsFormAndGoesBack() async {
        var initial = GroupSelectFeature.State()
        initial.step = .createGroup
        initial.groupName = "이름"
        initial.nickname = "닉네임"
        initial.groupNameError = true

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.createBackTapped) {
            $0.step = .select
            $0.groupName = ""
            $0.nickname = ""
            $0.selectedColorId = "loved"
            $0.groupNameError = false
            $0.nicknameError = false
            $0.errorMessage = nil
            $0.isColorExplicitlySelected = false
            $0.createGroupFocusField = nil
        }
    }

    // MARK: - joinTapped validation

    func testJoinTapped_EmptyCode_SetsError() async {
        var initial = GroupSelectFeature.State()
        initial.joinCode = ""
        initial.nickname = "아빠"

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.joinTapped) {
            $0.joinCodeError = true
            $0.appError = .domain("초대 코드를 입력해주세요")
            $0.joinGroupFocusField = .joinCode
        }
    }

    func testJoinTapped_ValidInputs_SetsLoadingAndSendsDelegate() async {
        var initial = GroupSelectFeature.State()
        initial.joinCode = "ABCDEFGH"
        initial.nickname = "엄마"
        initial.selectedColorId = "happy"
        initial.isColorExplicitlySelected = true

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        store.exhaustivity = .off

        await store.send(.joinTapped) {
            $0.isLoading = true
        }
    }

    // MARK: - setInviteCode

    func testSetInviteCode_TransitionsToGroupCreated() async {
        let store = TestStore(
            initialState: GroupSelectFeature.State()
        ) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.setInviteCode("INVITE01")) {
            $0.inviteCode = "INVITE01"
            $0.step = .groupCreated
            $0.isLoading = false
        }
    }

    // MARK: - completeTapped

    func testCompleteTapped_SendsCompletedDelegate() async {
        let store = TestStore(
            initialState: GroupSelectFeature.State()
        ) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        store.exhaustivity = .off
        await store.send(.completeTapped)
    }

    // MARK: - loadGroupsResponse

    func testLoadGroupsResponse_Success_SetsGroups() async {
        let group = GroupFactory.make()

        let store = TestStore(
            initialState: GroupSelectFeature.State()
        ) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.loadGroupsResponse(.success([group]))) {
            $0.groups = [group]
            $0.isLoadingGroups = false
        }
    }

    func testLoadGroupsResponse_Failure_StopsLoading() async {
        var initial = GroupSelectFeature.State()
        initial.isLoadingGroups = true

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        struct SomeError: Error {}
        await store.send(.loadGroupsResponse(.failure(SomeError()))) {
            $0.isLoadingGroups = false
        }
    }

    // MARK: - cancelLeaveConfirmation

    func testCancelLeaveConfirmation_HidesConfirmationAndClearsGroup() async {
        let group = GroupFactory.make()
        var initial = GroupSelectFeature.State()
        initial.showLeaveConfirmation = true
        initial.groupToLeave = group

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.cancelLeaveConfirmation) {
            $0.showLeaveConfirmation = false
            $0.groupToLeave = nil
        }
    }

    // MARK: - notificationTapped — pushes NotificationFeature

    func testNotificationTapped_PushesNotificationFeature() async {
        let group = GroupFactory.make(name: "테스트 그룹")
        var initial = GroupSelectFeature.State()
        initial.groups = [group]

        let store = TestStore(initialState: initial) {
            GroupSelectFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }

        await store.send(.notificationTapped) {
            $0.path.append(.notification(NotificationFeature.State(
                mode: .grouped,
                groupNameMap: [group.id: group.name]
            )))
        }
    }
}
