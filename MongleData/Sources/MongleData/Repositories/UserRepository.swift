//
//  UserRepository.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Domain

final class UserRepository: UserRepositoryInterface {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func get(id: UUID) async throws -> User {
        let endpoint = UserEndpoint.fetchUser(userId: id.uuidString)
        let userDTO: UserDTO = try await apiClient.request(endpoint)
        return UserMapper.toDomain(userDTO)
    }

    func update(_ user: User) async throws -> User {
        let dto = UserMapper.toDTO(user)
        let endpoint = UserEndpoint.updateUser(userId: user.id.uuidString, data: dto)
        let updatedDTO: UserDTO = try await apiClient.request(endpoint)
        return UserMapper.toDomain(updatedDTO)
    }

    func updateName(_ name: String) async throws {
        let endpoint = UserEndpoint.updateMe(name: name)
        let _: UserDTO = try await apiClient.request(endpoint)
    }

    func getMyStreak() async throws -> Int {
        struct StreakResponse: Decodable { let streakDays: Int }
        let response: StreakResponse = try await apiClient.request(UserEndpoint.getMyStreak)
        return response.streakDays
    }

    func registerDeviceToken(token: String, environment: String) async throws {
        struct OkResponse: Decodable { let ok: Bool }
        let _: OkResponse = try await apiClient.request(UserEndpoint.registerDeviceToken(token: token, environment: environment))
    }

    func grantAdHearts(amount: Int) async throws -> Int {
        struct Response: Decodable { let heartsRemaining: Int }
        let response: Response = try await apiClient.request(UserEndpoint.adHeartReward(amount: amount))
        return response.heartsRemaining
    }

    func getNotificationPreferences() async throws -> NotificationPreferences {
        let dto: NotificationPreferencesDTO = try await apiClient.request(UserEndpoint.getNotificationPreferences)
        return dto.toDomain()
    }

    func updateNotificationPreferences(_ params: [String: Any]) async throws -> NotificationPreferences {
        let dto: NotificationPreferencesDTO = try await apiClient.request(UserEndpoint.updateNotificationPreferences(params: params))
        return dto.toDomain()
    }
}

struct NotificationPreferencesDTO: Decodable {
    let notifAnswer: Bool
    let notifNudge: Bool
    let notifQuestion: Bool
    let quietHoursEnabled: Bool
    let quietHoursStart: String
    let quietHoursEnd: String

    func toDomain() -> NotificationPreferences {
        NotificationPreferences(
            notifAnswer: notifAnswer,
            notifNudge: notifNudge,
            notifQuestion: notifQuestion,
            quietHoursEnabled: quietHoursEnabled,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd
        )
    }
}
