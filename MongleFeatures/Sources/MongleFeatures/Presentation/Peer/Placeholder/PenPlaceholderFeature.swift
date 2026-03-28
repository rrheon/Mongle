import Foundation
import ComposableArchitecture

@Reducer
public struct PenPlaceholderFeature {
    @ObservableState
    public struct State: Equatable {
        public var title: String
        public var description: String

        public init(title: String, description: String) {
            self.title = title
            self.description = description
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
        Reduce { _, action in
            switch action {
            case .closeTapped:
                return .send(.delegate(.close))
            case .delegate:
                return .none
            }
        }
    }
}
