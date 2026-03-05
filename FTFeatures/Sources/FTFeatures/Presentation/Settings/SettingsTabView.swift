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

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F4F1")
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MongleSpacing.lg) {
                        // Profile Card
                        SettingsProfileCard(
                            user: store.currentUser,
                            onEditTapped: {}
                        )
                        .padding(.horizontal, MongleSpacing.lg)
                        .padding(.top, MongleSpacing.sm)

                        // 모늘의 기분 섹션
                        SettingsSectionCard(title: "모늘의 기분") {
                            SettingsRow(
                                icon: "face.smiling",
                                iconColor: Color(hex: "FFD54F"),
                                iconBg: Color(hex: "FFF3C4"),
                                title: "오늘의 기분 설정",
                                subtitle: "기분에 따라 몽글 색이 변해요",
                                trailing: .chevron
                            )
                            Divider().padding(.leading, 60)
                            SettingsRow(
                                icon: "clock.arrow.circlepath",
                                iconColor: Color(hex: "A8DFBC"),
                                iconBg: Color(hex: "D4F0E0"),
                                title: "기분 히스토리",
                                subtitle: "나의 감정 기록 돌아보기",
                                trailing: .chevron
                            )
                        }
                        .padding(.horizontal, MongleSpacing.lg)

                        // 그룹 관리 섹션
                        SettingsSectionCard(title: "그룹 관리") {
                            SettingsRow(
                                icon: "bell.fill",
                                iconColor: Color(hex: "A8DFBC"),
                                iconBg: Color(hex: "D4F0E0"),
                                title: "알림 설정",
                                subtitle: "답변 알림, 리마인더",
                                trailing: .chevron
                            )
                            Divider().padding(.leading, 60)
                            SettingsRow(
                                icon: "person.3.fill",
                                iconColor: Color(hex: "A8DFBC"),
                                iconBg: Color(hex: "D4F0E0"),
                                title: "그룹 관리",
                                subtitle: "멤버 초대, 그룹 설정",
                                trailing: .chevron
                            )
                            Divider().padding(.leading, 60)
                            SettingsRow(
                                icon: "person.crop.circle.fill",
                                iconColor: Color(hex: "A8DFBC"),
                                iconBg: Color(hex: "D4F0E0"),
                                title: "계정 관리",
                                subtitle: "로그아웃, 탈퇴",
                                trailing: .chevron,
                                action: { store.send(.logoutTapped) }
                            )
                        }
                        .padding(.horizontal, MongleSpacing.lg)

                        // Footer
                        Text("몽글 v\(store.appVersion)")
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textHint)
                            .frame(maxWidth: .infinity)
                            .padding(.top, MongleSpacing.sm)

                        Spacer()
                            .frame(height: MongleSpacing.xxl)
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
                Button("취소", role: .cancel) { store.send(.logoutCancelled) }
                Button("로그아웃", role: .destructive) { store.send(.logoutConfirmed) }
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
                Button("취소", role: .cancel) { store.send(.deleteAccountCancelled) }
                Button("탈퇴하기", role: .destructive) { store.send(.deleteAccountConfirmed) }
            } message: {
                Text("계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다.\n정말 탈퇴하시겠습니까?")
            }
            .onAppear { store.send(.onAppear) }
        }
    }
}

// MARK: - Settings Profile Card
private struct SettingsProfileCard: View {
    let user: User?
    let onEditTapped: () -> Void

    private let monggleColors: [Color] = [
        Color(hex: "A8DFBC"), Color(hex: "F5978E"),
        Color(hex: "FFD54F"), Color(hex: "42A5F5")
    ]

    private var monggleColor: Color {
        let name = user?.name ?? ""
        return monggleColors[abs(name.hashValue) % monggleColors.count]
    }

    var body: some View {
        MongleCard(cornerRadius: MongleRadius.xl) {
            HStack(spacing: MongleSpacing.md) {
                // Monggle Avatar
                ZStack {
                    Circle()
                        .fill(monggleColor)
                        .frame(width: 64, height: 64)

                    HStack(spacing: 8) {
                        Circle().fill(Color(hex: "1A1A1A")).frame(width: 7, height: 8)
                        Circle().fill(Color(hex: "1A1A1A")).frame(width: 7, height: 8)
                    }
                    .offset(y: 3)
                }

                VStack(alignment: .leading, spacing: MongleSpacing.xxs) {
                    Text(user?.name ?? "-")
                        .font(MongleFont.heading3())
                        .foregroundColor(MongleColor.textPrimary)

                    HStack(spacing: MongleSpacing.xxs) {
                        Text("오늘의 기분:")
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textSecondary)
                        Text("😊 사랑")
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textPrimary)
                    }
                }

                Spacer()

                Button(action: onEditTapped) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MongleColor.textHint)
                }
            }
        }
    }
}

// MARK: - Settings Section Card
private struct SettingsSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            Text(title)
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)
                .padding(.horizontal, MongleSpacing.xxs)

            VStack(spacing: 0) {
                content
            }
            .background(MongleColor.cardBackground)
            .cornerRadius(MongleRadius.xl)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Settings Row
private struct SettingsRow: View {
    enum Trailing {
        case chevron
        case toggle(Bool, (Bool) -> Void)
        case none
    }

    let icon: String
    let iconColor: Color
    var iconBg: Color = Color.clear
    let title: String
    var subtitle: String? = nil
    var titleColor: Color = MongleColor.textPrimary
    let trailing: Trailing
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: MongleSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: MongleRadius.xs)
                        .fill(iconBg.opacity(iconBg == .clear ? 0 : 1))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MongleFont.body1())
                        .foregroundColor(titleColor)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textSecondary)
                    }
                }

                Spacer()

                switch trailing {
                case .chevron:
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MongleColor.textHint)
                case .toggle(let isOn, let onToggle):
                    Toggle("", isOn: Binding(get: { isOn }, set: { onToggle($0) }))
                        .tint(MongleColor.primary)
                        .labelsHidden()
                case .none:
                    EmptyView()
                }
            }
            .padding(.horizontal, MongleSpacing.lg)
            .padding(.vertical, MongleSpacing.sm)
        }
        .disabled(action == nil && {
            if case .toggle = trailing { return false }
            return true
        }())
    }
}

// MARK: - Previews
#Preview("Settings Tab") {
    SettingsTabView(
        store: Store(initialState: SettingsFeature.State(
            currentUser: User(
                id: UUID(),
                email: "me@example.com",
                name: "Mom",
                profileImageURL: nil,
                role: .mother,
                createdAt: .now
            ),
            appVersion: "1.0.0"
        )) {
            SettingsFeature()
        }
    )
}
