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
            .fill(MongleColor.border)
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, MongleSpacing.md)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.tr("sheet_title"))
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.primary)
                Text(L10n.tr("sheet_subtitle"))
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
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(MongleScaleButtonStyle())
        }
    }

    // MARK: - Question Card

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            HStack(spacing: MongleSpacing.xs) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 13))
                    .foregroundColor(MongleColor.primary)
                Text(L10n.tr("sheet_title"))
                    .font(MongleFont.body2Bold())
                    .foregroundColor(MongleColor.primary)
                if store.isAnswered {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(MongleColor.primary)
                        Text(L10n.tr("home_answer_complete"))
                            .font(MongleFont.captionBold())
                            .foregroundColor(MongleColor.primary)
                    }
                } else if store.isSkipped {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color.purple)
                        Text(L10n.tr("home_skipped_label"))
                            .font(MongleFont.captionBold())
                            .foregroundColor(Color.purple)
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
        .monglePanel(
            background: MongleColor.primaryLight.opacity(0.15),
            cornerRadius: MongleRadius.large,
            borderColor: MongleColor.primary.opacity(0.3),
            shadowOpacity: 0
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: MongleSpacing.sm) {
            // 답변하기
            MongleButtonPrimary(store.isAnswered ? L10n.tr("sheet_answer_edit") : L10n.tr("sheet_answer")) {
                store.send(.answerTapped)
            }

          Divider()
              .background(MongleColor.divider)
          
        
            // 나만의 질문 작성하기
            actionRow(
                icon: "pencil.circle",
                title: L10n.tr("sheet_write_question"),
                subtitle: L10n.tr("sheet_heart_cost"),
                iconColor: MongleColor.primary
            ) {
                store.send(.writeQuestionTapped)
            }

            // 질문 넘기기 — 이미 넘긴 경우 숨김 (서버도 409 거부)
            if !store.isSkipped && !store.isAnswered {
                actionRow(
                    icon: "arrow.right.circle",
                    title: L10n.tr("sheet_skip"),
                    subtitle: L10n.tr("sheet_skip_desc"),
                    iconColor: MongleColor.primary
                ) {
                    store.send(.refreshQuestionTapped)
                }
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
            .monglePanel(
                background: MongleColor.cardGlass,
                cornerRadius: MongleRadius.medium,
                borderColor: MongleColor.border,
                shadowOpacity: 0.04
            )
        }
        .buttonStyle(MongleScaleButtonStyle())
    }
}
