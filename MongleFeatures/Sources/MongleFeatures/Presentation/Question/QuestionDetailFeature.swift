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
            // (이전: defaults.firstIndex(where:) linear scan → MoodOption.indexById dict O(1))
            if myAnswer != nil,
               let moodId = currentUser?.moodId,
               let index = MoodOption.indexById[moodId] {
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
        /// 다중 디바이스에서 hearts 가 변경됐을 수 있으므로 onAppear 마다 최신 값으로 갱신.
        case heartsRefreshed(Int)

        // MARK: - Presentation Actions
        case editCostPopup(PresentationAction<HeartCostPopupFeature.Action>)
        case adHeartGranted(Int)
        /// 수정 confirm 후 update API 가 실패했을 때 옵티미스틱 차감을 되돌리기 위한 내부 액션
        case editRollback
        /// 광고 시청을 사용자가 취소했거나 보상 미지급된 경우 — submitting 플래그 해제
        case adWatchAborted
        /// 광고 시청은 완료했으나 grantAdHearts 가 retry 후에도 실패 — 사용자에게 명시적 안내
        case adGrantFailed(AppError)

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
    @Dependency(\.authRepository) var authRepository
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
                return .merge(
                    .run { [answerRepository] send in
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
                    },
                    // 다중 디바이스 hearts sync — 다른 기기에서 답변/스킵/위시 등으로 hearts 가
                    // 바뀌었을 수 있으므로 questionDetail 진입 시 서버 최신 값을 가져온다.
                    // 이전엔 부모 화면에서 캡처한 stale hearts 로 editCostPopup/adReward 가 동작해
                    // 서버 검증과 어긋나는 경우가 있었음.
                    .run { [authRepository] send in
                        if let user = try? await authRepository.getCurrentUser() {
                            await send(.heartsRefreshed(user.hearts))
                        }
                    }
                )

            case .heartsRefreshed(let hearts):
                state.hearts = hearts
                return .none

            case .answerTextChanged(let text):
                guard !state.isSubmitting else { return .none }
                state.answerText = String(text.prefix(200))
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
                    state.appError = .domain(L10n.tr("error_answer_empty"))
                    return .none
                }
                guard state.question.dailyQuestionId != nil else {
                    state.appError = .domain(L10n.tr("error_question_load"))
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
                guard state.myAnswer != nil else { return .none }
                guard state.hearts >= 1 else {
                    state.appError = .domain(L10n.tr("home_hearts_insufficient"))
                    return .none
                }
                // 옵티미스틱 차감: UI 즉시 반영 + 사용자 즉각 피드백.
                // 실패 시 .editRollback 으로 되돌린다.
                state.hearts -= 1
                state.isSubmitting = true
                return performAnswerEdit(state: &state)

            case .editCostPopup(.presented(.delegate(.cancelled))):
                state.editCostPopup = nil
                return .none

            case .editCostPopup(.presented(.delegate(.watchAdRequested))):
                state.editCostPopup = nil
                state.isSubmitting = true   // 광고 시청 + 보상 지급 + 자동 update 한 묶음으로 락
                state.appError = nil
                return .run { [adClient, userRepository] send in
                    let earned = await adClient.showRewardedAd()
                    guard earned else {
                        // 사용자가 광고를 끝까지 안 봤거나 reward 콜백 미발화 — submitting 해제
                        await send(.adWatchAborted)
                        return
                    }
                    do {
                        // retry 포함 grant. 실패 시 자동 update 진행하지 않고 명시적 안내.
                        let heartsRemaining = try await AdRewardClient.grantAdHearts(
                            userRepository: userRepository,
                            amount: 1
                        )
                        await send(.adHeartGranted(heartsRemaining))
                    } catch {
                        await send(.adGrantFailed(AppError.from(error)))
                    }
                }

            case .editRollback:
                // update API 실패 → 옵티미스틱 차감 복구
                state.hearts += 1
                return .none

            case .adWatchAborted:
                state.isSubmitting = false
                return .none

            case .adGrantFailed(let error):
                // 광고는 봤지만 서버 보상 지급에 최종 실패. 자동 update 강행하지 않음.
                // (이전엔 hearts +=1 클라 단독 증가 + 자동 update 진행 → 서버 401/하트 부족 위험)
                state.isSubmitting = false
                state.appError = error
                return .none

            case .adHeartGranted(let hearts):
                // 서버 응답으로만 hearts sync. 실패 분기는 .adGrantFailed 로 분리됨.
                state.hearts = hearts
                // 광고 시청 완료 → 수정 작업 자동 실행 (다른 광고 보상 기능과 일관)
                guard state.myAnswer != nil else {
                    state.isSubmitting = false
                    return .none
                }
                guard state.hearts >= 1 else {
                    state.isSubmitting = false
                    state.appError = .domain(L10n.tr("home_hearts_insufficient"))
                    return .none
                }
                state.hearts -= 1   // edit 비용 옵티미스틱 차감
                return performAnswerEdit(state: &state)

            case .editCostPopup:
                return .none

            case .dismissErrorTapped:
                state.appError = nil
                return .none

            case .closeTapped:
                // 제출 중인 동안 close 입력은 무시 — 사용자가 dismiss 한 뒤 응답이 도착해도
                // 부모가 path.removeLast 시점이 충돌해 다음 화면이 비정상 표시되는 race 차단.
                guard !state.isSubmitting else { return .none }
                state.appError = nil
                state.editCostPopup = nil
                return .send(.delegate(.closed))

            // MARK: - Internal Actions
            case .loadDataResponse(.success(let data)):
                state.isLoading = false
                state.myAnswer = data.myAnswer
                state.familyAnswers = data.familyAnswers
                if let myAnswer = data.myAnswer {
                    state.answerText = myAnswer.content
                    // 수정 모드: 사용자의 현재 moodId로 기분 선택 복원
                    // (이전: defaults.firstIndex(where:) → MoodOption.indexById dict O(1))
                    if let moodId = state.currentUser?.moodId,
                       let index = MoodOption.indexById[moodId] {
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

    /// 답변 수정 공통 시퀀스. `editCostPopup(.confirmed)` 와 `.adHeartGranted` 가
    /// 동일한 update 로직 (locals 추출 + Answer 빌드 + repository.update + rollback)
    /// 을 가졌던 것을 단일 진입점으로 통합.
    /// 호출지에서 hearts 검증·옵티미스틱 차감·isSubmitting 플래그를 먼저 셋업한 뒤 호출.
    private func performAnswerEdit(state: inout State) -> Effect<Action> {
        guard let existingAnswer = state.myAnswer else { return .none }
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
                await send(.editRollback)
                await send(.submitAnswerResponse(.failure(AppError.from(error))))
            }
        }
    }
}
