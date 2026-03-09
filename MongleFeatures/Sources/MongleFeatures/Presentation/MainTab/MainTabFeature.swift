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
    @ObservableState
    public struct State: Equatable {
        public var selectedTab: Tab = .home
        public var isGuestMode = false
        public var showLoginRequiredAlert = false
        public var home: HomeFeature.State
        public var history: HistoryFeature.State
        public var notification: NotificationFeature.State
        public var settings: SettingsFeature.State
        @Presents public var profileEdit: ProfileEditFeature.State?
        @Presents public var peerAnswer: PeerAnswerFeature.State?
        @Presents public var answerFirstPopup: AnswerFirstPopupFeature.State?
        @Presents public var peerNudge: PeerNudgeFeature.State?
        @Presents public var supportScreen: SupportScreenFeature.State?

        public enum Tab: Hashable, Sendable {
            case home
            case history
            case notification
            case settings
        }

        public init(
            selectedTab: Tab = .home,
            isGuestMode: Bool = false,
            showLoginRequiredAlert: Bool = false,
            home: HomeFeature.State = HomeFeature.State(),
            history: HistoryFeature.State = HistoryFeature.State(),
            notification: NotificationFeature.State = NotificationFeature.State(),
            settings: SettingsFeature.State = SettingsFeature.State()
        ) {
            self.selectedTab = selectedTab
            self.isGuestMode = isGuestMode
            self.showLoginRequiredAlert = showLoginRequiredAlert
            self.home = home
            self.history = history
            self.notification = notification
            self.settings = settings
        }
    }

    public enum Action: Sendable, Equatable {
        case selectTab(State.Tab)
        case loginRequiredAlertConfirmed
        case loginRequiredAlertCancelled
        case home(HomeFeature.Action)
        case history(HistoryFeature.Action)
        case notification(NotificationFeature.Action)
        case settings(SettingsFeature.Action)
        case profileEdit(PresentationAction<ProfileEditFeature.Action>)
        case peerAnswer(PresentationAction<PeerAnswerFeature.Action>)
        case answerFirstPopup(PresentationAction<AnswerFirstPopupFeature.Action>)
        case peerNudge(PresentationAction<PeerNudgeFeature.Action>)
        case supportScreen(PresentationAction<SupportScreenFeature.Action>)
        case logout

        // MARK: - Delegate Actions (RootFeature에서 처리)
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case navigateToQuestionDetail(Question)
            case requestRefresh
            case requestLogin
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }

        Scope(state: \.history, action: \.history) {
            HistoryFeature()
        }

        Scope(state: \.notification, action: \.notification) {
            NotificationFeature()
        }

        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Reduce { state, action in
            switch action {
            case .selectTab(let tab):
                guard !(state.isGuestMode && tab != .home) else {
                    state.selectedTab = .home
                    state.showLoginRequiredAlert = true
                    return .none
                }
                state.selectedTab = tab
                return .none

            case .loginRequiredAlertConfirmed:
                state.showLoginRequiredAlert = false
                return .send(.delegate(.requestLogin))

            case .loginRequiredAlertCancelled:
                state.showLoginRequiredAlert = false
                return .none

            case .home(let homeAction):
                return handleHomeAction(state: &state, action: homeAction)

            case .history(let historyAction):
                return handleHistoryAction(state: &state, action: historyAction)

            case .notification(let notificationAction):
                return handleNotificationAction(state: &state, action: notificationAction)

            case .settings(let settingsAction):
                return handleSettingsAction(state: &state, action: settingsAction)

            case .profileEdit(let action):
                return handleProfileEditAction(state: &state, action: action)

            case .peerAnswer(let action):
                return handlePeerAnswerAction(state: &state, action: action)

            case .answerFirstPopup(let action):
                return handleAnswerFirstPopupAction(state: &state, action: action)

            case .peerNudge(let action):
                return handlePeerNudgeAction(state: &state, action: action)

            case .supportScreen(let action):
                return handleSupportScreenAction(state: &state, action: action)

            case .logout:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$profileEdit, action: \.profileEdit) {
            ProfileEditFeature()
        }
        .ifLet(\.$peerAnswer, action: \.peerAnswer) {
            PeerAnswerFeature()
        }
        .ifLet(\.$answerFirstPopup, action: \.answerFirstPopup) {
            AnswerFirstPopupFeature()
        }
        .ifLet(\.$peerNudge, action: \.peerNudge) {
            PeerNudgeFeature()
        }
        .ifLet(\.$supportScreen, action: \.supportScreen) {
            SupportScreenFeature()
        }
    }

    private func handleHomeAction(state: inout State, action: HomeFeature.Action) -> Effect<Action> {
        switch action {
        case .delegate(.navigateToQuestionDetail(let question)):
            guard !state.isGuestMode else {
                state.showLoginRequiredAlert = true
                return .none
            }
            return .send(.delegate(.navigateToQuestionDetail(question)))
        case .delegate(.requestRefresh):
            guard !state.isGuestMode else { return .none }
            return .send(.delegate(.requestRefresh))
        case .delegate(.navigateToNotifications):
            guard !state.isGuestMode else {
                state.showLoginRequiredAlert = true
                return .none
            }
            state.selectedTab = .notification
            return .none
        case .delegate(.navigateToHeartsSystem):
            guard !state.isGuestMode else {
                state.showLoginRequiredAlert = true
                return .none
            }
            state.supportScreen = SupportScreenFeature.State(screen: .heartsSystem)
            return .none
        case .delegate(.navigateToPeerAnswerSelfAnswered(let memberName)):
            guard !state.isGuestMode else {
                state.showLoginRequiredAlert = true
                return .none
            }
            state.peerAnswer = PeerAnswerFeature.State(
                memberName: memberName,
                questionText: state.home.todayQuestion?.content ?? "오늘 당신을 웃게 한 건 무엇인가요?",
                peerAnswer: "아침에 고양이가 제 발 위에서 잠든 것을 발견했어요. 너무 귀여워서 한동안 꼼짝도 못했지 뭐예요 🐱",
                myAnswer: "아이들이 아침에 처음으로 같이 요리해줬어요. 계란이 좀 타긴 했지만 정말 행복했어요 😊",
                peerAnswerTime: "오늘 오전 9:23",
                myAnswerTime: "오늘 오전 8:41"
            )
            return .none
        case .delegate(.showAnswerFirstPopup(let memberName)):
            guard !state.isGuestMode else {
                state.showLoginRequiredAlert = true
                return .none
            }
            state.answerFirstPopup = AnswerFirstPopupFeature.State(memberName: memberName)
            return .none
        case .delegate(.navigateToPeerNotAnsweredNudge(let memberName)):
            guard !state.isGuestMode else {
                state.showLoginRequiredAlert = true
                return .none
            }
            state.peerNudge = PeerNudgeFeature.State(memberName: memberName)
            return .none
        default:
            return .none
        }
    }

    private func handleHistoryAction(state: inout State, action: HistoryFeature.Action) -> Effect<Action> {
        switch action {
        case .delegate(.navigateToQuestionDetail(let question, _)):
            return .send(.delegate(.navigateToQuestionDetail(question)))
        case .delegate(.navigateToHistoryCalendar):
            state.supportScreen = SupportScreenFeature.State(screen: .historyCalendar)
            return .none
        default:
            return .none
        }
    }

    private func handleNotificationAction(state: inout State, action: NotificationFeature.Action) -> Effect<Action> {
        switch action {
        case .delegate(.navigateToQuestion):
            state.selectedTab = .home
            guard let question = state.home.todayQuestion else { return .none }
            return .send(.delegate(.navigateToQuestionDetail(question)))
        case .delegate(.navigateToTree):
            state.selectedTab = .home
            return .none
        case .delegate(.navigateToPeerNotAnsweredNudge(let memberName)):
            state.peerNudge = PeerNudgeFeature.State(memberName: memberName)
            return .none
        default:
            return .none
        }
    }

    private func handleSettingsAction(state: inout State, action: SettingsFeature.Action) -> Effect<Action> {
        switch action {
        case .delegate(.navigateToProfileEdit):
            state.profileEdit = ProfileEditFeature.State(user: state.settings.currentUser)
            return .none
        case .delegate(.navigateToNotifications):
            state.selectedTab = .notification
            return .none
        case .delegate(.navigateToNotificationSettings):
            state.supportScreen = SupportScreenFeature.State(screen: .notificationSettings)
            return .none
        case .delegate(.navigateToGroupManagement):
            state.supportScreen = SupportScreenFeature.State(screen: .groupManagement)
            return .none
        case .delegate(.navigateToMoodHistory):
            state.supportScreen = SupportScreenFeature.State(screen: .moodHistory)
            return .none
        case .delegate(.logout), .delegate(.accountDeleted):
            return .send(.logout)
        case .delegate(.openURL):
            return .none
        default:
            return .none
        }
    }

    private func handleProfileEditAction(
        state: inout State,
        action: PresentationAction<ProfileEditFeature.Action>
    ) -> Effect<Action> {
        switch action {
        case .presented(.delegate(.profileUpdated(let user))):
            state.settings.currentUser = user
            state.home.currentUser = user
            state.profileEdit = nil
            return .none
        case .presented(.delegate(.cancelled)):
            state.profileEdit = nil
            return .none
        default:
            return .none
        }
    }

    private func handlePeerAnswerAction(
        state: inout State,
        action: PresentationAction<PeerAnswerFeature.Action>
    ) -> Effect<Action> {
        if case .presented(.delegate(.close)) = action {
            state.peerAnswer = nil
        }
        return .none
    }

    private func handleAnswerFirstPopupAction(
        state: inout State,
        action: PresentationAction<AnswerFirstPopupFeature.Action>
    ) -> Effect<Action> {
        switch action {
        case .presented(.delegate(.answerNow)):
            state.answerFirstPopup = nil
            guard let question = state.home.todayQuestion else { return .none }
            return .send(.delegate(.navigateToQuestionDetail(question)))
        case .presented(.delegate(.close)):
            state.answerFirstPopup = nil
            return .none
        default:
            return .none
        }
    }

    private func handlePeerNudgeAction(
        state: inout State,
        action: PresentationAction<PeerNudgeFeature.Action>
    ) -> Effect<Action> {
        if case .presented(.delegate(.close)) = action {
            state.peerNudge = nil
        }
        return .none
    }

    private func handleSupportScreenAction(
        state: inout State,
        action: PresentationAction<SupportScreenFeature.Action>
    ) -> Effect<Action> {
        if case .presented(.delegate(.close)) = action {
            state.supportScreen = nil
        }
        return .none
    }
}
