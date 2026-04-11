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

        // MARK: - v2 Character Growth (PRD §2)
        /// 현재 사용자 캐릭터 스테이지 (0~5). 서버 `GET /users/me/character-stage` 응답.
        public var characterStage: Int = 0
        /// 본체 크기 배율. 서버에서 stage→multiplier 매핑으로 내려옴 (1.0~1.6).
        public var sizeMultiplier: CGFloat = 1.0
        /// 클라이언트가 마지막으로 확인한 stage. UserDefaults 로 영속화. stage up 토스트 트리거에 사용.
        public var lastSeenStage: Int = 0
        /// 다음 stage 까지 필요한 streak (최종 단계면 nil)
        public var nextStageStreak: Int? = nil
        /// stage up 토스트 표시 중인 경우 새 stage 값 (PRD §2.4). nil = 비표시.
        public var stageUpToastStage: Int? = nil

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
        case stageUpToastDismissed
        case characterStageFetched(CharacterStage)
        case characterStageFetchFailed
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

    /// PRD §2.2 stage→sizeMultiplier 매핑. 서버 응답이 진실 소스이지만,
    /// 캐시/오프라인/mock 단계에서 클라이언트 폴백으로 사용한다.
    public static func sizeMultiplier(forStage stage: Int) -> CGFloat {
        switch stage {
        case 0: return 1.00
        case 1: return 1.10
        case 2: return 1.20
        case 3: return 1.32
        case 4: return 1.45
        default: return 1.60
        }
    }

    private static let lastSeenStageKey = "mongle.character.lastSeenStage"

    @Dependency(\.userRepository) var userRepository

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
                // v2: lastSeenStage 복원
                state.lastSeenStage = UserDefaults.standard.integer(forKey: Self.lastSeenStageKey)

                // PRD §2.2 — 캐릭터 스테이지 라이브 호출 (Engine-4).
                // stage up 감지/토스트는 .characterStageFetched 에서 처리.
                let stageEffect: Effect<Action> = state.isGuest ? .none : .run { send in
                    do {
                        let stage = try await userRepository.getCharacterStage()
                        await send(.characterStageFetched(stage))
                    } catch {
                        await send(.characterStageFetchFailed)
                    }
                }

                // 오늘·어제 질문 모두 없을 때만 로딩 요청
                if state.todayQuestion == nil && state.yesterdayQuestion == nil && !state.isLoading {
                    state.isLoading = true
                    return .merge(stageEffect, .send(.delegate(.requestRefresh)))
                }
                return stageEffect

            case .characterStageFetched(let stage):
                let newStage = stage.stage
                state.characterStage = newStage
                state.sizeMultiplier = CGFloat(stage.sizeMultiplier)
                state.nextStageStreak = stage.nextStageStreak
                state.streakDays = stage.streakDays
                // PRD §2.4: stage up 감지 + 토스트 + 햅틱. 첫 진입(lastSeen=0)은 연출 억제.
                if state.lastSeenStage > 0 && newStage > state.lastSeenStage {
                    state.stageUpToastStage = newStage
                    UserDefaults.standard.set(newStage, forKey: Self.lastSeenStageKey)
                    state.lastSeenStage = newStage
                    return .run { send in
                        #if os(iOS)
                        await MainActor.run {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                        #endif
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        await send(.stageUpToastDismissed)
                    }
                } else if state.lastSeenStage == 0 || newStage > state.lastSeenStage {
                    UserDefaults.standard.set(newStage, forKey: Self.lastSeenStageKey)
                    state.lastSeenStage = newStage
                }
                return .none

            case .characterStageFetchFailed:
                // 오프라인/실패 시: streakDays 기반 로컬 폴백 매핑.
                // streakDays 가 아직 모르는 경우 stage 0 유지.
                let streak = state.streakDays
                let fallbackStage: Int
                switch streak {
                case 0...2:    fallbackStage = 0
                case 3...6:    fallbackStage = 1
                case 7...29:   fallbackStage = 2
                case 30...99:  fallbackStage = 3
                case 100...364: fallbackStage = 4
                default:       fallbackStage = 5
                }
                state.characterStage = fallbackStage
                state.sizeMultiplier = Self.sizeMultiplier(forStage: fallbackStage)
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
            case .stageUpToastDismissed:
                state.stageUpToastStage = nil
                return .none

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
