import Foundation
import ComposableArchitecture

@Reducer
public struct HeartsSystemFeature {
    @ObservableState
    public struct State: Equatable {
        public var heartBalance: Int

        public init(heartBalance: Int = 5) {
            self.heartBalance = heartBalance
        }
    }

    public enum Action: Sendable, Equatable {
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
            case .closeTapped:
                return .send(.delegate(.close))
            case .delegate:
                return .none
            }
        }
    }
}
