import Foundation
import Domain

final class NudgeRepository: NudgeRepositoryInterface {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func sendNudge(targetUserId: String) async throws -> Int {
        struct NudgeResponse: Decodable {
            let heartsRemaining: Int
        }
        let response: NudgeResponse = try await apiClient.request(NudgeEndpoint.send(targetUserId: targetUserId))
        return response.heartsRemaining
    }
}
