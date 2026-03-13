//
//  QuestionDetailFeature.swift
//  Mongle
//
//  Created by Claude on 2025-01-06.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct QuestionDetailFeature {
    @ObservableState
    public struct State: Equatable {
        public var question: Question
        public var currentUser: User?
        public var myAnswer: Answer?
        public var familyAnswers: [FamilyAnswer] = []
        public var answerText: String = ""
        public var selectedMoodIndex: Int? = nil
        public var isLoading: Bool = false
        public var isSubmitting: Bool = false
        public var errorMessage: String?

        public var hasMyAnswer: Bool { myAnswer != nil }
        public var isValidAnswer: Bool {
            !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        public var showMoodRequiredAlert: Bool = false

        public struct FamilyAnswer: Equatable, Identifiable, Sendable {
            public let id: UUID
            public let user: User
            public let answer: Answer

            public init(id: UUID = UUID(), user: User, answer: Answer) {
                self.id = id
                self.user = user
                self.answer = answer
            }
        }

        public init(
            question: Question,
            currentUser: User? = nil,
            myAnswer: Answer? = nil,
            familyAnswers: [FamilyAnswer] = [],
            answerText: String = "",
            selectedMoodIndex: Int? = nil,
            isLoading: Bool = false,
            isSubmitting: Bool = false,
            errorMessage: String? = nil
        ) {
            self.question = question
            self.currentUser = currentUser
            self.myAnswer = myAnswer
            self.familyAnswers = familyAnswers
            self.answerText = myAnswer?.content ?? answerText
            self.selectedMoodIndex = selectedMoodIndex
            self.isLoading = isLoading
            self.isSubmitting = isSubmitting
            self.errorMessage = errorMessage
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case onAppear
        case answerTextChanged(String)
        case moodSelected(Int)
        case submitAnswerTapped
        case moodRequiredAlertDismissed
        case dismissErrorTapped
        case closeTapped

        // MARK: - Internal Actions
        case loadDataResponse(Result<LoadedData, AnswerError>)
        case submitAnswerResponse(Result<Answer, AnswerError>)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case answerSubmitted(Answer)
            case closed
        }
    }

    public struct LoadedData: Equatable, Sendable {
        public let myAnswer: Answer?
        public let familyAnswers: [State.FamilyAnswer]

        public init(myAnswer: Answer?, familyAnswers: [State.FamilyAnswer]) {
            self.myAnswer = myAnswer
            self.familyAnswers = familyAnswers
        }
    }

    public enum AnswerError: Error, Equatable, Sendable {
        case emptyAnswer
        case networkError
        case unknown(String)

        var localizedDescription: String {
            switch self {
            case .emptyAnswer:
                return "답변을 입력해주세요."
            case .networkError:
                return "네트워크 연결을 확인해주세요."
            case .unknown(let message):
                return message
            }
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - View Actions
            case .onAppear:
                state.isLoading = true
                let questionId = state.question.id

                return .run { send in
                    // TODO: 실제 API 호출로 교체
                    try await Task.sleep(nanoseconds: 500_000_000)

                    // Mock 데이터
                    let lily = User(id: UUID(), email: "lily@example.com", name: "Lily", profileImageURL: nil, role: .daughter, createdAt: .now)
                    let mom = User(id: UUID(), email: "mom@example.com", name: "Mom", profileImageURL: nil, role: .mother, createdAt: .now)

                    let mockFamilyAnswers: [State.FamilyAnswer] = [
                        State.FamilyAnswer(
                            user: lily,
                            answer: Answer(
                                id: UUID(),
                                dailyQuestionId: questionId,
                                userId: lily.id,
                                content: "아침에 고양이가 제 발 위에서 잠든 것을 발견했어요. 너무 귀여워서 한동안 꼼짝도 못했지 뭐예요 🐱",
                                imageURL: nil,
                                createdAt: .now.addingTimeInterval(-18 * 60)
                            )
                        ),
                        State.FamilyAnswer(
                            user: mom,
                            answer: Answer(
                                id: UUID(),
                                dailyQuestionId: questionId,
                                userId: mom.id,
                                content: "오늘 오랜만에 가족이랑 같이 밥 먹었는데 진짜 행복했어요 😊",
                                imageURL: nil,
                                createdAt: .now.addingTimeInterval(-53 * 60)
                            )
                        )
                    ]

                    await send(.loadDataResponse(.success(LoadedData(
                        myAnswer: nil,
                        familyAnswers: mockFamilyAnswers
                    ))))
                }

            case .answerTextChanged(let text):
                state.answerText = text
                state.errorMessage = nil
                return .none

            case .moodSelected(let index):
                state.selectedMoodIndex = state.selectedMoodIndex == index ? nil : index
                return .none

            case .moodRequiredAlertDismissed:
                state.showMoodRequiredAlert = false
                return .none

            case .submitAnswerTapped:
                guard state.selectedMoodIndex != nil else {
                    state.showMoodRequiredAlert = true
                    return .none
                }
                guard state.isValidAnswer else {
                    state.errorMessage = "답변을 입력해주세요."
                    return .none
                }

                state.isSubmitting = true
                state.errorMessage = nil

                let answerText = state.answerText.trimmingCharacters(in: .whitespacesAndNewlines)
                let questionId = state.question.id
                let userId = state.currentUser?.id ?? UUID()
                let existingAnswerId = state.myAnswer?.id

                return .run { send in
                    // TODO: 실제 API 호출로 교체
                    try await Task.sleep(nanoseconds: 1_000_000_000)

                    let answer = Answer(
                        id: existingAnswerId ?? UUID(),
                        dailyQuestionId: questionId,
                        userId: userId,
                        content: answerText,
                        imageURL: nil,
                        createdAt: .now,
                        updatedAt: existingAnswerId != nil ? .now : nil
                    )

                    await send(.submitAnswerResponse(.success(answer)))
                }

            case .dismissErrorTapped:
                state.errorMessage = nil
                return .none

            case .closeTapped:
                return .send(.delegate(.closed))

            // MARK: - Internal Actions
            case .loadDataResponse(.success(let data)):
                state.isLoading = false
                state.myAnswer = data.myAnswer
                state.familyAnswers = data.familyAnswers
                if let myAnswer = data.myAnswer {
                    state.answerText = myAnswer.content
                }
                return .none

            case .loadDataResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .submitAnswerResponse(.success(let answer)):
                state.isSubmitting = false
                state.myAnswer = answer
                return .send(.delegate(.answerSubmitted(answer)))

            case .submitAnswerResponse(.failure(let error)):
                state.isSubmitting = false
                state.errorMessage = error.localizedDescription
                return .none

            // MARK: - Delegate Actions
            case .delegate:
                return .none
            }
        }
    }
}
