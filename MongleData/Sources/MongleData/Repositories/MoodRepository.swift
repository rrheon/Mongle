import Foundation
import Domain

final class MoodRepository: MoodRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func saveMood(mood: String, note: String?, date: String?) async throws -> MoodRecord {
        struct SaveMoodResponse: Decodable {
            let record: MoodRecordDTO
        }
        let response: SaveMoodResponse = try await apiClient.request(MoodEndpoint.save(mood: mood, note: note, date: date))
        return response.record.toDomain()
    }

    func getRecentMoods(days: Int) async throws -> [MoodRecord] {
        struct GetMoodsResponse: Decodable {
            let records: [MoodRecordDTO]
        }
        let response: GetMoodsResponse = try await apiClient.request(MoodEndpoint.getRecent(days: days))
        return response.records.map { $0.toDomain() }
    }
}

private struct MoodRecordDTO: Decodable {
    let id: String
    let mood: String
    let note: String?
    let date: String // YYYY-MM-DD

    func toDomain() -> MoodRecord {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let parsed = formatter.date(from: date) ?? Date()
        return MoodRecord(id: id, mood: mood, note: note, date: parsed)
    }
}
