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
      MongleButtonPrimary("다음") {
        store.send(.createNextTapped)
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
            Text("공유하기")
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

        MongleButtonPrimary("홈으로 가기") {
          store.send(.completeTapped)
        }
      }
      .padding(.horizontal, MongleSpacing.md)
      .padding(.top, MongleSpacing.sm)
      .padding(.bottom, MongleSpacing.lg)
      .background(MongleColor.background)

    case .joinWithCode:
      MongleButtonPrimary("참여하기") {
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
    if store.step == .select {
      HStack(spacing: 12) {
        Text("몽글")
          .font(MongleFont.heading3().weight(.bold))
          .foregroundColor(MongleColor.textPrimary)

        Spacer()

        Button {
          store.send(.notificationTapped)
        } label: {
          ZStack(alignment: .topTrailing) {
            Image(systemName: "bell.fill")
              .font(.system(size: 13))
              .foregroundColor(MongleColor.primary)
              .padding(.vertical, 6)
              .padding(.horizontal, 10)
              .background(MongleColor.primaryLight)
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
      .frame(height: 56)
      .padding(.top, 20)
      .padding(.horizontal, 20)
      .background(Color.white.ignoresSafeArea(edges: .top))
    } else {
      HStack(alignment: .center) {
        if store.step != .groupCreated {
          Button {
            switch store.step {
            case .createGroup: store.send(.createBackTapped)
            case .joinWithCode: store.send(.joinBackTapped)
            default: break
            }
          } label: {
            Image(systemName: "chevron.left")
              .font(.system(size: 18, weight: .medium))
              .foregroundColor(MongleColor.textPrimary)
              .frame(width: 44, height: 44)
          }
          .buttonStyle(MongleScaleButtonStyle())
        } else {
          Color.clear.frame(width: 28, height: 28)
        }
        Spacer()
        Text(navigationTitle)
          .font(MongleFont.body2Bold())
          .foregroundColor(MongleColor.textPrimary)
        Spacer()
        Color.clear.frame(width: 28, height: 28)
      }
      .padding(.horizontal, MongleSpacing.md)
      .padding(.vertical, MongleSpacing.md)
      .background(MongleColor.background)
    }
  }

  var navigationTitle: String {
    switch store.step {
    case .select:       return ""
    case .createGroup:  return "새 공간 만들기"
    case .groupCreated: return "새 공간 만들기"
    case .joinWithCode: return "초대코드로 참여하기"
    }
  }
}

#Preview("Group Select") {
  GroupSelectView(
    store: Store(initialState: GroupSelectFeature.State()) {
      GroupSelectFeature()
    }
  )
}
