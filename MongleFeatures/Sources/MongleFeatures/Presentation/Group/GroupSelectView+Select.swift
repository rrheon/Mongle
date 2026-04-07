import SwiftUI
import ComposableArchitecture
import Domain

// MARK: - Select Step

extension GroupSelectView {

  static let monggleColors: [Color] = [
    MongleColor.monggleGreen,
    MongleColor.monggleYellow,
    MongleColor.monggleBlue,
    MongleColor.mongglePink,
    MongleColor.monggleOrange
  ]

  static func monggleColor(for moodId: String) -> Color {
    switch moodId {
    case "happy":  return MongleColor.monggleYellow
    case "calm":   return MongleColor.monggleGreen
    case "loved":  return MongleColor.mongglePink
    case "sad":    return MongleColor.monggleBlue
    case "tired":  return MongleColor.monggleOrange
    default:       return MongleColor.mongglePink
    }
  }

  func memberColors(for group: MongleGroup) -> [Color] {
    if !group.memberMoodIds.isEmpty {
      return group.memberMoodIds.map { Self.monggleColor(for: $0) }
    }
    let count = max(group.memberIds.count, 1)
    return (0..<count).map { Self.monggleColors[$0 % Self.monggleColors.count] }
  }

  // MARK: - Select View

  var selectView: some View {
    VStack(alignment: .leading, spacing: MongleSpacing.lg) {
      if store.isLoadingGroups {
        ProgressView()
          .tint(MongleColor.primary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, MongleSpacing.md)
      } else if store.groups.isEmpty {
        Text(L10n.tr("group_empty"))
          .font(MongleFont.body2())
          .foregroundColor(MongleColor.textSecondary)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .padding(.vertical, MongleSpacing.lg)
      } else {
        VStack(spacing: MongleSpacing.md) {
          ForEach(store.groups, id: \.id) { group in
            MongleCardGroup(
              groupName: group.name,
              memberColors: memberColors(for: group),
              onTap: { store.send(.groupTapped(group)) }
            )
            .contextMenu {
              Button(role: .destructive) {
                store.send(.leaveGroupTapped(group))
              } label: {
                Label(L10n.tr("group_leave"), systemImage: "rectangle.portrait.and.arrow.right")
              }
            }
          }
        }
      }

      newSpaceButton

      #if os(iOS)
      if !store.groups.isEmpty {
        AdBannerSection()
          .padding(.top, MongleSpacing.sm)
      }
      #endif
    }
    .overlay {
      if store.showMaxGroupsAlert {
        MonglePopupView(
          icon: .init(
            systemName: "exclamationmark.circle.fill",
            foregroundColor: MongleColor.accentOrange,
            backgroundColor: MongleColor.bgWarm
          ),
          title: L10n.tr("group_max_title"),
          description: L10n.tr("group_max_desc"),
          primaryLabel: L10n.tr("common_confirm"),
          onPrimary: { store.send(.dismissMaxGroupsAlert) }
        )
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: store.showMaxGroupsAlert)
      }
      if store.showLeaveConfirmation {
        MonglePopupView(
          title: L10n.tr("group_leave_title"),
          description: L10n.tr("group_leave_desc", store.groupToLeave?.name ?? L10n.tr("app_name")),
          primaryLabel: L10n.tr("group_leave_btn"),
          secondaryLabel: L10n.tr("common_cancel"),
          isDestructive: true,
          onPrimary: { store.send(.confirmLeave) },
          onSecondary: { store.send(.cancelLeaveConfirmation) }
        )
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: store.showLeaveConfirmation)
      }
      if store.showLeaveTooSoonAlert {
        MonglePopupView(
          icon: .init(
            systemName: "clock.fill",
            foregroundColor: MongleColor.primary,
            backgroundColor: MongleColor.primaryLight
          ),
          title: L10n.tr("group_disband_error"),
          description: store.leaveTooSoonMessage,
          primaryLabel: L10n.tr("common_confirm"),
          onPrimary: { store.send(.dismissLeaveTooSoonAlert) }
        )
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: store.showLeaveTooSoonAlert)
      }
    }
    .navigationDestination(isPresented: Binding(
      get: { store.showTransferSheet },
      set: { if !$0 { store.send(.dismissTransferSheet) } }
    )) {
      transferCreatorView
    }
  }

  // MARK: - New Space Button

  var newSpaceButton: some View {
    HStack(spacing: MongleSpacing.md) {
      Image(systemName: "plus")
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(.white)
        .frame(width: 36, height: 36)
        .background(MongleColor.primaryLight)
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 2) {
        Text(L10n.tr("group_create"))
          .font(MongleFont.body2Bold())
          .foregroundColor(MongleColor.textPrimary)
        Text(L10n.tr("group_join"))
          .font(MongleFont.caption())
          .foregroundColor(MongleColor.textSecondary)
      }

      Spacer()
    }
    .padding(MongleSpacing.md)
    .background(Color.white)
    .cornerRadius(MongleRadius.xl)
    .overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(MongleColor.border, lineWidth: 1))
    .contentShape(Rectangle())
    .onTapGesture {
      store.send(.newSpaceButtonTapped)
    }
  }

  // MARK: - Action Sheet

  var actionSheetContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(L10n.tr("group_what_to_do"))
        .font(MongleFont.body1Bold())
        .foregroundColor(MongleColor.textPrimary)
        .padding(.horizontal, MongleSpacing.lg)
        .padding(.top, MongleSpacing.lg)
        .padding(.bottom, MongleSpacing.md)

      VStack(spacing: 0) {
        actionSheetRow(
          icon: "sparkles",
          iconColor: MongleColor.primary,
          title: L10n.tr("group_create"),
          subtitle: L10n.tr("group_create_desc")
        ) {
          store.send(.actionSheetNewSpaceTapped)
        }

        Divider().padding(.leading, 60)

        actionSheetRow(
          icon: "person.badge.key",
          iconColor: MongleColor.primary,
          title: L10n.tr("group_join"),
          subtitle: L10n.tr("group_join_desc")
        ) {
          store.send(.actionSheetJoinSpaceTapped)
        }
      }
      .background(Color.white)
      .cornerRadius(MongleRadius.xl)
      .padding(.horizontal, MongleSpacing.md)

      Spacer()
    }
    .background(MongleColor.background)
  }

  func actionSheetRow(
    icon: String,
    iconColor: Color,
    title: String,
    subtitle: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: MongleSpacing.md) {
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(iconColor)
          .frame(width: 44, height: 44)
          .background(iconColor.opacity(0.1))
          .clipShape(Circle())

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(MongleFont.body2Bold())
            .foregroundColor(MongleColor.textPrimary)
          Text(subtitle)
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textSecondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 14))
          .foregroundColor(MongleColor.textHint)
      }
      .padding(.horizontal, MongleSpacing.md)
      .padding(.vertical, MongleSpacing.md)
    }
    .buttonStyle(.plain)
  }

  // MARK: - Transfer Creator View (Push)

  var transferCreatorView: some View {
    VStack(spacing: 0) {
      MongleNavigationHeader(title: L10n.tr("mgmt_transfer_title")) {
        MongleBackButton { store.send(.dismissTransferSheet) }
      } right: {
        EmptyView()
      }

      VStack(spacing: MongleSpacing.md) {
        Text(L10n.tr("mgmt_transfer_desc"))
          .font(MongleFont.body2())
          .foregroundColor(MongleColor.textSecondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, MongleSpacing.md)
          .padding(.top, MongleSpacing.md)

        ScrollView(showsIndicators: false) {
          VStack(spacing: 0) {
            ForEach(store.transferCandidates, id: \.id) { member in
              let isSelected = store.selectedTransferMemberId == member.id
              Button {
                store.send(.transferMemberSelected(member.id))
              } label: {
                HStack(spacing: MongleSpacing.md) {
                  Circle()
                    .fill(MongleColor.primaryLight)
                    .frame(width: 40, height: 40)
                    .overlay(
                      Text(String(member.name.prefix(1)))
                        .font(MongleFont.body2Bold())
                        .foregroundColor(MongleColor.primary)
                    )

                  Text(member.name)
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textPrimary)

                  Spacer()

                  if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(MongleColor.primary)
                  }
                }
                .padding(.horizontal, MongleSpacing.lg)
                .padding(.vertical, MongleSpacing.md)
                .background(isSelected ? MongleColor.primaryLight.opacity(0.3) : Color.clear)
                .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              Divider().padding(.leading, MongleSpacing.lg + 40 + MongleSpacing.md)
            }
          }
        }

        MongleButtonPrimary(L10n.tr("mgmt_transfer_btn")) {
          store.send(.confirmTransferAndLeave)
        }
        .disabled(store.selectedTransferMemberId == nil)
        .opacity(store.selectedTransferMemberId == nil ? 0.5 : 1)
        .padding(.horizontal, MongleSpacing.md)
        .padding(.bottom, MongleSpacing.md)
      }
    }
    .background(MongleColor.background)
    .toolbar(.hidden, for: .navigationBar)
  }
}
