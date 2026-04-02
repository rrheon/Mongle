import Foundation
import ComposableArchitecture
import Domain
import UIKit

@Reducer
public struct GroupManagementFeature {
    @ObservableState
    public struct State: Equatable {
        public struct GroupMember: Equatable, Identifiable, Sendable {
            public let id: UUID
            public let name: String
            public let subtitle: String
            public let colorHex: String
            public let isOwner: Bool

            public init(id: UUID = UUID(), name: String, subtitle: String, colorHex: String, isOwner: Bool = false) {
                self.id = id
                self.name = name
                self.subtitle = subtitle
                self.colorHex = colorHex
                self.isOwner = isOwner
            }
        }

        public var groupName: String
        public var inviteCode: String
        public var members: [GroupMember]
        public var familyId: UUID?
        public var currentUserId: UUID?
        public var familyCreatedById: UUID?
        public var showLeaveConfirm: Bool = false
        public var isLeaving: Bool = false
        public var kickTargetMember: GroupMember?
        public var showKickConfirm: Bool = false
        public var isKicking: Bool = false
        public var transferCandidates: [GroupMember] = []
        public var showTransferSheet: Bool = false
        public var selectedTransferMemberId: UUID? = nil
        public var showCopiedToast: Bool = false
        public var errorMessage: String?

        public var isCurrentUserOwner: Bool {
            guard let currentUserId, let createdById = familyCreatedById else { return false }
            return currentUserId == createdById
        }

        public init(familyId: UUID? = nil, currentUserId: UUID? = nil, familyCreatedById: UUID? = nil) {
            self.familyId = familyId
            self.currentUserId = currentUserId
            self.familyCreatedById = familyCreatedById
            self.groupName = ""
            self.inviteCode = ""
            self.members = []
        }
    }

    public enum Action: Sendable, Equatable {
        case onAppear
        case groupDataLoaded(MongleGroup, [User])
        case inviteCodeCopyTapped
        case copiedToastDismissed
        case leaveGroupTapped
        case leaveGroupConfirmed
        case leaveGroupAlertDismissed
        case kickMemberTapped(State.GroupMember)
        case kickMemberConfirmed
        case kickMemberCancelled
        case kickMemberSuccess
        case kickMemberFailure(AppError)
        case transferMemberSelected(UUID)
        case confirmTransferAndLeave
        case dismissTransferSheet
        case dismissError
        case closeTapped
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
            case groupLeft
            case memberKicked
        }
    }

    @Dependency(\.familyRepository) var familyRepository

    private enum CancelID { case copiedToast }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { [familyRepository] send in
                    if let result = try? await familyRepository.getMyFamily() {
                        await send(.groupDataLoaded(result.0, result.1))
                    }
                }

            case .groupDataLoaded(let group, let users):
                state.familyCreatedById = group.createdBy
                state.familyId = group.id
                state.groupName = group.name
                state.inviteCode = group.inviteCode
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ko_KR")
                formatter.dateFormat = "yyyy년 M월"
                state.members = users.map { user in
                    let isOwner = user.id == state.familyCreatedById
                    let subtitle = isOwner ? "방장" : formatter.string(from: user.createdAt) + " 가입"
                    return State.GroupMember(id: user.id, name: user.name, subtitle: subtitle, colorHex: "", isOwner: isOwner)
                }
                return .none

            case .inviteCodeCopyTapped:
                let code = state.inviteCode
                state.showCopiedToast = true
                return .run { send in
                    await MainActor.run {
                        UIPasteboard.general.string = code
                    }
                    try await Task.sleep(for: .seconds(2))
                    await send(.copiedToastDismissed)
                }
                .cancellable(id: CancelID.copiedToast, cancelInFlight: true)

            case .copiedToastDismissed:
                state.showCopiedToast = false
                return .none

            case .leaveGroupTapped:
                state.showLeaveConfirm = true
                return .none

            case .leaveGroupAlertDismissed:
                state.showLeaveConfirm = false
                return .none

            case .leaveGroupConfirmed:
                state.showLeaveConfirm = false
                if state.isCurrentUserOwner {
                    let candidates = state.members.filter { !$0.isOwner }
                    if candidates.isEmpty {
                        state.isLeaving = true
                        return .run { [familyRepository] send in
                            try? await familyRepository.leaveFamily()
                            await send(.delegate(.groupLeft))
                        }
                    }
                    state.transferCandidates = candidates
                    state.showTransferSheet = true
                    return .none
                } else {
                    state.isLeaving = true
                    return .run { [familyRepository] send in
                        try? await familyRepository.leaveFamily()
                        await send(.delegate(.groupLeft))
                    }
                }

            case .kickMemberTapped(let member):
                state.kickTargetMember = member
                state.showKickConfirm = true
                return .none

            case .kickMemberCancelled:
                state.kickTargetMember = nil
                state.showKickConfirm = false
                return .none

            case .kickMemberConfirmed:
                guard let target = state.kickTargetMember else { return .none }
                state.showKickConfirm = false
                state.isKicking = true
                return .run { [familyRepository] send in
                    do {
                        try await familyRepository.kickMember(memberId: target.id)
                        await send(.kickMemberSuccess)
                    } catch {
                        await send(.kickMemberFailure(AppError.from(error)))
                    }
                }

            case .kickMemberSuccess:
                if let target = state.kickTargetMember {
                    state.members.removeAll { $0.id == target.id }
                }
                state.kickTargetMember = nil
                state.isKicking = false
                return .send(.delegate(.memberKicked))

            case .kickMemberFailure(let error):
                state.kickTargetMember = nil
                state.isKicking = false
                state.isLeaving = false
                state.errorMessage = error.userMessage
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .transferMemberSelected(let id):
                state.selectedTransferMemberId = id
                return .none

            case .confirmTransferAndLeave:
                guard let newCreatorId = state.selectedTransferMemberId else { return .none }
                state.showTransferSheet = false
                state.isLeaving = true
                return .run { [familyRepository] send in
                    do {
                        try await familyRepository.transferCreator(newCreatorId: newCreatorId)
                        try await familyRepository.leaveFamily()
                        await send(.delegate(.groupLeft))
                    } catch {
                        await send(.kickMemberFailure(AppError.from(error)))
                    }
                }

            case .dismissTransferSheet:
                state.showTransferSheet = false
                state.selectedTransferMemberId = nil
                return .none

            case .closeTapped:
                return .merge(
                    .cancel(id: CancelID.copiedToast),
                    .send(.delegate(.close))
                )

            case .delegate:
                return .none
            }
        }
    }
}
