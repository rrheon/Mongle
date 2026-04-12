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

// MARK: - Current User 상태 동기화 헬퍼
//
// Home.State 에는 현재 사용자의 "답변/패스" 상태가 이중으로 저장된다:
//   1) hasAnsweredToday / hasSkippedToday  — (본인 뱃지, 버튼 노출 분기)
//   2) memberAnswerStatus[me] / memberSkippedStatus[me]  — (다른 멤버 뷰 렌더링 / 공통)
// 두 소스는 항상 일치해야 하며, 부분 업데이트는 UI 상태 불일치로 이어진다.
// 아래 두 함수는 "현재 사용자" 에 대한 모든 관련 필드를 원자적으로 세팅한다.

private func setCurrentUserAnswered(_ state: inout HomeFeature.State) {
    state.hasAnsweredToday = true
    // answer 가 들어오면 skip 상태는 반드시 해제 (server 는 answer-after-skip 을 허용)
    state.hasSkippedToday = false
    if let userId = state.currentUser?.id {
        state.memberAnswerStatus[userId] = true
        state.memberSkippedStatus[userId] = nil
    }
}

private func setCurrentUserSkipped(_ state: inout HomeFeature.State) {
    state.hasSkippedToday = true
    // skip 이 들어오면 answer 는 반드시 해제 (server 는 skip-after-answer 를 차단하므로
    // 실제론 도달 불가능하지만 방어적으로 동기화)
    state.hasAnsweredToday = false
    if let userId = state.currentUser?.id {
        state.memberSkippedStatus[userId] = true
        state.memberAnswerStatus[userId] = nil
    }
}

private func resetCurrentUserDailyState(_ state: inout HomeFeature.State) {
    // 새 질문이 배정되는 케이스 (나만의 질문 작성 등) 에서 본인 상태를 포함해 전체 초기화.
    state.hasAnsweredToday = false
    state.hasSkippedToday = false
    state.memberAnswerStatus = [:]
    state.memberSkippedStatus = [:]
    state.familyAnswerCount = 0
}

private func formatAnswerTime(_ date: Date) -> String {
    let calendar = Calendar.current
    let timeFormatter = DateFormatter()
    timeFormatter.locale = Locale.current
    timeFormatter.dateFormat = DateFormatter.dateFormat(
        fromTemplate: "ahmm",
        options: 0,
        locale: Locale.current
    )
    if calendar.isDateInToday(date) {
        return L10n.tr("date_today") + " " + timeFormatter.string(from: date)
    } else if calendar.isDateInYesterday(date) {
        return L10n.tr("date_yesterday") + " " + timeFormatter.string(from: date)
    } else {
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.locale = Locale.current
        dateTimeFormatter.dateFormat = DateFormatter.dateFormat(
            fromTemplate: "MMMdahmm",
            options: 0,
            locale: Locale.current
        )
        return dateTimeFormatter.string(from: date)
    }
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
                    // 어제 질문에는 skip 이 적용 안 되므로, 오늘 질문일 때만 skip 상태 전달.
                    let isSkipped = state.home.todayQuestion != nil
                        ? state.home.hasSkippedToday
                        : false
                    state.modal = .questionSheet(
                        QuestionSheetFeature.State(
                            questionText: question.content,
                            isAnswered: isAnswered,
                            isSkipped: isSkipped
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
                        peerAnswerTime: answerTime.isEmpty ? L10n.tr("date_today") : answerTime,
                        isMine: true
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
                    // 그룹이 바뀌면 검색 캐시도 그룹별로 분리되어야 하므로 초기화
                    return .merge(
                        .send(.search(.reset)),
                        .send(.delegate(.groupSelected(family)))
                    )

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
                    // HistoryFeature 의 currentUser 도 같이 갱신해야 "질문 넘김" 카드 색상이 최신 상태.
                    state.history.currentUser = user
                    if let idx = state.history.familyMembers.firstIndex(where: { $0.id == user.id }) {
                        state.history.familyMembers[idx] = user
                    }
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
                    // 오늘의 질문이 이미 가족 누군가가 작성한 나만의 질문이면 그 시점에 차단.
                    // (기존엔 작성 화면 진입 후 submit 시점에서야 서버 에러로 알려줘 UX가 나빴음)
                    if state.home.todayQuestion?.isCustom == true {
                        state.modal = nil
                        state.showCustomQuestionExistsToast = true
                        return .run { send in
                            try await Task.sleep(nanoseconds: 2_500_000_000)
                            await send(.dismissCustomQuestionExistsToast)
                        }
                    }
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
                            await send(.skipQuestionResponse(.failure(AppError.domain(L10n.tr("error_ad_load_failed")))))
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

                case .modal(.presented(.peerAnswer(.delegate(.editAnswer)))):
                    state.modal = nil
                    let activeQuestion = state.home.todayQuestion ?? state.home.yesterdayQuestion
                    guard let question = activeQuestion else { return .none }
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
                    // 오늘의 질문 교체 + 하트 잔액 업데이트 + 본인 일일 상태 완전 초기화
                    state.home.todayQuestion = question
                    state.home.hearts = heartsRemaining
                    resetCurrentUserDailyState(&state.home)
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
                    // 본인 답변 상태 (플래그 + 맵 동시) 를 원자적으로 세팅
                    setCurrentUserAnswered(&state.home)
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
                        state.history.currentUser = updated
                        if let idx = state.history.familyMembers.firstIndex(where: { $0.id == updated.id }) {
                            state.history.familyMembers[idx] = updated
                        }
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
                        state.history.currentUser = updated
                        if let idx = state.history.familyMembers.firstIndex(where: { $0.id == updated.id }) {
                            state.history.familyMembers[idx] = updated
                        }
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
                    // 알림 화면에서 뒤로가기 — Home 의 배지는 "현재 그룹" 한정 미읽음으로 재계산
                    if case let .notification(notifState) = state.path[id: id] {
                        let currentFamilyId = state.home.family?.id
                        state.home.hasUnreadNotifications = notifState.hasUnread(forFamily: currentFamilyId)
                    }
                    state.path.removeLast()
                    return .none

                case .path(.element(id: let id, action: .notification(.delegate(.navigateToQuestion(let markAsReadId))))):
                    // 알림 카드를 탭해 질문 화면으로 이동 — pop 전에 현재 알림 스코프의 미읽음을 다시 계산.
                    // (해당 알림은 NotificationFeature 에서 이미 optimistic 하게 isRead=true 처리됨)
                    if case let .notification(notifState) = state.path[id: id] {
                        let currentFamilyId = state.home.family?.id
                        state.home.hasUnreadNotifications = notifState.hasUnread(forFamily: currentFamilyId)
                    }
                    state.path.removeLast()
                    // 알림 삭제 API 호출 (navigation 성공 여부와 무관하게 실행)
                    let markReadEffect: Effect<Action> = {
                        guard let notifId = markAsReadId else { return .none }
                        return .run { [notificationRepository] _ in
                            _ = try? await notificationRepository.delete(id: notifId)
                        }
                    }()
                    guard let question = state.home.todayQuestion ?? state.home.yesterdayQuestion else {
                        return markReadEffect
                    }
                    state.path.append(.questionDetail(QuestionDetailFeature.State(
                        question: question,
                        currentUser: state.home.currentUser,
                        familyMembers: state.home.familyMembers,
                        hearts: state.home.hearts
                    )))
                    return markReadEffect

                case .skipQuestionResponse(.success(let heartsRemaining)):
                    // 개인 패스: 질문 유지, 하트 차감, 본인 패스 상태 원자적 세팅
                    state.home.hearts = heartsRemaining
                    setCurrentUserSkipped(&state.home)
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
                        peerAnswerTime: peerAnswerTime.isEmpty ? L10n.tr("date_today") : peerAnswerTime,
                        myAnswerTime: myAnswerTime.isEmpty ? L10n.tr("date_today") : myAnswerTime
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

                case .dismissCustomQuestionExistsToast:
                    state.showCustomQuestionExistsToast = false
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
