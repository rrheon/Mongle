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

        public init() {
            let today = Date()
            let calendar = Calendar.current
            self.currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            self.selectedDate = today
            self.moodRecords = []
            self.isMoodLoading = false
            self.moodCalendar = [:]
        }
    }

    public enum Action: Sendable, Equatable {
        case onAppear
        case moodLoaded([Domain.MoodRecord])
        case previousMonthTapped
        case nextMonthTapped
        case dateSelected(Date)
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
                return .run { [moodRepository] send in
                    let records = (try? await moodRepository.getRecentMoods(days: 31)) ?? []
                    await send(.moodLoaded(records))
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
