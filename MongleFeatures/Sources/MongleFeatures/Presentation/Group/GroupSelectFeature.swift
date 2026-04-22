import Foundation
import ComposableArchitecture
import Domain
import UserNotifications
import UIKit

public enum CreateGroupFocusField: Equatable, Sendable {
    case groupName
    case nickname
}

public enum JoinGroupFocusField: Equatable, Sendable {
    case joinCode
    case nickname
}

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
            case notificationPermission
            case quietHoursPermission
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

        // MARK: - 알림 허용 플로우
        public var isFromJoin: Bool = false

        // MARK: - 알림 배지
        public var hasUnreadNotifications: Bool = false

        // MARK: - 참여 에러 토스트
        public var showAlreadyMemberToast: Bool = false
        public var showInvalidCodeToast: Bool = false
        public var showMaxGroupsToast: Bool = false

        // MARK: - 그룹 생성 폼
        public var createGroupFocusField: CreateGroupFocusField? = nil
        public var joinGroupFocusField: JoinGroupFocusField? = nil
        public var isColorExplicitlySelected: Bool = false

        // MARK: - 그룹 나가기
        public var showGroupLeftToast: Bool = false
        public var currentUserId: UUID? = nil
        public var groupToLeave: MongleGroup? = nil
        public var showLeaveConfirmation: Bool = false
        public var showLeaveFinalConfirmation: Bool = false
        public var showLeaveTooSoonToast: Bool = false   // 72시간(3일) 미경과 안내 토스트
        public var leaveTooSoonMessage: String = ""
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
        case setJoinSuccess
        case notificationPermissionAllowed
        case notificationPermissionSkipped
        case quietHoursPermissionEnabled
        case quietHoursPermissionSkipped
        case setError(String?)
        case setAppError(AppError?)
        case dismissError
        case onAppear
        case unreadNotificationsLoaded(Bool)
        case loadGroupsResponse(Result<[MongleGroup], Error>)
        case groupTapped(MongleGroup)
        case dismissMaxGroupsAlert
        case path(StackActionOf<Path>)

        // MARK: - 그룹 나가기
        case leaveGroupTapped(MongleGroup)
        case firstConfirmLeave
        case cancelLeaveFinalConfirmation
        case confirmLeave
        case cancelLeaveConfirmation
        case dismissLeaveTooSoonToast
        case setTransferCandidates([User])
        case transferMemberSelected(UUID)
        case confirmTransferAndLeave
        case dismissTransferSheet
        case groupLeftToastDismissed
        case showJoinAlreadyMemberToast
        case showJoinInvalidCodeToast
        case alreadyMemberToastDismissed
        case invalidCodeToastDismissed
        case maxGroupsToastDismissed
        case createGroupFocusFieldHandled
        case joinGroupFocusFieldHandled

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

    @Dependency(\.notificationRepository) var notificationRepository

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
                guard state.groups.count < 3 else {
                    state.showMaxGroupsToast = true
                    return .none
                }
                state.step = .createGroup
                return .none

            case .actionSheetJoinSpaceTapped:
                state.showActionSheet = false
                guard state.groups.count < 3 else {
                    state.showMaxGroupsToast = true
                    return .none
                }
                state.step = .joinWithCode
                return .none

            case .notificationTapped:
                let groupNameMap = Dictionary(uniqueKeysWithValues: state.groups.map { ($0.id, $0.name) })
                state.path.append(.notification(NotificationFeature.State(mode: .grouped, groupNameMap: groupNameMap)))
                return .none

            case .groupNameChanged(let name):
                state.groupName = String(name.prefix(10))
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
                state.isColorExplicitlySelected = true
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
                if nameEmpty {
                    state.appError = .domain(L10n.tr("group_name_error"))
                    state.createGroupFocusField = .groupName
                    return .none
                }
                if nickEmpty {
                    state.appError = .domain(L10n.tr("group_nickname_error"))
                    state.createGroupFocusField = .nickname
                    return .none
                }
                if !state.isColorExplicitlySelected {
                    let colorIds = ["calm", "happy", "loved", "sad", "tired"]
                    state.selectedColorId = colorIds.randomElement() ?? "loved"
                }
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
                state.isColorExplicitlySelected = false
                state.createGroupFocusField = nil
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
                state.isColorExplicitlySelected = false
                state.joinGroupFocusField = nil
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
                if codeEmpty {
                    state.appError = .domain(L10n.tr("group_code_placeholder"))
                    state.joinGroupFocusField = .joinCode
                    return .none
                }
                if nickEmpty {
                    state.appError = .domain(L10n.tr("group_nickname_error"))
                    state.joinGroupFocusField = .nickname
                    return .none
                }
                if !state.isColorExplicitlySelected {
                    let colorIds = ["calm", "happy", "loved", "sad", "tired"]
                    state.selectedColorId = colorIds.randomElement() ?? "loved"
                }
                state.isLoading = true
                return .send(.delegate(.joinFamily(inviteCode: state.joinCode, nickname: state.nickname, colorId: state.selectedColorId)))

            case .setLoading(let loading):
                state.isLoading = loading
                return .none

            case .setInviteCode(let code):
                state.inviteCode = code
                state.isLoading = false
                state.isFromJoin = false
                state.step = .groupCreated
                return .none

            case .setJoinSuccess:
                state.isLoading = false
                return .send(.delegate(.completed))

            case .notificationPermissionAllowed:
                state.step = .quietHoursPermission
                return .run { _ in
                    _ = try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .badge, .sound])
                    await MainActor.run {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }

            case .notificationPermissionSkipped:
                state.step = .quietHoursPermission
                return .none

            case .quietHoursPermissionEnabled:
                UserDefaults.standard.set(true, forKey: "notification.quietHours")
                UserDefaults.standard.set(true, forKey: "mongle.didShowNotificationSetup")
                if state.isFromJoin {
                    return .send(.delegate(.completed))
                }
                state.step = .groupCreated
                return .none

            case .quietHoursPermissionSkipped:
                UserDefaults.standard.set(false, forKey: "notification.quietHours")
                UserDefaults.standard.set(true, forKey: "mongle.didShowNotificationSetup")
                if state.isFromJoin {
                    return .send(.delegate(.completed))
                }
                state.step = .groupCreated
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
                // 그룹 목록은 RootFeature 가 별도로 로드하므로 여기선 알림 미읽음만 갱신.
                // (예전엔 isLoadingGroups = true 로 잘못 세팅해서 Root 의 loadGroupsResponse 와
                //  레이스가 발생할 수 있었다.)
                return .run { [notificationRepository] send in
                    let items = (try? await notificationRepository.getNotifications(limit: 50)) ?? []
                    let hasUnread = items.contains { !$0.isRead }
                    await send(.unreadNotificationsLoaded(hasUnread))
                }

            case .unreadNotificationsLoaded(let hasUnread):
                state.hasUnreadNotifications = hasUnread
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

            case .path(.element(id: let id, action: .notification(.delegate(.close)))):
                if case let .notification(notifState) = state.path[id: id] {
                    state.hasUnreadNotifications = notifState.hasUnread
                }
                state.path.removeLast()
                return .none

            case .path(.element(id: _, action: .notification(.delegate(.navigateToGroup(let familyId, let markAsReadId))))):
                state.path.removeAll()
                let markEffect: Effect<Action> = {
                    guard let notifId = markAsReadId else { return .none }
                    return .run { [notificationRepository] _ in
                        _ = try? await notificationRepository.delete(id: notifId)
                    }
                }()
                if let group = state.groups.first(where: { $0.id == familyId }) {
                    return .merge(markEffect, .send(.delegate(.groupSelected(group))))
                }
                return markEffect

            case .path:
                return .none

            // MARK: - 그룹 나가기

            case .leaveGroupTapped(let group):
                let isOwner = state.currentUserId.map { group.createdBy == $0 } ?? false
                // 그룹 생성 후 3일(72시간) 이내에는 그룹장이 나갈 수 없음 (반복 생성/삭제 방지)
                // 일반 멤버나 위임 후 나가기는 이 제한에 해당하지 않음
                if isOwner {
                    let hoursSinceCreation = Date().timeIntervalSince(group.createdAt) / 3600
                    if hoursSinceCreation < 72 {
                        let daysLeft = Int(ceil((72 - hoursSinceCreation) / 24))
                        state.leaveTooSoonMessage = L10n.tr("group_leave_too_soon", daysLeft)
                        state.showLeaveTooSoonToast = true
                        return .none
                    }
                }
                state.groupToLeave = group
                if isOwner {
                    // 방장: 먼저 위임할 멤버 목록 요청
                    return .send(.delegate(.requestMembersForGroup(group)))
                } else {
                    // 일반 멤버: 확인 알림 표시
                    state.showLeaveConfirmation = true
                    return .none
                }

            case .dismissLeaveTooSoonToast:
                state.showLeaveTooSoonToast = false
                return .none

            case .firstConfirmLeave:
                state.showLeaveConfirmation = false
                state.showLeaveFinalConfirmation = true
                return .none

            case .cancelLeaveFinalConfirmation:
                state.showLeaveFinalConfirmation = false
                return .none

            case .confirmLeave:
                state.showLeaveConfirmation = false
                state.showLeaveFinalConfirmation = false
                guard let group = state.groupToLeave else { return .none }
                state.isProcessingLeave = true
                return .send(.delegate(.leaveGroup(group)))

            case .cancelLeaveConfirmation:
                state.showLeaveConfirmation = false
                state.showLeaveFinalConfirmation = false
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

            case .maxGroupsToastDismissed:
                state.showMaxGroupsToast = false
                return .none

            case .createGroupFocusFieldHandled:
                state.createGroupFocusField = nil
                return .none

            case .joinGroupFocusFieldHandled:
                state.joinGroupFocusField = nil
                return .none

            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
