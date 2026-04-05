import SwiftUI
import ComposableArchitecture

public struct GroupManagementView: View {
  @Bindable var store: StoreOf<GroupManagementFeature>
  
  public init(store: StoreOf<GroupManagementFeature>) {
    self.store = store
  }
  
  public var body: some View {
    VStack(spacing: 0) {
      MongleNavigationHeader(title: L10n.tr("mgmt_title")) {
        MongleBackButton { store.send(.closeTapped) }
      } right: {
        EmptyView()
      }
      
      ScrollView(showsIndicators: false) {
        VStack(spacing: MongleSpacing.md) {
          groupInfoSection
          membersSection
          
          MongleButtonSecondary(L10n.tr("mgmt_leave")) {
            store.send(.leaveGroupTapped)
          }
        }
        .padding(MongleSpacing.md)
        .padding(.bottom, MongleSpacing.xl)
      }
      .background(MongleColor.background)
    }
    .toolbar(.hidden, for: .navigationBar)
    .overlay {
      if store.showLeaveConfirm {
        MonglePopupView(
          title: L10n.tr("group_leave_title"),
          description: L10n.tr("mgmt_leave_desc"),
          primaryLabel: L10n.tr("mgmt_leave_btn"),
          secondaryLabel: L10n.tr("common_cancel"),
          isDestructive: true,
          onPrimary: { store.send(.leaveGroupConfirmed) },
          onSecondary: { store.send(.leaveGroupAlertDismissed) }
        )
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: store.showLeaveConfirm)
      }
    }
    .overlay {
      if store.showKickConfirm {
        MonglePopupView(
          icon: .init(
            systemName: "person.fill.xmark",
            foregroundColor: MongleColor.error,
            backgroundColor: MongleColor.bgErrorSoft
          ),
          title: store.kickTargetMember.map { L10n.tr("mgmt_kick", $0.name) } ?? L10n.tr("mgmt_kick_btn"),
          description: L10n.tr("mgmt_kick_desc"),
          primaryLabel: L10n.tr("mgmt_kick_btn"),
          secondaryLabel: L10n.tr("common_cancel"),
          isDestructive: true,
          onPrimary: { store.send(.kickMemberConfirmed) },
          onSecondary: { store.send(.kickMemberCancelled) }
        )
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: store.showKickConfirm)
      }
    }
    .overlay {
      if let errorMessage = store.errorMessage {
        MonglePopupView(
          icon: .init(
            systemName: "exclamationmark.circle.fill",
            foregroundColor: MongleColor.error,
            backgroundColor: MongleColor.bgErrorSoft
          ),
          title: L10n.tr("error_title"),
          description: errorMessage,
          primaryLabel: L10n.tr("common_confirm"),
          onPrimary: { store.send(.dismissError) }
        )
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: store.errorMessage)
      }
    }
    .navigationDestination(isPresented: Binding(
      get: { store.showTransferSheet },
      set: { if !$0 { store.send(.dismissTransferSheet) } }
    )) {
      transferCreatorView
    }
    .overlay(alignment: .bottom) {
      if store.showCopiedToast {
        MongleToastView(type: .inviteCodeCopied)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .padding(.bottom, MongleSpacing.lg)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: store.showCopiedToast)
    .preferredColorScheme(.light)
    .onAppear { store.send(.onAppear) }
  }
  
  // MARK: - Group Info
  
  private var groupInfoSection: some View {
    VStack(alignment: .leading, spacing: MongleSpacing.sm) {
      sectionTitle(L10n.tr("mgmt_invite_section"), subtitle: L10n.tr("mgmt_invite_desc"))
      
      VStack(spacing: MongleSpacing.sm) {
        
        // 1. 초대 코드 복사 버튼
        Button {
          store.send(.inviteCodeCopyTapped)
        } label: {
          MongleInviteRowView(
            title: L10n.tr("group_invite_code"),
            value: store.inviteCode.isEmpty ? L10n.tr("common_loading") : store.inviteCode,
            buttonIcon: "doc.on.doc.fill",
            buttonTitle: L10n.tr("common_copy")
          )
        }
        .buttonStyle(MongleScaleButtonStyle())
        .disabled(store.inviteCode.isEmpty)

        // 2. 초대 링크 공유 버튼
        ShareLink(
          item: AppConfig.inviteShareText(code: store.inviteCode)
        ) {
          MongleInviteRowView(
            title: L10n.tr("group_invite_link"),
            value: store.inviteCode.isEmpty ? L10n.tr("common_loading") : AppConfig.inviteLink(code: store.inviteCode),
            buttonIcon: "square.and.arrow.up.fill",
            buttonTitle: L10n.tr("common_share")
          )
        }
        .buttonStyle(MongleScaleButtonStyle())
        .disabled(store.inviteCode.isEmpty)
        
      }
      .padding(MongleSpacing.md)
      .monglePanel(background: MongleColor.cardBackground, cornerRadius: MongleRadius.large, borderColor: MongleColor.borderWarm, shadowOpacity: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  // MARK: - 공통 초대 Row 컴포넌트
  public struct MongleInviteRowView: View {
    let title: String
    let value: String
    let buttonIcon: String
    let buttonTitle: String
    
    public init(title: String, value: String, buttonIcon: String, buttonTitle: String) {
      self.title = title
      self.value = value
      self.buttonIcon = buttonIcon
      self.buttonTitle = buttonTitle
    }
    
    public var body: some View {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textSecondary)
          Text(value)
          // 링크가 길 경우를 대비해 폰트를 살짝 조정하거나, 한 줄로 제한 후 축소되도록 설정
            .font(MongleFont.body1Bold())
            .foregroundColor(MongleColor.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8) // 글자가 길면 80%까지 자동 축소
        }
        
        Spacer(minLength: 16)
        
        HStack(spacing: 4) {
          Image(systemName: buttonIcon)
            .font(.system(size: 14))
          Text(buttonTitle)
            .font(MongleFont.body2Bold())
        }
        // 기존 textHint(회색) 대신 약간 더 눌러보고 싶게 primaryDark로 통일하는 것을 추천합니다!
        .foregroundColor(MongleColor.textHint)
        .padding(.horizontal, MongleSpacing.sm)
        .padding(.vertical, 8)
        .background(Color.white)
        .clipShape(Capsule())
      }
      .padding(MongleSpacing.md)
      .background(MongleColor.primaryLight.opacity(0.15)) // 베이스 배경 통일
      .clipShape(RoundedRectangle(cornerRadius: MongleRadius.medium))
    }
  }
  
  // MARK: - Members
  
  private var membersSection: some View {
    VStack(alignment: .leading, spacing: MongleSpacing.sm) {
      sectionTitle("멤버", subtitle: "현재 이 공간에 연결된 사람들")
      
      ForEach(Array(store.members.enumerated()), id: \.element.id) { index, member in
        HStack(spacing: MongleSpacing.md) {
          MongleMonggle(color: monggleColor(for: member.moodId, fallbackIndex: index), size: 40)
          
          VStack(alignment: .leading, spacing: 2) {
            Text(member.name)
              .font(MongleFont.body2Bold())
              .foregroundColor(MongleColor.textPrimary)
            if member.isOwner {
              Text(member.subtitle)
                .font(MongleFont.captionBold())
                .foregroundColor(.white)
                .padding(.horizontal, MongleSpacing.xs)
                .padding(.vertical, 2)
                .background(MongleColor.primary)
                .clipShape(Capsule())
            } else {
              Text(member.subtitle)
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textSecondary)
            }
          }
          
          Spacer()
          
          if store.isCurrentUserOwner && !member.isOwner {
            Button {
              store.send(.kickMemberTapped(member))
            } label: {
              Text(L10n.tr("mgmt_kick_btn"))
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.error)
                .padding(.horizontal, MongleSpacing.sm)
                .padding(.vertical, MongleSpacing.xxs)
                .background(MongleColor.error.opacity(0.1))
                .clipShape(Capsule())
            }
          }
        }
        .padding(MongleSpacing.md)
        .monglePanel(background: MongleColor.cardBackground, cornerRadius: MongleRadius.large, borderColor: MongleColor.borderWarm, shadowOpacity: 0)
      }
    }
  }
  
  // MARK: - Transfer Creator View (Push)

  private var transferCreatorView: some View {
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

        ScrollView {
          VStack(spacing: MongleSpacing.sm) {
            ForEach(Array(store.transferCandidates.enumerated()), id: \.element.id) { index, member in
              HStack(spacing: MongleSpacing.md) {
                MongleMonggle(color: monggleColor(for: member.moodId, fallbackIndex: index + 1), size: 40)

                Text(member.name)
                  .font(MongleFont.body2Bold())
                  .foregroundColor(MongleColor.textPrimary)

                Spacer()

                if store.selectedTransferMemberId == member.id {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(MongleColor.primary)
                }
              }
              .padding(MongleSpacing.md)
              .background(store.selectedTransferMemberId == member.id ? MongleColor.primaryLight : MongleColor.cardBackground)
              .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
              .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.large)
                  .stroke(store.selectedTransferMemberId == member.id ? MongleColor.primary : MongleColor.borderWarm, lineWidth: 1)
              )
              .onTapGesture {
                store.send(.transferMemberSelected(member.id))
              }
            }
          }
          .padding(.horizontal, MongleSpacing.md)
        }

        Button {
          store.send(.confirmTransferAndLeave)
        } label: {
          Text(L10n.tr("mgmt_transfer_btn"))
            .font(MongleFont.body1Bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(MongleSpacing.md)
            .background(store.selectedTransferMemberId != nil ? MongleColor.error : MongleColor.textHint)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
        }
        .disabled(store.selectedTransferMemberId == nil)
        .padding(.horizontal, MongleSpacing.md)
        .padding(.bottom, MongleSpacing.md)
      }
    }
    .background(MongleColor.background)
    .toolbar(.hidden, for: .navigationBar)
  }
  
  // MARK: - Helpers
  
  private func monggleColor(for moodId: String?, fallbackIndex: Int) -> Color {
    switch moodId {
    case "happy": return MongleColor.monggleYellow
    case "calm":  return MongleColor.monggleGreen
    case "loved": return MongleColor.mongglePink
    case "sad":   return MongleColor.monggleBlue
    case "tired": return MongleColor.monggleOrange
    default:
      let colors: [Color] = [
        MongleColor.monggleYellow, MongleColor.monggleGreen,
        MongleColor.mongglePink, MongleColor.monggleBlue, MongleColor.monggleOrange
      ]
      return colors[fallbackIndex % colors.count]
    }
  }
  
  private func sectionTitle(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
        .font(MongleFont.body1Bold())
        .foregroundColor(MongleColor.textPrimary)
      Text(subtitle)
        .font(MongleFont.caption())
        .foregroundColor(MongleColor.textSecondary)
    }
  }
  
  private func invitePill(_ title: String) -> some View {
    Text(title)
      .font(MongleFont.captionBold())
      .foregroundColor(MongleColor.primaryDark)
      .padding(.horizontal, MongleSpacing.sm)
      .padding(.vertical, MongleSpacing.xxs)
      .background(MongleColor.primaryLight)
      .clipShape(Capsule())
  }
}
