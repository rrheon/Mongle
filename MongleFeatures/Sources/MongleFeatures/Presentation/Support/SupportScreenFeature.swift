import Foundation
import ComposableArchitecture
import Domain
import UIKit

@Reducer
public struct SupportScreenFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Screen: Equatable, Sendable {
            case heartsSystem
            case historyCalendar
            case notificationSettings
            case groupManagement
            case moodHistory

            public var title: String {
                switch self {
                case .heartsSystem:
                    return "하트 💗"
                case .historyCalendar:
                    return "히스토리 달력"
                case .notificationSettings:
                    return "알림 설정"
                case .groupManagement:
                    return "그룹 관리"
                case .moodHistory:
                    return "기분 히스토리"
                }
            }
        }

        public struct ToggleItem: Equatable, Identifiable, Sendable {
            public let id: String
            public let title: String
            public let subtitle: String
            public var isOn: Bool

            public init(id: String, title: String, subtitle: String, isOn: Bool) {
                self.id = id
                self.title = title
                self.subtitle = subtitle
                self.isOn = isOn
            }
        }

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

        public var screen: Screen
        public var heartBalance: Int
        public var notificationItems: [ToggleItem]
        public var quietHours: String
        public var currentMonth: Date
        public var selectedDate: Date
        public var moodCalendar: [Date: String]
        public var groupName: String
        public var inviteCode: String
        public var members: [GroupMember]
        public var moodRecords: [Domain.MoodRecord]
        public var isMoodLoading: Bool = false
        public var familyId: UUID?
        public var currentUserId: UUID?
        public var familyCreatedById: UUID?
        public var showLeaveConfirm: Bool = false
        public var isLeaving: Bool = false
        public var kickTargetMember: GroupMember?
        public var showKickConfirm: Bool = false
        public var isKicking: Bool = false

        public var isCurrentUserOwner: Bool {
            guard let currentUserId, let createdById = familyCreatedById else { return false }
            return currentUserId == createdById
        }

        // MARK: - 방장 위임
        public var transferCandidates: [GroupMember] = []
        public var showTransferSheet: Bool = false
        public var selectedTransferMemberId: UUID? = nil

        public init(screen: Screen, familyId: UUID? = nil, currentUserId: UUID? = nil, familyCreatedById: UUID? = nil) {
            self.familyId = familyId
            self.currentUserId = currentUserId
            self.familyCreatedById = familyCreatedById
            self.screen = screen
            self.heartBalance = 5
            let ud = UserDefaults.standard
            self.notificationItems = [
                .init(id: "r1", title: "가족이 답변했을 때", subtitle: "가족이 오늘의 질문에 답변하면 알림",
                      isOn: ud.object(forKey: "notification.r1") as? Bool ?? true),
                .init(id: "r2", title: "내 답변에 반응이 왔을 때", subtitle: "하트, 댓글 등의 반응 알림",
                      isOn: ud.object(forKey: "notification.r2") as? Bool ?? true),
                .init(id: "r3", title: "재촉 알림을 받았을 때", subtitle: "가족에게 답변 재촉 알림을 받으면 알림",
                      isOn: ud.object(forKey: "notification.r3") as? Bool ?? true),
                .init(id: "r4", title: "내가 재촉 알림을 보냈을 때 결과", subtitle: "재촉 후 상대방이 답변하면 알림",
                      isOn: ud.object(forKey: "notification.r4") as? Bool ?? true),
                .init(id: "r5", title: "새 질문 알림", subtitle: "매일 오전 새 질문이 등록되면 알림",
                      isOn: ud.object(forKey: "notification.r5") as? Bool ?? true),
                .init(id: "r6", title: "하트 관련 알림", subtitle: "하트를 받거나 소비했을 때 알림",
                      isOn: ud.object(forKey: "notification.r6") as? Bool ?? true),
            ]
            self.quietHours = "오후 10:00 - 오전 8:00"
            let today = Date()
            let calendar = Calendar.current
            self.currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            self.selectedDate = today
            self.moodCalendar = [:]
            self.groupName = ""
            self.inviteCode = ""
            self.members = []
            self.moodRecords = []
        }
    }

    public enum Action: Sendable, Equatable {
        case onAppear
        case closeTapped
        case previousMonthTapped
        case nextMonthTapped
        case dateSelected(Date)
        case toggleChanged(String, Bool)
        case inviteTapped
        case leaveGroupTapped
        case leaveGroupConfirmed
        case leaveGroupAlertDismissed
        case kickMemberTapped(State.GroupMember)
        case kickMemberConfirmed
        case kickMemberCancelled
        case kickMemberSuccess
        case kickMemberFailure(AppError)
        case moodLoaded([Domain.MoodRecord])
        case groupDataLoaded(MongleGroup, [User])
        case transferMemberSelected(UUID)
        case confirmTransferAndLeave
        case dismissTransferSheet
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
            case groupLeft
        }
    }

    @Dependency(\.familyRepository) var familyRepository
    @Dependency(\.moodRepository) var moodRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if state.screen == .moodHistory || state.screen == .historyCalendar {
                    state.isMoodLoading = true
                    return .run { [moodRepository] send in
                        let records = (try? await moodRepository.getRecentMoods(days: 31)) ?? []
                        await send(.moodLoaded(records))
                    }
                }
                if state.screen == .groupManagement {
                    return .run { [familyRepository] send in
                        if let result = try? await familyRepository.getMyFamily() {
                            await send(.groupDataLoaded(result.0, result.1))
                        }
                    }
                }
                return .none

            case .moodLoaded(let records):
                state.isMoodLoading = false
                state.moodRecords = records
                var cal: [Date: String] = [:]
                for record in records {
                    cal[Calendar.current.startOfDay(for: record.date)] = record.mood
                }
                state.moodCalendar = cal
                return .none

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

            case .closeTapped:
                return .send(.delegate(.close))

            case .previousMonthTapped:
                if let month = Calendar.current.date(byAdding: .month, value: -1, to: state.currentMonth) {
                    state.currentMonth = month
                }
                return .none

            case .nextMonthTapped:
                if let month = Calendar.current.date(byAdding: .month, value: 1, to: state.currentMonth) {
                    state.currentMonth = month
                }
                return .none

            case .dateSelected(let date):
                state.selectedDate = date
                return .none

            case .toggleChanged(let id, let isOn):
                if let index = state.notificationItems.firstIndex(where: { $0.id == id }) {
                    state.notificationItems[index].isOn = isOn
                    UserDefaults.standard.set(isOn, forKey: "notification.\(id)")
                }
                return .none

            case .inviteTapped:
                let code = state.inviteCode
                return .run { _ in
                    await MainActor.run {
                        UIPasteboard.general.string = code
                    }
                }

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
                        // 혼자인 경우 바로 나가기
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
                return .none

            case .kickMemberFailure:
                state.kickTargetMember = nil
                state.isKicking = false
                return .none

            case .transferMemberSelected(let id):
                state.selectedTransferMemberId = id
                return .none

            case .confirmTransferAndLeave:
                guard let newCreatorId = state.selectedTransferMemberId else { return .none }
                state.showTransferSheet = false
                state.isLeaving = true
                return .run { [familyRepository] send in
                    try? await familyRepository.transferCreator(newCreatorId: newCreatorId)
                    try? await familyRepository.leaveFamily()
                    await send(.delegate(.groupLeft))
                }

            case .dismissTransferSheet:
                state.showTransferSheet = false
                state.selectedTransferMemberId = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
