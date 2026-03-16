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

                        Text("몽글 v1.0.0")
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
            .onAppear { store.send(.onAppear) }
            .navigationDestination(
                item: $store.scope(state: \.mongleCardEdit, action: \.mongleCardEdit)
            ) { cardEditStore in
                MongleCardEditView(store: cardEditStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.supportScreen, action: \.supportScreen)
            ) { supportStore in
                SupportScreenView(store: supportStore)
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
            Text("MY")
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
            MongleMonggle(color: .blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(store.user?.name ?? "Mongle User")
                    .font(MongleFont.heading3())
                    .foregroundColor(MongleColor.textPrimary)
            }

            Spacer()
        }
        .padding(MongleSpacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: MongleRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: MongleRadius.xl)
                .stroke(MongleColor.border.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 4)
    }


    // MARK: - 활동 및 기록

    private var moodSection: some View {
        settingsSection(
            title: "활동 및 기록",
            rows: [
                ProfileSettingsRow(
                    icon: "face.smiling.fill",
                    iconColor: MongleColor.moodHappy,
                    iconBackground: MongleColor.moodHappyLight,
                    title: "프로필 편집",
                    subtitle: "이름과 기분을 변경할 수 있어요",
                    action: { store.send(.moodSettingTapped) }
                ),
                ProfileSettingsRow(
                    icon: "calendar",
                    iconColor: MongleColor.moodCalm,
                    iconBackground: MongleColor.moodCalmLight,
                    title: "기분 히스토리",
                    subtitle: "나의 감정 기록 돌아보기",
                    action: { store.send(.moodHistoryTapped) }
                )
            ]
        )
    }

    // MARK: - 앱 설정

    private var groupSection: some View {
        settingsSection(
            title: "앱 설정",
            rows: [
                ProfileSettingsRow(
                    icon: "bell.fill",
                    iconColor: MongleColor.primary,
                    iconBackground: MongleColor.primaryLight,
                    title: "알림 설정",
                    subtitle: "답변 알림, 리마인더",
                    action: { store.send(.notificationSettingsTapped) }
                ),
                ProfileSettingsRow(
                    icon: "person.3.fill",
                    iconColor: MongleColor.accentOrange,
                    iconBackground: MongleColor.bgWarm,
                    title: "그룹 관리",
                    subtitle: "멤버 초대, 그룹 설정",
                    action: { store.send(.groupManagementTapped) }
                ),
                ProfileSettingsRow(
                    icon: "gearshape.fill",
                    iconColor: MongleColor.moodCalm,
                    iconBackground: MongleColor.moodCalmLight,
                    title: "계정 관리",
                    subtitle: "로그아웃, 탈퇴",
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
                  .buttonStyle(PlainButtonStyle())

                  // 마지막 항목이 아닐 때만 구분선 표시
                  if index < rows.count - 1 {
                      Divider()
                          .padding(.leading, 64) // 아이콘 너비 + 간격만큼 push
                  }
              }
          }
          .background(MongleColor.cardBackgroundSolid)
          .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
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
