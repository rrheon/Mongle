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
            ScrollView(showsIndicators: false) {
                VStack(spacing: MongleSpacing.lg) {
                    profileCard
                    #if os(iOS)
                    AdBannerSection()
                    #endif
                    moodSection
                    groupSection
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
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { store.send(.onAppear) }
            .overlay {
                if store.showLogoutConfirmation {
                    MonglePopupView(
                        icon: .init(
                            systemName: "arrow.right.square.fill",
                            foregroundColor: MongleColor.bgMintLight,
                            backgroundColor: MongleColor.primaryLight
                        ),
                        title: "로그아웃",
                        description: "정말 로그아웃 하시겠습니까?",
                        primaryLabel: "로그아웃",
                        secondaryLabel: "취소",
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

                        title: "회원탈퇴",
                        description: "계정을 삭제하면 모든 데이터가\n영구적으로 삭제됩니다.",
                        primaryLabel: "탈퇴하기",
                        secondaryLabel: "취소",
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
                        Text("내 프로필")
                            .font(MongleFont.body2Bold())
                            .foregroundColor(MongleColor.primary)
                        Text(store.currentUser?.name ?? "Mongle User")
                            .font(MongleFont.heading3())
                            .foregroundColor(MongleColor.textPrimary)
                        Text("오늘의 기분: 사랑")
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
            title: "오늘의 기분",
            rows: [
                SettingsRowModel(
                    icon: "face.smiling.fill",
                    iconColor: MongleColor.moodHappy,
                    iconBackground: MongleColor.moodHappyLight,
                    title: "오늘의 기분 설정",
                    subtitle: "기분에 따라 몽글 색이 변해요",
                    action: { store.send(.profileEditTapped) }
                ),
                SettingsRowModel(
                    icon: "clock.arrow.circlepath",
                    iconColor: MongleColor.moodCalm,
                    iconBackground: MongleColor.moodCalmLight,
                    title: "기분 히스토리",
                    subtitle: "나의 감정 기록 돌아보기",
                    action: { store.send(.moodHistoryTapped) }
                )
            ]
        )
    }

    private var groupSection: some View {
        settingsSection(
            title: "그룹 관리",
            rows: [
                SettingsRowModel(
                    icon: "bell.fill",
                    iconColor: MongleColor.primary,
                    iconBackground: MongleColor.primaryLight,
                    title: "알림 설정",
                    subtitle: "답변 알림, 리마인더",
                    action: { store.send(.notificationSettingsTapped) }
                ),
                SettingsRowModel(
                    icon: "person.3.fill",
                    iconColor: MongleColor.accentOrange,
                    iconBackground: MongleColor.bgWarm,
                    title: "그룹 관리",
                    subtitle: "멤버 초대, 그룹 설정",
                    action: { store.send(.groupManagementTapped) }
                ),
                SettingsRowModel(
                    icon: "bell.badge.fill",
                    iconColor: MongleColor.info,
                    iconBackground: MongleColor.bgInfoLight,
                    title: "알림 센터",
                    subtitle: "가족 답변과 시스템 알림 확인",
                    action: { store.send(.notificationsTapped) }
                )
            ]
        )
    }

    private var accountSection: some View {
        settingsSection(
            title: "계정",
            rows: [
                SettingsRowModel(
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: MongleColor.textPrimary,
                    iconBackground: MongleColor.bgNeutralWarm,
                    title: "로그아웃",
                    subtitle: "현재 계정에서 로그아웃",
                    action: { store.send(.logoutTapped) }
                ),
                SettingsRowModel(
                    icon: "trash.fill",
                    iconColor: MongleColor.error,
                    iconBackground: MongleColor.bgDanger,
                    title: "회원탈퇴",
                    subtitle: "모든 데이터를 삭제하고 앱을 떠나요",
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
