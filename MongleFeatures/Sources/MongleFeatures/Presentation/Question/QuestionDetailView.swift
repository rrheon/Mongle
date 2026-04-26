//
//  QuestionDetailView.swift
//  Mongle
//

import SwiftUI
import ComposableArchitecture
import Domain

struct QuestionDetailView: View {
    @Bindable var store: StoreOf<QuestionDetailFeature>
    @FocusState private var isAnswerFocused: Bool
    @State private var isClosing = false

    private let moods = MoodOption.defaults

    var body: some View {
        VStack(spacing: 0) {
            customHeader

            if store.isLoading {
                Spacer()
                ProgressView().tint(MongleColor.primary)
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            questionSection
                            moodPickerSection
                            answerInputSection

                            Color.clear.frame(height: 1).id("answerBottom")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    // scrollTo 는 focus 획득 시점에만 1회 호출.
                    // 이전엔 .onChange(of: store.answerText) 가 매 keystroke 마다 scrollTo 를
                    // 발화시켰는데 (200자 답변 = ~200회 애니메이션), TextField 가 커지면서 키보드에
                    // 가려질 때 사용자가 직접 스크롤로 조정하는 게 자연스럽고 hitch 도 줄어든다.
                    .onChange(of: isAnswerFocused) { _, focused in
                        if focused {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("answerBottom", anchor: .bottom)
                            }
                        }
                    }
                }

                ctaButton
            }
        }
        .background(MongleColor.background)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { store.send(.onAppear) }
        .mongleErrorToast(
            error: store.appError,
            onDismiss: { store.send(.dismissErrorTapped) }
        )
        .overlay {
            if store.showMoodRequiredAlert {
                MonglePopupView(
                    icon: .init(
                        systemName: "face.smiling.fill",
                        foregroundColor: MongleColor.primary,
                        backgroundColor: MongleColor.primaryLight
                    ),
                    title: L10n.tr("detail_mood_required_title"),
                    description: L10n.tr("detail_mood_required_desc"),
                    primaryLabel: L10n.tr("common_confirm"),
                    onPrimary: { store.send(.moodRequiredAlertDismissed) }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: store.showMoodRequiredAlert)
            }
        }
        .overlay {
            if let popupStore = store.scope(state: \.editCostPopup, action: \.editCostPopup) {
                HeartCostPopupView(store: popupStore)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: store.editCostPopup != nil)
            }
        }
    }

    // MARK: - Header

    private var customHeader: some View {
        MongleNavigationHeader(title: L10n.tr("detail_title")) {
            MongleBackButton {
                isClosing = true
                store.send(.closeTapped)
            }
        } right: {
            EmptyView()
        }
    }

    // MARK: - Question Section

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("detail_today_question"))
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.primary)

            Text(store.question.content)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(MongleColor.textPrimary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MongleSpacing.lg)
        .monglePanel(background: Color.white, cornerRadius: MongleRadius.xl, borderColor: MongleColor.border, shadowOpacity: 0)
    }

    // MARK: - Mood Picker

    private var moodPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.tr("detail_today_mongle"))
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.textSecondary)
                Spacer()
                if store.selectedMoodIndex == nil {
                    Text(L10n.tr("detail_select_mood"))
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textHint)
                }
            }

            HStack(spacing: 8) {
                ForEach(moods.indices, id: \.self) { index in
                    moodCell(index: index)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MongleSpacing.lg)
        .monglePanel(background: Color.white, cornerRadius: MongleRadius.xl, borderColor: MongleColor.border, shadowOpacity: 0)
    }

    private func moodCell(index: Int) -> some View {
        let isSelected = store.selectedMoodIndex == index
        let mood = moods[index]
        let noneSelected = store.selectedMoodIndex == nil

        return Button {
            store.send(.moodSelected(index))
        } label: {
            VStack(spacing: 6) {
                MongleMonggle(color: mood.color, size: 36)
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                Text(mood.label)
                    .font(.system(size: 12))
                    .foregroundColor(MongleColor.textSecondary)

                Circle()
                    .fill(isSelected ? MongleColor.primary : MongleColor.border)
                    .frame(width: 7, height: 7)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .opacity(noneSelected || isSelected ? 1.0 : 0.45)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Answer Input

    private var answerInputSection: some View {
        VStack(alignment: .trailing, spacing: 6) {
            // sending(\.answerTextChanged) 패턴 — Binding identity 가 body 호출간 동일하게 유지되어
            // SwiftUI input session 안정화. 200자 클립과 isSubmitting guard 는 이미 reducer 에서 처리.
            TextField(
                L10n.tr("detail_answer_placeholder"),
                text: $store.answerText.sending(\.answerTextChanged),
                prompt: Text(L10n.tr("detail_answer_placeholder")).foregroundColor(MongleColor.textSecondary),
                axis: .vertical
            )
            .font(MongleFont.body2())
            .foregroundColor(MongleColor.textPrimary)
            .lineSpacing(4)
            .lineLimit(5...10)
            .focused($isAnswerFocused)
            .padding(MongleSpacing.md)
            .frame(minHeight: 120, alignment: .topLeading)
            .monglePanel(
                background: MongleColor.cardBackgroundSolid,
                cornerRadius: MongleRadius.large,
                borderColor: isAnswerFocused ? MongleColor.primary : MongleColor.border,
                shadowOpacity: 0.04
            )
            .animation(.easeInOut(duration: 0.2), value: isAnswerFocused)

            // 글자수 카운터를 별도 자식 View 로 격리 — answerText 외 다른 상태 변화에 의한
            // 무관한 재평가 차단 (focus 변경, isSubmitting 변경 등으로 부모 body 가 재평가
            // 되더라도 AnswerCharCounter 는 입력값이 동일하면 SwiftUI 가 body 평가 skip).
            AnswerCharCounter(count: store.answerText.count, limit: 200)
        }
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button {
            store.send(.submitAnswerTapped)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Text(store.hasMyAnswer ? L10n.tr("detail_edit_submit") : L10n.tr("detail_submit"))
                    .font(MongleFont.button())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [MongleColor.primaryGradientStart, MongleColor.primaryGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: MongleColor.primaryGradientStart.opacity(0.4), radius: 16, x: 0, y: 6)
        }
        .buttonStyle(MongleScaleButtonStyle())
        .disabled(!store.isValidAnswer || store.isSubmitting)
        .opacity((!store.isValidAnswer || store.isSubmitting) ? 0.6 : 1)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 32)
        .background(MongleColor.background)
    }
}

// MARK: - Answer Char Counter (격리된 자식 View)

/// 답변 글자수 표시. answerText 만 의존하도록 분리해 다른 상태 변경 (focus, isSubmitting,
/// mood 선택, hearts 갱신 등) 에 의한 무관 재평가를 차단.
private struct AnswerCharCounter: View {
    let count: Int
    let limit: Int

    var body: some View {
        Text("\(count)/\(limit)")
            .font(MongleFont.caption())
            .foregroundColor(count >= limit ? MongleColor.error : MongleColor.textHint)
    }
}

#Preview("Question Detail") {
    QuestionDetailView(
        store: Store(initialState: QuestionDetailFeature.State(
            question: Question(
                id: UUID(),
                content: "오늘 당신을 웃게 한 건 무엇인가요?",
                category: .daily,
                order: 1
            ),
            currentUser: User(id: UUID(), email: "me@example.com", name: "나", profileImageURL: nil, role: .son, createdAt: .now),
            familyAnswers: [
                QuestionDetailFeature.State.FamilyAnswer(
                    user: User(id: UUID(), email: "lily@example.com", name: "Lily", profileImageURL: nil, role: .daughter, createdAt: .now),
                    answer: Answer(id: UUID(), dailyQuestionId: UUID(), userId: UUID(), content: "아침에 고양이가 제 발 위에서 잠든 것을 발견했어요 🐱", imageURL: nil, createdAt: .now.addingTimeInterval(-18 * 60))
                )
            ]
        )) {
            QuestionDetailFeature()
        }
    )
}
