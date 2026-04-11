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

    init(apiClient: APIClientProtocol = APIClient()) {
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

    func registerDeviceToken(token: String) async throws {
        struct OkResponse: Decodable { let ok: Bool }
        let _: OkResponse = try await apiClient.request(UserEndpoint.registerDeviceToken(token: token))
    }

    func grantAdHearts(amount: Int) async throws -> Int {
        struct Response: Decodable { let heartsRemaining: Int }
        let response: Response = try await apiClient.request(UserEndpoint.adHeartReward(amount: amount))
        return response.heartsRemaining
    }

    // MARK: - v2 (PRD §2.2 / §4 / §9)

    func getCharacterStage() async throws -> CharacterStage {
        let dto: CharacterStageDTO = try await apiClient.request(UserEndpoint.getCharacterStage)
        return CharacterStageMapper.toDomain(dto)
    }

    func getBadges() async throws -> BadgeList {
        let dto: BadgeListResponseDTO = try await apiClient.request(UserEndpoint.getBadges)
        return BadgeMapper.toDomain(dto)
    }

    func markBadgesSeen(codes: [String]) async throws {
        let _: OkResponseDTO = try await apiClient.request(UserEndpoint.markBadgesSeen(codes: codes))
    }

    func updateNotificationPrefs(streakRisk: Bool?, badgeEarned: Bool?) async throws {
        let _: UserDTO = try await apiClient.request(
            UserEndpoint.updateNotificationPrefs(streakRisk: streakRisk, badgeEarned: badgeEarned)
        )
    }
}
