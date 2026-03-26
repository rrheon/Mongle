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
        Text("참여 중인 그룹이 없어요.\n새 공간을 만들거나 초대코드로 참여해보세요.")
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
              streakDays: group.streakDays > 0 ? group.streakDays : nil,
              onTap: { store.send(.groupTapped(group)) }
            )
            .contextMenu {
              Button(role: .destructive) {
                store.send(.leaveGroupTapped(group))
              } label: {
                Label("그룹 나가기", systemImage: "rectangle.portrait.and.arrow.right")
              }
            }
          }
        }
      }

      newSpaceButton
    }
    .overlay {
      if store.showMaxGroupsAlert {
        MonglePopupView(
          icon: .init(
            systemName: "exclamationmark.circle.fill",
            foregroundColor: MongleColor.accentOrange,
            backgroundColor: MongleColor.bgWarm
          ),
          title: "그룹 한도 초과",
          description: "그룹은 최대 3개까지 참여할 수 있어요.",
          primaryLabel: "확인",
          onPrimary: { store.send(.dismissMaxGroupsAlert) }
        )
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: store.showMaxGroupsAlert)
      }
      if store.showLeaveConfirmation {
        MonglePopupView(
          icon: .init(
            systemName: "rectangle.portrait.and.arrow.right.fill",
            foregroundColor: MongleColor.error,
            backgroundColor: MongleColor.bgErrorSoft
          ),
          title: "그룹 나가기",
          description: "\(store.groupToLeave?.name ?? "그룹")에서 나가시겠어요?\n그룹 관련 데이터가 삭제되지만 작성한 답변은 유지됩니다.",
          primaryLabel: "나가기",
          secondaryLabel: "취소",
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
          title: "그룹 해제 불가",
          description: store.leaveTooSoonMessage,
          primaryLabel: "확인",
          onPrimary: { store.send(.dismissLeaveTooSoonAlert) }
        )
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: store.showLeaveTooSoonAlert)
      }
    }
    .sheet(isPresented: Binding(
      get: { store.showTransferSheet },
      set: { if !$0 { store.send(.dismissTransferSheet) } }
    )) {
      transferCreatorSheet
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
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
        Text("새 공간 만들기")
          .font(MongleFont.body2Bold())
          .foregroundColor(MongleColor.textPrimary)
        Text("초대코드로 참여하기")
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
      Text("무엇을 하시겠어요?")
        .font(MongleFont.body1Bold())
        .foregroundColor(MongleColor.textPrimary)
        .padding(.horizontal, MongleSpacing.lg)
        .padding(.top, MongleSpacing.lg)
        .padding(.bottom, MongleSpacing.md)

      VStack(spacing: 0) {
        actionSheetRow(
          icon: "sparkles",
          iconColor: MongleColor.primary,
          title: "새 공간 만들기",
          subtitle: "우리만의 공간을 직접 만들어요"
        ) {
          store.send(.actionSheetNewSpaceTapped)
        }

        Divider().padding(.leading, 60)

        actionSheetRow(
          icon: "person.badge.key",
          iconColor: MongleColor.secondary,
          title: "초대코드로 참여하기",
          subtitle: "받은 초대코드로 참여하세요"
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

  // MARK: - Transfer Creator Sheet

  var transferCreatorSheet: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text("방장 위임")
          .font(MongleFont.body1Bold())
          .foregroundColor(MongleColor.textPrimary)
        Text("그룹을 나가기 전에 방장을 위임할 멤버를 선택해주세요.")
          .font(MongleFont.body2())
          .foregroundColor(MongleColor.textSecondary)
          .lineSpacing(3)
      }
      .padding(.horizontal, MongleSpacing.lg)
      .padding(.top, MongleSpacing.lg)
      .padding(.bottom, MongleSpacing.md)

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

      VStack(spacing: MongleSpacing.sm) {
        MongleButtonPrimary("위임하고 나가기") {
          store.send(.confirmTransferAndLeave)
        }
        .disabled(store.selectedTransferMemberId == nil)
        .opacity(store.selectedTransferMemberId == nil ? 0.5 : 1)

        Button("취소") {
          store.send(.dismissTransferSheet)
        }
        .font(MongleFont.body2())
        .foregroundColor(MongleColor.textSecondary)
      }
      .padding(.horizontal, MongleSpacing.md)
      .padding(.vertical, MongleSpacing.md)
    }
    .background(MongleColor.background)
  }
}
