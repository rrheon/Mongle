//
//  MainTabFeature.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct MainTabFeature {
  public init() {}
  
  public var body: some ReducerOf<Self> {
    reducer
  }
}
//@Reducer
//public struct MainTabFeature {
//    @ObservableState
//    public struct State: Equatable {
//        public var selectedTab: Tab = .home
//        public var isGuestMode = false
//        public var home: HomeFeature.State
//        public var history: HistoryFeature.State
//        public var notification: NotificationFeature.State
//        public var profile: ProfileEditFeature.State
//        @Presents public var peerAnswer: PeerAnswerFeature.State?
//        @Presents public var answerFirstPopup: AnswerFirstPopupFeature.State?
//        @Presents public var peerNudge: PeerNudgeFeature.State?
//        @Presents public var supportScreen: SupportScreenFeature.State?
//        @Presents public var homeQuestionDetail: QuestionDetailFeature.State?
//        @Presents public var questionSheet: QuestionSheetFeature.State?
//        @Presents public var heartCostPopup: HeartCostPopupFeature.State?
//        @Presents public var writeQuestion: WriteQuestionFeature.State?
//        @Presents public var notificationPush: NotificationFeature.State?
//      
//        public var showRefreshToast: Bool = false
//        public var showWriteToast: Bool = false
//
//        public enum Tab: Hashable, Sendable {
//            case home
//            case history
//            case notification
//            case settings
//        }
//
//        public init(
//            selectedTab: Tab = .home,
//            isGuestMode: Bool = false,
//            home: HomeFeature.State = HomeFeature.State(),
//            history: HistoryFeature.State = HistoryFeature.State(),
//            notification: NotificationFeature.State = NotificationFeature.State(),
//            profile: ProfileEditFeature.State = ProfileEditFeature.State()
//        ) {
//            self.selectedTab = selectedTab
//            self.isGuestMode = isGuestMode
//            self.home = home
//            self.history = history
//            self.notification = notification
//            self.profile = profile
//        }
//    }
//
//    public enum Action: Sendable, Equatable {
//        case selectTab(State.Tab)
//        case loginRequiredAlertConfirmed
//        case loginRequiredAlertCancelled
//        case home(HomeFeature.Action)
//        case history(HistoryFeature.Action)
//        case notification(NotificationFeature.Action)
//        case profile(ProfileEditFeature.Action)
//        case peerAnswer(PresentationAction<PeerAnswerFeature.Action>)
//        case answerFirstPopup(PresentationAction<AnswerFirstPopupFeature.Action>)
//        case peerNudge(PresentationAction<PeerNudgeFeature.Action>)
//        case supportScreen(PresentationAction<SupportScreenFeature.Action>)
//        case homeQuestionDetail(PresentationAction<QuestionDetailFeature.Action>)
//        case questionSheet(PresentationAction<QuestionSheetFeature.Action>)
//        case heartCostPopup(PresentationAction<HeartCostPopupFeature.Action>)
//        case writeQuestion(PresentationAction<WriteQuestionFeature.Action>)
//        case dismissRefreshToast
//        case dismissWriteToast
//        case logout
//
//        // MARK: - Delegate Actions (RootFeature에서 처리)
//        case delegate(Delegate)
//
//        public enum Delegate: Sendable, Equatable {
//            case navigateToQuestionDetail(Question)
//            case requestRefresh
//            case requestLogin
//        }
//    }
//
//    public init() {}
//
//    // Swift 타입 체커 한계 회피를 위해 body를 두 단계로 분리
//    public var body: some Reducer<State, Action> {
//        newFeatureReducers
//    }
//
//    // 새로 추가된 피처의 ifLet (3개)
//    private var newFeatureReducers: some Reducer<State, Action> {
//        baseReducers
//            .ifLet(\.$questionSheet, action: \.questionSheet) { QuestionSheetFeature() }
//            .ifLet(\.$heartCostPopup, action: \.heartCostPopup) { HeartCostPopupFeature() }
//            .ifLet(\.$writeQuestion, action: \.writeQuestion) { WriteQuestionFeature() }
//            .ifLet(\.$notificationPush, action: \.notification) { NotificationFeature() }
//    }
//
//    // 기존 피처의 Scope / Reduce / ifLet
//    private var baseReducers: some Reducer<State, Action> {
//        CombineReducers {
//            Scope(state: \.home, action: \.home) { HomeFeature() }
//            Scope(state: \.history, action: \.history) { HistoryFeature() }
//            Scope(state: \.notification, action: \.notification) { NotificationFeature() }
//            Scope(state: \.profile, action: \.profile) { ProfileEditFeature() }
//            Reduce { state, action in
//                switch action {
//                case .selectTab(let tab):
//                    state.selectedTab = tab
//                    return .none
//                case .loginRequiredAlertConfirmed:
//                    return .send(.delegate(.requestLogin))
//                case .loginRequiredAlertCancelled:
//                    return .none
//                case .home(let homeAction):
//                    return handleHomeAction(state: &state, action: homeAction)
//                case .history(let historyAction):
//                    return handleHistoryAction(state: &state, action: historyAction)
//                case .notification(let notificationAction):
//                    return handleNotificationAction(state: &state, action: notificationAction)
//                case .profile(let profileAction):
//                    return handleProfileAction(state: &state, action: profileAction)
//                case .peerAnswer(let action):
//                    return handlePeerAnswerAction(state: &state, action: action)
//                case .answerFirstPopup(let action):
//                    return handleAnswerFirstPopupAction(state: &state, action: action)
//                case .peerNudge(let action):
//                    return handlePeerNudgeAction(state: &state, action: action)
//                case .supportScreen(let action):
//                    return handleSupportScreenAction(state: &state, action: action)
//                case .homeQuestionDetail(let action):
//                    return handleHomeQuestionDetailAction(state: &state, action: action)
//                case .questionSheet(let action):
//                    return handleQuestionSheetAction(state: &state, action: action)
//                case .heartCostPopup(let action):
//                    return handleHeartCostPopupAction(state: &state, action: action)
//                case .writeQuestion(let action):
//                    return handleWriteQuestionAction(state: &state, action: action)
//                case .dismissRefreshToast:
//                    state.showRefreshToast = false
//                    return .none
//                case .dismissWriteToast:
//                    state.showWriteToast = false
//                    return .none
//                case .logout:
//                    return .none
//                case .delegate:
//                    return .none
//                }
//            }
//        }
//        .ifLet(\.$peerAnswer, action: \.peerAnswer) { PeerAnswerFeature() }
//        .ifLet(\.$answerFirstPopup, action: \.answerFirstPopup) { AnswerFirstPopupFeature() }
//        .ifLet(\.$peerNudge, action: \.peerNudge) { PeerNudgeFeature() }
//        .ifLet(\.$supportScreen, action: \.supportScreen) { SupportScreenFeature() }
//        .ifLet(\.$homeQuestionDetail, action: \.homeQuestionDetail) { QuestionDetailFeature() }
//    }
//
//    private func handleHomeAction(state: inout State, action: HomeFeature.Action) -> Effect<Action> {
//        switch action {
//        case .delegate(.showQuestionSheet(let question)):
//            state.questionSheet = QuestionSheetFeature.State(
//                questionText: question.content,
//                isAnswered: state.home.hasAnsweredToday
//            )
//            return .none
//        case .delegate(.requestRefresh):
//            return .send(.delegate(.requestRefresh))
//        case .delegate(.navigateToNotifications):
//            state.selectedTab = .notification
//            return .none
//        case .delegate(.navigateToHeartsSystem):
//            state.supportScreen = SupportScreenFeature.State(screen: .heartsSystem)
//            return .none
//        case .delegate(.navigateToPeerAnswerSelfAnswered(let memberName)):
//            state.peerAnswer = PeerAnswerFeature.State(
//                memberName: memberName,
//                questionText: state.home.todayQuestion?.content ?? "오늘 당신을 웃게 한 건 무엇인가요?",
//                peerAnswer: "아침에 고양이가 제 발 위에서 잠든 것을 발견했어요. 너무 귀여워서 한동안 꼼짝도 못했지 뭐예요 🐱",
//                myAnswer: "아이들이 아침에 처음으로 같이 요리해줬어요. 계란이 좀 타긴 했지만 정말 행복했어요 😊",
//                peerAnswerTime: "오늘 오전 9:23",
//                myAnswerTime: "오늘 오전 8:41"
//            )
//            return .none
//        case .delegate(.showAnswerFirstPopup(let memberName)):
//            state.answerFirstPopup = AnswerFirstPopupFeature.State(memberName: memberName, popupType: .viewAnswer)
//            return .none
//        case .delegate(.showNudgeUnavailablePopup(let memberName)):
//            state.answerFirstPopup = AnswerFirstPopupFeature.State(memberName: memberName, popupType: .nudge)
//            return .none
//        case .delegate(.navigateToPeerNotAnsweredNudge(let memberName)):
//            state.peerNudge = PeerNudgeFeature.State(
//                memberName: memberName,
//                questionText: state.home.todayQuestion?.content ?? ""
//            )
//            return .none
//        case .delegate(.navigateToNotifications):
//          state.notificationPush = NotificationFeature.State()
//          return .none
//        default:
//            return .none
//        }
//    }
//
//    private func handleHistoryAction(state: inout State, action: HistoryFeature.Action) -> Effect<Action> {
//        switch action {
//        case .delegate(.navigateToQuestionDetail(let question, _)):
//            return .send(.delegate(.navigateToQuestionDetail(question)))
//        case .delegate(.navigateToHistoryCalendar):
//            state.supportScreen = SupportScreenFeature.State(screen: .historyCalendar)
//            return .none
//        default:
//            return .none
//        }
//    }
//
//    private func handleNotificationAction(state: inout State, action: NotificationFeature.Action) -> Effect<Action> {
//        switch action {
//        case .delegate(.navigateToQuestion):
//            state.selectedTab = .home
//            guard let question = state.home.todayQuestion else { return .none }
//            return .send(.delegate(.navigateToQuestionDetail(question)))
//        case .delegate(.navigateToTree):
//            state.selectedTab = .home
//            return .none
//        case .delegate(.navigateToPeerNotAnsweredNudge(let memberName)):
//            state.peerNudge = PeerNudgeFeature.State(
//                memberName: memberName,
//                questionText: state.home.todayQuestion?.content ?? ""
//            )
//            return .none
//        default:
//            return .none
//        }
//    }
//
//    private func handleProfileAction(state: inout State, action: ProfileEditFeature.Action) -> Effect<Action> {
//        switch action {
//        case .delegate(.profileUpdated(let user)):
//            state.home.currentUser = user
//            return .none
//        case .delegate(.navigateToMoodHistory):
//            state.supportScreen = SupportScreenFeature.State(screen: .moodHistory)
//            return .none
//        case .delegate(.navigateToNotificationSettings):
//            state.supportScreen = SupportScreenFeature.State(screen: .notificationSettings)
//            return .none
//        case .delegate(.navigateToGroupManagement):
//            state.supportScreen = SupportScreenFeature.State(screen: .groupManagement)
//            return .none
//        case .delegate(.navigateToMoodSetting), .delegate(.navigateToAccountManagement):
//            return .none
//        default:
//            return .none
//        }
//    }
//
//    private func handlePeerAnswerAction(
//        state: inout State,
//        action: PresentationAction<PeerAnswerFeature.Action>
//    ) -> Effect<Action> {
//        if case .presented(.delegate(.close)) = action {
//            state.peerAnswer = nil
//        }
//        return .none
//    }
//
//    private func handleAnswerFirstPopupAction(
//        state: inout State,
//        action: PresentationAction<AnswerFirstPopupFeature.Action>
//    ) -> Effect<Action> {
//        switch action {
//        case .presented(.delegate(.answerNow)):
//            state.answerFirstPopup = nil
//            guard let question = state.home.todayQuestion else { return .none }
//            return .send(.delegate(.navigateToQuestionDetail(question)))
//        case .presented(.delegate(.close)):
//            state.answerFirstPopup = nil
//            return .none
//        default:
//            return .none
//        }
//    }
//
//    private func handlePeerNudgeAction(
//        state: inout State,
//        action: PresentationAction<PeerNudgeFeature.Action>
//    ) -> Effect<Action> {
//        if case .presented(.delegate(.close)) = action {
//            state.peerNudge = nil
//        }
//        return .none
//    }
//
//    private func handleSupportScreenAction(
//        state: inout State,
//        action: PresentationAction<SupportScreenFeature.Action>
//    ) -> Effect<Action> {
//        if case .presented(.delegate(.close)) = action {
//            state.supportScreen = nil
//        }
//        return .none
//    }
//
//    private func handleHomeQuestionDetailAction(
//        state: inout State,
//        action: PresentationAction<QuestionDetailFeature.Action>
//    ) -> Effect<Action> {
//        switch action {
//        case .presented(.delegate(.answerSubmitted)):
//            state.home.hasAnsweredToday = true
//            return .none
//        case .presented(.delegate(.closed)):
//            state.homeQuestionDetail = nil
//            return .none
//        default:
//            return .none
//        }
//    }
//
//    private func handleQuestionSheetAction(
//        state: inout State,
//        action: PresentationAction<QuestionSheetFeature.Action>
//    ) -> Effect<Action> {
//        switch action {
//        case .presented(.delegate(.close)):
//            state.questionSheet = nil
//            return .none
//        case .presented(.delegate(.navigateToAnswer)):
//            state.questionSheet = nil
//            guard let question = state.home.todayQuestion else { return .none }
//            state.homeQuestionDetail = QuestionDetailFeature.State(
//                question: question,
//                currentUser: state.home.currentUser
//            )
//            return .none
//        case .presented(.delegate(.showWriteQuestionCost)):
//            state.questionSheet = nil
//            state.heartCostPopup = HeartCostPopupFeature.State(costType: .writeQuestion)
//            return .none
//        case .presented(.delegate(.showRefreshQuestionCost)):
//            state.questionSheet = nil
//            state.heartCostPopup = HeartCostPopupFeature.State(costType: .refreshQuestion)
//            return .none
//        default:
//            return .none
//        }
//    }
//
//    private func handleHeartCostPopupAction(
//        state: inout State,
//        action: PresentationAction<HeartCostPopupFeature.Action>
//    ) -> Effect<Action> {
//        switch action {
//        case .presented(.delegate(.confirmed(.writeQuestion))):
//            state.heartCostPopup = nil
//            state.writeQuestion = WriteQuestionFeature.State()
//            return .none
//        case .presented(.delegate(.confirmed(.refreshQuestion))):
//            state.heartCostPopup = nil
//            state.showRefreshToast = true
//            return .run { send in
//                try? await Task.sleep(nanoseconds: 3_000_000_000)
//                await send(.dismissRefreshToast)
//            }
//        case .presented(.delegate(.cancelled)):
//            state.heartCostPopup = nil
//            return .none
//        default:
//            return .none
//        }
//    }
//
//    private func handleWriteQuestionAction(
//        state: inout State,
//        action: PresentationAction<WriteQuestionFeature.Action>
//    ) -> Effect<Action> {
//        switch action {
//        case .presented(.delegate(.close)):
//            state.writeQuestion = nil
//            return .none
//        case .presented(.delegate(.questionSubmitted)):
//            state.writeQuestion = nil
//            state.showWriteToast = true
//            return .run { send in
//                try? await Task.sleep(nanoseconds: 3_000_000_000)
//                await send(.dismissWriteToast)
//            }
//        default:
//            return .none
//        }
//    }
//}
