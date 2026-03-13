import SwiftUI
import UIKit
import ComposableArchitecture

// MARK: - Group Display Model

struct GroupInfo: Identifiable {
  let id: UUID
  let name: String
  let memberColors: [Color]
  let streakDays: Int
}

// MARK: - GroupSelectView

/// 몽글 그룹 선택 View
public struct GroupSelectView: View {
  @Bindable var store: StoreOf<GroupSelectFeature>
  @State private var codeCopied = false
  @State private var linkCopied = false
  // 임시 샘플 데이터 (추후 서버 연동 시 state에서 받아올 예정)
  private let groups: [GroupInfo] = [
    GroupInfo(
      id: UUID(),
      name: "Kim Family",
      memberColors: [
        MongleColor.monggleGreen,
        MongleColor.monggleYellow,
        MongleColor.monggleBlue,
        MongleColor.mongglePink,
        MongleColor.monggleOrange
      ],
      streakDays: 12
    ),
    GroupInfo(
      id: UUID(),
      name: "절친 모임",
      memberColors: [
        MongleColor.monggleGreen,
        MongleColor.monggleYellow,
        MongleColor.monggleBlue
      ],
      streakDays: 7
    )
  ]

  public init(store: StoreOf<GroupSelectFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack {
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
    }
    .sheet(isPresented: Binding(
      get: { store.showActionSheet },
      set: { if !$0 { store.send(.actionSheetDismissed) } }
    )) {
      actionSheetContent
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.visible)
    }
  }

  // MARK: - Bottom Button Bar

  @ViewBuilder
  private var bottomButtonBar: some View {
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

  private var customHeader: some View {
    HStack(alignment: .center) {
      if store.step == .select {
//        Text("내 몽글 공간")
//          .font(MongleFont.heading1())
//          .foregroundColor(MongleColor.textPrimary)
        Image("MongleTitleWithLogo_ko", bundle: .module)
          .resizable()
          .scaledToFit()
          .frame(height: 38)
        
        Spacer()
        Button {
          store.send(.notificationTapped)
        } label: {
          ZStack(alignment: .topTrailing) {
            Image(systemName: "bell")
              .font(.system(size: 20))
              .foregroundColor(MongleColor.textPrimary)
            Circle()
              .fill(Color.red)
              .frame(width: 8, height: 8)
              .offset(x: 2, y: -2)
          }
        }
      } else {
        Button {
          switch store.step {
          case .createGroup: store.send(.createBackTapped)
          case .groupCreated: store.send(.createBackTapped)
          case .joinWithCode:   store.send(.joinBackTapped)
          default: break
          }
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(MongleColor.textPrimary)
        }
        Spacer()
        Text(navigationTitle)
          .font(MongleFont.body2Bold())
          .foregroundColor(MongleColor.textPrimary)
        Spacer()
        // trailing spacer for center alignment
        Color.clear.frame(width: 28, height: 28)
      }
    }
    .padding(.horizontal, MongleSpacing.md)
    .padding(.vertical, MongleSpacing.md)
    .background(MongleColor.background)
  }

  private var navigationTitle: String {
    switch store.step {
    case .select:      return ""
    case .createGroup: return "새 공간 만들기"
    case .groupCreated: return "새 공간 만들기"
    case .joinWithCode:   return "초대코드로 참여하기"
    }
  }

  // MARK: - Select View

  private var selectView: some View {
    VStack(alignment: .leading, spacing: MongleSpacing.lg) {
      VStack(spacing: MongleSpacing.md) {
        ForEach(groups) { group in
          MongleCardGroup(
            groupName: group.name,
            memberColors: group.memberColors,
            streakDays: group.streakDays
          )
        }
      }

      newSpaceButton
    }
  }

  private var newSpaceButton: some View {
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

  // MARK: - Action Sheet (Bottom Sheet)

  private var actionSheetContent: some View {
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

  private func actionSheetRow(
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

  // MARK: - 새로운 그룹 만들기

  private var createGroupView: some View {
    VStack(spacing: MongleSpacing.lg) {
      // 프로세스 진행 UI
      HStack(spacing: MongleSpacing.xs) {
        Capsule()
          .fill(MongleColor.moodCalm)
          .frame(height: 4)
        Capsule()
          .fill(MongleColor.moodCalm.opacity(0.3))
          .frame(height: 4)
      }
      .padding(.bottom, MongleSpacing.sm)

      // 몽글 로고
      MongleLogo(size: .large, type: .MongleLogo)

      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text("우리만의 몽글 공간을 만들어요")
          .font(MongleFont.heading2())
          .foregroundColor(MongleColor.textPrimary)
        Text("가족이나 친구와 함께 마음을 나눠보세요")
          .font(MongleFont.body2())
          .foregroundColor(MongleColor.textSecondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // 공간 이름 필드
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text("공간 이름")
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.textSecondary)

        HStack(spacing: MongleSpacing.sm) {
          Image(systemName: "house")
            .font(.system(size: 16))
            .foregroundColor(MongleColor.textHint)
          TextField("김씨네 가족", text: $store.groupName.sending(\.groupNameChanged))
            .font(MongleFont.body2())
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(
          RoundedRectangle(cornerRadius: MongleRadius.large)
            .stroke(store.groupNameError ? MongleColor.error : MongleColor.border, lineWidth: 1)
        )

        if store.groupNameError {
          Text("공간 이름을 입력해주세요")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.error)
        } else {
          Text("가족, 친한 친구, 커플 등 자유롭게!")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textHint)
        }
      }

      // 닉네임 필드
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text("내 닉네임")
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.textSecondary)

        HStack(spacing: MongleSpacing.sm) {
          Image(systemName: "person")
            .font(.system(size: 16))
            .foregroundColor(MongleColor.textHint)
          TextField("엄마", text: $store.nickname.sending(\.nicknameChanged))
            .font(MongleFont.body2())
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(
          RoundedRectangle(cornerRadius: MongleRadius.large)
            .stroke(store.nicknameError ? MongleColor.error : MongleColor.border, lineWidth: 1)
        )

        if store.nicknameError {
          Text("닉네임을 입력해주세요")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.error)
        } else {
          Text("다른 멤버에게 보여지는 이름이에요")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textHint)
        }
      }
    }
  }

  // MARK: - 초대코드로 참여하기

  private var inviteLink: String {
    "https://monggle.app/join/\(store.inviteCode.lowercased())"
  }

  private var shareText: String {
    "몽글에서 함께해요! 🌿\n초대코드: \(store.inviteCode)\n링크: \(inviteLink)"
  }

  private var groupCreatedView: some View {
    VStack(alignment: .leading, spacing: MongleSpacing.lg) {
      // 프로세스 진행 UI
      HStack(spacing: MongleSpacing.xs) {
        Capsule()
          .fill(MongleColor.moodCalm)
          .frame(height: 4)
        Capsule()
          .fill(MongleColor.moodCalm)
          .frame(height: 4)
      }
      .padding(.bottom, MongleSpacing.sm)

      // 공간이 만들어졌다는 문구
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text("공간이 만들어졌어요! 🎉")
          .font(MongleFont.heading2())
          .foregroundColor(MongleColor.textPrimary)
        Text("아래 코드나 링크로 친구를 초대해보세요")
          .font(MongleFont.body2())
          .foregroundColor(MongleColor.textSecondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // 초대코드 카드
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text("초대 코드")
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.textSecondary)

        HStack {
          Text(store.inviteCode)
            .font(MongleFont.heading3())
            .foregroundColor(MongleColor.primary)

          Spacer()

          Button {
            UIPasteboard.general.string = store.inviteCode
            codeCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { codeCopied = false }
          } label: {
            Label(codeCopied ? "복사됨" : "복사", systemImage: codeCopied ? "checkmark" : "doc.on.doc")
              .font(MongleFont.captionBold())
              .foregroundColor(codeCopied ? MongleColor.success : MongleColor.primary)
              .padding(.horizontal, MongleSpacing.sm)
              .padding(.vertical, MongleSpacing.xxs)
              .background(codeCopied ? MongleColor.success.opacity(0.12) : MongleColor.primaryLight)
              .clipShape(Capsule())
          }
          .animation(.easeInOut(duration: 0.2), value: codeCopied)
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.large).stroke(MongleColor.border, lineWidth: 1))
      }

      // 초대 링크
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text("초대 링크")
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.textSecondary)

        HStack {
          Text(inviteLink)
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textPrimary)
            .lineLimit(1)
            .truncationMode(.middle)

          Spacer()

          Button {
            UIPasteboard.general.string = inviteLink
            linkCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { linkCopied = false }
          } label: {
            Label(linkCopied ? "복사됨" : "복사", systemImage: linkCopied ? "checkmark" : "doc.on.doc")
              .font(MongleFont.captionBold())
              .foregroundColor(linkCopied ? MongleColor.success : MongleColor.primary)
              .padding(.horizontal, MongleSpacing.sm)
              .padding(.vertical, MongleSpacing.xxs)
              .background(linkCopied ? MongleColor.success.opacity(0.12) : MongleColor.primaryLight)
              .clipShape(Capsule())
          }
          .animation(.easeInOut(duration: 0.2), value: linkCopied)
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.large).stroke(MongleColor.border, lineWidth: 1))
      }
    }
  }

  // MARK: - Join With Code

  private var joinWithCodeView: some View {
    VStack(spacing: MongleSpacing.lg) {
      MongleLogo(size: .large, type: .MongleLogo)

      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text("초대코드를 입력해주세요.")
          .font(MongleFont.heading2())
          .foregroundColor(MongleColor.textPrimary)

        Text("친구나 가족에게 받은 코드를 입력하면\n함께 공간에 참여할 수 있어요")
          .font(MongleFont.body2())
          .foregroundColor(MongleColor.textSecondary)
          .lineSpacing(3)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // 초대 코드 필드
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text("초대 코드")
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.textSecondary)

        HStack(spacing: MongleSpacing.sm) {
          Image(systemName: "key")
            .font(.system(size: 16))
            .foregroundColor(MongleColor.textHint)
          TextField("MONG-4729", text: $store.joinCode.sending(\.joinCodeChanged))
            .font(MongleFont.body2())
            .textCase(.uppercase)
            .autocorrectionDisabled()
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(
          RoundedRectangle(cornerRadius: MongleRadius.large)
            .stroke(store.joinCodeError ? MongleColor.error : MongleColor.border, lineWidth: 1)
        )

        if store.joinCodeError {
          Text("초대 코드를 입력해주세요")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.error)
        } else {
          Text("대문자와 숫자로 이루어진 코드에요")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textHint)
        }
      }

      // 닉네임 필드
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text("내 닉네임")
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.textSecondary)

        HStack(spacing: MongleSpacing.sm) {
          Image(systemName: "person")
            .font(.system(size: 16))
            .foregroundColor(MongleColor.textHint)
          TextField("엄마", text: $store.nickname.sending(\.nicknameChanged))
            .font(MongleFont.body2())
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(
          RoundedRectangle(cornerRadius: MongleRadius.large)
            .stroke(store.nicknameError ? MongleColor.error : MongleColor.border, lineWidth: 1)
        )

        if store.nicknameError {
          Text("닉네임을 입력해주세요")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.error)
        } else {
          Text("다른 멤버에게 보여지는 이름이에요")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textHint)
        }
      }
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
