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
                MongleColor.surface
                    .ignoresSafeArea()

                if store.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: MongleSpacing.lg) {
                            // Question Card
                            QuestionCard(question: store.question)
                                .padding(.horizontal, MongleSpacing.lg)
                                .padding(.top, MongleSpacing.md)

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
                            .padding(.horizontal, MongleSpacing.lg)

                            // Error Message
                            if let errorMessage = store.errorMessage {
                                ErrorMessageView(message: errorMessage) {
                                    store.send(.dismissErrorTapped)
                                }
                                .padding(.horizontal, MongleSpacing.lg)
                            }

                            // Family Answers Section
                            if !store.familyAnswers.isEmpty {
                                FamilyAnswersSection(answers: store.familyAnswers)
                                    .padding(.horizontal, MongleSpacing.lg)
                            }

                            Spacer()
                                .frame(height: MongleSpacing.xxl)
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
                            .foregroundColor(MongleColor.textSecondary)
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
        VStack(alignment: .leading, spacing: MongleSpacing.md) {
            HStack {
                Text(question.category.rawValue)
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.primary)
                    .padding(.horizontal, MongleSpacing.sm)
                    .padding(.vertical, MongleSpacing.xxs)
                    .background(MongleColor.primaryLight.opacity(0.3))
                    .cornerRadius(MongleRadius.small)

                Spacer()

                Text("오늘의 질문")
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }

            Text(question.content)
                .font(MongleFont.heading2())
                .foregroundColor(MongleColor.textPrimary)
                .lineSpacing(4)
        }
        .padding(MongleSpacing.lg)
        .background(MongleColor.background)
        .cornerRadius(MongleRadius.large)
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
        VStack(alignment: .leading, spacing: MongleSpacing.md) {
            HStack {
                Text("나의 답변")
                    .font(MongleFont.body1())
                    .fontWeight(.semibold)
                    .foregroundColor(MongleColor.textPrimary)

                if hasExistingAnswer {
                    Text("수정")
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textHint)
                }

                Spacer()
            }

            TextEditor(text: $answerText)
                .font(MongleFont.body1())
                .frame(minHeight: 120)
                .padding(MongleSpacing.md)
                .background(MongleColor.background)
                .cornerRadius(MongleRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: MongleRadius.medium)
                        .stroke(isFocused.wrappedValue ? MongleColor.primary : MongleColor.border, lineWidth: isFocused.wrappedValue ? 2 : 1)
                )
                .focused(isFocused)

            if answerText.isEmpty {
                Text("가족과 나누고 싶은 이야기를 적어주세요")
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textHint)
                    .padding(.horizontal, MongleSpacing.md)
                    .offset(y: -100)
                    .allowsHitTesting(false)
            }

            MongleButton(
                hasExistingAnswer ? "답변 수정하기" : "답변 등록하기",
                style: .primary,
                isLoading: isSubmitting
            ) {
                onSubmit()
            }
            .disabled(!isValid || isSubmitting)
            .opacity(isValid ? 1 : 0.6)
        }
        .padding(MongleSpacing.lg)
        .background(MongleColor.background)
        .cornerRadius(MongleRadius.large)
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
                .foregroundColor(MongleColor.error)

            Text(message)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.error)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(MongleColor.textSecondary)
            }
        }
        .padding(MongleSpacing.md)
        .background(MongleColor.error.opacity(0.1))
        .cornerRadius(MongleRadius.medium)
    }
}

// MARK: - Family Answers Section
private struct FamilyAnswersSection: View {
    let answers: [QuestionDetailFeature.State.FamilyAnswer]

    var body: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.md) {
            HStack {
                Text("가족의 답변")
                    .font(MongleFont.body1())
                    .fontWeight(.semibold)
                    .foregroundColor(MongleColor.textPrimary)

                Text("\(answers.count)")
                    .font(MongleFont.caption())
                    .foregroundColor(.white)
                    .padding(.horizontal, MongleSpacing.xs)
                    .padding(.vertical, 2)
                    .background(MongleColor.primary)
                    .cornerRadius(MongleRadius.full)

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
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            // User Info
            HStack(spacing: MongleSpacing.sm) {
                Circle()
                    .fill(MongleColor.primaryLight)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(user.name.prefix(1)))
                            .font(MongleFont.body2())
                            .foregroundColor(MongleColor.primaryDark)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(MongleFont.body2())
                        .fontWeight(.medium)
                        .foregroundColor(MongleColor.textPrimary)

                    Text(user.role.rawValue)
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textHint)
                }

                Spacer()

                Text(timeAgoString(from: answer.createdAt))
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }

            // Answer Content
            Text(answer.content)
                .font(MongleFont.body1())
                .foregroundColor(MongleColor.textPrimary)
                .lineSpacing(4)
        }
        .padding(MongleSpacing.md)
        .background(MongleColor.background)
        .cornerRadius(MongleRadius.medium)
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
