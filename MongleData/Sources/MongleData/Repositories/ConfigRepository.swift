import Foundation
import Domain

final class ConfigRepository: ConfigRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func fetch() async throws -> AppConfig {
        struct Response: Decodable {
            let isAdEnabled: Bool
        }
        let response: Response = try await apiClient.request(ConfigEndpoint.get)
        return AppConfig(isAdEnabled: response.isAdEnabled)
    }
}
