import Foundation
import UIKit
import UserNotifications
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
        public var isLoading: Bool = true
        /// 시스템 알림이 차단된 상태인지 (배너 표시용)
        public var isSystemNotificationDenied: Bool = false
        /// 알림 설정 저장 실패 시 토스트 표시
        public var showSaveError: Bool = false

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
        case onAppear
        case scenePhaseActive
        case systemPermissionChecked(isDenied: Bool)
        case preferencesLoaded(NotificationPreferences)
        case loadFailed
        case closeTapped
        case toggleChanged(String, Bool)
        case quietHoursToggleChanged(Bool)
        case openSystemSettingsTapped
        case serverUpdateCompleted
        case saveFailedRollback(id: String, previousValue: Bool)
        case quietHoursSaveFailedRollback(previousValue: Bool)
        case dismissSaveError
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
            case .onAppear, .scenePhaseActive:
                let isInitialLoad = state.isLoading
                if action == .onAppear { state.isLoading = true }
                return .run { send in
                    // 시스템 알림 권한 상태 체크
                    let settings = await UNUserNotificationCenter.current().notificationSettings()
                    let isDenied = settings.authorizationStatus == .denied
                    await send(.systemPermissionChecked(isDenied: isDenied))

                    // 최초 로드 시에만 서버 선호도 가져오기
                    if isInitialLoad {
                        do {
                            let prefs = try await userRepository.getNotificationPreferences()
                            await send(.preferencesLoaded(prefs))
                        } catch {
                            await send(.loadFailed)
                        }
                    }
                }

            case .systemPermissionChecked(let isDenied):
                state.isSystemNotificationDenied = isDenied
                return .none

            case .preferencesLoaded(let prefs):
                state.isLoading = false
                if let idx = state.notificationItems.firstIndex(where: { $0.id == "r1" }) {
                    state.notificationItems[idx].isOn = prefs.notifAnswer
                }
                if let idx = state.notificationItems.firstIndex(where: { $0.id == "r3" }) {
                    state.notificationItems[idx].isOn = prefs.notifNudge
                }
                if let idx = state.notificationItems.firstIndex(where: { $0.id == "r5" }) {
                    state.notificationItems[idx].isOn = prefs.notifQuestion
                }
                state.quietHoursEnabled = prefs.quietHoursEnabled
                UserDefaults.standard.set(prefs.notifAnswer, forKey: "notification.r1")
                UserDefaults.standard.set(prefs.notifNudge, forKey: "notification.r3")
                UserDefaults.standard.set(prefs.notifQuestion, forKey: "notification.r5")
                UserDefaults.standard.set(prefs.quietHoursEnabled, forKey: "notification.quietHours")
                return .none

            case .loadFailed:
                state.isLoading = false
                return .none

            case .closeTapped:
                return .send(.delegate(.close))

            case .toggleChanged(let id, let isOn):
                let previousValue = state.notificationItems.first(where: { $0.id == id })?.isOn ?? !isOn
                if let index = state.notificationItems.firstIndex(where: { $0.id == id }) {
                    state.notificationItems[index].isOn = isOn
                    UserDefaults.standard.set(isOn, forKey: "notification.\(id)")
                }
                let paramKey: String
                switch id {
                case "r1": paramKey = "notifAnswer"
                case "r3": paramKey = "notifNudge"
                case "r5": paramKey = "notifQuestion"
                default: return .none
                }
                return .run { [userRepository] send in
                    do {
                        _ = try await userRepository.updateNotificationPreferences([paramKey: isOn])
                    } catch {
                        await send(.saveFailedRollback(id: id, previousValue: previousValue))
                    }
                }

            case .saveFailedRollback(let id, let previousValue):
                if let index = state.notificationItems.firstIndex(where: { $0.id == id }) {
                    state.notificationItems[index].isOn = previousValue
                    UserDefaults.standard.set(previousValue, forKey: "notification.\(id)")
                }
                state.showSaveError = true
                return .run { send in
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    await send(.dismissSaveError)
                }

            case .quietHoursToggleChanged(let isOn):
                let previousValue = state.quietHoursEnabled
                state.quietHoursEnabled = isOn
                UserDefaults.standard.set(isOn, forKey: "notification.quietHours")
                return .run { [userRepository] send in
                    do {
                        _ = try await userRepository.updateNotificationPreferences(["quietHoursEnabled": isOn])
                    } catch {
                        await send(.quietHoursSaveFailedRollback(previousValue: previousValue))
                    }
                }

            case .quietHoursSaveFailedRollback(let previousValue):
                state.quietHoursEnabled = previousValue
                UserDefaults.standard.set(previousValue, forKey: "notification.quietHours")
                state.showSaveError = true
                return .run { send in
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    await send(.dismissSaveError)
                }

            case .dismissSaveError:
                state.showSaveError = false
                return .none

            case .openSystemSettingsTapped:
                return .run { _ in
                    await MainActor.run {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

            case .serverUpdateCompleted, .delegate:
                return .none
            }
        }
    }
}
