//
//  HomeFeature.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation
import ComposableArchitecture
import Domain
import UserNotifications
import UIKit

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var todayQuestion: Question?
        /// 오전 11시 이전에 표시할 어제 질문 (답변 수정 가능)
        public var yesterdayQuestion: Question?
        public var hasAnsweredYesterday: Bool = false
        public var family: MongleGroup?
        public var familyMembers: [User] = []
        public var currentUser: User?
        public var isLoading = false
        public var isRefreshing = false
        public var errorMessage: String?
        public var appError: AppError?
        public var hasFamily: Bool { family != nil }
        public var hasAnsweredToday: Bool = false
        public var hasSkippedToday: Bool = false
        public var hearts: Int = 5
        public var familyAnswerCount: Int
        // 각 멤버별 답변 상태 (userId: hasAnswered)
        public var memberAnswerStatus: [UUID: Bool] = [:]
        // 각 멤버별 패스 여부 (userId: hasSkipped) — 서버 memberAnswerStatuses 에서 파생
        public var memberSkippedStatus: [UUID: Bool] = [:]
        public var showGuestLoginPrompt: Bool = false
        public var streakDays: Int = 0
        public var allFamilies: [MongleGroup] = []
        public var hasUnreadNotifications: Bool = false
        public var showNotificationPermission: Bool = false

        public var isGuest: Bool { currentUser == nil }

        public init(
            todayQuestion: Question? = nil,
            yesterdayQuestion: Question? = nil,
            hasAnsweredYesterday: Bool = false,
            family: MongleGroup? = nil,
            familyMembers: [User] = [],
            currentUser: User? = nil,
            isLoading: Bool = false,
            isRefreshing: Bool = false,
            errorMessage: String? = nil,
            appError: AppError? = nil,
            hasAnsweredToday: Bool = false,
            hasSkippedToday: Bool = false,
            hearts: Int = 5,
            familyAnswerCount: Int = 0,
            memberAnswerStatus: [UUID: Bool] = [:],
            memberSkippedStatus: [UUID: Bool] = [:],
            streakDays: Int = 0,
            allFamilies: [MongleGroup] = [],
            hasUnreadNotifications: Bool = false
        ) {
            self.todayQuestion = todayQuestion
            self.yesterdayQuestion = yesterdayQuestion
            self.hasAnsweredYesterday = hasAnsweredYesterday
            self.family = family
            self.familyMembers = familyMembers
            self.currentUser = currentUser
            self.isLoading = isLoading
            self.isRefreshing = isRefreshing
            self.errorMessage = errorMessage
            self.appError = appError
            self.hasAnsweredToday = hasAnsweredToday
            self.hasSkippedToday = hasSkippedToday
            self.hearts = hearts
            self.familyAnswerCount = familyAnswerCount
            self.memberAnswerStatus = memberAnswerStatus
            self.memberSkippedStatus = memberSkippedStatus
            self.streakDays = streakDays
            self.allFamilies = allFamilies
            self.hasUnreadNotifications = hasUnreadNotifications
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
        case myMonggleTapped
        case nudgeUnavailableTapped(String)
        case refreshData
        case dismissError
        case guestLoginTapped
        case guestLoginDismissed
        case groupSelected(MongleGroup)
        case navigateToGroupSelectTapped

        // MARK: - Internal Actions
        case setLoading(Bool)
        case setRefreshing(Bool)
        case setError(String?)
        case setAppError(AppError?)
        case unreadNotificationsLoaded(Bool)
        case notificationPermissionAllowed
        case notificationPermissionSkipped

        // MARK: - Delegate Actions (상위 Feature에서 처리)
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case showQuestionSheet(Question)
            case navigateToNotifications
            case navigateToHeartsSystem
            case navigateToPeerAnswerSelfAnswered(String)
            case navigateToMyAnswer
            case showAnswerFirstPopup(String)
            case navigateToPeerNotAnsweredNudge(User)
            case showNudgeUnavailablePopup(String)
            case requestRefresh
            case requestLogin
            case groupSelected(MongleGroup)
            case navigateToGroupSelect
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - View Actions
            case .onAppear:
                // 그룹별 알림 허용 체크
                if let family = state.family {
                    let key = "mongle.notifSetup.\(family.id.uuidString)"
                    if !UserDefaults.standard.bool(forKey: key) {
                        state.showNotificationPermission = true
                    }
                }
                // 오늘·어제 질문 모두 없을 때만 로딩 요청
                if state.todayQuestion == nil && state.yesterdayQuestion == nil && !state.isLoading {
                    state.isLoading = true
                    return .send(.delegate(.requestRefresh))
                }
                return .none

            case .questionTapped:
                if state.isGuest {
                    state.showGuestLoginPrompt = true
                    return .none
                }
                // 오늘 질문 없으면(오전 11시 이전) 어제 질문으로 시트 표시
                let activeQuestion = state.todayQuestion ?? state.yesterdayQuestion
                guard let question = activeQuestion else { return .none }
                return .send(.delegate(.showQuestionSheet(question)))

            case .notificationTapped:
                return .send(.delegate(.navigateToNotifications))

            case .heartsTapped:
                if state.isGuest {
                    state.showGuestLoginPrompt = true
                    return .none
                }
                return .send(.delegate(.navigateToHeartsSystem))

            case .myMonggleTapped:
                if state.isGuest {
                    state.showGuestLoginPrompt = true
                    return .none
                }
                // 오전 11시 이전이면 어제 질문 기준으로 판단
                let activeQuestion = state.todayQuestion ?? state.yesterdayQuestion
                let hasAnswered = state.todayQuestion != nil ? state.hasAnsweredToday : state.hasAnsweredYesterday
                if hasAnswered {
                    return .send(.delegate(.navigateToMyAnswer))
                } else {
                    // 패스한 경우에도 질문 시트를 보여줌 (답변 가능 + 다른 사람 답변 열람 가능)
                    guard let question = activeQuestion else { return .none }
                    return .send(.delegate(.showQuestionSheet(question)))
                }

            case .peerAnswerTapped(let memberName):
                if state.isGuest {
                    state.showGuestLoginPrompt = true
                    return .none
                }
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

            case .groupSelected(let family):
                if state.isGuest {
                    state.showGuestLoginPrompt = true
                    return .none
                }
                return .send(.delegate(.groupSelected(family)))

            case .navigateToGroupSelectTapped:
                if state.isGuest {
                    state.showGuestLoginPrompt = true
                    return .none
                }
                return .send(.delegate(.navigateToGroupSelect))

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

            case .unreadNotificationsLoaded(let hasUnread):
                state.hasUnreadNotifications = hasUnread
                return .none

            case .notificationPermissionAllowed:
                if let family = state.family {
                    UserDefaults.standard.set(true, forKey: "mongle.notifSetup.\(family.id.uuidString)")
                }
                state.showNotificationPermission = false
                return .run { _ in
                    _ = try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .badge, .sound])
                    await MainActor.run {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }

            case .notificationPermissionSkipped:
                if let family = state.family {
                    UserDefaults.standard.set(true, forKey: "mongle.notifSetup.\(family.id.uuidString)")
                }
                state.showNotificationPermission = false
                return .none

            // MARK: - Delegate Actions
            case .delegate:
                // 상위 Feature에서 처리
                return .none
            }
        }
    }
}
