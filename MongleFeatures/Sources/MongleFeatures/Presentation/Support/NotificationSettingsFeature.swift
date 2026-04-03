import Foundation
import ComposableArchitecture

@Reducer
public struct NotificationSettingsFeature {
    @ObservableState
    public struct State: Equatable {
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

        public var notificationItems: [ToggleItem]
        public var quietHours: String
        public var quietHoursEnabled: Bool

        public init() {
            let ud = UserDefaults.standard
            self.notificationItems = [
                .init(id: "r1", title: L10n.tr("notif_settings_answer_desc"), subtitle: L10n.tr("notif_settings_answer_detail"),
                      isOn: ud.object(forKey: "notification.r1") as? Bool ?? true),
                .init(id: "r3", title: L10n.tr("notif_settings_nudge_desc"), subtitle: L10n.tr("notif_settings_nudge_detail"),
                      isOn: ud.object(forKey: "notification.r3") as? Bool ?? true),
                .init(id: "r5", title: L10n.tr("notif_settings_question_desc"), subtitle: L10n.tr("notif_settings_question_detail"),
                      isOn: ud.object(forKey: "notification.r5") as? Bool ?? true),
            ]
            self.quietHours = L10n.tr("perm_dnd_time")
            self.quietHoursEnabled = ud.object(forKey: "notification.quietHours") as? Bool ?? true
        }
    }

    public enum Action: Sendable, Equatable {
        case closeTapped
        case toggleChanged(String, Bool)
        case quietHoursToggleChanged(Bool)
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

            case .toggleChanged(let id, let isOn):
                if let index = state.notificationItems.firstIndex(where: { $0.id == id }) {
                    state.notificationItems[index].isOn = isOn
                    UserDefaults.standard.set(isOn, forKey: "notification.\(id)")
                }
                return .none

            case .quietHoursToggleChanged(let isOn):
                state.quietHoursEnabled = isOn
                UserDefaults.standard.set(isOn, forKey: "notification.quietHours")
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
