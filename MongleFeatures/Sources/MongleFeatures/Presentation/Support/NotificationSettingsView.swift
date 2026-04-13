import SwiftUI
import ComposableArchitecture

public struct NotificationSettingsView: View {
    @Bindable var store: StoreOf<NotificationSettingsFeature>

    public init(store: StoreOf<NotificationSettingsFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            MongleNavigationHeader(title: L10n.tr("notif_settings_title")) {
                MongleBackButton { store.send(.closeTapped) }
            } right: {
                EmptyView()
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MongleSpacing.md) {
                    // 시스템 알림 차단 경고 배너
                    if store.isSystemNotificationDenied {
                        systemNotificationBanner
                    }

                    settingsSection(title: L10n.tr("notif_settings_answer"), items: Array(store.notificationItems.prefix(1)))
                    settingsSection(title: L10n.tr("notif_settings_nudge"), items: Array(store.notificationItems.dropFirst(1).prefix(1)))
                    settingsSection(title: L10n.tr("notif_settings_system"), items: Array(store.notificationItems.dropFirst(2)))

                    HStack(spacing: MongleSpacing.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.tr("notif_settings_dnd"))
                                .font(MongleFont.body2Bold())
                                .foregroundColor(MongleColor.textPrimary)
                            Text(store.quietHours)
                                .font(MongleFont.caption())
                                .foregroundColor(MongleColor.textSecondary)
                        }
                        Spacer()
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { store.quietHoursEnabled },
                                set: { store.send(.quietHoursToggleChanged($0)) }
                            )
                        )
                        .labelsHidden()
                        .tint(MongleColor.primary)
                    }
                    .padding(MongleSpacing.md)
                    .monglePanel(background: MongleColor.cardBackground, cornerRadius: MongleRadius.large, borderColor: MongleColor.borderWarm, shadowOpacity: 0)
                }
                .padding(MongleSpacing.md)
                .padding(.bottom, MongleSpacing.xl)
            }
            .background(MongleColor.background)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { store.send(.onAppear) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            store.send(.scenePhaseActive)
        }
    }

    /// 시스템 알림이 꺼져있을 때 표시하는 경고 배너
    private var systemNotificationBanner: some View {
        HStack(spacing: MongleSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(MongleColor.error)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tr("notif_system_off_title"))
                    .font(MongleFont.body2Bold())
                    .foregroundColor(MongleColor.textPrimary)
                Text(L10n.tr("notif_system_off_desc"))
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textSecondary)
            }
            Spacer()
            Button {
                store.send(.openSystemSettingsTapped)
            } label: {
                Text(L10n.tr("notif_system_off_button"))
                    .font(MongleFont.captionBold())
                    .foregroundColor(.white)
                    .padding(.horizontal, MongleSpacing.sm)
                    .padding(.vertical, MongleSpacing.xxs)
                    .background(MongleColor.primary)
                    .cornerRadius(MongleRadius.medium)
            }
        }
        .padding(MongleSpacing.md)
        .monglePanel(background: MongleColor.error.opacity(0.08), cornerRadius: MongleRadius.large, borderColor: MongleColor.error.opacity(0.3), shadowOpacity: 0)
    }

    private func settingsSection(title: String, items: [NotificationSettingsFeature.State.ToggleItem]) -> some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            Text(title)
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)
                .padding(.horizontal, MongleSpacing.xxs)

            VStack(spacing: 0) {
                ForEach(items) { item in
                    HStack(spacing: MongleSpacing.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(MongleFont.body2Bold())
                                .foregroundColor(MongleColor.textPrimary)
                            Text(item.subtitle)
                                .font(MongleFont.caption())
                                .foregroundColor(MongleColor.textSecondary)
                        }
                        Spacer()
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { item.isOn },
                                set: { store.send(.toggleChanged(item.id, $0)) }
                            )
                        )
                        .labelsHidden()
                        .tint(MongleColor.primary)
                    }
                    .padding(MongleSpacing.md)

                    if item.id != items.last?.id {
                        Divider()
                    }
                }
            }
            .monglePanel(background: MongleColor.cardBackground, cornerRadius: MongleRadius.large, borderColor: MongleColor.borderWarm, shadowOpacity: 0)
        }
    }
}
