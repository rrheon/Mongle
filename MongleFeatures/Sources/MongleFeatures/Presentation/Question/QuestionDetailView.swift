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
                    .onChange(of: isAnswerFocused) { _, focused in
                        if focused {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("answerBottom", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: store.answerText) { _, _ in
                        if isAnswerFocused {
                            proxy.scrollTo("answerBottom", anchor: .bottom)
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
            TextField(L10n.tr("detail_answer_placeholder"), text: Binding(
                get: { store.answerText },
                set: { newValue in
                    guard !store.isSubmitting, !isClosing else { return }
                    if newValue.count > 200 { return }
                    store.send(.answerTextChanged(newValue))
                }
            ), prompt: Text(L10n.tr("detail_answer_placeholder")).foregroundColor(MongleColor.textSecondary), axis: .vertical)
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

            Text("\(store.answerText.count)/200")
                .font(MongleFont.caption())
                .foregroundColor(store.answerText.count >= 200 ? MongleColor.error : MongleColor.textHint)
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
