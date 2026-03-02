//
//  QuestionDetailView.swift
//  Mongle
//
//  Created by Claude on 2025-01-06.
//

import SwiftUI
import ComposableArchitecture
import Domain

struct QuestionDetailView: View {
    @Bindable var store: StoreOf<QuestionDetailFeature>
    @FocusState private var isAnswerFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.surface
                    .ignoresSafeArea()

                if store.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: FTSpacing.lg) {
                            // Question Card
                            QuestionCard(question: store.question)
                                .padding(.horizontal, FTSpacing.lg)
                                .padding(.top, FTSpacing.md)

                            // My Answer Section
                            MyAnswerSection(
                                answerText: Binding(
                                    get: { store.answerText },
                                    set: { store.send(.answerTextChanged($0)) }
                                ),
                                hasExistingAnswer: store.hasMyAnswer,
                                isSubmitting: store.isSubmitting,
                                isValid: store.isValidAnswer,
                                isFocused: $isAnswerFocused,
                                onSubmit: { store.send(.submitAnswerTapped) }
                            )
                            .padding(.horizontal, FTSpacing.lg)

                            // Error Message
                            if let errorMessage = store.errorMessage {
                                ErrorMessageView(message: errorMessage) {
                                    store.send(.dismissErrorTapped)
                                }
                                .padding(.horizontal, FTSpacing.lg)
                            }

                            // Family Answers Section
                            if !store.familyAnswers.isEmpty {
                                FamilyAnswersSection(answers: store.familyAnswers)
                                    .padding(.horizontal, FTSpacing.lg)
                            }

                            Spacer()
                                .frame(height: FTSpacing.xxl)
                        }
                    }
                }
            }
            .navigationTitle("오늘의 질문")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        store.send(.closeTapped)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(FTColor.textSecondary)
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

// MARK: - Question Card
private struct QuestionCard: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: FTSpacing.md) {
            HStack {
                Text(question.category.rawValue)
                    .font(FTFont.caption())
                    .foregroundColor(FTColor.primary)
                    .padding(.horizontal, FTSpacing.sm)
                    .padding(.vertical, FTSpacing.xxs)
                    .background(FTColor.primaryLight.opacity(0.3))
                    .cornerRadius(FTRadius.small)

                Spacer()

                Text("오늘의 질문")
                    .font(FTFont.caption())
                    .foregroundColor(FTColor.textHint)
            }

            Text(question.content)
                .font(FTFont.heading2())
                .foregroundColor(FTColor.textPrimary)
                .lineSpacing(4)
        }
        .padding(FTSpacing.lg)
        .background(FTColor.background)
        .cornerRadius(FTRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - My Answer Section
private struct MyAnswerSection: View {
    @Binding var answerText: String
    let hasExistingAnswer: Bool
    let isSubmitting: Bool
    let isValid: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FTSpacing.md) {
            HStack {
                Text("나의 답변")
                    .font(FTFont.body1())
                    .fontWeight(.semibold)
                    .foregroundColor(FTColor.textPrimary)

                if hasExistingAnswer {
                    Text("수정")
                        .font(FTFont.caption())
                        .foregroundColor(FTColor.textHint)
                }

                Spacer()
            }

            TextEditor(text: $answerText)
                .font(FTFont.body1())
                .frame(minHeight: 120)
                .padding(FTSpacing.md)
                .background(FTColor.background)
                .cornerRadius(FTRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: FTRadius.medium)
                        .stroke(isFocused.wrappedValue ? FTColor.primary : FTColor.border, lineWidth: isFocused.wrappedValue ? 2 : 1)
                )
                .focused(isFocused)

            if answerText.isEmpty {
                Text("가족과 나누고 싶은 이야기를 적어주세요")
                    .font(FTFont.body2())
                    .foregroundColor(FTColor.textHint)
                    .padding(.horizontal, FTSpacing.md)
                    .offset(y: -100)
                    .allowsHitTesting(false)
            }

            FTButton(
                hasExistingAnswer ? "답변 수정하기" : "답변 등록하기",
                style: .primary,
                isLoading: isSubmitting
            ) {
                onSubmit()
            }
            .disabled(!isValid || isSubmitting)
            .opacity(isValid ? 1 : 0.6)
        }
        .padding(FTSpacing.lg)
        .background(FTColor.background)
        .cornerRadius(FTRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Error Message View
private struct ErrorMessageView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(FTColor.error)

            Text(message)
                .font(FTFont.body2())
                .foregroundColor(FTColor.error)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(FTColor.textSecondary)
            }
        }
        .padding(FTSpacing.md)
        .background(FTColor.error.opacity(0.1))
        .cornerRadius(FTRadius.medium)
    }
}

// MARK: - Family Answers Section
private struct FamilyAnswersSection: View {
    let answers: [QuestionDetailFeature.State.FamilyAnswer]

    var body: some View {
        VStack(alignment: .leading, spacing: FTSpacing.md) {
            HStack {
                Text("가족의 답변")
                    .font(FTFont.body1())
                    .fontWeight(.semibold)
                    .foregroundColor(FTColor.textPrimary)

                Text("\(answers.count)")
                    .font(FTFont.caption())
                    .foregroundColor(.white)
                    .padding(.horizontal, FTSpacing.xs)
                    .padding(.vertical, 2)
                    .background(FTColor.primary)
                    .cornerRadius(FTRadius.full)

                Spacer()
            }

            ForEach(answers) { familyAnswer in
                FamilyAnswerCard(
                    user: familyAnswer.user,
                    answer: familyAnswer.answer
                )
            }
        }
    }
}

// MARK: - Family Answer Card
private struct FamilyAnswerCard: View {
    let user: User
    let answer: Answer

    var body: some View {
        VStack(alignment: .leading, spacing: FTSpacing.sm) {
            // User Info
            HStack(spacing: FTSpacing.sm) {
                Circle()
                    .fill(FTColor.primaryLight)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(user.name.prefix(1)))
                            .font(FTFont.body2())
                            .foregroundColor(FTColor.primaryDark)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(FTFont.body2())
                        .fontWeight(.medium)
                        .foregroundColor(FTColor.textPrimary)

                    Text(user.role.rawValue)
                        .font(FTFont.caption())
                        .foregroundColor(FTColor.textHint)
                }

                Spacer()

                Text(timeAgoString(from: answer.createdAt))
                    .font(FTFont.caption())
                    .foregroundColor(FTColor.textHint)
            }

            // Answer Content
            Text(answer.content)
                .font(FTFont.body1())
                .foregroundColor(FTColor.textPrimary)
                .lineSpacing(4)
        }
        .padding(FTSpacing.md)
        .background(FTColor.background)
        .cornerRadius(FTRadius.medium)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Previews
#Preview("Question Detail") {
    QuestionDetailView(
        store: Store(initialState: QuestionDetailFeature.State(
            question: Question(
                id: UUID(),
                content: "오늘 가장 감사했던 순간은 언제인가요?",
                category: .gratitude,
                order: 1
            ),
            currentUser: User(id: UUID(), email: "me@example.com", name: "나", profileImageURL: nil, role: .son, createdAt: .now),
            familyAnswers: [
                QuestionDetailFeature.State.FamilyAnswer(
                    user: User(id: UUID(), email: "dad@example.com", name: "아빠", profileImageURL: nil, role: .father, createdAt: .now),
                    answer: Answer(id: UUID(), dailyQuestionId: UUID(), userId: UUID(), content: "오늘 아침에 가족들과 함께 식사한 시간이 가장 감사했습니다.", imageURL: nil, createdAt: .now)
                ),
                QuestionDetailFeature.State.FamilyAnswer(
                    user: User(id: UUID(), email: "mom@example.com", name: "엄마", profileImageURL: nil, role: .mother, createdAt: .now),
                    answer: Answer(id: UUID(), dailyQuestionId: UUID(), userId: UUID(), content: "모두가 건강하게 하루를 보낸 것에 감사해요.", imageURL: nil, createdAt: .now)
                )
            ]
        )) {
            QuestionDetailFeature()
        }
    )
}

#Preview("Question Detail - Loading") {
    QuestionDetailView(
        store: Store(initialState: QuestionDetailFeature.State(
            question: Question(
                id: UUID(),
                content: "오늘 가장 감사했던 순간은 언제인가요?",
                category: .gratitude,
                order: 1
            ),
            isLoading: true
        )) {
            QuestionDetailFeature()
        }
    )
}
