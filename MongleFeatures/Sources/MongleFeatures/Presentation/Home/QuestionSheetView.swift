import SwiftUI
import ComposableArchitecture

struct QuestionSheetContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - 03-A · Home (Question Sheet)

/// 오늘의 질문 답변 바텀시트.
/// v2 디자인(claude.ai/design 핸드오프) 톤으로 통일 — cream 배경 + SUIT + ink/mint/coral 팔레트.
/// 맨 상단 질문 카드는 Home(`HomeQuestionCardV2`)에서 쓰는 글래스 카드 UI 를 그대로 옮겨와,
/// 상태 칩 + SUIT-20 질문 + mint CTA(답변하기) 구성을 동일하게 맞춘다.
public struct QuestionSheetView: View {
    @Bindable var store: StoreOf<QuestionSheetFeature>

    public init(store: StoreOf<QuestionSheetFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            dragHandle
            VStack(alignment: .leading, spacing: 18) {
                header
                questionCard
                actionRows
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: QuestionSheetContentHeightKey.self,
                        value: geo.size.height
                    )
                }
            )
        }
        .background(V2Palette.cream)
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: MongleRadius.full)
            .fill(V2Palette.ink.opacity(0.15))
            .frame(width: 40, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 16)
    }

    // MARK: - Header

    /// "오늘의 질문" eyebrow 는 아래 질문 카드의 상태 칩과 중복되므로 두지 않고,
    /// 시트의 행동 유도 문구(무엇을 할까요?)만 타이틀로 남긴다.
    private var header: some View {
        HStack(alignment: .center) {
            Text(L10n.tr("sheet_subtitle"))
                .font(V2Font.suit(20, .bold))
                .foregroundStyle(V2Palette.ink)
            Spacer()
            Button {
                store.send(.closeTapped)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(V2Palette.mutedSoft)
                    .frame(width: 32, height: 32)
                    .background(V2Palette.ink.opacity(0.06), in: Circle())
                    .contentShape(Rectangle())
            }
            .buttonStyle(MongleScaleButtonStyle())
        }
    }

    // MARK: - Question Card (Home UI)

    private var statusLabel: String {
        if store.isAnswered { return L10n.tr("home_answer_complete") }
        if store.isSkipped { return L10n.tr("home_skipped_label") }
        return L10n.tr("home_today_question")
    }

    private var statusColor: Color {
        if store.isAnswered { return V2Palette.mintInk }
        if store.isSkipped { return V2Palette.muted }
        return V2Palette.coral
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 상태 칩 — Home 질문 카드와 동일(dot + label + 답변 완료 시 체크).
            HStack(spacing: 6) {
                Circle().fill(statusColor).frame(width: 6, height: 6)
                Text(statusLabel)
                    .font(V2Font.suit(12, .bold))
                    .foregroundStyle(statusColor)
                    .tracking(0.3)
                if store.isAnswered {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(V2Palette.mintInk)
                }
            }

            Text(store.questionText)
                .font(V2Font.suit(20, .bold))
                .foregroundStyle(V2Palette.ink)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            // mint CTA — Home 카드의 답변 버튼을 그대로 가져온다. 답변 완료 상태면 "수정" 진입.
            Button {
                store.send(.answerTapped)
            } label: {
                HStack(spacing: 6) {
                    Text(store.isAnswered ? L10n.tr("sheet_answer_edit") : L10n.tr("sheet_answer"))
                        .font(V2Font.suit(15, .bold))
                        .foregroundStyle(V2Palette.ink)
                    Image(systemName: store.isAnswered ? "pencil" : "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(V2Palette.ink)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(V2Palette.mint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(MongleScaleButtonStyle())
            .padding(.top, 16)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.82))
                )
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 6)
        }
    }

    // MARK: - Secondary Actions

    private var actionRows: some View {
        VStack(spacing: 10) {
            // 나만의 질문 작성하기
            actionRow(
                icon: "pencil.and.scribble",
                iconColor: V2Palette.streak,
                title: L10n.tr("sheet_write_question"),
                subtitle: L10n.tr("sheet_heart_cost")
            ) {
                store.send(.writeQuestionTapped)
            }

            // 질문 넘기기 — 이미 넘긴 경우/답변한 경우 숨김 (서버도 409 거부)
            if !store.isSkipped && !store.isAnswered {
                actionRow(
                    icon: "arrow.right.circle",
                    iconColor: V2Palette.coral,
                    title: L10n.tr("sheet_skip"),
                    subtitle: L10n.tr("sheet_skip_desc")
                ) {
                    store.send(.refreshQuestionTapped)
                }
            }
        }
    }

    private func actionRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(V2Font.suit(15, .bold))
                        .foregroundStyle(V2Palette.ink)
                    Text(subtitle)
                        .font(V2Font.suit(12, .regular))
                        .foregroundStyle(V2Palette.muted)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(V2Palette.muted)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(V2Palette.paperWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(V2Palette.hairline, lineWidth: 1)
                    )
            }
        }
        .buttonStyle(MongleScaleButtonStyle())
    }
}
