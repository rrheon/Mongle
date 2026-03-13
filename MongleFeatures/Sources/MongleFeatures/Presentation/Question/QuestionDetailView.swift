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
    @State private var answerEditorHeight: CGFloat = 120

    private let moods: [(emoji: String, color: Color)] = [
        ("😊", MongleColor.monggleYellow),
        ("😌", MongleColor.monggleGreen),
        ("🥰", MongleColor.mongglePink),
        ("😢", MongleColor.monggleBlue),
        ("😴", MongleColor.monggleOrange)
    ]

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

                            if let errorMessage = store.errorMessage {
                                errorBanner(errorMessage)
                            }

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
        .alert(
            "오늘의 몽글을 선택해주세요",
            isPresented: Binding(
                get: { store.showMoodRequiredAlert },
                set: { _ in }
            )
        ) {
            Button("확인") { store.send(.moodRequiredAlertDismissed) }
        } message: {
            Text("지금 기분과 가장 비슷한 몽글 캐릭터를 골라보세요 🌿")
        }
    }

    // MARK: - Header

    private var customHeader: some View {
        ZStack {
            Text("마음 남기기")
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)

            HStack {
                Button { store.send(.closeTapped) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(MongleColor.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 8)
        .background(Color.white)
    }

    // MARK: - Question Section

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🌿 Today's Question")
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
        .background(Color.white)
        .cornerRadius(MongleRadius.xl)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(MongleColor.border, lineWidth: 1))
    }

    // MARK: - Mood Picker

    private var moodPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("오늘의 몽글")
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.textSecondary)
                Spacer()
                if store.selectedMoodIndex == nil {
                    Text("하나를 선택해주세요")
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
        .background(Color.white)
        .cornerRadius(MongleRadius.xl)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(MongleColor.border, lineWidth: 1))
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

                Text(mood.emoji)
                    .font(.system(size: 12))

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
        ZStack(alignment: .topLeading) {
            // 높이 측정용 숨김 텍스트
            Text(store.answerText.isEmpty ? " " : store.answerText)
                .font(MongleFont.body2())
                .lineSpacing(4)
                .padding(MongleSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(0)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            answerEditorHeight = max(120, geo.size.height)
                        }.onChange(of: store.answerText) { _, _ in
                            answerEditorHeight = max(120, geo.size.height)
                        }
                    }
                )

            TextEditor(text: Binding(
                get: { store.answerText },
                set: { store.send(.answerTextChanged($0)) }
            ))
            .font(MongleFont.body2())
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .frame(height: answerEditorHeight)
            .padding(MongleSpacing.md)
            .focused($isAnswerFocused)

            if store.answerText.isEmpty {
                Text("오늘의 감정을 자유롭게 적어보세요.\n어떤 이야기든 좋아요.")
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textHint)
                    .lineSpacing(4)
                    .padding(.horizontal, MongleSpacing.md + 4)
                    .padding(.vertical, MongleSpacing.md + 8)
                    .allowsHitTesting(false)
            }
        }
        .background(MongleColor.cardBackgroundSolid)
        .cornerRadius(MongleRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: MongleRadius.large)
                .stroke(
                    isAnswerFocused ? MongleColor.primary : MongleColor.border,
                    lineWidth: isAnswerFocused ? 1.5 : 1
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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
                Text(store.hasMyAnswer ? "답변 수정하기" : "마음 남기기")
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
        .disabled(!store.isValidAnswer || store.isSubmitting)
        .opacity((!store.isValidAnswer || store.isSubmitting) ? 0.6 : 1)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 32)
        .background(MongleColor.background)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: MongleSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(MongleColor.error)
            Text(message)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.error)
            Spacer()
            Button { store.send(.dismissErrorTapped) } label: {
                Image(systemName: "xmark")
                    .foregroundColor(MongleColor.textSecondary)
            }
        }
        .padding(MongleSpacing.md)
        .background(MongleColor.bgErrorSoft)
        .cornerRadius(MongleRadius.large)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.large).stroke(MongleColor.error.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Family Answers

    private var familyAnswersSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.md) {
            HStack {
                Text("가족의 답변")
                    .font(MongleFont.body1Bold())
                    .foregroundColor(MongleColor.textPrimary)
                Text("\(store.familyAnswers.count)")
                    .font(MongleFont.captionBold())
                    .foregroundColor(.white)
                    .padding(.horizontal, MongleSpacing.xs)
                    .padding(.vertical, 2)
                    .background(MongleColor.primary)
                    .clipShape(Capsule())
                Spacer()
            }

            ForEach(store.familyAnswers) { familyAnswer in
                familyAnswerCard(familyAnswer)
            }
        }
    }

    private func familyAnswerCard(_ item: QuestionDetailFeature.State.FamilyAnswer) -> some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            HStack(spacing: MongleSpacing.sm) {
                Circle()
                    .fill(MongleColor.primaryLight)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(item.user.name.prefix(1)))
                            .font(MongleFont.body2Bold())
                            .foregroundColor(MongleColor.primary)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.user.name)
                        .font(MongleFont.body2Bold())
                        .foregroundColor(MongleColor.textPrimary)
                    Text(item.user.role.rawValue)
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textHint)
                }
                Spacer()
                Text(timeAgoString(from: item.answer.createdAt))
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }

            Text(item.answer.content)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MongleSpacing.md)
        .background(Color.white)
        .cornerRadius(MongleRadius.large)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.large).stroke(MongleColor.border, lineWidth: 1))
    }

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
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
