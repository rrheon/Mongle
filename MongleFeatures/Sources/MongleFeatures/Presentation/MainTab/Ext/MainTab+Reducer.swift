//
//  File.swift
//  MongleFeatures
//
//  Created by 최용헌 on 3/12/26.
//

import Foundation
import ComposableArchitecture
import Domain
import SwiftUI

private func monggleColor(for moodId: String?) -> Color {
    switch moodId {
    case "happy":  return MongleColor.monggleYellow
    case "calm":   return MongleColor.monggleGreen
    case "loved":  return MongleColor.mongglePink
    case "sad":    return MongleColor.monggleBlue
    case "tired":  return MongleColor.monggleOrange
    default:       return MongleColor.mongglePink
    }
}

private func formatAnswerTime(_ date: Date) -> String {
    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    if calendar.isDateInToday(date) {
        formatter.dateFormat = "오늘 a h:mm"
    } else if calendar.isDateInYesterday(date) {
        formatter.dateFormat = "어제 a h:mm"
    } else {
        formatter.dateFormat = "M월 d일 a h:mm"
    }
    return formatter.string(from: date)
}

extension MainTabFeature {

    var reducer: some ReducerOf<Self> {

        CombineReducers {

            Scope(state: \.home, action: \.home) { HomeFeature() }
            Scope(state: \.history, action: \.history) { HistoryFeature() }
            Scope(state: \.search, action: \.search) { SearchHistoryFeature() }
            Scope(state: \.notification, action: \.notification) { NotificationFeature() }
            Scope(state: \.profile, action: \.profile) { ProfileEditFeature() }

            Reduce { state, action in

                switch action {

                case .selectTab(let tab):
                    state.selectedTab = tab
                    return .none

                case .home(.delegate(.showQuestionSheet(let question))):
                    // 오늘 질문이 없으면(오전 11시 이전) 어제 답변 여부로 판단
                    let isAnswered = state.home.todayQuestion != nil
                        ? state.home.hasAnsweredToday
                        : state.home.hasAnsweredYesterday
                    state.modal = .questionSheet(
                        QuestionSheetFeature.State(
                            questionText: question.content,
                            isAnswered: isAnswered
                        )
                    )
                    return .none

                // MARK: - Home Delegate

                case .home(.delegate(.navigateToNotifications)):
                    if let familyId = state.home.family?.id,
                       let familyName = state.home.family?.name {
                        state.path.append(.notification(NotificationFeature.State(
                            mode: .filtered(familyId: familyId, familyName: familyName)
                        )))
                    } else {
                        state.path.append(.notification(NotificationFeature.State()))
                    }
                    return .none

                case .home(.delegate(.navigateToMyAnswer)):
                    // 오늘 질문이 없으면(오전 11시 이전) 어제 질문 기준
                    let activeQuestion = state.home.todayQuestion ?? state.home.yesterdayQuestion
                    let questionText = activeQuestion?.content ?? ""
                    let memberName = state.home.currentUser?.name ?? ""
                    let questionId = activeQuestion?.id
                    let currentUserId = state.home.currentUser?.id
                    let myMonggleColor = monggleColor(for: state.home.currentUser?.moodId)
                    return .run { send in
                        var answerText = ""
                        var answerTime = ""
                        if let qId = questionId,
                           let userId = currentUserId {
                            let answer = try? await answerRepository.getByUserAndDailyQuestion(dailyQuestionId: qId, userId: userId)
                            answerText = answer?.content ?? ""
                            if let date = answer?.updatedAt ?? answer?.createdAt {
                                answerTime = formatAnswerTime(date)
                            }
                        }
                        await send(.showMyAnswer(memberName: memberName, questionText: questionText, answerText: answerText, monggleColor: myMonggleColor, answerTime: answerTime))
                    }

                case .showMyAnswer(let memberName, let questionText, let answerText, let monggleColor, let answerTime):
                    state.modal = .peerAnswer(PeerAnswerFeature.State(
                        memberName: memberName,
                        monggleColor: monggleColor,
                        questionText: questionText,
                        peerAnswer: answerText,
                        myAnswer: answerText,
                        peerAnswerTime: answerTime.isEmpty ? "오늘" : answerTime
                    ))
                    return .none

                case .home(.delegate(.navigateToPeerAnswerSelfAnswered(let memberName))):
                    let questionText = state.home.todayQuestion?.content ?? ""
                    let questionId = state.home.todayQuestion?.id
                    let currentUserId = state.home.currentUser?.id
                    let targetUser = state.home.familyMembers.first { $0.name == memberName }
                    let targetUserId = targetUser?.id
                    let peerMonggleColor = monggleColor(for: targetUser?.moodId)
                    return .run { [answerRepository] send in
                        var peerAnswer = ""
                        var myAnswer = ""
                        var peerAnswerTime = ""
                        var myAnswerTime = ""
                        if let qId = questionId {
                            let answers = (try? await answerRepository.getByDailyQuestion(dailyQuestionId: qId)) ?? []
                            let peerAnswerObj = answers.first { $0.userId == targetUserId }
                            let myAnswerObj = answers.first { $0.userId == currentUserId }
                            peerAnswer = peerAnswerObj?.content ?? ""
                            myAnswer = myAnswerObj?.content ?? ""
                            if let date = peerAnswerObj.flatMap({ $0.updatedAt ?? $0.createdAt }) {
                                peerAnswerTime = formatAnswerTime(date)
                            }
                            if let date = myAnswerObj.flatMap({ $0.updatedAt ?? $0.createdAt }) {
                                myAnswerTime = formatAnswerTime(date)
                            }
                        }
                        await send(.showPeerAnswer(memberName: memberName, questionText: questionText, peerAnswer: peerAnswer, myAnswer: myAnswer, monggleColor: peerMonggleColor, peerAnswerTime: peerAnswerTime, myAnswerTime: myAnswerTime))
                    }

                case .home(.delegate(.navigateToPeerNotAnsweredNudge(let targetUser))):
                    let questionText = state.home.todayQuestion?.content ?? ""
                    let hearts = state.home.hearts
                    state.path.append(.peerNudge(PeerNudgeFeature.State(
                        targetUserId: targetUser.id.uuidString,
                        memberName: targetUser.name,
                        memberMoodId: targetUser.moodId,
                        questionText: questionText,
                        hearts: hearts
                    )))
                    return .none

                case .home(.delegate(.showAnswerFirstPopup(let memberName))):
                    state.modal = .answerFirstPopup(AnswerFirstPopupFeature.State(memberName: memberName, popupType: .viewAnswer))
                    return .none

                case .home(.delegate(.showNudgeUnavailablePopup(let memberName))):
                    state.modal = .answerFirstPopup(AnswerFirstPopupFeature.State(memberName: memberName, popupType: .nudge))
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

                case .profile(.delegate(.logout)):
                    return .send(.logout)

                case .profile(.delegate(.groupLeft)):
                    return .send(.delegate(.navigateToGroupSelect(fromGroupLeft: true)))

                case .profile(.delegate(.memberKicked)):
                    return .send(.delegate(.requestRefresh))

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
                    state.modal = .heartCostPopup(HeartCostPopupFeature.State(costType: .writeQuestion, hearts: state.home.hearts))
                    return .none

                case .modal(.presented(.questionSheet(.delegate(.showRefreshQuestionCost)))):
                    state.modal = .heartCostPopup(HeartCostPopupFeature.State(costType: .refreshQuestion, hearts: state.home.hearts))
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
                                let heartsRemaining = try await questionRepository.skipTodayQuestion()
                                await send(.skipQuestionResponse(.success(heartsRemaining)))
                            } catch {
                                await send(.skipQuestionResponse(.failure(AppError.from(error))))
                            }
                        }
                    default:
                        state.modal = nil
                        return .none
                    }

                case .modal(.presented(.heartCostPopup(.delegate(.cancelled)))):
                    state.modal = nil
                    return .none

                case .modal(.presented(.heartCostPopup(.delegate(.watchAdRequested(let costType))))):
                    // 팝업 닫고 광고 재생 → 시청 완료 시 서버에서 하트 지급 후 작업 수행
                    let hearts = state.home.hearts
                    state.modal = nil
                    let cost = costType.cost
                    return .run { [costType, cost, hearts] send in
                        let earned = await adClient.showRewardedAd()
                        guard earned else {
                            // 광고 로드 실패 또는 시청 취소 → 에러 표시
                            await send(.skipQuestionResponse(.failure(AppError.domain("광고를 불러올 수 없습니다. 다시 시도해주세요."))))
                            return
                        }
                        do {
                            let heartsRemaining = try await userRepository.grantAdHearts(amount: cost)
                            await send(.adRewardEarned(costType, heartsRemaining: heartsRemaining))
                        } catch {
                            // 서버 지급 실패 시 로컬에서 cost만큼 임시 추가 (fallback)
                            await send(.adRewardEarned(costType, heartsRemaining: -1))
                        }
                    }

                case .adRewardEarned(let costType, let heartsRemaining):
                    // 광고 시청 완료 → 하트 업데이트 후 요청 작업 수행
                    if heartsRemaining >= 0 {
                        state.home.hearts = heartsRemaining
                    } else {
                        state.home.hearts += costType.cost
                    }
                    switch costType {
                    case .writeQuestion:
                        state.path.append(.writeQuestion(WriteQuestionFeature.State()))
                        return .none
                    case .refreshQuestion:
                        return .run { [questionRepository] send in
                            do {
                                let heartsRemaining = try await questionRepository.skipTodayQuestion()
                                await send(.skipQuestionResponse(.success(heartsRemaining)))
                            } catch {
                                await send(.skipQuestionResponse(.failure(AppError.from(error))))
                            }
                        }
                    default:
                        return .none
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
                    // 오늘 질문이 바뀌었으므로 히스토리 캐시 무효화
                    state.history.historyItems = [:]
                    state.history.loadedMonths = []
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
                                familyMembers: state.home.familyMembers,
                                hearts: state.home.hearts
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
                                familyMembers: state.home.familyMembers,
                                hearts: state.home.hearts
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
                    state.path.removeLast()
                    state.showAnswerSubmittedToast = true
                    state.showAnswerHeartPopup = true
                    return .merge(
                        .send(.history(.forceReload)),
                        .run { [userRepository] _ in
                            guard let user = updatedUser else { return }
                            _ = try? await userRepository.update(user)
                        },
                        .run { send in
                            try await Task.sleep(nanoseconds: 3_000_000_000)
                            await send(.dismissAnswerSubmittedToast)
                        }
                    )

                case .path(.element(id: _, action: .questionDetail(.delegate(.answerEdited(_, let moodId))))):
                    state.path.removeLast()
                    state.home.hearts = max(0, state.home.hearts - 1)
                    let editUpdatedUser: User? = {
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
                        .send(.history(.forceReload)),
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

                case .path(.element(id: let id, action: .notification(.delegate(.close)))):
                    if case let .notification(notifState) = state.path[id: id] {
                        state.home.hasUnreadNotifications = notifState.hasUnread
                    }
                    state.path.removeLast()
                    return .none

                case .path(.element(id: _, action: .notification(.delegate(.navigateToQuestion(let markAsReadId))))):
                    state.path.removeLast()
                    guard let question = state.home.todayQuestion else { return .none }
                    state.path.append(.questionDetail(QuestionDetailFeature.State(
                        question: question,
                        currentUser: state.home.currentUser,
                        familyMembers: state.home.familyMembers,
                        hearts: state.home.hearts
                    )))
                    guard let notifId = markAsReadId else { return .none }
                    return .run { [notificationRepository] _ in
                        _ = try? await notificationRepository.markAsRead(id: notifId)
                    }

                case .skipQuestionResponse(.success(let heartsRemaining)):
                    // 개인 패스: 질문 유지, 하트 차감, 패스 상태 기록
                    state.home.hearts = heartsRemaining
                    state.home.hasSkippedToday = true
                    state.showRefreshToast = true
                    return .merge(
                        .send(.history(.forceReload)),
                        .run { send in
                            try await Task.sleep(nanoseconds: 3_000_000_000)
                            await send(.dismissRefreshToast)
                        }
                    )

                case .skipQuestionResponse(.failure(let error)):
                    state.home.appError = error
                    return .none

                case .dismissAnswerHeartPopup:
                    state.showAnswerHeartPopup = false
                    return .none

                case .showPeerAnswer(let memberName, let questionText, let peerAnswer, let myAnswer, let monggleColor, let peerAnswerTime, let myAnswerTime):
                    state.modal = .peerAnswer(PeerAnswerFeature.State(
                        memberName: memberName,
                        monggleColor: monggleColor,
                        questionText: questionText,
                        peerAnswer: peerAnswer,
                        myAnswer: myAnswer,
                        peerAnswerTime: peerAnswerTime.isEmpty ? "오늘" : peerAnswerTime,
                        myAnswerTime: myAnswerTime.isEmpty ? "오늘" : myAnswerTime
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
