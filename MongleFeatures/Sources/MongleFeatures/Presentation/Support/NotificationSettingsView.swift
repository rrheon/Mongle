import SwiftUI
import ComposableArchitecture

public struct NotificationSettingsView: View {
    @Bindable var store: StoreOf<NotificationSettingsFeature>

    public init(store: StoreOf<NotificationSettingsFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            MongleNavigationHeader(title: "알림 설정") {
                MongleBackButton { store.send(.closeTapped) }
            } right: {
                EmptyView()
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MongleSpacing.md) {
                    settingsSection(title: "답변 알림", items: Array(store.notificationItems.prefix(1)))
                    settingsSection(title: "재촉 알림", items: Array(store.notificationItems.dropFirst(1).prefix(1)))
                    settingsSection(title: "시스템 알림", items: Array(store.notificationItems.dropFirst(2)))

                    HStack(spacing: MongleSpacing.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("방해 금지 시간")
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
