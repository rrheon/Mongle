//
//  File.swift
//  MongleFeatures
//
//  Created by 최용헌 on 3/12/26.
//

import Foundation
import ComposableArchitecture
import Domain

extension MainTabFeature {

    var reducer: some ReducerOf<Self> {

        CombineReducers {

            Scope(state: \.home, action: \.home) { HomeFeature() }
            Scope(state: \.history, action: \.history) { HistoryFeature() }
            Scope(state: \.notification, action: \.notification) { NotificationFeature() }
            Scope(state: \.profile, action: \.profile) { ProfileEditFeature() }

            Reduce { state, action in

                switch action {

                case .selectTab(let tab):
                    state.selectedTab = tab
                    return .none

                case .home(.delegate(.showQuestionSheet(let question))):

                    state.modal = .questionSheet(
                        QuestionSheetFeature.State(
                            questionText: question.content,
                            isAnswered: state.home.hasAnsweredToday
                        )
                    )

                    return .none

                // MARK: - Home Delegate

                case .home(.delegate(.navigateToNotifications)):
                    state.path.append(.notification(NotificationFeature.State()))
                    return .none

                case .home(.delegate(.navigateToMyAnswer)):
                    let questionText = state.home.todayQuestion?.content ?? ""
                    let memberName = state.home.currentUser?.name ?? ""
                    let dailyQuestionIdString = state.home.todayQuestion?.dailyQuestionId
                    let currentUserId = state.home.currentUser?.id
                    return .run { send in
                        var answerText = ""
                        if let dqIdString = dailyQuestionIdString,
                           let dqId = UUID(uuidString: dqIdString),
                           let userId = currentUserId {
                            answerText = (try? await answerRepository.getByUserAndDailyQuestion(dailyQuestionId: dqId, userId: userId))?.content ?? ""
                        }
                        await send(.showMyAnswer(memberName: memberName, questionText: questionText, answerText: answerText))
                    }

                case .showMyAnswer(let memberName, let questionText, let answerText):
                    state.modal = .peerAnswer(PeerAnswerFeature.State(
                        memberName: memberName,
                        questionText: questionText,
                        peerAnswer: answerText,
                        myAnswer: answerText
                    ))
                    return .none

                case .home(.delegate(.navigateToPeerAnswerSelfAnswered(let memberName))):
                    let questionText = state.home.todayQuestion?.content ?? ""
                    state.modal = .peerAnswer(PeerAnswerFeature.State(
                        memberName: memberName,
                        questionText: questionText,
                        peerAnswer: "",
                        myAnswer: ""
                    ))
                    return .none

                case .home(.delegate(.navigateToPeerNotAnsweredNudge(let targetUser))):
                    let questionText = state.home.todayQuestion?.content ?? ""
                    let hearts = state.home.hearts
                    state.path.append(.peerNudge(PeerNudgeFeature.State(
                        targetUserId: targetUser.id.uuidString,
                        memberName: targetUser.name,
                        questionText: questionText,
                        hearts: hearts
                    )))
                    return .none

                case .home(.delegate(.showAnswerFirstPopup(let memberName))):
                    state.modal = .answerFirstPopup(AnswerFirstPopupFeature.State(memberName: memberName, popupType: .viewAnswer))
                    return .none

                case .home(.delegate(.showNudgeUnavailablePopup(_))):
                    // MongleView에서 로컬 alert으로 처리
                    return .none

                case .home(.delegate(.navigateToHeartsSystem)):
                    state.modal = .heartInfoPopup(HeartInfoPopupFeature.State(hearts: state.home.hearts))
                    return .none

                case .home(.delegate(.requestRefresh)):
                    return .send(.delegate(.requestRefresh))

                case .home(.delegate(.requestLogin)):
                    return .send(.delegate(.requestLogin))

                // MARK: - QuestionSheet Delegate

                case .modal(.presented(.questionSheet(.delegate(.close)))):
                    state.modal = nil
                    return .none

                case .modal(.presented(.questionSheet(.delegate(.navigateToAnswer)))):
                    state.modal = nil
                    guard let question = state.home.todayQuestion else { return .none }
                    return .run { send in
                        // 시트 dismiss 애니메이션 완료 후 push
                        try await Task.sleep(nanoseconds: 350_000_000)
                        await send(.delegate(.navigateToQuestionDetail(question)))
                    }

                case .modal(.presented(.questionSheet(.delegate(.showWriteQuestionCost)))):
                    state.modal = .heartCostPopup(HeartCostPopupFeature.State(costType: .writeQuestion))
                    return .none

                case .modal(.presented(.questionSheet(.delegate(.showRefreshQuestionCost)))):
                    state.modal = .heartCostPopup(HeartCostPopupFeature.State(costType: .refreshQuestion))
                    return .none

                // MARK: - HeartCostPopup Delegate

                case .modal(.presented(.heartCostPopup(.delegate(.confirmed(let costType))))):
                    switch costType {
                    case .writeQuestion:
                        state.modal = nil
                        state.path.append(.writeQuestion(WriteQuestionFeature.State()))
                        return .none
                    case .refreshQuestion:
                        state.modal = nil
                        return .run { [questionRepository] send in
                            do {
                                let newQuestion = try await questionRepository.skipTodayQuestion()
                                await send(.skipQuestionResponse(.success(newQuestion)))
                            } catch {
                                await send(.skipQuestionResponse(.failure(AppError.from(error))))
                            }
                        }
                    }

                case .modal(.presented(.heartCostPopup(.delegate(.cancelled)))):
                    state.modal = nil
                    return .none

                case .modal(.presented(.heartCostPopup(.delegate(.watchAdRequested(let costType))))):
                    // 팝업 닫고 광고 재생 → 시청 완료 시 작업 수행
                    state.modal = nil
                    return .run { [costType] send in
                        let earned = await adClient.showRewardedAd()
                        if earned {
                            await send(.adRewardEarned(costType))
                        }
                    }

                case .adRewardEarned(let costType):
                    // 광고 시청 완료 → 하트 +1 지급 후 요청 작업 수행
                    state.home.hearts += 1
                    switch costType {
                    case .writeQuestion:
                        state.path.append(.writeQuestion(WriteQuestionFeature.State()))
                        return .none
                    case .refreshQuestion:
                        return .run { [questionRepository] send in
                            do {
                                let newQuestion = try await questionRepository.skipTodayQuestion()
                                await send(.skipQuestionResponse(.success(newQuestion)))
                            } catch {
                                await send(.skipQuestionResponse(.failure(AppError.from(error))))
                            }
                        }
                    }

                // MARK: - HeartInfoPopup Delegate

                case .modal(.presented(.heartInfoPopup(.delegate(.close)))):
                    state.modal = nil
                    return .none

                // MARK: - PeerAnswer Delegate

                case .modal(.presented(.peerAnswer(.delegate(.close)))):
                    state.modal = nil
                    return .none

                // MARK: - PeerNudge Delegate

                case .path(.element(id: _, action: .peerNudge(.delegate(.close)))):
                    state.path.removeLast()
                    return .none

                case .path(.element(id: _, action: .peerNudge(.delegate(.nudgeSent(let heartsRemaining))))):
                    state.home.hearts = heartsRemaining
                    state.showNudgeToast = true
                    return .run { send in
                        try await Task.sleep(nanoseconds: 3_000_000_000)
                        await send(.dismissNudgeToast)
                    }

                // MARK: - AnswerFirstPopup Delegate

                case .modal(.presented(.answerFirstPopup(.delegate(.answerNow)))):
                    state.modal = nil
                    guard let question = state.home.todayQuestion else { return .none }
                    return .run { send in
                        await send(.delegate(.navigateToQuestionDetail(question)))
                    }

                case .modal(.presented(.answerFirstPopup(.delegate(.close)))):
                    state.modal = nil
                    return .none

                // MARK: - WriteQuestion Delegate

                case .path(.element(id: _, action: .writeQuestion(.delegate(.close)))):
                    state.path.removeLast()
                    return .none

                case .path(.element(id: _, action: .writeQuestion(.delegate(.questionSubmitted(let question, let heartsRemaining))))):
                    state.path.removeLast()
                    // 오늘의 질문 교체 + 하트 잔액 업데이트 + 답변 상태 초기화
                    state.home.todayQuestion = question
                    state.home.hearts = heartsRemaining
                    state.home.memberAnswerStatus = [:]
                    state.home.hasAnsweredToday = false
                    state.home.familyAnswerCount = 0
                    state.showWriteToast = true
                    return .run { send in
                        try await Task.sleep(nanoseconds: 3_000_000_000)
                        await send(.dismissWriteToast)
                    }

                case .delegate(.navigateToQuestionDetail(let question)):

                    state.path.append(
                        .questionDetail(
                            QuestionDetailFeature.State(
                                question: question,
                                currentUser: state.home.currentUser,
                                familyMembers: state.home.familyMembers
                            )
                        )
                    )

                    return .none

                case .path(.element(id: _, action: .questionDetail(.delegate(.answerSubmitted(let answer))))):
                    state.home.hasAnsweredToday = true
                    if let userId = state.home.currentUser?.id {
                        state.home.memberAnswerStatus[userId] = true
                    }
                    state.path.removeLast()
                    state.showAnswerSubmittedToast = true
                    return .run { send in
                        try await Task.sleep(nanoseconds: 3_000_000_000)
                        await send(.dismissAnswerSubmittedToast)
                    }

                case .path(.element(id: _, action: .questionDetail(.delegate(.answerEdited(_))))):
                    state.showEditAnswerToast = true
                    return .run { send in
                        try await Task.sleep(nanoseconds: 3_000_000_000)
                        await send(.dismissEditAnswerToast)
                    }

                case .path(.element(id: _, action: .questionDetail(.delegate(.closed)))):
                    state.path.removeLast()
                    return .none

                case .path(.element(id: _, action: .notification(.delegate(.close)))):
                    state.path.removeLast()
                    return .none

                case .skipQuestionResponse(.success(let question)):
                    if let question = question {
                        state.home.todayQuestion = question
                        state.home.hearts = max(0, state.home.hearts - 1)
                        state.home.memberAnswerStatus = [:]
                        state.home.hasAnsweredToday = false
                        state.home.familyAnswerCount = 0
                    }
                    state.showRefreshToast = true
                    return .run { send in
                        try await Task.sleep(nanoseconds: 3_000_000_000)
                        await send(.dismissRefreshToast)
                    }

                case .skipQuestionResponse(.failure(let error)):
                    state.home.appError = error
                    return .none

                case .dismissRefreshToast:
                    state.showRefreshToast = false
                    return .none

                case .dismissWriteToast:
                    state.showWriteToast = false
                    return .none

                case .dismissNudgeToast:
                    state.showNudgeToast = false
                    return .none

                case .dismissEditAnswerToast:
                    state.showEditAnswerToast = false
                    return .none

                case .dismissAnswerSubmittedToast:
                    state.showAnswerSubmittedToast = false
                    return .none

                case .logout:
                    return .none

                default:
                    return .none
                }
            }
        }

        .forEach(\.path, action: \.path)

        .ifLet(\.$modal, action: \.modal) {
            Modal()
        }
    }
}
