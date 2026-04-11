//
//  ProfileEditView.swift
//  Mongle
//
//  Created by Claude on 1/9/26.
//

import SwiftUI
import ComposableArchitecture
import Domain

public struct ProfileEditView: View {
    @Bindable var store: StoreOf<ProfileEditFeature>

    public init(store: StoreOf<ProfileEditFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MongleSpacing.lg) {
                        profileCard
                        
                      // 광고 배너
                        #if os(iOS)
                        AdBannerSection()
                            .padding(.horizontal, 20)
                            .padding(.bottom, 4)
                        #endif

                        moodSection
                        groupSection

                        Text(L10n.tr("settings_version", "1.0.0"))
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
            }
            .navigationBarHidden(true)
            .toolbarBackground(Color.white, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .onAppear { store.send(.onAppear) }
            .overlay {
                if store.showGuestLoginPrompt {
                    MonglePopupView(
                        icon: .init(
                            systemName: "person.crop.circle.badge.exclamationmark.fill",
                            foregroundColor: MongleColor.primary,
                            backgroundColor: MongleColor.primaryLight
                        ),
                        title: L10n.tr("settings_login_required"),
                        description: L10n.tr("settings_login_required_desc"),
                        primaryLabel: L10n.tr("settings_login_btn"),
                        secondaryLabel: L10n.tr("common_cancel"),
                        onPrimary: { store.send(.guestLoginTapped) },
                        onSecondary: { store.send(.guestLoginDismissed) }
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: store.showGuestLoginPrompt)
                }
            }
            .navigationDestination(
                item: $store.scope(state: \.mongleCardEdit, action: \.mongleCardEdit)
            ) { cardEditStore in
                MongleCardEditView(store: cardEditStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.notificationSettings, action: \.notificationSettings)
            ) { notifStore in
                NotificationSettingsView(store: notifStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.groupManagement, action: \.groupManagement)
            ) { groupStore in
                GroupManagementView(store: groupStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.moodHistory, action: \.moodHistory)
            ) { moodStore in
                MoodHistoryView(store: moodStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.accountManagement, action: \.accountManagement)
            ) { accountStore in
                AccountManagementView(store: accountStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.badges, action: \.badges)
            ) { badgesStore in
                BadgesView(store: badgesStore)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            Text(L10n.tr("settings_my"))
                .font(MongleFont.heading3().weight(.bold))
                .foregroundColor(MongleColor.textPrimary)

            Spacer()
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
        .background(Color.white)
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: MongleSpacing.md) {
            MongleMonggle.forMood(store.user?.moodId)

            VStack(alignment: .leading, spacing: 4) {
                Text(store.user?.name ?? "Mongle User")
                    .font(MongleFont.heading3())
                    .foregroundColor(MongleColor.textPrimary)
                if let moodId = store.user?.moodId,
                   let mood = MoodOption.defaults.first(where: { $0.id == moodId }) {
                    Text(mood.label)
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textSecondary)
                }
            }

            Spacer()
        }
        .padding(MongleSpacing.md)
        .monglePanel(
            background: Color.white.opacity(0.85),
            cornerRadius: MongleRadius.xl,
            borderColor: MongleColor.border.opacity(0.3),
            shadowOpacity: 0.04
        )
    }


    // MARK: - 활동 및 기록

    private var moodSection: some View {
        settingsSection(
            title: L10n.tr("settings_profile"),
            rows: [
                ProfileSettingsRow(
                    icon: "face.smiling.fill",
                    iconColor: MongleColor.bgMintLight,
                    iconBackground: MongleColor.primaryLight,
                    title: L10n.tr("settings_profile_edit"),
                    subtitle: L10n.tr("settings_profile_edit_desc"),
                    action: { store.send(.moodSettingTapped) }
                ),
                ProfileSettingsRow(
                    icon: "rosette",
                    iconColor: MongleColor.bgMintLight,
                    iconBackground: MongleColor.primaryLight,
                    title: L10n.tr("settings_badges"),
                    subtitle: L10n.tr("settings_badges_desc"),
                    action: { store.send(.badgesTapped) }
                )
            ]
        )
    }

    // MARK: - 앱 설정

    private var groupSection: some View {
        settingsSection(
            title: L10n.tr("settings_app"),
            rows: [
                ProfileSettingsRow(
                    icon: "bell.fill",
                    iconColor: MongleColor.bgMintLight,
                    iconBackground: MongleColor.primaryLight,
                    title: L10n.tr("settings_notifications"),
                    subtitle: L10n.tr("settings_notifications_desc"),
                    action: { store.send(.notificationSettingsTapped) }
                ),
                ProfileSettingsRow(
                    icon: "person.3.fill",
                    iconColor: MongleColor.bgMintLight,
                    iconBackground: MongleColor.primaryLight,
                    title: L10n.tr("settings_group"),
                    subtitle: L10n.tr("settings_group_desc"),
                    action: { store.send(.groupManagementTapped) }
                ),
                ProfileSettingsRow(
                    icon: "gearshape.fill",
                    iconColor: MongleColor.bgMintLight,
                    iconBackground: MongleColor.primaryLight,
                    title: L10n.tr("settings_account"),
                    subtitle: L10n.tr("settings_account_desc"),
                    action: { store.send(.accountManagementTapped) }
                )
            ]
        )
    }

    // MARK: - Settings Section Builder

  struct SettingsRowView: View {
    fileprivate let row: ProfileSettingsRow
      
      var body: some View {
          HStack(spacing: MongleSpacing.md) {
              // 아이콘 영역
              iconView
              
              // 텍스트 영역
              VStack(alignment: .leading, spacing: 2) {
                  Text(row.title)
                      .font(MongleFont.body1())
                      .foregroundColor(MongleColor.textPrimary)
                  
                  if !row.subtitle.isEmpty { // 서브타이틀이 있을 때만 렌더링
                      Text(row.subtitle)
                          .font(MongleFont.caption())
                          .foregroundColor(MongleColor.textHint)
                  }
              }
              
              Spacer()
              
              Image(systemName: "chevron.right")
                  .font(.system(size: 12, weight: .semibold))
                  .foregroundColor(MongleColor.textHint)
          }
          .padding(.horizontal, MongleSpacing.md)
          .contentShape(Rectangle()) // 투명한 영역도 클릭 가능하게 설정
      }
      
      private var iconView: some View {
          RoundedRectangle(cornerRadius: MongleRadius.medium)
              .fill(row.iconBackground)
              .frame(width: 36, height: 36)
              .overlay(
                  Image(systemName: row.icon)
                      .font(.system(size: 18, weight: .medium))
                      .foregroundColor(row.iconColor)
              )
      }
  }
  
  private func settingsSection(title: String, rows: [ProfileSettingsRow]) -> some View {
      VStack(alignment: .leading, spacing: MongleSpacing.sm) {
          // 섹션 타이틀
          Text(title)
              .font(MongleFont.captionBold())
              .foregroundColor(MongleColor.textSecondary)
              .padding(.horizontal, MongleSpacing.xxs)

          // 섹션 카드 컨테이너
          VStack(spacing: 0) {
              ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                  Button(action: row.action) {
                      SettingsRowView(row: row)
                          .frame(minHeight: 56)
                  }
                  .buttonStyle(MongleRowButtonStyle())

                  // 마지막 항목이 아닐 때만 구분선 표시
                  if index < rows.count - 1 {
                      Divider()
                          .padding(.leading, 64) // 아이콘 너비 + 간격만큼 push
                  }
              }
          }
          .monglePanel(
              background: MongleColor.cardBackgroundSolid,
              cornerRadius: MongleRadius.large,
              borderColor: MongleColor.border,
              shadowOpacity: 0.03
          )
      }
  }
}

// MARK: - Private Models

fileprivate struct ProfileSettingsRow: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let iconBackground: Color
    let title: String
    let subtitle: String
    let action: () -> Void
}

// MARK: - Preview

#Preview {
    ProfileEditView(
        store: Store(initialState: ProfileEditFeature.State()) {
            ProfileEditFeature()
        }
    )
}
