//
//  SettingsTabView.swift
//  Mongle
//
//  Created by Claude on 2025-01-06.
//

import SwiftUI
import ComposableArchitecture
import Domain

struct SettingsTabView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.surface
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: FTSpacing.lg) {
                        // Profile Card
                        SettingsProfileCard(user: store.currentUser)
                            .padding(.horizontal, FTSpacing.lg)
                            .padding(.top, FTSpacing.sm)

                        // Notification Settings
                        SettingsNotificationCard(
                            notificationsEnabled: store.notificationsEnabled,
                            onToggle: { store.send(.notificationsToggled($0)) }
                        )
                        .padding(.horizontal, FTSpacing.lg)

                        // App Info
                        SettingsAppInfoCard(
                            version: store.appVersion,
                            onTermsTapped: { store.send(.termsOfServiceTapped) },
                            onPrivacyTapped: { store.send(.privacyPolicyTapped) },
                            onContactTapped: { store.send(.contactUsTapped) }
                        )
                        .padding(.horizontal, FTSpacing.lg)

                        // Account Actions
                        SettingsAccountCard(
                            onLogoutTapped: { store.send(.logoutTapped) },
                            onDeleteAccountTapped: { store.send(.deleteAccountTapped) }
                        )
                        .padding(.horizontal, FTSpacing.lg)

                        Spacer()
                            .frame(height: FTSpacing.xxl)
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .alert(
                "로그아웃",
                isPresented: Binding(
                    get: { store.showLogoutConfirmation },
                    set: { _ in store.send(.logoutCancelled) }
                )
            ) {
                Button("취소", role: .cancel) {
                    store.send(.logoutCancelled)
                }
                Button("로그아웃", role: .destructive) {
                    store.send(.logoutConfirmed)
                }
            } message: {
                Text("정말 로그아웃 하시겠습니까?")
            }
            .alert(
                "회원탈퇴",
                isPresented: Binding(
                    get: { store.showDeleteAccountConfirmation },
                    set: { _ in store.send(.deleteAccountCancelled) }
                )
            ) {
                Button("취소", role: .cancel) {
                    store.send(.deleteAccountCancelled)
                }
                Button("탈퇴하기", role: .destructive) {
                    store.send(.deleteAccountConfirmed)
                }
            } message: {
                Text("계정을 삭제하면 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다.\n정말 탈퇴하시겠습니까?")
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

// MARK: - Settings Profile Card
private struct SettingsProfileCard: View {
    let user: User?

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            HStack(spacing: FTSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(FTColor.primaryLight)
                        .frame(width: 72, height: 72)

                    Text(String(user?.name.prefix(1) ?? "?"))
                        .font(FTFont.heading2())
                        .foregroundColor(FTColor.primary)
                }

                VStack(alignment: .leading, spacing: FTSpacing.xs) {
                    Text(user?.name ?? "-")
                        .font(FTFont.heading3())
                        .foregroundColor(FTColor.textPrimary)

                    Text(user?.email ?? "-")
                        .font(FTFont.body2())
                        .foregroundColor(FTColor.textSecondary)

                    if let role = user?.role {
                        HStack(spacing: FTSpacing.xxs) {
                            Image(systemName: roleIcon(role))
                                .font(.system(size: 10))
                            Text(role.rawValue)
                                .font(FTFont.captionBold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, FTSpacing.sm)
                        .padding(.vertical, FTSpacing.xxs)
                        .background(FTColor.primary)
                        .cornerRadius(FTRadius.full)
                    }
                }

                Spacer()

                // Edit Button
                Button {
                    // TODO: Edit profile
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(FTColor.textHint)
                }
            }
        }
    }

    private func roleIcon(_ role: FamilyRole) -> String {
        switch role {
        case .father: return "figure.stand"
        case .mother: return "figure.stand.dress"
        case .son, .daughter: return "figure.and.child.holdinghands"
        case .other: return "person.fill"
        }
    }
}

// MARK: - Settings Notification Card
private struct SettingsNotificationCard: View {
    let notificationsEnabled: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            VStack(alignment: .leading, spacing: FTSpacing.md) {
                FTSectionHeader(title: "알림 설정")

                HStack {
                    HStack(spacing: FTSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(FTColor.primaryLight)
                                .frame(width: 40, height: 40)

                            Image(systemName: "bell.fill")
                                .font(.system(size: 18))
                                .foregroundColor(FTColor.primary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("푸시 알림")
                                .font(FTFont.body1())
                                .foregroundColor(FTColor.textPrimary)

                            Text("매일 새로운 질문 알림을 받아요")
                                .font(FTFont.caption())
                                .foregroundColor(FTColor.textSecondary)
                        }
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { notificationsEnabled },
                        set: { onToggle($0) }
                    ))
                    .tint(FTColor.primary)
                    .labelsHidden()
                }
            }
        }
    }
}

// MARK: - Settings App Info Card
private struct SettingsAppInfoCard: View {
    let version: String
    let onTermsTapped: () -> Void
    let onPrivacyTapped: () -> Void
    let onContactTapped: () -> Void

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            VStack(alignment: .leading, spacing: FTSpacing.sm) {
                FTSectionHeader(title: "앱 정보")

                VStack(spacing: 0) {
                    // Version
                    SettingsRow(
                        icon: "info.circle.fill",
                        iconColor: FTColor.info,
                        title: "버전",
                        trailing: .text(version)
                    )

                    Divider()
                        .padding(.leading, 52)

                    // Terms
                    SettingsRow(
                        icon: "doc.text.fill",
                        iconColor: FTColor.textHint,
                        title: "이용약관",
                        trailing: .chevron,
                        action: onTermsTapped
                    )

                    Divider()
                        .padding(.leading, 52)

                    // Privacy
                    SettingsRow(
                        icon: "hand.raised.fill",
                        iconColor: FTColor.textHint,
                        title: "개인정보처리방침",
                        trailing: .chevron,
                        action: onPrivacyTapped
                    )

                    Divider()
                        .padding(.leading, 52)

                    // Contact
                    SettingsRow(
                        icon: "envelope.fill",
                        iconColor: FTColor.textHint,
                        title: "문의하기",
                        trailing: .chevron,
                        action: onContactTapped
                    )
                }
            }
        }
    }
}

// MARK: - Settings Account Card
private struct SettingsAccountCard: View {
    let onLogoutTapped: () -> Void
    let onDeleteAccountTapped: () -> Void

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            VStack(alignment: .leading, spacing: FTSpacing.sm) {
                FTSectionHeader(title: "계정")

                SettingsRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: FTColor.error,
                    title: "로그아웃",
                    titleColor: FTColor.error,
                    trailing: .none,
                    action: onLogoutTapped
                )

                Divider()
                    .padding(.leading, 52)

                SettingsRow(
                    icon: "trash.fill",
                    iconColor: FTColor.error,
                    title: "회원탈퇴",
                    titleColor: FTColor.error,
                    trailing: .none,
                    action: onDeleteAccountTapped
                )
            }
        }
    }
}

// MARK: - Settings Row
private struct SettingsRow: View {
    enum Trailing {
        case chevron
        case text(String)
        case none
    }

    let icon: String
    let iconColor: Color
    let title: String
    var titleColor: Color = FTColor.textPrimary
    let trailing: Trailing
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: FTSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(FTFont.body1())
                    .foregroundColor(titleColor)

                Spacer()

                switch trailing {
                case .chevron:
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FTColor.textHint)
                case .text(let value):
                    Text(value)
                        .font(FTFont.body2())
                        .foregroundColor(FTColor.textSecondary)
                case .none:
                    EmptyView()
                }
            }
            .padding(.vertical, FTSpacing.sm)
        }
        .disabled(action == nil)
    }
}

// MARK: - Previews
#Preview("Settings Tab") {
    SettingsTabView(
        store: Store(initialState: SettingsFeature.State(
            currentUser: User(
                id: UUID(),
                email: "me@example.com",
                name: "나",
                profileImageURL: nil,
                role: .son,
                createdAt: .now
            ),
            appVersion: "1.0.0",
            notificationsEnabled: true
        )) {
            SettingsFeature()
        }
    )
}

#Preview("Settings Tab - No User") {
    SettingsTabView(
        store: Store(initialState: SettingsFeature.State(
            appVersion: "1.0.0"
        )) {
            SettingsFeature()
        }
    )
}
