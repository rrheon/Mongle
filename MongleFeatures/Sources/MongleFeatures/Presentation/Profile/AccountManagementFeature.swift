import ComposableArchitecture

@Reducer
public struct AccountManagementFeature {
    @ObservableState
    public struct State: Equatable {
        public var showLogoutConfirm = false
        public var showDeleteConfirm = false

        public init() {}
    }

    public enum Action: Sendable, Equatable {
        case backTapped
        case logoutTapped
        case logoutConfirmed
        case deleteAccountTapped
        case deleteAccountConfirmed
        case alertDismissed
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
            case logout
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .send(.delegate(.close))

            case .logoutTapped:
                state.showLogoutConfirm = true
                return .none

            case .logoutConfirmed:
                state.showLogoutConfirm = false
                return .send(.delegate(.logout))

            case .deleteAccountTapped:
                state.showDeleteConfirm = true
                return .none

            case .deleteAccountConfirmed:
                state.showDeleteConfirm = false
                return .none

            case .alertDismissed:
                state.showLogoutConfirm = false
                state.showDeleteConfirm = false
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
