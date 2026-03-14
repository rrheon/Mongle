import Foundation
import ComposableArchitecture

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

        public struct MoodRecord: Equatable, Identifiable, Sendable {
            public let id: UUID
            public let date: Date
            public let label: String
            public let colorHex: String

            public init(id: UUID = UUID(), date: Date, label: String, colorHex: String) {
                self.id = id
                self.date = date
                self.label = label
                self.colorHex = colorHex
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
        public var moodRecords: [MoodRecord]

        public init(screen: Screen) {
            let calendar = Calendar(identifier: .gregorian)
            let baseDate = calendar.date(from: DateComponents(year: 2025, month: 3, day: 13)) ?? Date()
            let previousDay = calendar.date(byAdding: .day, value: -1, to: baseDate) ?? baseDate
            let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: baseDate) ?? baseDate
            let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: baseDate) ?? baseDate
            let fourDaysAgo = calendar.date(byAdding: .day, value: -4, to: baseDate) ?? baseDate
            let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: baseDate) ?? baseDate
            let monthDate = calendar.date(from: DateComponents(year: 2025, month: 3, day: 1)) ?? baseDate

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
            self.currentMonth = monthDate
            self.selectedDate = baseDate
            self.moodCalendar = [
                monthDate: "calm",
                calendar.date(from: DateComponents(year: 2025, month: 3, day: 2)) ?? baseDate: "happy",
                calendar.date(from: DateComponents(year: 2025, month: 3, day: 4)) ?? baseDate: "loved",
                calendar.date(from: DateComponents(year: 2025, month: 3, day: 7)) ?? baseDate: "tired",
                calendar.date(from: DateComponents(year: 2025, month: 3, day: 10)) ?? baseDate: "excited",
                baseDate: "happy",
                calendar.date(from: DateComponents(year: 2025, month: 3, day: 17)) ?? baseDate: "anxious",
                calendar.date(from: DateComponents(year: 2025, month: 3, day: 22)) ?? baseDate: "calm",
                calendar.date(from: DateComponents(year: 2025, month: 3, day: 27)) ?? baseDate: "loved",
            ]
            self.groupName = "우리 가족 💛"
            self.inviteCode = "MONG-4729"
            self.members = [
                .init(name: "Mom (나)", subtitle: "방장", colorHex: "4DB6AC", isOwner: true),
                .init(name: "Lily", subtitle: "2025년 1월 가입", colorHex: "F06292"),
                .init(name: "Ben", subtitle: "2025년 2월 가입", colorHex: "42A5F5"),
                .init(name: "Dad", subtitle: "2025년 2월 가입", colorHex: "FFD54F"),
                .init(name: "Alex", subtitle: "2025년 2월 가입", colorHex: "AB47BC"),
            ]
            self.moodRecords = [
                .init(date: baseDate, label: "기쁨", colorHex: "FFD54F"),
                .init(date: previousDay, label: "평온", colorHex: "A8DFBC"),
                .init(date: twoDaysAgo, label: "설렘", colorHex: "FF9800"),
                .init(date: threeDaysAgo, label: "사랑", colorHex: "F48FB1"),
                .init(date: fourDaysAgo, label: "지침", colorHex: "90A4AE"),
                .init(date: fiveDaysAgo, label: "불안", colorHex: "BA68C8"),
            ]
        }
    }

    public enum Action: Sendable, Equatable {
        case closeTapped
        case previousMonthTapped
        case nextMonthTapped
        case dateSelected(Date)
        case toggleChanged(String, Bool)
        case inviteTapped
        case leaveGroupTapped
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

            case .inviteTapped, .leaveGroupTapped, .delegate:
                return .none
            }
        }
    }
}
