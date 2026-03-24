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

    func getNotifications(limit: Int) async throws -> [Domain.Notification] {
        if let error = getNotificationsError { throw error }
        return getNotificationsResult
    }

    func markAsRead(id: UUID) async throws -> Domain.Notification {
        if let error = markAsReadError { throw error }
        return markAsReadResult!
    }

    func markAllAsRead() async throws -> Int {
        markAllAsReadResult
    }

    func delete(id: UUID) async throws {
        if let error = deleteError { throw error }
    }

    func deleteAll() async throws -> Int {
        deleteAllResult
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
