import Foundation
import Domain

// MARK: - Mock NotificationRepository

final class MockNotificationRepository: NotificationRepositoryProtocol, @unchecked Sendable {
    var getNotificationsResult: [Domain.Notification] = []
    var getNotificationsError: Error?
    var markAsReadResult: Domain.Notification?
    var markAsReadError: Error?
    var markAllAsReadResult: Int = 0
    var deleteError: Error?
    var deleteAllResult: Int = 0

    func getNotifications(limit: Int, familyId: UUID?) async throws -> [Domain.Notification] {
        if let error = getNotificationsError { throw error }
        return getNotificationsResult
    }

    func getUnreadCount() async throws -> Int {
        getNotificationsResult.filter { !$0.isRead }.count
    }

    func markAsRead(id: UUID) async throws -> Domain.Notification {
        if let error = markAsReadError { throw error }
        return markAsReadResult!
    }

    func markAllAsRead(familyId: UUID?) async throws -> Int {
        markAllAsReadResult
    }

    func delete(id: UUID) async throws {
        if let error = deleteError { throw error }
    }

    func deleteAll(familyId: UUID?) async throws -> Int {
        deleteAllResult
    }
}

// MARK: - Mock ShopRepository

final class MockShopRepository: ShopRepositoryInterface, @unchecked Sendable {
    var catalogResult: [ShopItem] = []
    var catalogError: Error?
    var inventoryResult: ShopInventory = ShopInventory()
    var inventoryError: Error?
    /// purchase 후 반환할 잔여 하트.
    var purchaseHeartsRemaining: Int = 0
    var purchaseError: Error?
    /// equipDecoration 이 반환할 장착 현황. nil 이면 (slot,itemId) 로 즉석 구성.
    var equipResult: EquippedDecorations?
    var equipError: Error?

    func getCatalog() async throws -> [ShopItem] {
        if let catalogError { throw catalogError }
        return catalogResult
    }

    func getInventory() async throws -> ShopInventory {
        if let inventoryError { throw inventoryError }
        return inventoryResult
    }

    func purchase(itemId: String) async throws -> Int {
        if let purchaseError { throw purchaseError }
        return purchaseHeartsRemaining
    }

    func equipDecoration(slot: DecorationSlot, itemId: String?) async throws -> EquippedDecorations {
        if let equipError { throw equipError }
        if let equipResult { return equipResult }
        var eq = EquippedDecorations()
        switch slot {
        case .head: eq.head = itemId
        case .back: eq.back = itemId
        case .feet: eq.feet = itemId
        }
        return eq
    }

    /// applyBackground 가 반환할 인벤토리. nil 이면 inventoryResult 에 itemId 를 적용해 반환.
    var applyBackgroundResult: ShopInventory?
    var applyBackgroundError: Error?

    func applyBackground(itemId: String) async throws -> ShopInventory {
        if let applyBackgroundError { throw applyBackgroundError }
        if let applyBackgroundResult { return applyBackgroundResult }
        var inv = inventoryResult
        inv.ownedBackgroundIds.insert(itemId)
        inv.appliedBackgroundId = itemId
        return inv
    }
}

// MARK: - Factory Helpers

enum NotificationFactory {
    static func make(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        familyId: UUID? = nil,
        type: NotificationType = .newQuestion,
        title: String = "알림 제목",
        body: String = "알림 내용",
        isRead: Bool = false,
        createdAt: Date = Date()
    ) -> Domain.Notification {
        Domain.Notification(
            id: id,
            userId: userId,
            familyId: familyId,
            type: type,
            title: title,
            body: body,
            isRead: isRead,
            createdAt: createdAt
        )
    }
}

enum GroupFactory {
    static func make(
        id: UUID = UUID(),
        name: String = "우리 가족",
        memberIds: [UUID] = [],
        memberMoodIds: [String] = [],
        createdBy: UUID = UUID(),
        createdAt: Date = Date(),
        inviteCode: String = "ABCDEFGH"
    ) -> MongleGroup {
        MongleGroup(
            id: id,
            name: name,
            memberIds: memberIds,
            createdBy: createdBy,
            createdAt: createdAt,
            inviteCode: inviteCode,
            memberMoodIds: memberMoodIds
        )
    }
}
