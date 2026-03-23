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
        public var familyMembers: [User]
        public var myAnswer: Answer?
        public var familyAnswers: [FamilyAnswer] = []
        public var answerText: String = ""
        public var selectedMoodIndex: Int? = nil
        public var isLoading: Bool = false
        public var isSubmitting: Bool = false
        public var appError: AppError?
        public var showMoodRequiredAlert: Bool = false

        public var hasMyAnswer: Bool { myAnswer != nil }
        public var isValidAnswer: Bool {
            !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

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
            familyMembers: [User] = [],
            myAnswer: Answer? = nil,
            familyAnswers: [FamilyAnswer] = [],
            answerText: String = "",
            selectedMoodIndex: Int? = nil,
            isLoading: Bool = false,
            isSubmitting: Bool = false
        ) {
            self.question = question
            self.currentUser = currentUser
            self.familyMembers = familyMembers
            self.myAnswer = myAnswer
            self.familyAnswers = familyAnswers
            self.answerText = myAnswer?.content ?? answerText
            self.selectedMoodIndex = selectedMoodIndex
            self.isLoading = isLoading
            self.isSubmitting = isSubmitting
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
        case loadDataResponse(Result<LoadedData, AppError>)
        case submitAnswerResponse(Result<Answer, AppError>)
        case setAppError(AppError?)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case answerSubmitted(Answer, moodId: String?)
            case answerEdited(Answer, moodId: String?)
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

    @Dependency(\.answerRepository) var answerRepository
    @Dependency(\.errorHandler) var errorHandler

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - View Actions
            case .onAppear:
                state.isLoading = true
                guard state.question.dailyQuestionId != nil else {
                    // dailyQuestionId 없으면 빈 상태
                    state.isLoading = false
                    return .none
                }
                // 서버 /answers API는 Question.id 기준 (DailyQuestion.id 아님)
                let questionId = state.question.id
                let currentUserId = state.currentUser?.id
                let members = state.familyMembers
                return .run { [answerRepository] send in
                    do {
                        let answers = try await answerRepository.getByDailyQuestion(dailyQuestionId: questionId)
                        let myAnswer = answers.first(where: { $0.userId == currentUserId })
                        let familyAnswers: [State.FamilyAnswer] = answers
                            .filter { $0.userId != currentUserId }
                            .map { answer in
                                let user = members.first(where: { $0.id == answer.userId })
                                    ?? User(id: answer.userId, email: "", name: "멤버",
                                            profileImageURL: nil, role: .other, createdAt: Date())
                                return State.FamilyAnswer(user: user, answer: answer)
                            }
                        await send(.loadDataResponse(.success(LoadedData(myAnswer: myAnswer, familyAnswers: familyAnswers))))
                    } catch {
                        await send(.loadDataResponse(.failure(AppError.from(error))))
                    }
                }

            case .answerTextChanged(let text):
                state.answerText = text
                state.appError = nil
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
                    state.appError = .domain("답변을 입력해주세요.")
                    return .none
                }
                guard state.question.dailyQuestionId != nil else {
                    state.appError = .domain("질문 정보를 불러올 수 없습니다.")
                    return .none
                }

                state.isSubmitting = true
                state.appError = nil

                let answerText = state.answerText.trimmingCharacters(in: .whitespacesAndNewlines)
                let userId = state.currentUser?.id ?? UUID()
                let existingAnswer = state.myAnswer
                // Question.id를 사용 (서버 /answers API는 Question 테이블 ID 기준)
                let questionId = state.question.id

                return .run { [answerRepository] send in
                    do {
                        let result: Answer
                        if let existing = existingAnswer {
                            let updated = Answer(
                                id: existing.id,
                                dailyQuestionId: questionId,
                                userId: userId,
                                content: answerText,
                                imageURL: existing.imageURL,
                                createdAt: existing.createdAt,
                                updatedAt: Date()
                            )
                            result = try await answerRepository.update(updated)
                        } else {
                            let newAnswer = Answer(
                                id: UUID(),
                                dailyQuestionId: questionId,
                                userId: userId,
                                content: answerText,
                                imageURL: nil,
                                createdAt: Date()
                            )
                            result = try await answerRepository.create(newAnswer)
                        }
                        await send(.submitAnswerResponse(.success(result)))
                    } catch {
                        await send(.submitAnswerResponse(.failure(AppError.from(error))))
                    }
                }

            case .dismissErrorTapped:
                state.appError = nil
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
                state.appError = error
                return .none

            case .submitAnswerResponse(.success(let answer)):
                let wasEditing = state.hasMyAnswer
                state.isSubmitting = false
                state.myAnswer = answer
                let moodId = state.selectedMoodIndex.map { MoodOption.defaults[$0].id }
                return .send(wasEditing ? .delegate(.answerEdited(answer, moodId: moodId)) : .delegate(.answerSubmitted(answer, moodId: moodId)))

            case .submitAnswerResponse(.failure(let error)):
                state.isSubmitting = false
                state.appError = error
                return .none

            case .setAppError(let error):
                state.appError = error
                state.isLoading = false
                state.isSubmitting = false
                return .none

            // MARK: - Delegate Actions
            case .delegate:
                return .none
            }
        }
    }
}
