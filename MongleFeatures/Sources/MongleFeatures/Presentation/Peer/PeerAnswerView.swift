import SwiftUI
import ComposableArchitecture

public struct PeerAnswerView: View {
    @Bindable var store: StoreOf<PeerAnswerFeature>

    public init(store: StoreOf<PeerAnswerFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MongleSpacing.lg) {
                    questionCard
                    answerCard(title: "\(store.memberName)의 답변", subtitle: store.memberName, time: store.peerAnswerTime, body: store.peerAnswer, accent: MongleColor.moodLoved)
                    answerCard(title: "나의 답변", subtitle: nil, time: store.myAnswerTime, body: store.myAnswer, accent: MongleColor.primary)

                    HStack(spacing: MongleSpacing.sm) {
                        MongleButtonSecondary("공감해요") {
                            store.send(.reactTapped)
                        }
                        MongleButtonSecondary("댓글 달기") {
                            store.send(.commentTapped)
                        }
                    }
                }
                .padding(.horizontal, MongleSpacing.md)
                .padding(.vertical, MongleSpacing.md)
            }
            .background(MongleColor.background)
            .navigationTitle("\(store.memberName)의 답변")
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

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("오늘의 질문")
                        .font(MongleFont.body2Bold())
                        .foregroundColor(MongleColor.primary)
                    Text("같은 질문에 대한 서로의 답변을 비교해보세요")
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textSecondary)
                }

                Spacer()

                Text("답변 비교")
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.primary)
                    .padding(.horizontal, MongleSpacing.sm)
                    .padding(.vertical, MongleSpacing.xxs)
                    .background(MongleColor.primaryLight)
                    .clipShape(Capsule())
            }

            Text(store.questionText)
                .font(MongleFont.heading3())
                .foregroundColor(MongleColor.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MongleSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 148, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFF6E9"), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .monglePanel(background: .clear, cornerRadius: MongleRadius.xl, borderColor: Color(hex: "F4E4D7"), shadowOpacity: 0.04)
    }

    private func answerCard(title: String, subtitle: String?, time: String, body: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            HStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(accent)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MongleFont.body2Bold())
                        .foregroundColor(MongleColor.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textSecondary)
                    }
                }

                Spacer()

                Text(time)
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }

            Text(body)
                .font(MongleFont.body1())
                .foregroundColor(MongleColor.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MongleSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 164, alignment: .topLeading)
        .monglePanel(cornerRadius: MongleRadius.large, shadowOpacity: 0.02)
    }
}
