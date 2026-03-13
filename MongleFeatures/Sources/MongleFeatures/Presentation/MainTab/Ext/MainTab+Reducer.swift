//
//  File.swift
//  MongleFeatures
//
//  Created by 최용헌 on 3/12/26.
//

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

                case .home(.delegate(.navigateToPeerAnswerSelfAnswered(let memberName))):
                    let questionText = state.home.todayQuestion?.content ?? ""
                    state.modal = .peerAnswer(PeerAnswerFeature.State(
                        memberName: memberName,
                        questionText: questionText,
                        peerAnswer: "",
                        myAnswer: ""
                    ))
                    return .none

                case .home(.delegate(.navigateToPeerNotAnsweredNudge(let memberName))):
                    let questionText = state.home.todayQuestion?.content ?? ""
                    state.path.append(.peerNudge(PeerNudgeFeature.State(memberName: memberName, questionText: questionText)))
                    return .none

                case .home(.delegate(.showAnswerFirstPopup(let memberName))):
                    state.modal = .answerFirstPopup(AnswerFirstPopupFeature.State(memberName: memberName, popupType: .viewAnswer))
                    return .none

                case .home(.delegate(.showNudgeUnavailablePopup(_))):
                    // MongleView에서 로컬 alert으로 처리
                    return .none

                case .home(.delegate(.requestRefresh)):
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
                        try? await Task.sleep(nanoseconds: 350_000_000)
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
                        state.showRefreshToast = true
                        return .run { send in
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            await send(.dismissRefreshToast)
                        }
                    }

                case .modal(.presented(.heartCostPopup(.delegate(.cancelled)))):
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

                case .path(.element(id: _, action: .writeQuestion(.delegate(.questionSubmitted)))):
                    state.path.removeLast()
                    state.showWriteToast = true
                    return .run { send in
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        await send(.dismissWriteToast)
                    }

                case .delegate(.navigateToQuestionDetail(let question)):

                    state.path.append(
                        .questionDetail(
                            QuestionDetailFeature.State(
                                question: question,
                                currentUser: state.home.currentUser
                            )
                        )
                    )

                    return .none

                case .path(.element(id: _, action: .questionDetail(.delegate(.answerSubmitted(_))))):
                    state.home.hasAnsweredToday = true
                    return .none

                case .path(.element(id: _, action: .questionDetail(.delegate(.closed)))):
                    state.path.removeLast()
                    return .none

                case .path(.element(id: _, action: .notification(.delegate(.close)))):
                    state.path.removeLast()
                    return .none

                case .dismissRefreshToast:
                    state.showRefreshToast = false
                    return .none

                case .dismissWriteToast:
                    state.showWriteToast = false
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
