import Foundation
import Domain

final class NotificationRepository: NotificationRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func getNotifications(limit: Int, familyId: UUID?) async throws -> [Domain.Notification] {
        struct Response: Decodable {
            let notifications: [NotificationDTO]
        }
        let response: Response = try await apiClient.request(
            NotificationEndpoint.getAll(limit: limit, familyId: familyId?.uuidString.lowercased())
        )
        return response.notifications.compactMap { $0.toDomain() }
    }

    func getUnreadCount() async throws -> Int {
        struct Response: Decodable { let count: Int }
        let response: Response = try await apiClient.request(NotificationEndpoint.unreadCount)
        return response.count
    }

    func markAsRead(id: UUID) async throws -> Domain.Notification {
        let dto: NotificationDTO = try await apiClient.request(NotificationEndpoint.markAsRead(id: id.uuidString))
        guard let notification = dto.toDomain() else { throw APIError.decodingError("notification mapping failed") }
        return notification
    }

    func markAllAsRead(familyId: UUID?) async throws -> Int {
        struct Response: Decodable { let count: Int }
        let response: Response = try await apiClient.request(
            NotificationEndpoint.markAllAsRead(familyId: familyId?.uuidString.lowercased())
        )
        return response.count
    }

    func delete(id: UUID) async throws {
        try await apiClient.request(NotificationEndpoint.delete(id: id.uuidString))
    }

    func deleteAll(familyId: UUID?) async throws -> Int {
        struct Response: Decodable { let count: Int }
        let response: Response = try await apiClient.request(
            NotificationEndpoint.deleteAll(familyId: familyId?.uuidString.lowercased())
        )
        return response.count
    }
}

private struct NotificationDTO: Decodable {
    let id: String
    let userId: String
    let familyId: String?
    let type: String
    let title: String
    let body: String
    let isRead: Bool
    let createdAt: String
    let colorId: String?

    func toDomain() -> Domain.Notification? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let id = UUID(uuidString: self.id),
              let userId = UUID(uuidString: self.userId),
              let notifType = mapType(type),
              let date = formatter.date(from: createdAt)
        else { return nil }

        return Domain.Notification(
            id: id,
            userId: userId,
            familyId: familyId.flatMap { UUID(uuidString: $0) },
            type: notifType,
            title: title,
            body: body,
            isRead: isRead,
            createdAt: date,
            colorId: colorId
        )
    }

    private func mapType(_ raw: String) -> Domain.NotificationType? {
        switch raw {
        case "NEW_QUESTION": return .newQuestion
        case "MEMBER_ANSWERED": return .memberAnswered
        case "ALL_ANSWERED": return .allAnswered
        case "ANSWER_REQUEST": return .answerRequest
        case "BADGE_EARNED": return .badgeEarned
        case "REMINDER": return .reminder
        default: return nil
        }
    }
}
