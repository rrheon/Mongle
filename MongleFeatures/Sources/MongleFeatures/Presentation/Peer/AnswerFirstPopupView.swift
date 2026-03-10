import SwiftUI
import ComposableArchitecture

public struct AnswerFirstPopupView: View {
    @Bindable var store: StoreOf<AnswerFirstPopupFeature>

    public init(store: StoreOf<AnswerFirstPopupFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: MongleSpacing.lg) {
                Circle()
                    .fill(Color(hex: "FFF1DE"))
                    .frame(width: 92, height: 92)
                    .overlay(
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(MongleColor.accentOrange)
                    )

                VStack(spacing: MongleSpacing.sm) {
                    Text("아직 오늘 답변을 안 했어요!")
                        .font(MongleFont.heading3())
                        .foregroundColor(MongleColor.textPrimary)

                    Text("\(store.memberName)의 답변을 보려면\n먼저 오늘의 질문에 답해주세요 🌿")
                        .font(MongleFont.body2())
                        .foregroundColor(MongleColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    Text("답변을 남기면 가족의 마음도 바로 열려요.")
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textHint)
                }

                VStack(spacing: MongleSpacing.sm) {
                    MongleButtonPrimary("답변하러 가기") {
                        store.send(.answerNowTapped)
                    }

                    Button("나중에 할게요") {
                        store.send(.laterTapped)
                    }
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textHint)
                }
            }
            .padding(MongleSpacing.lg)
            .frame(maxWidth: 344)
            .monglePanel(cornerRadius: MongleRadius.xl, shadowOpacity: 0.08)
            .padding(.horizontal, MongleSpacing.lg)
        }
    }
}
