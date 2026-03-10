import SwiftUI
import ComposableArchitecture

public struct PeerNudgeView: View {
    @Bindable var store: StoreOf<PeerNudgeFeature>

    public init(store: StoreOf<PeerNudgeFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MongleSpacing.lg) {
                    statusCard
                    nudgeCard
                }
                .padding(.horizontal, MongleSpacing.md)
                .padding(.vertical, MongleSpacing.md)
            }
            .background(MongleColor.background)
            .navigationTitle("답변 재촉하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.closeTapped)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .foregroundColor(MongleColor.textSecondary)
                }
            }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("아직 답변하지 않았어요")
                        .font(MongleFont.heading3())
                        .foregroundColor(MongleColor.textPrimary)
                    Text("답변이 올라오면 여기서 바로 확인할 수 있어요")
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textSecondary)
                }

                Spacer()

                Text("대기 중")
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.accentOrange)
                    .padding(.horizontal, MongleSpacing.sm)
                    .padding(.vertical, MongleSpacing.xxs)
                    .background(Color(hex: "FFF1DE"))
                    .clipShape(Capsule())
            }

            Text("\(store.memberName)이 오늘의 질문에 답변하면\n여기서 바로 확인할 수 있어요.")
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
        }
        .padding(MongleSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 148, alignment: .topLeading)
        .monglePanel(background: Color(hex: "FFF7F2"), cornerRadius: MongleRadius.xl, borderColor: Color(hex: "F4E4D7"), shadowOpacity: 0.03)
    }

    private var nudgeCard: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.md) {
            Text("💌 답변을 재촉해볼까요?")
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)

            Text("\(store.memberName)에게 알림을 보내 답변을 재촉할 수 있어요.\n하트 1개가 소모됩니다.")
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textSecondary)
                .lineSpacing(3)

            HStack {
                Text("보유 하트: \(store.hearts)개")
                    .font(MongleFont.body2Bold())
                    .foregroundColor(MongleColor.textPrimary)

                Spacer()

                Text(store.isSent ? "전송 완료" : "-1")
                    .font(MongleFont.captionBold())
                    .foregroundColor(store.isSent ? MongleColor.primary : MongleColor.heartRed)
                    .padding(.horizontal, MongleSpacing.sm)
                    .padding(.vertical, MongleSpacing.xxs)
                    .background(store.isSent ? MongleColor.primaryLight : MongleColor.heartRedLight)
                    .clipShape(Capsule())
            }

            MongleButtonPrimary(store.isSent ? "재촉 완료" : "재촉하기 💌") {
                store.send(.nudgeTapped)
            }
            .disabled(store.isSent || store.hearts <= 0)
            .opacity((store.isSent || store.hearts <= 0) ? 0.6 : 1)
        }
        .padding(MongleSpacing.lg)
        .frame(minHeight: 210, alignment: .topLeading)
        .monglePanel(cornerRadius: MongleRadius.xl, shadowOpacity: 0.03)
    }
}
