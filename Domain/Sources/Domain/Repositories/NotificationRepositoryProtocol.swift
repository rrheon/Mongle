import Foundation

public protocol NotificationRepositoryProtocol: Sendable {
    func getNotifications(limit: Int) async throws -> [Notification]
    func markAsRead(id: UUID) async throws -> Notification
    func markAllAsRead() async throws -> Int
}
