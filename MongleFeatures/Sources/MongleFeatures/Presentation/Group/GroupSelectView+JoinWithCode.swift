import SwiftUI
import ComposableArchitecture

// MARK: - Join With Code Step

extension GroupSelectView {

  var joinWithCodeView: some View {
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
          Text("닉네임을 입력해주세요")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.error)
        } else {
          Text("다른 멤버에게 보여지는 이름이에요")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textHint)
        }
      }

      monggleColorPicker()
    }
  }
}
