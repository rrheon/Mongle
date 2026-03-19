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
                    let questionId = state.home.todayQuestion?.id
                    let currentUserId = state.home.currentUser?.id
                    return .run { send in
                        var answerText = ""
                        if let qId = questionId,
                           let userId = currentUserId {
                            answerText = (try? await answerRepository.getByUserAndDailyQuestion(dailyQuestionId: qId, userId: userId))?.content ?? ""
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
                    let questionId = state.home.todayQuestion?.id
                    let currentUserId = state.home.currentUser?.id
                    let targetUser = state.home.familyMembers.first { $0.name == memberName }
                    let targetUserId = targetUser?.id
                    return .run { [answerRepository] send in
                        var peerAnswer = ""
                        var myAnswer = ""
                        if let qId = questionId {
                            let answers = (try? await answerRepository.getByDailyQuestion(dailyQuestionId: qId)) ?? []
                            peerAnswer = answers.first { $0.userId == targetUserId }?.content ?? ""
                            myAnswer = answers.first { $0.userId == currentUserId }?.content ?? ""
                        }
                        await send(.showPeerAnswer(memberName: memberName, questionText: questionText, peerAnswer: peerAnswer, myAnswer: myAnswer))
                    }

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

                case .home(.delegate(.groupSelected(let family))):
                    state.currentUserMoodId = nil
                    state.history.historyItems = [:]
                    state.history.loadedMonths = []
                    return .send(.delegate(.groupSelected(family)))

                case .home(.delegate(.navigateToGroupSelect)):
                  return .send(.delegate(.navigateToGroupSelect()))

                // MARK: - Profile Delegate

                case .profile(.delegate(.requestLogin)):
                    return .send(.delegate(.requestLogin))

                case .profile(.delegate(.profileUpdated(let user))):
                    if let idx = state.home.familyMembers.firstIndex(where: { $0.id == user.id }) {
                        state.home.familyMembers[idx] = user
                    }
                    state.home.currentUser = user
                    state.currentUserMoodId = user.moodId
                    state.previewMoodId = nil
                    return .none

                case .profile(.delegate(.colorPreview(let moodId))):
                    state.previewMoodId = moodId
                    return .none

                case .profile(.delegate(.colorPreviewCancelled)):
                    state.previewMoodId = nil
                    return .none

                case .profile(.delegate(.groupLeft)):
                    return .send(.delegate(.navigateToGroupSelect(fromGroupLeft: true)))

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

                case .history(.delegate(.navigateToQuestionDetail(let question, _))):
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

                case .path(.element(id: _, action: .questionDetail(.delegate(.answerSubmitted(_, let moodId))))):
                    state.home.hasAnsweredToday = true
                    if let userId = state.home.currentUser?.id {
                        state.home.memberAnswerStatus[userId] = true
                    }
                    state.home.hearts += 1
                    // moodId로 유저 객체 생성 (HomeView + 프로필 화면 즉시 반영용)
                    let updatedUser: User? = {
                        guard let moodId = moodId, let current = state.home.currentUser else { return nil }
                        return User(
                            id: current.id,
                            email: current.email,
                            name: current.name,
                            profileImageURL: current.profileImageURL,
                            role: current.role,
                            hearts: current.hearts,
                            moodId: moodId,
                            createdAt: current.createdAt
                        )
                    }()
                    if let updated = updatedUser {
                        state.currentUserMoodId = updated.moodId
                        state.home.currentUser = updated
                        if let idx = state.home.familyMembers.firstIndex(where: { $0.id == updated.id }) {
                            state.home.familyMembers[idx] = updated
                        }
                        state.profile.user = updated
                    }
                    state.history.historyItems = [:]
                    state.history.loadedMonths = []
                    state.path.removeLast()
                    state.showAnswerSubmittedToast = true
                    state.showAnswerHeartPopup = true
                    return .merge(
                        .run { [userRepository] _ in
                            guard let user = updatedUser else { return }
                            _ = try? await userRepository.update(user)
                        },
                        .run { send in
                            try await Task.sleep(nanoseconds: 3_000_000_000)
                            await send(.dismissAnswerSubmittedToast)
                        }
                    )

                case .path(.element(id: _, action: .questionDetail(.delegate(.answerEdited(let answer, let moodId))))):
                    state.history.historyItems = [:]
                    state.history.loadedMonths = []
                    // 오늘 질문 수정인 경우에만 색상 업데이트
                    let isTodayQuestion = answer.dailyQuestionId == state.home.todayQuestion?.id
                    let editUpdatedUser: User? = {
                        guard isTodayQuestion, let moodId = moodId, let current = state.home.currentUser else { return nil }
                        return User(
                            id: current.id,
                            email: current.email,
                            name: current.name,
                            profileImageURL: current.profileImageURL,
                            role: current.role,
                            hearts: current.hearts,
                            moodId: moodId,
                            createdAt: current.createdAt
                        )
                    }()
                    if let updated = editUpdatedUser {
                        state.currentUserMoodId = updated.moodId
                        state.home.currentUser = updated
                        if let idx = state.home.familyMembers.firstIndex(where: { $0.id == updated.id }) {
                            state.home.familyMembers[idx] = updated
                        }
                        state.profile.user = updated
                    }
                    state.showEditAnswerToast = true
                    return .merge(
                        .run { [userRepository] _ in
                            guard let user = editUpdatedUser else { return }
                            _ = try? await userRepository.update(user)
                        },
                        .run { send in
                            try await Task.sleep(nanoseconds: 3_000_000_000)
                            await send(.dismissEditAnswerToast)
                        }
                    )

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

                case .dismissAnswerHeartPopup:
                    state.showAnswerHeartPopup = false
                    return .none

                case .showPeerAnswer(let memberName, let questionText, let peerAnswer, let myAnswer):
                    state.modal = .peerAnswer(PeerAnswerFeature.State(
                        memberName: memberName,
                        questionText: questionText,
                        peerAnswer: peerAnswer,
                        myAnswer: myAnswer
                    ))
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
