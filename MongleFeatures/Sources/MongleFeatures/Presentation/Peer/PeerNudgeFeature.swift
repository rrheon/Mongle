import Foundation
import ComposableArchitecture

@Reducer
public struct PeerNudgeFeature {
    @ObservableState
    public struct State: Equatable {
        public var memberName: String
        public var questionText: String
        public var hearts: Int
        public var isSent: Bool

        public init(memberName: String, questionText: String = "", hearts: Int = 5, isSent: Bool = false) {
            self.memberName = memberName
            self.questionText = questionText
            self.hearts = hearts
            self.isSent = isSent
        }
    }

    public enum Action: Sendable, Equatable {
        case nudgeTapped
        case closeTapped
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .nudgeTapped:
                guard state.hearts > 0 else { return .none }
                state.hearts -= 1
                state.isSent = true
                return .none

            case .closeTapped:
                return .send(.delegate(.close))

            case .delegate:
                return .none
            }
        }
    }
}
