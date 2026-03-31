import Foundation

protocol AuthAPIServiceProtocol {
    func login(email: String, password: String) async throws -> UserDTO
    func signup(name: String, email: String, password: String, role: String) async throws -> UserDTO
    func logout() async throws
    func getCurrentUser() async throws -> UserDTO?
}

final class AuthAPIService: AuthAPIServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func login(email: String, password: String) async throws -> UserDTO {
        let endpoint = AuthEndpoint.login(email: email, password: password)
        return try await apiClient.request(endpoint)
    }

    func signup(name: String, email: String, password: String, role: String) async throws -> UserDTO {
        let endpoint = AuthEndpoint.signup(name: name, email: email, password: password, role: role)
        return try await apiClient.request(endpoint)
    }

    func logout() async throws {
        let endpoint = AuthEndpoint.logout
        try await apiClient.request(endpoint)
    }

    func getCurrentUser() async throws -> UserDTO? {
        let endpoint = AuthEndpoint.getCurrentUser
        do {
            let user: UserDTO = try await apiClient.request(endpoint)
            return user
        } catch APIError.unauthorized {
            return nil
        }
    }
}
