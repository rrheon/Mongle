import SwiftUI
import ComposableArchitecture

// MARK: - Join With Code Step

extension GroupSelectView {

  var joinWithCodeView: some View {
    VStack(spacing: MongleSpacing.lg) {
      MongleLogo(size: .large, type: .MongleLogo)

      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text(L10n.tr("group_join_headline"))
          .font(MongleFont.heading2())
          .foregroundColor(MongleColor.textPrimary)

        Text(L10n.tr("group_join_subtitle"))
          .font(MongleFont.body2())
          .foregroundColor(MongleColor.textSecondary)
          .lineSpacing(3)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // 초대 코드 필드
      VStack(alignment: .leading, spacing: MongleSpacing.xs) {
        Text(L10n.tr("group_code_label"))
          .font(MongleFont.captionBold())
          .foregroundColor(MongleColor.textSecondary)

        HStack(spacing: MongleSpacing.sm) {
          Image(systemName: "key")
            .font(.system(size: 16))
            .foregroundColor(MongleColor.textHint)
          TextField("MONG-4729", text: $store.joinCode.sending(\.joinCodeChanged))
            .font(MongleFont.body2())
            .foregroundColor(MongleColor.textPrimary)
            .textCase(.uppercase)
            .autocorrectionDisabled()
            .focused($joinGroupFocus, equals: .joinCode)
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(
          RoundedRectangle(cornerRadius: MongleRadius.large)
            .stroke(
              store.joinCodeError ? MongleColor.error
                : joinGroupFocus == .joinCode ? MongleColor.primary
                : MongleColor.border,
              lineWidth: joinGroupFocus == .joinCode ? 1.5 : 1
            )
        )

        if store.joinCodeError {
          Text(L10n.tr("group_code_placeholder"))
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.error)
        } else {
          Text(L10n.tr("group_code_hint"))
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
            .focused($joinGroupFocus, equals: .nickname)
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(
          RoundedRectangle(cornerRadius: MongleRadius.large)
            .stroke(
              store.nicknameError ? MongleColor.error
                : joinGroupFocus == .nickname ? MongleColor.primary
                : MongleColor.border,
              lineWidth: joinGroupFocus == .nickname ? 1.5 : 1
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
}
