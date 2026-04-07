//
//  SettingsTabView.swift
//  Mongle
//
//  Created by Claude on 2025-01-06.
//

import SwiftUI
import SafariServices
import ComposableArchitecture
import Domain

struct SettingsTabView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @State private var legalURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MongleSpacing.lg) {
                    profileCard
                    #if os(iOS)
                    AdBannerSection()
                    #endif
                    moodSection
                    groupSection
                    legalSection
                    accountSection

                    Text("몽글 v\(store.appVersion)")
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textHint)
                        .frame(maxWidth: .infinity)
                        .padding(.top, MongleSpacing.sm)
                }
                .padding(.horizontal, MongleSpacing.md)
                .padding(.top, MongleSpacing.md)
                .padding(.bottom, MongleSpacing.xl)
            }
            .background(MongleColor.background)
            .navigationTitle(L10n.tr("settings_app"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { store.send(.onAppear) }
            .sheet(item: $legalURL) { url in
                SettingsSafariSheet(url: url)
                    .ignoresSafeArea()
            }
            .overlay {
                if store.showLogoutConfirmation {
                    MonglePopupView(
                        icon: .init(
                            systemName: "arrow.right.square.fill",
                            foregroundColor: MongleColor.bgMintLight,
                            backgroundColor: MongleColor.primaryLight
                        ),
                        title: L10n.tr("settings_logout"),
                        description: L10n.tr("settings_logout_confirm"),
                        primaryLabel: L10n.tr("settings_logout"),
                        secondaryLabel: L10n.tr("common_cancel"),
                        onPrimary: { store.send(.logoutConfirmed) },
                        onSecondary: { store.send(.logoutCancelled) }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: store.showLogoutConfirmation)
                }
                if store.showDeleteAccountConfirmation {
                    MonglePopupView(
                        icon: .init(
                            systemName: "trash.fill",
                            foregroundColor: MongleColor.bgMintLight,
                            backgroundColor: MongleColor.primaryLight
                        ),

                        title: L10n.tr("settings_delete_account"),
                        description: L10n.tr("settings_delete_confirm"),
                        primaryLabel: L10n.tr("settings_delete_btn"),
                        secondaryLabel: L10n.tr("common_cancel"),
                        onPrimary: { store.send(.deleteAccountConfirmed) },
                        onSecondary: { store.send(.deleteAccountCancelled) }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: store.showDeleteAccountConfirmation)
                }
            }
        }
    }

    private var profileCard: some View {
        Button {
            store.send(.profileEditTapped)
        } label: {
            VStack(alignment: .leading, spacing: MongleSpacing.md) {
                HStack(spacing: MongleSpacing.md) {
                    Circle()
                        .fill(profileAccent.light)
                        .frame(width: 68, height: 68)
                        .overlay(
                            Image(systemName: profileAccent.icon)
                                .font(.system(size: 26))
                                .foregroundColor(profileAccent.color)
                        )

                    VStack(alignment: .leading, spacing: MongleSpacing.xxs) {
                        Text(L10n.tr("settings_profile"))
                            .font(MongleFont.body2Bold())
                            .foregroundColor(MongleColor.primary)
                        Text(store.currentUser?.name ?? "Mongle User")
                            .font(MongleFont.heading3())
                            .foregroundColor(MongleColor.textPrimary)
                        Text(L10n.tr("mood_loved"))
                            .font(MongleFont.body2())
                            .foregroundColor(MongleColor.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MongleColor.textHint)
                }

                HStack(spacing: MongleSpacing.xs) {
                    settingsChip("감정 수정")
                    settingsChip("프로필 편집")
                    settingsChip("그룹 연결")
                }
            }
            .padding(MongleSpacing.md)
            .background(
                LinearGradient(
                    colors: [MongleColor.bgCreamy, Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .monglePanel(background: .clear, cornerRadius: MongleRadius.xl, shadowOpacity: 0.03)
        }
        .buttonStyle(.plain)
    }

    private var moodSection: some View {
        settingsSection(
            title: L10n.tr("settings_profile"),
            rows: [
                SettingsRowModel(
                    icon: "face.smiling.fill",
                    iconColor: MongleColor.moodHappy,
                    iconBackground: MongleColor.moodHappyLight,
                    title: L10n.tr("settings_profile_edit"),
                    subtitle: L10n.tr("settings_profile_edit_desc"),
                    action: { store.send(.profileEditTapped) }
                ),
                SettingsRowModel(
                    icon: "clock.arrow.circlepath",
                    iconColor: MongleColor.moodCalm,
                    iconBackground: MongleColor.moodCalmLight,
                    title: L10n.tr("settings_mood_history"),
                    subtitle: L10n.tr("settings_mood_history_desc"),
                    action: { store.send(.moodHistoryTapped) }
                )
            ]
        )
    }

    private var groupSection: some View {
        settingsSection(
            title: L10n.tr("settings_group"),
            rows: [
                SettingsRowModel(
                    icon: "bell.fill",
                    iconColor: MongleColor.primary,
                    iconBackground: MongleColor.primaryLight,
                    title: L10n.tr("settings_notifications"),
                    subtitle: L10n.tr("settings_notifications_desc"),
                    action: { store.send(.notificationSettingsTapped) }
                ),
                SettingsRowModel(
                    icon: "person.3.fill",
                    iconColor: MongleColor.accentOrange,
                    iconBackground: MongleColor.bgWarm,
                    title: L10n.tr("settings_group"),
                    subtitle: L10n.tr("settings_group_desc"),
                    action: { store.send(.groupManagementTapped) }
                ),
                SettingsRowModel(
                    icon: "bell.badge.fill",
                    iconColor: MongleColor.info,
                    iconBackground: MongleColor.bgInfoLight,
                    title: L10n.tr("home_notifications"),
                    subtitle: L10n.tr("notif_settings_answer_desc"),
                    action: { store.send(.notificationsTapped) }
                )
            ]
        )
    }

    private var legalSection: some View {
        settingsSection(
            title: L10n.tr("settings_legal"),
            rows: [
                SettingsRowModel(
                    icon: "doc.text.fill",
                    iconColor: MongleColor.textPrimary,
                    iconBackground: MongleColor.bgNeutralWarm,
                    title: L10n.tr("settings_terms"),
                    subtitle: "",
                    action: { legalURL = LegalLinks.termsURL }
                ),
                SettingsRowModel(
                    icon: "lock.shield.fill",
                    iconColor: MongleColor.primary,
                    iconBackground: MongleColor.primaryLight,
                    title: L10n.tr("settings_privacy"),
                    subtitle: "",
                    action: { legalURL = LegalLinks.privacyURL }
                )
            ]
        )
    }

    private var accountSection: some View {
        settingsSection(
            title: L10n.tr("settings_account"),
            rows: [
                SettingsRowModel(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: MongleColor.textPrimary,
                    iconBackground: MongleColor.bgNeutralWarm,
                    title: L10n.tr("settings_logout"),
                    subtitle: L10n.tr("settings_logout_desc"),
                    action: { store.send(.logoutTapped) }
                ),
                SettingsRowModel(
                    icon: "trash.fill",
                    iconColor: MongleColor.error,
                    iconBackground: MongleColor.bgDanger,
                    title: L10n.tr("settings_delete_account"),
                    subtitle: L10n.tr("settings_delete_account_desc"),
                    titleColor: MongleColor.error,
                    action: { store.send(.deleteAccountTapped) }
                )
            ]
        )
    }

    private func settingsSection(title: String, rows: [SettingsRowModel]) -> some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            Text(title)
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)
                .padding(.horizontal, MongleSpacing.xxs)

            VStack(spacing: 0) {
                ForEach(rows) { row in
                    Button(action: row.action) {
                        HStack(spacing: MongleSpacing.md) {
                            RoundedRectangle(cornerRadius: MongleRadius.medium)
                                .fill(row.iconBackground)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: row.icon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(row.iconColor)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(MongleFont.body1())
                                    .foregroundColor(row.titleColor)
                                Text(row.subtitle)
                                    .font(MongleFont.caption())
                                    .foregroundColor(MongleColor.textHint)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(MongleColor.textHint)
                        }
                        .padding(.horizontal, MongleSpacing.md)
                        .frame(minHeight: 56, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    if row.id != rows.last?.id {
                        Divider()
                            .padding(.leading, 64)
                    }
                }
            }
            .background(MongleColor.cardBackgroundSolid)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
        }
    }

    private var profileAccent: (color: Color, light: Color, icon: String) {
        let options: [(Color, Color, String)] = [
            (MongleColor.moodHappy, MongleColor.moodHappyLight, "sun.max.fill"),
            (MongleColor.moodLoved, MongleColor.moodLovedLight, "heart.fill"),
            (MongleColor.moodCalm, MongleColor.moodCalmLight, "leaf.fill"),
            (MongleColor.moodExcited, MongleColor.moodExcitedLight, "sparkles")
        ]
        let index = abs((store.currentUser?.name ?? "몽글").hashValue) % options.count
        return options[index]
    }

    private func settingsChip(_ title: String) -> some View {
        Text(title)
            .font(MongleFont.captionBold())
            .foregroundColor(MongleColor.primaryDark)
            .padding(.horizontal, MongleSpacing.sm)
            .padding(.vertical, MongleSpacing.xxs)
            .background(MongleColor.primaryLight)
            .clipShape(Capsule())
    }

}

private struct SettingsSafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

private struct SettingsRowModel: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    let subtitle: String
    var titleColor: Color = MongleColor.textPrimary
    let action: () -> Void
}
