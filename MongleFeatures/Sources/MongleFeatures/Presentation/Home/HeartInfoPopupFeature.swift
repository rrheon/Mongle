import ComposableArchitecture

@Reducer
public struct HeartInfoPopupFeature {
    @ObservableState
    public struct State: Equatable {
        public var hearts: Int

        public init(hearts: Int = 5) {
            self.hearts = hearts
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
