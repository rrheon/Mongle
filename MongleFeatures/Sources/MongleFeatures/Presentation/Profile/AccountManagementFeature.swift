import ComposableArchitecture

@Reducer
public struct AccountManagementFeature {
    @ObservableState
    public struct State: Equatable {
        public var showLogoutConfirm = false
        public var showDeleteConfirm = false
        public var isLoading = false
        public var errorMessage: String? = nil
        public var appError: AppError? = nil

        public init() {}
    }

    public enum Action: Sendable, Equatable {
        case backTapped
        case logoutTapped
        case logoutConfirmed
        case deleteAccountTapped
        case deleteAccountConfirmed
        case alertDismissed
        case setLoading(Bool)
        case setError(String?)
        case setAppError(AppError?)
        case dismissError
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
            case logout
            case accountDeleted
        }
    }

    @Dependency(\.authRepository) var authRepository

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
                state.isLoading = true
                return .run { send in
                    do {
                        try await authRepository.logout()
                        await send(.delegate(.logout))
                    } catch {
                        await send(.setAppError(AppError.from(error)))
                    }
                }

            case .deleteAccountTapped:
                state.showDeleteConfirm = true
                return .none

            case .deleteAccountConfirmed:
                state.showDeleteConfirm = false
                state.isLoading = true
                return .run { send in
                    do {
                        try await authRepository.deleteAccount()
                        await send(.delegate(.accountDeleted))
                    } catch {
                        await send(.setAppError(AppError.from(error)))
                    }
                }

            case .alertDismissed:
                state.showLogoutConfirm = false
                state.showDeleteConfirm = false
                return .none

            case .setLoading(let loading):
                state.isLoading = loading
                return .none

            case .setError(let message):
                state.errorMessage = message
                state.isLoading = false
                return .none

            case .setAppError(let error):
                state.appError = error
                state.errorMessage = error?.userMessage
                state.isLoading = false
                return .none

            case .dismissError:
                state.errorMessage = nil
                state.appError = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
