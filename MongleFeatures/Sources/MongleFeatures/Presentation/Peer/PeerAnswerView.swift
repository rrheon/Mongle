import SwiftUI
import ComposableArchitecture

struct PeerAnswerContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

public struct PeerAnswerView: View {
    @Bindable var store: StoreOf<PeerAnswerFeature>

    public init(store: StoreOf<PeerAnswerFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            dragHandle
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    questionCard
                    VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                        peerInfoRow
                        answerCard
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(MongleColor.border, lineWidth: 1)
                    )

                }
                .padding(.top, MongleSpacing.sm)
                .padding(.horizontal, 20)
                .padding(.bottom, MongleSpacing.xl)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: PeerAnswerContentHeightKey.self,
                            value: geo.size.height
                        )
                    }
                )
            }
        }
        .background(MongleColor.cardBackgroundSolid)
    }

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: MongleRadius.full)
            .fill(MongleColor.border)
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, MongleSpacing.sm)
    }

    private var header: some View {
        HStack {
            Spacer()
            Button {
                store.send(.closeTapped)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MongleColor.textHint)
                    .padding(MongleSpacing.sm)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
    }

  // MARK: 오늘의 질문 카드

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            Text("오늘의 질문")
                .font(MongleFont.body2Bold())
                .foregroundColor(MongleColor.primary)
            Text(store.questionText)
                .font(MongleFont.button())
                .foregroundColor(MongleColor.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MongleColor.primary, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
    }

  // MARK: 몽글 캐릭터 섹션

    private var peerInfoRow: some View {
        HStack(spacing: MongleSpacing.sm) {
            MongleMonggle(color: store.monggleColor, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(store.memberName)
                    .font(MongleFont.button())
                    .foregroundColor(MongleColor.textPrimary)
                Text(store.peerAnswerTime)
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

  // MARK: 답변카드

    private var answerCard: some View {
        Text(store.peerAnswer)
            .font(MongleFont.body2())
            .foregroundColor(MongleColor.textSecondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(MongleSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MongleColor.cardGlass)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.xl))
    }
}
