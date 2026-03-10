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
                MongleColor.background
                    .ignoresSafeArea()

                if store.isLoading {
                    ProgressView()
                        .tint(MongleColor.primary)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: MongleSpacing.lg) {
                            questionCard
                            answerComposer

                            if let errorMessage = store.errorMessage {
                                errorBanner(errorMessage)
                            }

                            if !store.familyAnswers.isEmpty {
                                familyAnswersSection
                            }
                        }
                        .padding(.horizontal, MongleSpacing.md)
                        .padding(.vertical, MongleSpacing.md)
                    }
                }
            }
            .navigationTitle("답변하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("오늘의 기분은?")
                        .font(MongleFont.body2Bold())
                        .foregroundColor(MongleColor.primary)
                    Text("질문에 답한 뒤 가족의 답변을 확인해보세요")
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textSecondary)
                }

                Spacer()

                Text(store.hasMyAnswer ? "답변 완료" : "오늘 질문")
                    .font(MongleFont.captionBold())
                    .foregroundColor(store.hasMyAnswer ? MongleColor.primary : MongleColor.accentOrange)
                    .padding(.horizontal, MongleSpacing.sm)
                    .padding(.vertical, MongleSpacing.xxs)
                    .background(store.hasMyAnswer ? MongleColor.primaryLight : Color(hex: "FFF1DE"))
                    .clipShape(Capsule())
            }

            Text(store.question.content)
                .font(MongleFont.heading2())
                .foregroundColor(MongleColor.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(store.question.category.rawValue)
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textSecondary)
        }
        .padding(MongleSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 176, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFF5E9"), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .monglePanel(background: .clear, cornerRadius: MongleRadius.xl, borderColor: Color(hex: "F4E4D7"), shadowOpacity: 0.04)
    }

    private var answerComposer: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.md) {
            HStack {
                Text("나의 답변")
                    .font(MongleFont.body1Bold())
                    .foregroundColor(MongleColor.textPrimary)

                if store.hasMyAnswer {
                    Text("답변 수정")
                        .font(MongleFont.captionBold())
                        .foregroundColor(MongleColor.primary)
                }

                Spacer()
            }

            Text("지금 떠오르는 감정이나 장면을 편하게 적어보세요.")
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textSecondary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: Binding(
                    get: { store.answerText },
                    set: { store.send(.answerTextChanged($0)) }
                ))
                .font(UIFont(name: "Outfit-Regular", size: 16) == nil ? .system(size: 16, weight: .regular, design: .rounded) : .custom("Outfit-Regular", size: 16))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 180)
                .padding(MongleSpacing.md)
                .background(Color(hex: "FCFAF7"))
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: MongleRadius.large)
                        .stroke(isAnswerFocused ? MongleColor.primary : Color(hex: "E8E0D6"), lineWidth: isAnswerFocused ? 2 : 1)
                )
                .focused($isAnswerFocused)

                if store.answerText.isEmpty {
                    Text("오늘의 감정을 자유롭게 적어보세요.")
                        .font(MongleFont.body2())
                        .foregroundColor(MongleColor.textHint)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 30)
                        .allowsHitTesting(false)
                }
            }

            MongleButtonPrimary(store.hasMyAnswer ? "답변 수정하기" : "답변하기") {
                store.send(.submitAnswerTapped)
            }
            .disabled(!store.isValidAnswer || store.isSubmitting)
            .opacity((!store.isValidAnswer || store.isSubmitting) ? 0.6 : 1)
        }
        .padding(MongleSpacing.lg)
        .monglePanel(cornerRadius: MongleRadius.xl, shadowOpacity: 0.03)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: MongleSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(MongleColor.error)

            Text(message)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.error)

            Spacer()

            Button {
                store.send(.dismissErrorTapped)
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(MongleColor.textSecondary)
            }
        }
        .padding(MongleSpacing.md)
        .monglePanel(background: Color(hex: "FDEBEC"), cornerRadius: MongleRadius.large, borderColor: MongleColor.error.opacity(0.12), shadowOpacity: 0.01)
    }

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

            Text("가족이 남긴 오늘의 생각을 차례대로 볼 수 있어요.")
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textSecondary)

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
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MongleSpacing.md)
        .frame(minHeight: 134, alignment: .topLeading)
        .monglePanel(cornerRadius: MongleRadius.large, shadowOpacity: 0.02)
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
                content: "가족에게 고마운 순간은?",
                category: .gratitude,
                order: 1
            ),
            currentUser: User(id: UUID(), email: "me@example.com", name: "나", profileImageURL: nil, role: .son, createdAt: .now),
            familyAnswers: [
                QuestionDetailFeature.State.FamilyAnswer(
                    user: User(id: UUID(), email: "dad@example.com", name: "아빠", profileImageURL: nil, role: .father, createdAt: .now),
                    answer: Answer(id: UUID(), dailyQuestionId: UUID(), userId: UUID(), content: "오늘 아침에 같이 밥 먹은 시간이 고마웠어요.", imageURL: nil, createdAt: .now)
                )
            ]
        )) {
            QuestionDetailFeature()
        }
    )
}
