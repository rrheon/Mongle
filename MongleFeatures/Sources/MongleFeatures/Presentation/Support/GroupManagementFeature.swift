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
            public let moodId: String?
            public let isOwner: Bool

            public init(id: UUID = UUID(), name: String, subtitle: String, moodId: String? = nil, isOwner: Bool = false) {
                self.id = id
                self.name = name
                self.subtitle = subtitle
                self.moodId = moodId
                self.isOwner = isOwner
            }
        }

        public var groupName: String
        public var inviteCode: String
        public var members: [GroupMember]
        public var familyId: UUID?
        public var currentUserId: UUID?
        public var familyCreatedById: UUID?
        public var familyCreatedAt: Date?
        public var showLeaveConfirm: Bool = false
        public var showLeaveFinalConfirm: Bool = false
        public var showLeaveTooSoonToast: Bool = false   // 72시간(3일) 미경과 안내 토스트
        public var leaveTooSoonMessage: String = ""
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
        case leaveGroupFirstConfirmed
        case leaveGroupFinalCancelled
        case leaveGroupConfirmed
        case leaveGroupAlertDismissed
        case leaveGroupFailure(AppError)
        case dismissLeaveTooSoonToast
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
                state.familyCreatedAt = group.createdAt
                state.familyId = group.id
                state.groupName = group.name
                state.inviteCode = group.inviteCode
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ko_KR")
                formatter.dateFormat = "yyyy년 M월"
                state.members = users.map { user in
                    let isOwner = user.id == state.familyCreatedById
                    let subtitle = isOwner ? "방장" : formatter.string(from: user.createdAt) + " 가입"
                    return State.GroupMember(id: user.id, name: user.name, subtitle: subtitle, moodId: user.moodId, isOwner: isOwner)
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

            case .leaveGroupFirstConfirmed:
                state.showLeaveConfirm = false
                state.showLeaveFinalConfirm = true
                return .none

            case .leaveGroupFinalCancelled:
                state.showLeaveFinalConfirm = false
                return .none

            case .leaveGroupAlertDismissed:
                state.showLeaveConfirm = false
                state.showLeaveFinalConfirm = false
                return .none

            case .leaveGroupConfirmed:
                state.showLeaveConfirm = false
                state.showLeaveFinalConfirm = false
                if state.isCurrentUserOwner {
                    // 방장은 멤버 수와 무관하게 그룹 생성 후 72시간 이내 나가기 불가
                    // (위임 후 나가기로 빠져나가는 것도 차단 — GroupSelectFeature / Android 와 동일 정책)
                    if let createdAt = state.familyCreatedAt {
                        let hoursSinceCreation = Date().timeIntervalSince(createdAt) / 3600
                        if hoursSinceCreation < 72 {
                            let daysLeft = Int(ceil((72 - hoursSinceCreation) / 24))
                            state.leaveTooSoonMessage = L10n.tr("group_leave_too_soon", daysLeft)
                            state.showLeaveTooSoonToast = true
                            return .none
                        }
                    }
                    let candidates = state.members.filter { !$0.isOwner }
                    if candidates.isEmpty {
                        state.isLeaving = true
                        return .run { [familyRepository] send in
                            do {
                                try await familyRepository.leaveFamily()
                                await send(.delegate(.groupLeft))
                            } catch {
                                await send(.leaveGroupFailure(AppError.from(error)))
                            }
                        }
                    }
                    state.transferCandidates = candidates
                    state.showTransferSheet = true
                    return .none
                } else {
                    state.isLeaving = true
                    return .run { [familyRepository] send in
                        do {
                            try await familyRepository.leaveFamily()
                            await send(.delegate(.groupLeft))
                        } catch {
                            await send(.leaveGroupFailure(AppError.from(error)))
                        }
                    }
                }

            case .leaveGroupFailure(let error):
                state.isLeaving = false
                // 서버가 72시간 제한으로 거부한 경우에도 토스트로 통일해서 안내
                let msg = error.userMessage
                if msg.contains("3일") || msg.contains("72") {
                    state.leaveTooSoonMessage = msg
                    state.showLeaveTooSoonToast = true
                } else {
                    state.errorMessage = msg
                }
                return .none

            case .dismissLeaveTooSoonToast:
                state.showLeaveTooSoonToast = false
                return .none

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
                        await send(.leaveGroupFailure(AppError.from(error)))
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
