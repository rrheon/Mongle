import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct GroupSelectFeature {

    // MARK: - Path (Push Navigation)

    @Reducer(state: .equatable, action: .equatable)
    public enum Path {
        case notification(NotificationFeature)
    }

    @ObservableState
    public struct State: Equatable {
        public enum Step: Equatable, Sendable {
            case select
            case createGroup
            case groupCreated
            case joinWithCode
        }

        public var step: Step = .select
        public var path = StackState<Path.State>()
        public var showActionSheet: Bool = false
        public var groupName: String = ""
        public var nickname: String = ""
        public var inviteCode: String = ""
        public var joinCode: String = ""
        public var selectedColorId: String = "loved"

        public var groupNameError: Bool = false
        public var nicknameError: Bool = false
        public var joinCodeError: Bool = false

        public var isLoading: Bool = false
        public var errorMessage: String? = nil
        public var appError: AppError? = nil

        public var groups: [MongleGroup] = []
        public var isLoadingGroups: Bool = false
        public var showMaxGroupsAlert: Bool = false

        // MARK: - 참여 에러 토스트
        public var showAlreadyMemberToast: Bool = false
        public var showInvalidCodeToast: Bool = false

        // MARK: - 그룹 나가기
        public var showGroupLeftToast: Bool = false
        public var currentUserId: UUID? = nil
        public var groupToLeave: MongleGroup? = nil
        public var showLeaveConfirmation: Bool = false
        public var transferCandidates: [User] = []
        public var showTransferSheet: Bool = false
        public var selectedTransferMemberId: UUID? = nil
        public var isProcessingLeave: Bool = false

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
        case colorChanged(String)
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
        case path(StackActionOf<Path>)

        // MARK: - 그룹 나가기
        case leaveGroupTapped(MongleGroup)
        case confirmLeave
        case cancelLeaveConfirmation
        case setTransferCandidates([User])
        case transferMemberSelected(UUID)
        case confirmTransferAndLeave
        case dismissTransferSheet
        case groupLeftToastDismissed
        case showJoinAlreadyMemberToast
        case showJoinInvalidCodeToast
        case alreadyMemberToastDismissed
        case invalidCodeToastDismissed

        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case completed
            case createFamily(name: String, nickname: String, colorId: String)
            case joinFamily(inviteCode: String, nickname: String, colorId: String)
            case groupSelected(MongleGroup)
            case leaveGroup(MongleGroup)
            case transferCreatorAndLeave(newCreatorId: UUID, group: MongleGroup)
            case requestMembersForGroup(MongleGroup)
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
                let groupNameMap = Dictionary(uniqueKeysWithValues: state.groups.map { ($0.id, $0.name) })
                state.path.append(.notification(NotificationFeature.State(mode: .grouped, groupNameMap: groupNameMap)))
                return .none

            case .groupNameChanged(let name):
                state.groupName = String(name.prefix(15))
                state.groupNameError = false
                return .none

            case .nicknameChanged(let name):
                state.nickname = String(name.prefix(10))
                state.nicknameError = false
                return .none

            case .joinCodeChanged(let code):
                state.joinCode = String(code.prefix(20))
                state.joinCodeError = false
                return .none

            case .colorChanged(let colorId):
                state.selectedColorId = colorId
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
                return .send(.delegate(.createFamily(name: state.groupName, nickname: state.nickname, colorId: state.selectedColorId)))

            case .createBackTapped:
                state.step = .select
                state.groupName = ""
                state.nickname = ""
                state.selectedColorId = "loved"
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
                state.selectedColorId = "loved"
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
                return .send(.delegate(.joinFamily(inviteCode: state.joinCode, nickname: state.nickname, colorId: state.selectedColorId)))

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

            case .path(.element(id: _, action: .notification(.delegate(.close)))):
                state.path.removeLast()
                return .none

            case .path(.element(id: _, action: .notification(.delegate(.navigateToGroup(let familyId))))):
                state.path.removeAll()
                if let group = state.groups.first(where: { $0.id == familyId }) {
                    return .send(.delegate(.groupSelected(group)))
                }
                return .none

            case .path:
                return .none

            // MARK: - 그룹 나가기

            case .leaveGroupTapped(let group):
                state.groupToLeave = group
                if let userId = state.currentUserId, group.createdBy == userId {
                    // 방장: 먼저 위임할 멤버 목록 요청
                    return .send(.delegate(.requestMembersForGroup(group)))
                } else {
                    // 일반 멤버: 확인 알림 표시
                    state.showLeaveConfirmation = true
                    return .none
                }

            case .confirmLeave:
                state.showLeaveConfirmation = false
                guard let group = state.groupToLeave else { return .none }
                state.isProcessingLeave = true
                return .send(.delegate(.leaveGroup(group)))

            case .cancelLeaveConfirmation:
                state.showLeaveConfirmation = false
                state.groupToLeave = nil
                return .none

            case .setTransferCandidates(let users):
                state.transferCandidates = users.filter { $0.id != state.currentUserId }
                state.showTransferSheet = true
                return .none

            case .transferMemberSelected(let id):
                state.selectedTransferMemberId = id
                return .none

            case .confirmTransferAndLeave:
                guard let group = state.groupToLeave,
                      let newCreatorId = state.selectedTransferMemberId else { return .none }
                state.showTransferSheet = false
                state.isProcessingLeave = true
                return .send(.delegate(.transferCreatorAndLeave(newCreatorId: newCreatorId, group: group)))

            case .dismissTransferSheet:
                state.showTransferSheet = false
                state.groupToLeave = nil
                state.selectedTransferMemberId = nil
                return .none

            case .groupLeftToastDismissed:
                state.showGroupLeftToast = false
                return .none

            case .showJoinAlreadyMemberToast:
                state.isLoading = false
                state.showAlreadyMemberToast = true
                return .none

            case .showJoinInvalidCodeToast:
                state.isLoading = false
                state.showInvalidCodeToast = true
                return .none

            case .alreadyMemberToastDismissed:
                state.showAlreadyMemberToast = false
                return .none

            case .invalidCodeToastDismissed:
                state.showInvalidCodeToast = false
                return .none

            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
