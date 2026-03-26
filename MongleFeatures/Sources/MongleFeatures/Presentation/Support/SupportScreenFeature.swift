import Foundation
import ComposableArchitecture

@Reducer
public struct SupportScreenFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Destination: Equatable {
            case historyCalendar
        }

        public var destination: Destination
        public var historyCalendar: HistoryCalendarFeature.State

        public init(destination: Destination = .historyCalendar) {
            self.destination = destination
            self.historyCalendar = HistoryCalendarFeature.State()
        }
    }

    public enum Action: Sendable, Equatable {
        case closeTapped
        case historyCalendar(HistoryCalendarFeature.Action)
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.historyCalendar, action: \.historyCalendar) {
            HistoryCalendarFeature()
        }
        Reduce { state, action in
            switch action {
            case .closeTapped:
                return .send(.delegate(.close))
            case .historyCalendar(.delegate(.close)):
                return .send(.delegate(.close))
            case .historyCalendar:
                return .none
            case .delegate:
                return .none
            }
        }
    }
}
