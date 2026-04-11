import Foundation
import ComposableArchitecture
import Domain

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
        /// PRD §3.3/§9 — toggle PUT 실패 시 사용자에게 표시할 토스트 메시지.
        public var errorToast: String?

        public init(currentUser: User? = nil) {
            let ud = UserDefaults.standard
            // 서버 진실 소스 우선: UserResponse 의 두 필드가 있으면 그 값으로 초기화하고 UD 캐시도 갱신.
            // 없으면 UD 캐시 → 기본 true 순서.
            let streakRiskInitial: Bool
            let badgeEarnedInitial: Bool
            if let user = currentUser {
                streakRiskInitial = user.streakRiskNotify
                badgeEarnedInitial = user.badgeEarnedNotify
                ud.set(streakRiskInitial, forKey: "notification.streakRisk")
                ud.set(badgeEarnedInitial, forKey: "notification.badgeEarned")
            } else {
                streakRiskInitial = ud.object(forKey: "notification.streakRisk") as? Bool ?? true
                badgeEarnedInitial = ud.object(forKey: "notification.badgeEarned") as? Bool ?? true
            }
            self.notificationItems = [
                .init(id: "r1", title: L10n.tr("notif_settings_answer_desc"), subtitle: L10n.tr("notif_settings_answer_detail"),
                      isOn: ud.object(forKey: "notification.r1") as? Bool ?? true),
                .init(id: "r3", title: L10n.tr("notif_settings_nudge_desc"), subtitle: L10n.tr("notif_settings_nudge_detail"),
                      isOn: ud.object(forKey: "notification.r3") as? Bool ?? true),
                .init(id: "r5", title: L10n.tr("notif_settings_question_desc"), subtitle: L10n.tr("notif_settings_question_detail"),
                      isOn: ud.object(forKey: "notification.r5") as? Bool ?? true),
                // v2 UI-4 (PRD §3.3/§9): 알림 옵트아웃 토글 2개. UserResponse 신규 필드 주입 + UserDefaults 캐시.
                // badgeEarnedNotify 는 푸시에만 영향, 인앱 배지 획득 팝업은 토글과 무관하게 항상 표시.
                .init(id: "streakRisk", title: L10n.tr("settings_notif_streak_risk"), subtitle: L10n.tr("settings_notif_streak_risk_desc"),
                      isOn: streakRiskInitial),
                .init(id: "badgeEarned", title: L10n.tr("settings_notif_badge_earned"), subtitle: L10n.tr("settings_notif_badge_earned_desc"),
                      isOn: badgeEarnedInitial),
            ]
            self.quietHours = L10n.tr("perm_dnd_time")
            self.quietHoursEnabled = ud.object(forKey: "notification.quietHours") as? Bool ?? true
        }
    }

    public enum Action: Sendable, Equatable {
        case closeTapped
        case toggleChanged(String, Bool)
        case quietHoursToggleChanged(Bool)
        case prefsSyncFailed(id: String, previousValue: Bool)
        case errorToastDismissed
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
        }
    }

    @Dependency(\.userRepository) var userRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .closeTapped:
                return .send(.delegate(.close))

            case .toggleChanged(let id, let isOn):
                let previous = !isOn
                if let index = state.notificationItems.firstIndex(where: { $0.id == id }) {
                    state.notificationItems[index].isOn = isOn
                    UserDefaults.standard.set(isOn, forKey: "notification.\(id)")
                }
                // Engine-8: streakRisk / badgeEarned 두 토글만 PUT /users/me 부분 업데이트로 동기화.
                // 실패 시 이전 값으로 롤백 + 에러 토스트 (PRD 확정).
                switch id {
                case "streakRisk":
                    return .run { send in
                        do {
                            try await userRepository.updateNotificationPrefs(streakRisk: isOn, badgeEarned: nil)
                        } catch {
                            await send(.prefsSyncFailed(id: id, previousValue: previous))
                        }
                    }
                case "badgeEarned":
                    return .run { send in
                        do {
                            try await userRepository.updateNotificationPrefs(streakRisk: nil, badgeEarned: isOn)
                        } catch {
                            await send(.prefsSyncFailed(id: id, previousValue: previous))
                        }
                    }
                default:
                    return .none
                }

            case .prefsSyncFailed(let id, let previousValue):
                if let index = state.notificationItems.firstIndex(where: { $0.id == id }) {
                    state.notificationItems[index].isOn = previousValue
                    UserDefaults.standard.set(previousValue, forKey: "notification.\(id)")
                }
                state.errorToast = L10n.tr("settings_notif_sync_failed")
                return .run { send in
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    await send(.errorToastDismissed)
                }

            case .errorToastDismissed:
                state.errorToast = nil
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
