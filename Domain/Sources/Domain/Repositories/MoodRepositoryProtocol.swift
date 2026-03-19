import Foundation

public struct MoodRecord: Equatable, Identifiable, Sendable {
    public let id: String
    public let mood: String
    public let note: String?
    public let date: Date

    public init(id: String, mood: String, note: String?, date: Date) {
        self.id = id
        self.mood = mood
        self.note = note
        self.date = date
    }
}

public protocol MoodRepositoryProtocol: Sendable {
    func saveMood(mood: String, note: String?, date: String?) async throws -> MoodRecord
    func getRecentMoods(days: Int) async throws -> [MoodRecord]
}
