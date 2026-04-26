import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct HistoryCalendarFeature {
    @ObservableState
    public struct State: Equatable {
        public var moodRecords: [Domain.MoodRecord]
        public var isMoodLoading: Bool
        public var currentMonth: Date
        public var selectedDate: Date
        public var moodCalendar: [Date: String]
        public var errorMessage: String?

        public init() {
            let today = Date()
            let calendar = Calendar.current
            self.currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            self.selectedDate = today
            self.moodRecords = []
            self.isMoodLoading = false
            self.moodCalendar = [:]
            self.errorMessage = nil
        }
    }

    public enum Action: Sendable, Equatable {
        case onAppear
        case moodLoaded([Domain.MoodRecord])
        case loadFailed(String)
        case previousMonthTapped
        case nextMonthTapped
        case dateSelected(Date)
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
                // try? silent fallback → do-catch 로 변경. 실패 시 사용자가 빈 차트로
                // 오해하지 않도록 errorMessage 로 안내.
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
                var cal: [Date: String] = [:]
                for record in records {
                    cal[Calendar.current.startOfDay(for: record.date)] = record.mood
                }
                state.moodCalendar = cal
                return .none

            case .loadFailed(let message):
                state.isMoodLoading = false
                state.errorMessage = message
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .previousMonthTapped:
                if let month = Calendar.current.date(byAdding: .month, value: -1, to: state.currentMonth) {
                    state.currentMonth = month
                }
                return .none

            case .nextMonthTapped:
                if let month = Calendar.current.date(byAdding: .month, value: 1, to: state.currentMonth) {
                    state.currentMonth = month
                }
                return .none

            case .dateSelected(let date):
                state.selectedDate = date
                return .none

            case .closeTapped:
                return .send(.delegate(.close))

            case .delegate:
                return .none
            }
        }
    }
}
