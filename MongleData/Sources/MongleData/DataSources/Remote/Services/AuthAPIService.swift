import Foundation

protocol AuthAPIServiceProtocol {
    func logout() async throws
    func getCurrentUser(grantDailyHeart: Bool) async throws -> UserDTO?
}

final class AuthAPIService: AuthAPIServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func logout() async throws {
        let endpoint = AuthEndpoint.logout
        try await apiClient.request(endpoint)
    }

    func getCurrentUser(grantDailyHeart: Bool) async throws -> UserDTO? {
        let endpoint = AuthEndpoint.getCurrentUser(grantDailyHeart: grantDailyHeart)
        do {
            let user: UserDTO = try await apiClient.request(endpoint)
            return user
        } catch APIError.unauthorized {
            return nil
        }
    }
}
