import SwiftUI
import ComposableArchitecture

// MARK: - Create Group Step

extension GroupSelectView {

  static let colorOptions: [(id: String, color: Color, label: String)] = [
    ("calm",  MongleColor.monggleGreen,  "초록"),
    ("happy", MongleColor.monggleYellow, "노랑"),
    ("loved", MongleColor.mongglePink,   "분홍"),
    ("sad",   MongleColor.monggleBlue,   "파랑"),
    ("tired", MongleColor.monggleOrange, "주황"),
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
        HStack {
          Text("공간 이름")
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
          TextField("김씨네 가족", text: $store.groupName.sending(\.groupNameChanged))
            .font(MongleFont.body2())
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
          Text("공간 이름을 입력해주세요")
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.error)
        } else {
          Text("가족, 친한 친구, 커플 등 자유롭게! (최대 10자)")
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

  // MARK: - Color Picker (공유)

  @ViewBuilder
  func monggleColorPicker() -> some View {
    VStack(alignment: .leading, spacing: MongleSpacing.xs) {
      Text("내 몽글 색상")
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

      Text("다른 멤버에게 보여지는 몽글 캐릭터 색상이에요")
        .font(MongleFont.caption())
        .foregroundColor(MongleColor.textHint)
    }
  }
}
