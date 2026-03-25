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
        public var hearts: Int = 0
      @Presents public var editCostPopup: HeartCostPopupFeature.State?

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
            isSubmitting: Bool = false,
            hearts: Int = 0
        ) {
            self.question = question
            self.currentUser = currentUser
            self.familyMembers = familyMembers
            self.myAnswer = myAnswer
            self.familyAnswers = familyAnswers
            self.answerText = myAnswer?.content ?? answerText
            self.hearts = hearts
            // 수정 모드: 사용자의 현재 moodId로 초기 선택
            if myAnswer != nil,
               let moodId = currentUser?.moodId,
               let index = MoodOption.defaults.firstIndex(where: { $0.id == moodId }) {
                self.selectedMoodIndex = index
            } else {
                self.selectedMoodIndex = selectedMoodIndex
            }
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

        // MARK: - Presentation Actions
        case editCostPopup(PresentationAction<HeartCostPopupFeature.Action>)
        case adHeartGranted(Int)

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
    @Dependency(\.userRepository) var userRepository
    @Dependency(\.adClient) var adClient
    @Dependency(\.errorHandler) var errorHandler

    public init() {}

    public var body: some ReducerOf<Self> {
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
                guard !state.isSubmitting else { return .none }
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

                if state.hasMyAnswer {
                    // 수정인 경우: 하트 소모 팝업 표시
                    state.editCostPopup = HeartCostPopupFeature.State(
                        costType: .editAnswer,
                        hearts: state.hearts
                    )
                    return .none
                }

                // 신규 답변인 경우: 바로 제출
                state.isSubmitting = true
                state.appError = nil

                let answerText = state.answerText.trimmingCharacters(in: .whitespacesAndNewlines)
                let userId = state.currentUser?.id ?? UUID()
                let questionId = state.question.id
                let selectedMoodId = state.selectedMoodIndex.map { MoodOption.defaults[$0].id }

                return .run { [answerRepository] send in
                    do {
                        let newAnswer = Answer(
                            id: UUID(),
                            dailyQuestionId: questionId,
                            userId: userId,
                            content: answerText,
                            imageURL: nil,
                            createdAt: Date()
                        )
                        let result = try await answerRepository.create(newAnswer, moodId: selectedMoodId)
                        await send(.submitAnswerResponse(.success(result)))
                    } catch {
                        await send(.submitAnswerResponse(.failure(AppError.from(error))))
                    }
                }

            case .editCostPopup(.presented(.delegate(.confirmed))):
                state.editCostPopup = nil
                guard let existingAnswer = state.myAnswer else { return .none }
                state.isSubmitting = true
                state.appError = nil

                let editAnswerText = state.answerText.trimmingCharacters(in: .whitespacesAndNewlines)
                let editUserId = state.currentUser?.id ?? UUID()
                let editQuestionId = state.question.id
                let editMoodId = state.selectedMoodIndex.map { MoodOption.defaults[$0].id }
                let updated = Answer(
                    id: existingAnswer.id,
                    dailyQuestionId: editQuestionId,
                    userId: editUserId,
                    content: editAnswerText,
                    imageURL: existingAnswer.imageURL,
                    createdAt: existingAnswer.createdAt,
                    updatedAt: Date()
                )
                return .run { [answerRepository] send in
                    do {
                        let result = try await answerRepository.update(updated, moodId: editMoodId)
                        await send(.submitAnswerResponse(.success(result)))
                    } catch {
                        await send(.submitAnswerResponse(.failure(AppError.from(error))))
                    }
                }

            case .editCostPopup(.presented(.delegate(.cancelled))):
                state.editCostPopup = nil
                return .none

            case .editCostPopup(.presented(.delegate(.watchAdRequested))):
                state.editCostPopup = nil
                return .run { [adClient, userRepository] send in
                    let earned = await adClient.showRewardedAd()
                    guard earned else { return }
                    do {
                        let heartsRemaining = try await userRepository.grantAdHearts(amount: 1)
                        await send(.adHeartGranted(heartsRemaining))
                    } catch {
                        await send(.adHeartGranted(-1))
                    }
                }

            case .adHeartGranted(let hearts):
                if hearts >= 0 {
                    state.hearts = hearts
                } else {
                    state.hearts += 1
                }
                state.editCostPopup = HeartCostPopupFeature.State(costType: .editAnswer, hearts: state.hearts)
                return .none

            case .editCostPopup:
                return .none

            case .dismissErrorTapped:
                state.appError = nil
                return .none

            case .closeTapped:
                state.appError = nil
                return .send(.delegate(.closed))

            // MARK: - Internal Actions
            case .loadDataResponse(.success(let data)):
                state.isLoading = false
                state.myAnswer = data.myAnswer
                state.familyAnswers = data.familyAnswers
                if let myAnswer = data.myAnswer {
                    state.answerText = myAnswer.content
                    // 수정 모드: 사용자의 현재 moodId로 기분 선택 복원
                    if let moodId = state.currentUser?.moodId,
                       let index = MoodOption.defaults.firstIndex(where: { $0.id == moodId }) {
                        state.selectedMoodIndex = index
                    }
                }
                return .none

            case .loadDataResponse(.failure(let error)):
                state.isLoading = false
                state.appError = error
                return .none

            case .submitAnswerResponse(.success(let answer)):
                let wasEditing = state.hasMyAnswer
                // isSubmitting을 false로 초기화하지 않음: dismiss 중 TextField가 answerTextChanged를 재전송하는 것을 방지
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
        .ifLet(\.$editCostPopup, action: \.editCostPopup) {
            HeartCostPopupFeature()
        }
    }
}
