import Foundation
import ComposableArchitecture

@Reducer
public struct AnswerFirstPopupFeature {
    @ObservableState
    public struct State: Equatable {
        public var memberName: String

        public init(memberName: String) {
            self.memberName = memberName
        }
    }

    public enum Action: Sendable, Equatable {
        case answerNowTapped
        case laterTapped
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case answerNow
            case close
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .answerNowTapped:
                return .send(.delegate(.answerNow))
            case .laterTapped:
                return .send(.delegate(.close))
            case .delegate:
                return .none
            }
        }
    }
}
