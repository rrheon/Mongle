import Foundation
import ComposableArchitecture
import Domain

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
        public var appError: AppError? = nil

        public var groups: [MongleGroup] = []
        public var isLoadingGroups: Bool = false
        public var showMaxGroupsAlert: Bool = false

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

    public enum Action: Sendable {
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
        case setAppError(AppError?)
        case dismissError
        case onAppear
        case loadGroupsResponse(Result<[MongleGroup], Error>)
        case groupTapped(MongleGroup)
        case dismissMaxGroupsAlert
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case completed
            case notificationTapped
            case createFamily(name: String, nickname: String)
            case joinFamily(inviteCode: String, nickname: String)
            case groupSelected(MongleGroup)
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
                guard state.groups.count < 3 else {
                    state.showMaxGroupsAlert = true
                    return .none
                }
                let nameEmpty = state.groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let nickEmpty = state.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                state.groupNameError = nameEmpty
                state.nicknameError = nickEmpty
                guard !nameEmpty && !nickEmpty else { return .none }
                state.isLoading = true
                return .send(.delegate(.createFamily(name: state.groupName, nickname: state.nickname)))

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
                guard state.groups.count < 3 else {
                    state.showMaxGroupsAlert = true
                    return .none
                }
                let codeEmpty = state.joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let nickEmpty = state.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                state.joinCodeError = codeEmpty
                state.nicknameError = nickEmpty
                guard !codeEmpty && !nickEmpty else { return .none }
                state.isLoading = true
                return .send(.delegate(.joinFamily(inviteCode: state.joinCode, nickname: state.nickname)))

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

            case .setAppError(let error):
                state.appError = error
                state.errorMessage = error?.userMessage
                state.isLoading = false
                return .none

            case .dismissError:
                state.errorMessage = nil
                state.appError = nil
                return .none

            case .onAppear:
                state.isLoadingGroups = true
                return .none

            case .loadGroupsResponse(.success(let groups)):
                state.groups = groups
                state.isLoadingGroups = false
                return .none

            case .loadGroupsResponse(.failure):
                state.isLoadingGroups = false
                return .none

            case .groupTapped(let group):
                return .send(.delegate(.groupSelected(group)))

            case .dismissMaxGroupsAlert:
                state.showMaxGroupsAlert = false
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
