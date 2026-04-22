import Foundation

public protocol NotificationRepositoryProtocol: Sendable {
    func getNotifications(limit: Int, familyId: UUID?) async throws -> [Notification]
    func markAsRead(id: UUID) async throws -> Notification
    func markAllAsRead(familyId: UUID?) async throws -> Int
    func delete(id: UUID) async throws
    func deleteAll(familyId: UUID?) async throws -> Int
}

public extension NotificationRepositoryProtocol {
    func getNotifications(limit: Int) async throws -> [Notification] {
        try await getNotifications(limit: limit, familyId: nil)
    }
    func markAllAsRead() async throws -> Int {
        try await markAllAsRead(familyId: nil)
    }
    func deleteAll() async throws -> Int {
        try await deleteAll(familyId: nil)
    }
}
