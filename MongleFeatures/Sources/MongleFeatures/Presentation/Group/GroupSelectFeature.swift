import Foundation
import ComposableArchitecture

@Reducer
public struct GroupSelectFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Step: Equatable, Sendable {
            case select
            case createGroup
            case groupCreated
            case joinWithCode
        }

        public var step: Step = .select
        public var showActionSheet: Bool = false
        public var groupName: String = ""
        public var nickname: String = ""
        public var inviteCode: String = ""
        public var joinCode: String = ""

        public var groupNameError: Bool = false
        public var nicknameError: Bool = false
        public var joinCodeError: Bool = false

        public var isLoading: Bool = false
        public var errorMessage: String? = nil

        public init(
            step: Step = .select,
            groupName: String = "",
            nickname: String = "",
            inviteCode: String = "",
            joinCode: String = ""
        ) {
            self.step = step
            self.groupName = groupName
            self.nickname = nickname
            self.inviteCode = inviteCode
            self.joinCode = joinCode
        }
    }

    public enum Action: Sendable, Equatable {
        case newSpaceButtonTapped
        case actionSheetDismissed
        case actionSheetNewSpaceTapped
        case actionSheetJoinSpaceTapped
        case notificationTapped
        case groupNameChanged(String)
        case nicknameChanged(String)
        case joinCodeChanged(String)
        case createNextTapped
        case createBackTapped
        case completeTapped
        case joinBackTapped
        case joinTapped
        case setLoading(Bool)
        case setInviteCode(String)
        case setError(String?)
        case dismissError
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case completed
            case notificationTapped
            case createFamily(name: String)
            case joinFamily(inviteCode: String)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .newSpaceButtonTapped:
                state.showActionSheet = true
                return .none

            case .actionSheetDismissed:
                state.showActionSheet = false
                return .none

            case .actionSheetNewSpaceTapped:
                state.showActionSheet = false
                state.step = .createGroup
                return .none

            case .actionSheetJoinSpaceTapped:
                state.showActionSheet = false
                state.step = .joinWithCode
                return .none

            case .notificationTapped:
                return .send(.delegate(.notificationTapped))

            case .groupNameChanged(let name):
                state.groupName = name
                state.groupNameError = false
                return .none

            case .nicknameChanged(let name):
                state.nickname = name
                state.nicknameError = false
                return .none

            case .joinCodeChanged(let code):
                state.joinCode = code
                state.joinCodeError = false
                return .none

            case .createNextTapped:
                let nameEmpty = state.groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let nickEmpty = state.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                state.groupNameError = nameEmpty
                state.nicknameError = nickEmpty
                guard !nameEmpty && !nickEmpty else { return .none }
                state.isLoading = true
                return .send(.delegate(.createFamily(name: state.groupName)))

            case .createBackTapped:
                state.step = .select
                state.groupName = ""
                state.nickname = ""
                state.groupNameError = false
                state.nicknameError = false
                state.errorMessage = nil
                return .none

            case .completeTapped:
                return .send(.delegate(.completed))

            case .joinBackTapped:
                state.step = .select
                state.joinCode = ""
                state.nickname = ""
                state.joinCodeError = false
                state.nicknameError = false
                state.errorMessage = nil
                return .none

            case .joinTapped:
                let codeEmpty = state.joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let nickEmpty = state.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                state.joinCodeError = codeEmpty
                state.nicknameError = nickEmpty
                guard !codeEmpty && !nickEmpty else { return .none }
                state.isLoading = true
                return .send(.delegate(.joinFamily(inviteCode: state.joinCode)))

            case .setLoading(let loading):
                state.isLoading = loading
                return .none

            case .setInviteCode(let code):
                state.inviteCode = code
                state.step = .groupCreated
                state.isLoading = false
                return .none

            case .setError(let message):
                state.errorMessage = message
                state.isLoading = false
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
