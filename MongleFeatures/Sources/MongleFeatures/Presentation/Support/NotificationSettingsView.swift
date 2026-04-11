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
        .overlay(alignment: .top) {
            if let toast = store.errorToast {
                Text(toast)
                    .font(MongleFont.caption())
                    .foregroundColor(.white)
                    .padding(.horizontal, MongleSpacing.md)
                    .padding(.vertical, MongleSpacing.sm)
                    .background(Color.black.opacity(0.78))
                    .clipShape(Capsule())
                    .padding(.top, MongleSpacing.lg)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: store.errorToast)
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
