import XCTest
import ComposableArchitecture
import Domain
@testable import MongleFeatures

@MainActor
final class NotificationFeatureTests: XCTestCase {

    // MARK: - onAppear

    func testOnAppear_LoadsNotificationsWhenEmpty() async {
        let userId = UUID()
        let notif = NotificationFactory.make(userId: userId, isRead: false)
        let repo = MockNotificationRepository()
        repo.getNotificationsResult = [notif]

        let store = TestStore(
            initialState: NotificationFeature.State()
        ) {
            NotificationFeature()
        } withDependencies: {
            $0.notificationRepository = repo
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.notificationsLoaded([notif])) {
            $0.notifications = [notif]
            $0.isLoading = false
        }
    }

    func testOnAppear_SkipsLoadWhenNotificationsAlreadyLoaded() async {
        let existing = NotificationFactory.make()
        let repo = MockNotificationRepository()

        let store = TestStore(
            initialState: NotificationFeature.State(notifications: [existing])
        ) {
            NotificationFeature()
        } withDependencies: {
            $0.notificationRepository = repo
        }

        // 이미 알림이 있으면 아무 effect 없이 .none 반환
        await store.send(.onAppear)
    }

    // MARK: - refresh

    func testRefresh_AlwaysReloadsNotifications() async {
        let existing = NotificationFactory.make()
        let fresh = NotificationFactory.make(title: "새 알림")
        let repo = MockNotificationRepository()
        repo.getNotificationsResult = [fresh]

        let store = TestStore(
            initialState: NotificationFeature.State(notifications: [existing])
        ) {
            NotificationFeature()
        } withDependencies: {
            $0.notificationRepository = repo
        }

        await store.send(.refresh) {
            $0.isLoading = true
        }
        await store.receive(.notificationsLoaded([fresh])) {
            $0.notifications = [fresh]
            $0.isLoading = false
        }
    }

    // MARK: - markAsRead

    func testMarkAsRead_OptimisticallyUpdatesState() async {
        let notifId = UUID()
        let userId = UUID()
        let unread = NotificationFactory.make(id: notifId, userId: userId, isRead: false)
        let repo = MockNotificationRepository()
        repo.markAsReadResult = NotificationFactory.make(id: notifId, userId: userId, isRead: true)

        let store = TestStore(
            initialState: NotificationFeature.State(notifications: [unread])
        ) {
            NotificationFeature()
        } withDependencies: {
            $0.notificationRepository = repo
        }

        await store.send(.markAsRead(unread)) {
            $0.notifications[0] = MongleNotification(
                id: notifId,
                userId: userId,
                familyId: nil,
                type: .newQuestion,
                title: "알림 제목",
                body: "알림 내용",
                isRead: true,
                createdAt: unread.createdAt
            )
        }
    }

    // MARK: - markAllAsRead

    func testMarkAllAsRead_SetsAllNotificationsAsRead() async {
        let userId = UUID()
        let notif1 = NotificationFactory.make(userId: userId, isRead: false)
        let notif2 = NotificationFactory.make(userId: userId, isRead: false)
        let repo = MockNotificationRepository()

        let store = TestStore(
            initialState: NotificationFeature.State(notifications: [notif1, notif2])
        ) {
            NotificationFeature()
        } withDependencies: {
            $0.notificationRepository = repo
        }

        await store.send(.markAllAsRead) {
            $0.notifications = $0.notifications.map { n in
                MongleNotification(
                    id: n.id,
                    userId: n.userId,
                    familyId: n.familyId,
                    type: n.type,
                    title: n.title,
                    body: n.body,
                    isRead: true,
                    createdAt: n.createdAt
                )
            }
        }
    }

    // MARK: - deleteNotification

    func testDeleteNotification_RemovesFromState() async {
        let notif = NotificationFactory.make()
        let repo = MockNotificationRepository()

        let store = TestStore(
            initialState: NotificationFeature.State(notifications: [notif])
        ) {
            NotificationFeature()
        } withDependencies: {
            $0.notificationRepository = repo
        }

        await store.send(.deleteNotification(notif)) {
            $0.notifications = []
        }
    }

    // MARK: - deleteAll

    func testDeleteAll_ClearsAllNotifications() async {
        let notif1 = NotificationFactory.make()
        let notif2 = NotificationFactory.make()
        let repo = MockNotificationRepository()

        let store = TestStore(
            initialState: NotificationFeature.State(notifications: [notif1, notif2])
        ) {
            NotificationFeature()
        } withDependencies: {
            $0.notificationRepository = repo
        }

        await store.send(.deleteAll) {
            $0.notifications = []
        }
    }

    // MARK: - backTapped → delegate(.close)

    func testBackTapped_SendsCloseDelegate() async {
        let repo = MockNotificationRepository()

        let store = TestStore(
            initialState: NotificationFeature.State()
        ) {
            NotificationFeature()
        } withDependencies: {
            $0.notificationRepository = repo
        }

        await store.send(.backTapped)
        await store.receive(.delegate(.close))
    }

    // MARK: - dismissError

    func testDismissError_ClearsErrorMessage() async {
        let repo = MockNotificationRepository()

        let store = TestStore(
            initialState: NotificationFeature.State()
        ) {
            NotificationFeature()
        } withDependencies: {
            $0.notificationRepository = repo
        }

        // setError로 에러 상태 설정 후 dismiss 테스트
        await store.send(.setError("오류 발생")) {
            $0.errorMessage = "오류 발생"
            $0.isLoading = false
        }
        await store.send(.dismissError) {
            $0.errorMessage = nil
        }
    }

    // MARK: - State computed properties

    func testUnreadCount_CountsUnreadNotifications() {
        let notif1 = NotificationFactory.make(isRead: false)
        let notif2 = NotificationFactory.make(isRead: true)
        let notif3 = NotificationFactory.make(isRead: false)

        let state = NotificationFeature.State(notifications: [notif1, notif2, notif3])
        XCTAssertEqual(state.unreadCount, 2)
        XCTAssertTrue(state.hasUnread)
    }

    func testHasUnread_FalseWhenAllRead() {
        let notif = NotificationFactory.make(isRead: true)
        let state = NotificationFeature.State(notifications: [notif])
        XCTAssertFalse(state.hasUnread)
        XCTAssertEqual(state.unreadCount, 0)
    }

    // MARK: - groupedNotifications (mode: .all)

    func testGroupedNotifications_AllMode_GroupsByDate() {
        let today = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -10, to: today)!

        let recentNotif = NotificationFactory.make(createdAt: today)
        let oldNotif = NotificationFactory.make(createdAt: weekAgo)

        let state = NotificationFeature.State(notifications: [recentNotif, oldNotif], mode: .all)
        let grouped = state.groupedNotifications

        // 오늘 항목과 이전 항목이 별도 섹션으로 분리됨
        XCTAssertEqual(grouped.count, 2)
        XCTAssertEqual(grouped[0].0, "오늘")
        XCTAssertEqual(grouped[1].0, "이전")
    }

    func testGroupedNotifications_FilteredMode_FiltersByFamilyId() {
        let targetFamilyId = UUID()
        let otherFamilyId = UUID()

        let notif1 = NotificationFactory.make(familyId: targetFamilyId)
        let notif2 = NotificationFactory.make(familyId: otherFamilyId)

        let state = NotificationFeature.State(
            notifications: [notif1, notif2],
            mode: .filtered(familyId: targetFamilyId, familyName: "우리 가족")
        )
        let grouped = state.groupedNotifications
        let allNotifs = grouped.flatMap { $0.1 }

        XCTAssertEqual(allNotifs.count, 1)
        XCTAssertEqual(allNotifs[0].familyId, targetFamilyId)
    }
}
