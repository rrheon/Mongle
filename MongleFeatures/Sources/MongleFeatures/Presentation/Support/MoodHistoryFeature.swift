import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct MoodHistoryFeature {
    @ObservableState
    public struct State: Equatable {
        public var moodRecords: [Domain.MoodRecord]
        public var isMoodLoading: Bool
        public var currentMonth: Date
        public var errorMessage: String?

        public init() {
            let today = Date()
            let calendar = Calendar.current
            self.currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            self.moodRecords = []
            self.isMoodLoading = false
            self.errorMessage = nil
        }
    }

    public enum Action: Sendable, Equatable {
        case onAppear
        case moodLoaded([Domain.MoodRecord])
        case loadFailed(String)
        case dismissError
        case closeTapped
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
        }
    }

    @Dependency(\.moodRepository) var moodRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isMoodLoading = true
                state.errorMessage = nil
                // try? silent fallback → do-catch (사용자 노출)
                return .run { [moodRepository] send in
                    do {
                        let records = try await moodRepository.getRecentMoods(days: 31)
                        await send(.moodLoaded(records))
                    } catch {
                        await send(.loadFailed(AppError.from(error).userMessage))
                    }
                }

            case .moodLoaded(let records):
                state.isMoodLoading = false
                state.moodRecords = records
                return .none

            case .loadFailed(let message):
                state.isMoodLoading = false
                state.errorMessage = message
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .closeTapped:
                return .send(.delegate(.close))

            case .delegate:
                return .none
            }
        }
    }
}
