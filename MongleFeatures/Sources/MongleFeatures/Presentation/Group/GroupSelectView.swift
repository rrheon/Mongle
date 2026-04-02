import SwiftUI
import UIKit
import ComposableArchitecture
import Domain

// MARK: - GroupSelectView

/// 몽글 그룹 선택 View
public struct GroupSelectView: View {
  @Bindable var store: StoreOf<GroupSelectFeature>
  @State var codeCopied = false
  @State var linkCopied = false

  @FocusState var createGroupFocus: CreateGroupFocusField?
  @FocusState var joinGroupFocus: JoinGroupFocusField?

  public init(store: StoreOf<GroupSelectFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      VStack(spacing: 0) {
        customHeader

        ScrollView(showsIndicators: false) {
          VStack(alignment: .leading, spacing: MongleSpacing.lg) {
            switch store.step {
            case .select:
              selectView
            case .createGroup:
              createGroupView
            case .notificationPermission:
              notificationPermissionView
            case .quietHoursPermission:
              quietHoursPermissionView
            case .groupCreated:
              groupCreatedView
            case .joinWithCode:
              joinWithCodeView
            }
          }
          .padding(.horizontal, MongleSpacing.md)
          .padding(.top, MongleSpacing.md)
          .padding(.bottom, MongleSpacing.sm)
        }
        .scrollDismissesKeyboard(.immediately)

        bottomButtonBar
      }
      .background(MongleColor.background)
      .toolbar(.hidden, for: .navigationBar)
      .mongleErrorToast(
        error: store.appError,
        onDismiss: { store.send(.dismissError) }
      )
    } destination: { store in
      switch store.case {
      case let .notification(notificationStore):
        NotificationView(store: notificationStore)
          .navigationBarBackButtonHidden(true)
      }
    }
    .sheet(isPresented: Binding(
      get: { store.showActionSheet },
      set: { if !$0 { store.send(.actionSheetDismissed) } }
    )) {
      actionSheetContent
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.visible)
    }
    .overlay(alignment: .bottom) {
      if store.showGroupLeftToast {
        MongleToastView(type: .groupLeft)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .padding(.bottom, MongleSpacing.lg)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: store.showGroupLeftToast)
    .task(id: store.showGroupLeftToast) {
      guard store.showGroupLeftToast else { return }
      try? await Task.sleep(for: .seconds(2))
      store.send(.groupLeftToastDismissed)
    }
    .overlay(alignment: .bottom) {
      if store.showAlreadyMemberToast {
        MongleToastView(type: .alreadyMember)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .padding(.bottom, MongleSpacing.lg)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: store.showAlreadyMemberToast)
    .task(id: store.showAlreadyMemberToast) {
      guard store.showAlreadyMemberToast else { return }
      try? await Task.sleep(for: .seconds(2))
      store.send(.alreadyMemberToastDismissed)
    }
    .overlay(alignment: .bottom) {
      if store.showInvalidCodeToast {
        MongleToastView(type: .invalidInviteCode)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .padding(.bottom, MongleSpacing.lg)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: store.showInvalidCodeToast)
    .task(id: store.showInvalidCodeToast) {
      guard store.showInvalidCodeToast else { return }
      try? await Task.sleep(for: .seconds(2))
      store.send(.invalidCodeToastDismissed)
    }
    .overlay(alignment: .bottom) {
      if store.showMaxGroupsToast {
        MongleToastView(type: .maxGroupsReached)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .padding(.bottom, MongleSpacing.lg)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: store.showMaxGroupsToast)
    .task(id: store.showMaxGroupsToast) {
      guard store.showMaxGroupsToast else { return }
      try? await Task.sleep(for: .seconds(2))
      store.send(.maxGroupsToastDismissed)
    }
    .onChange(of: store.createGroupFocusField) { _, newValue in
      guard let field = newValue else { return }
      switch field {
      case .groupName: createGroupFocus = .groupName
      case .nickname:  createGroupFocus = .nickname
      }
      store.send(.createGroupFocusFieldHandled)
    }
    .onChange(of: store.joinGroupFocusField) { _, newValue in
      guard let field = newValue else { return }
      switch field {
      case .joinCode: joinGroupFocus = .joinCode
      case .nickname: joinGroupFocus = .nickname
      }
      store.send(.joinGroupFocusFieldHandled)
    }
  }

  // MARK: - Bottom Button Bar

  @ViewBuilder
  var bottomButtonBar: some View {
    switch store.step {
    case .createGroup:
      MongleButtonPrimary(L10n.tr("common_next")) {
        store.send(.createNextTapped)
      }
      .padding(.horizontal, MongleSpacing.md)
      .padding(.top, MongleSpacing.sm)
      .padding(.bottom, MongleSpacing.lg)
      .background(MongleColor.background)

    case .notificationPermission:
      VStack(spacing: MongleSpacing.sm) {
        MongleButtonPrimary(L10n.tr("perm_notif_allow")) {
          store.send(.notificationPermissionAllowed)
        }
        Button(L10n.tr("perm_notif_later")) {
          store.send(.notificationPermissionSkipped)
        }
        .frame(height: 44)
        .font(MongleFont.body2())
        .foregroundColor(MongleColor.textSecondary)
      }
      .padding(.horizontal, MongleSpacing.md)
      .padding(.top, MongleSpacing.sm)
      .padding(.bottom, MongleSpacing.lg)
      .background(MongleColor.background)

    case .quietHoursPermission:
      VStack(spacing: MongleSpacing.sm) {
        MongleButtonPrimary(L10n.tr("perm_dnd_use")) {
          store.send(.quietHoursPermissionEnabled)
        }
        Button(L10n.tr("perm_dnd_skip")) {
          store.send(.quietHoursPermissionSkipped)
        }
        .frame(height: 44)
        .font(MongleFont.body2())
        .foregroundColor(MongleColor.textSecondary)
      }
      .padding(.horizontal, MongleSpacing.md)
      .padding(.top, MongleSpacing.sm)
      .padding(.bottom, MongleSpacing.lg)
      .background(MongleColor.background)

    case .groupCreated:
      VStack(spacing: MongleSpacing.sm) {
        ShareLink(item: shareText) {
          HStack(spacing: MongleSpacing.xs) {
            Image(systemName: "square.and.arrow.up")
            Text(L10n.tr("common_share"))
          }
          .font(MongleFont.button())
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .foregroundColor(MongleColor.primary)
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: MongleRadius.full))
          .overlay(
            RoundedRectangle(cornerRadius: MongleRadius.full)
              .stroke(MongleColor.primary, lineWidth: 1.2)
          )
        }

        MongleButtonPrimary(L10n.tr("group_go_home")) {
          store.send(.completeTapped)
        }
      }
      .padding(.horizontal, MongleSpacing.md)
      .padding(.top, MongleSpacing.sm)
      .padding(.bottom, MongleSpacing.lg)
      .background(MongleColor.background)

    case .joinWithCode:
      MongleButtonPrimary(L10n.tr("group_join_btn")) {
        store.send(.joinTapped)
      }
      .padding(.horizontal, MongleSpacing.md)
      .padding(.top, MongleSpacing.sm)
      .padding(.bottom, MongleSpacing.lg)
      .background(MongleColor.background)

    case .select:
      EmptyView()
    }
  }

  // MARK: - Custom Header

  @ViewBuilder
  var customHeader: some View {
    switch store.step {
    case .select:
      MongleNavigationHeader(
          left: {
            Text(L10n.tr("app_name"))
                .font(MongleFont.heading3())
                .foregroundColor(MongleColor.textPrimary)
                .padding(.horizontal)
                .disabled(true)
          },
          right: {
            notificationButton
              .padding(.horizontal)
          }
      )

    case .createGroup:
      MongleNavigationHeader(title: L10n.tr("group_create_title")) {
        MongleBackButton { store.send(.createBackTapped) }
      } right: {
        EmptyView()
      }

    case .joinWithCode:
      MongleNavigationHeader(title: L10n.tr("group_join_title")) {
        MongleBackButton { store.send(.joinBackTapped) }
      } right: {
        EmptyView()
      }

    case .groupCreated:
      MongleNavigationHeader(title: L10n.tr("group_create_title")) {
        EmptyView()
      } right: {
        EmptyView()
      }

    case .notificationPermission:
      MongleNavigationHeader(title: L10n.tr("notif_settings_title")) {
        EmptyView()
      } right: {
        EmptyView()
      }

    case .quietHoursPermission:
      MongleNavigationHeader(title: L10n.tr("notif_settings_dnd")) {
        EmptyView()
      } right: {
        EmptyView()
      }
    }
  }

  private var notificationButton: some View {
    Button {
      store.send(.notificationTapped)
    } label: {
      ZStack(alignment: .topTrailing) {
        Image(systemName: "bell.fill")
          .font(.system(size: 13))
          .foregroundColor(MongleColor.primary)
          .padding(.vertical, 6)
          .padding(.horizontal, 10)
          .background(MongleColor.bgNeutral)
          .clipShape(Capsule())

        if store.hasUnreadNotifications {
          Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
            .offset(x: -2, y: 2)
        }
      }
    }
    .buttonStyle(.plain)
  }
}

#Preview("Group Select") {
  GroupSelectView(
    store: Store(initialState: GroupSelectFeature.State()) {
      GroupSelectFeature()
    }
  )
}
