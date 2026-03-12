import SwiftUI
import ComposableArchitecture

struct QuestionSheetContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - 03-A · Home (Question Sheet)

public struct QuestionSheetView: View {
    @Bindable var store: StoreOf<QuestionSheetFeature>

    public init(store: StoreOf<QuestionSheetFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            dragHandle
            VStack(alignment: .leading, spacing: MongleSpacing.lg) {
                header
                questionCard
                Divider()
                    .background(MongleColor.divider)
                actionButtons
            }
            .padding(.horizontal, MongleSpacing.md)
            .padding(.bottom, MongleSpacing.xl)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: QuestionSheetContentHeightKey.self,
                        value: geo.size.height
                    )
                }
            )
        }
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: MongleRadius.full)
            .fill(Color(hex: "E0E0E0"))
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, MongleSpacing.md)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("오늘의 질문")
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.primary)
                Text("무엇을 할까요?")
                    .font(MongleFont.heading3())
                    .foregroundColor(MongleColor.textPrimary)
            }
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
    }

    // MARK: - Question Card

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            HStack(spacing: MongleSpacing.xs) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 13))
                    .foregroundColor(MongleColor.primary)
                Text("오늘의 질문")
                    .font(MongleFont.body2Bold())
                    .foregroundColor(MongleColor.primary)
                if store.isAnswered {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(MongleColor.primary)
                        Text("답변 완료")
                            .font(MongleFont.captionBold())
                            .foregroundColor(MongleColor.primary)
                    }
                }
            }
            Text(store.questionText)
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MongleSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MongleColor.primaryLight.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: MongleRadius.large)
                .stroke(MongleColor.primary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: MongleSpacing.sm) {
            // 답변하기
            MongleButtonPrimary(store.isAnswered ? "답변 수정하기" : "답변하기") {
                store.send(.answerTapped)
            }

            // 나만의 질문 작성하기
            actionRow(
                icon: "pencil.circle",
                title: "나만의 질문 작성하기",
                subtitle: "하트 3개 소모",
                iconColor: MongleColor.accentOrange
            ) {
                store.send(.writeQuestionTapped)
            }

            // 질문 다시 받기
            actionRow(
                icon: "arrow.clockwise.circle",
                title: "질문 다시 받기",
                subtitle: "하트 3개 소모",
                iconColor: MongleColor.secondary
            ) {
                store.send(.refreshQuestionTapped)
            }
        }
    }

    private func actionRow(
        icon: String,
        title: String,
        subtitle: String,
        iconColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: MongleSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MongleFont.body1Bold())
                        .foregroundColor(MongleColor.textPrimary)
                    Text(subtitle)
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textHint)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MongleColor.textHint)
            }
            .padding(.vertical, MongleSpacing.sm)
            .padding(.horizontal, MongleSpacing.md)
            .background(MongleColor.cardGlass)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.medium)
                    .stroke(MongleColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
