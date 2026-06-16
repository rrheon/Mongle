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
    @Environment(\.openURL) private var openURL

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
                        AdBannerSection(bottom: 4, horizontal: 20)
                        #endif

                        moodSection
                        groupSection
                        legalSection

                        Text(L10n.tr("settings_version", "1.0.0"))
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textHint)
                            .frame(maxWidth: .infinity)
                            .padding(.top, MongleSpacing.sm)
                    }
                    .padding(.horizontal, MongleSpacing.md)
                    .padding(.top, MongleSpacing.md)
                    // MG-140 — v2 탭바 영역만큼 bottom inset 확보.
                    .padding(.bottom, 110)
                }
                // MG-140 — Home/History/Search 와 동일 cream 배경.
                .background(V2Palette.cream)
            }
            // MG-140 — 상단 safeArea(시스템 navigationBar 영역) 까지 cream 으로 덮어
            // 흰색 띠가 남는 것을 방지. .toolbarBackground(.hidden, for: .navigationBar)
            // 도 함께 적용해 NavigationStack 의 기본 흰 toolbar 배경을 끈다.
            .background(V2Palette.cream.ignoresSafeArea())
            .navigationBarHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
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
        // MG-140 — v2 톤에 맞춰 헤더는 cream 위에 투명.
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

    // MARK: - 약관 및 정책

    private var legalSection: some View {
        settingsSection(
            title: L10n.tr("settings_legal"),
            rows: [
                ProfileSettingsRow(
                    icon: "doc.text.fill",
                    iconColor: MongleColor.bgMintLight,
                    iconBackground: MongleColor.primaryLight,
                    title: L10n.tr("settings_terms"),
                    subtitle: "",
                    action: { openURL(LegalLinks.termsURL) }
                ),
                ProfileSettingsRow(
                    icon: "lock.shield.fill",
                    iconColor: MongleColor.bgMintLight,
                    iconBackground: MongleColor.primaryLight,
                    title: L10n.tr("settings_privacy"),
                    subtitle: "",
                    action: { openURL(LegalLinks.privacyURL) }
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
          // MG-140 — V2 시안(V2SettingRow) 의 톤으로 통일. row 별로 다르던
          // iconBackground / iconColor 는 무시하고 v2 cream2 chip + mutedSoft 아이콘.
          RoundedRectangle(cornerRadius: MongleRadius.medium)
              .fill(Color(hex: "F7F0E5"))
              .frame(width: 36, height: 36)
              .overlay(
                  Image(systemName: row.icon)
                      .font(.system(size: 18, weight: .medium))
                      .foregroundColor(V2Palette.mutedSoft)
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
