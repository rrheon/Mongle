//
//  HomeFeature.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var todayQuestion: Question?
        public var family: MongleGroup?
        public var familyMembers: [User] = []
        public var currentUser: User?
        public var isLoading = false
        public var isRefreshing = false
        public var errorMessage: String?
        public var appError: AppError?
        public var hasFamily: Bool { family != nil }
        public var hasAnsweredToday: Bool = false
        public var hearts: Int = 5
        public var familyAnswerCount: Int
        // 각 멤버별 답변 상태 (userId: hasAnswered)
        public var memberAnswerStatus: [UUID: Bool] = [:]
        public var showGuestLoginPrompt: Bool = false
        public var streakDays: Int = 0

        public var isGuest: Bool { currentUser == nil }

        public init(
            todayQuestion: Question? = nil,
            family: MongleGroup? = nil,
            familyMembers: [User] = [],
            currentUser: User? = nil,
            isLoading: Bool = false,
            isRefreshing: Bool = false,
            errorMessage: String? = nil,
            appError: AppError? = nil,
            hasAnsweredToday: Bool = false,
            hearts: Int = 5,
            familyAnswerCount: Int = 0,
            memberAnswerStatus: [UUID: Bool] = [:],
            streakDays: Int = 0
        ) {
            self.todayQuestion = todayQuestion
            self.family = family
            self.familyMembers = familyMembers
            self.currentUser = currentUser
            self.isLoading = isLoading
            self.isRefreshing = isRefreshing
            self.errorMessage = errorMessage
            self.appError = appError
            self.hasAnsweredToday = hasAnsweredToday
            self.hearts = hearts
            self.familyAnswerCount = familyAnswerCount
            self.memberAnswerStatus = memberAnswerStatus
            self.streakDays = streakDays
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case onAppear
        case questionTapped
        case notificationTapped
        case heartsTapped
        case peerAnswerTapped(String)
        case answerRequiredTapped(String)
        case peerNudgeTapped(String)
        case nudgeUnavailableTapped(String)
        case refreshData
        case dismissError
        case guestLoginTapped
        case guestLoginDismissed

        // MARK: - Internal Actions
        case setLoading(Bool)
        case setRefreshing(Bool)
        case setError(String?)
        case setAppError(AppError?)

        // MARK: - Delegate Actions (상위 Feature에서 처리)
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case showQuestionSheet(Question)
            case navigateToNotifications
            case navigateToHeartsSystem
            case navigateToPeerAnswerSelfAnswered(String)
            case showAnswerFirstPopup(String)
            case navigateToPeerNotAnsweredNudge(User)
            case showNudgeUnavailablePopup(String)
            case requestRefresh
            case requestLogin
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - View Actions
            case .onAppear:
                // 데이터가 없으면 로딩 요청
                if state.todayQuestion == nil && !state.isLoading {
                    state.isLoading = true
                    return .send(.delegate(.requestRefresh))
                }
                return .none

            case .questionTapped:
                if state.isGuest {
                    state.showGuestLoginPrompt = true
                    return .none
                }
                guard let question = state.todayQuestion else { return .none }
                return .send(.delegate(.showQuestionSheet(question)))

            case .notificationTapped:
                return .send(.delegate(.navigateToNotifications))

            case .heartsTapped:
                if state.isGuest {
                    state.showGuestLoginPrompt = true
                    return .none
                }
                return .send(.delegate(.navigateToHeartsSystem))

            case .peerAnswerTapped(let memberName):
                return .send(.delegate(.navigateToPeerAnswerSelfAnswered(memberName)))

            case .answerRequiredTapped(let memberName):
                if state.isGuest {
                    state.showGuestLoginPrompt = true
                    return .none
                }
                return .send(.delegate(.showAnswerFirstPopup(memberName)))

            case .peerNudgeTapped(let memberName):
                if state.isGuest {
                    state.showGuestLoginPrompt = true
                    return .none
                }
                // familyMembers에서 이름으로 User 조회
                let targetUser = state.familyMembers.first { $0.name == memberName }
                if let user = targetUser {
                    return .send(.delegate(.navigateToPeerNotAnsweredNudge(user)))
                }
                return .none

            case .nudgeUnavailableTapped(let memberName):
                return .send(.delegate(.showNudgeUnavailablePopup(memberName)))

            case .refreshData:
                guard !state.isRefreshing else { return .none }
                state.isRefreshing = true
                state.errorMessage = nil
                return .send(.delegate(.requestRefresh))

            case .dismissError:
                state.errorMessage = nil
                state.appError = nil
                return .none

            case .guestLoginTapped:
                state.showGuestLoginPrompt = false
                return .send(.delegate(.requestLogin))

            case .guestLoginDismissed:
                state.showGuestLoginPrompt = false
                return .none

            // MARK: - Internal Actions
            case .setLoading(let isLoading):
                state.isLoading = isLoading
                if !isLoading {
                    state.isRefreshing = false
                }
                return .none

            case .setRefreshing(let isRefreshing):
                state.isRefreshing = isRefreshing
                return .none

            case .setError(let message):
                state.errorMessage = message
                state.isLoading = false
                state.isRefreshing = false
                return .none

            case .setAppError(let error):
                state.appError = error
                state.errorMessage = error?.userMessage
                state.isLoading = false
                state.isRefreshing = false
                return .none

            // MARK: - Delegate Actions
            case .delegate:
                // 상위 Feature에서 처리
                return .none
            }
        }
    }
}
