import SwiftUI
import ComposableArchitecture

// MARK: - Create Group Step

extension GroupSelectView {

  static let colorOptions: [(id: String, color: Color, label: String)] = [
    ("calm",  MongleColor.monggleGreen,  L10n.tr("group_color_green")),
    ("happy", MongleColor.monggleYellow, L10n.tr("group_color_yellow")),
    ("loved", MongleColor.mongglePink,   L10n.tr("group_color_pink")),
    ("sad",   MongleColor.monggleBlue,   L10n.tr("group_color_blue")),
    ("tired", MongleColor.monggleOrange, L10n.tr("group_color_orange")),
  ]

  // MARK: - Create Group View

  var createGroupView: some View {
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

      MongleLogo(size: .large, type: .MongleLogo)

      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text(L10n.tr("group_create_headline"))
          .font(MongleFont.heading2())
          .foregroundColor(MongleColor.textPrimary)
        Text(L10n.tr("group_create_subtitle"))
          .font(MongleFont.body2())
          .foregroundColor(MongleColor.textSecondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // 공간 이름 필드
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        HStack {
          Text(L10n.tr("group_name_label"))
            .font(MongleFont.captionBold())
            .foregroundColor(MongleColor.textSecondary)
          Spacer()
          Text("\(store.groupName.count)/10")
            .font(MongleFont.caption())
            .foregroundColor(store.groupName.count >= 10 ? MongleColor.error : MongleColor.textHint)
        }

        HStack(spacing: MongleSpacing.sm) {
          Image(systemName: "house")
            .font(.system(size: 16))
            .foregroundColor(MongleColor.textHint)
          TextField(L10n.tr("group_name_placeholder"), text: $store.groupName.sending(\.groupNameChanged))
            .font(MongleFont.body2())
            .foregroundColor(MongleColor.textPrimary)
            .focused($createGroupFocus, equals: .groupName)
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(
          RoundedRectangle(cornerRadius: MongleRadius.large)
            .stroke(
              store.groupNameError ? MongleColor.error
                : createGroupFocus == .groupName ? MongleColor.primary
                : MongleColor.border,
              lineWidth: createGroupFocus == .groupName ? 1.5 : 1
            )
        )

        if store.groupNameError {
          Text(L10n.tr("group_name_error"))
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.error)
        } else {
          Text(L10n.tr("group_name_hint"))
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textHint)
        }
      }

      // 닉네임 필드
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text(L10n.tr("group_nickname_label"))
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.textSecondary)

        HStack(spacing: MongleSpacing.sm) {
          Image(systemName: "person")
            .font(.system(size: 16))
            .foregroundColor(MongleColor.textHint)
          TextField(L10n.tr("group_nickname_placeholder"), text: $store.nickname.sending(\.nicknameChanged))
            .font(MongleFont.body2())
            .foregroundColor(MongleColor.textPrimary)
            .focused($createGroupFocus, equals: .nickname)
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(
          RoundedRectangle(cornerRadius: MongleRadius.large)
            .stroke(
              store.nicknameError ? MongleColor.error
                : createGroupFocus == .nickname ? MongleColor.primary
                : MongleColor.border,
              lineWidth: createGroupFocus == .nickname ? 1.5 : 1
            )
        )

        if store.nicknameError {
          Text(L10n.tr("group_nickname_error"))
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.error)
        } else {
          Text(L10n.tr("group_nickname_hint"))
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textHint)
        }
      }

      monggleColorPicker()
    }
  }

  // MARK: - Color Picker (공유)

  @ViewBuilder
  func monggleColorPicker() -> some View {
    VStack(alignment: .leading, spacing: MongleSpacing.xs) {
      Text(L10n.tr("group_color_label"))
        .font(MongleFont.captionBold())
        .foregroundColor(MongleColor.textSecondary)

      HStack(spacing: MongleSpacing.md) {
        ForEach(Self.colorOptions, id: \.id) { option in
          let isSelected = store.selectedColorId == option.id
          Button {
            store.send(.colorChanged(option.id))
          } label: {
            MongleMonggle(color: option.color, size: 48)
              .padding(4)
              .background(
                Circle()
                  .stroke(isSelected ? option.color : Color.clear, lineWidth: 3)
                  .frame(width: 60, height: 60)
              )
              .scaleEffect(isSelected ? 1.1 : 1.0)
              .animation(.easeInOut(duration: 0.15), value: isSelected)
          }
          .buttonStyle(.plain)
        }
        Spacer()
      }

      Text(L10n.tr("group_color_hint"))
        .font(MongleFont.caption())
        .foregroundColor(MongleColor.textHint)
    }
  }
}
