import Foundation

protocol UserAPIServiceProtocol {
    func fetchUser(userId: String) async throws -> UserDTO
    func updateUser(userId: String, data: UserDTO) async throws -> UserDTO
}

final class UserAPIService: UserAPIServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func fetchUser(userId: String) async throws -> UserDTO {
        let endpoint = UserEndpoint.fetchUser(userId: userId)
        return try await apiClient.request(endpoint)
    }

    func updateUser(userId: String, data: UserDTO) async throws -> UserDTO {
        let endpoint = UserEndpoint.updateUser(userId: userId, data: data)
        return try await apiClient.request(endpoint)
    }
}
