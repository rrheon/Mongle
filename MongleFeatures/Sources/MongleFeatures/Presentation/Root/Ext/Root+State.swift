//
//  Root+State.swift
//  MongleFeatures
//

import Foundation
import ComposableArchitecture
import Domain

extension RootFeature {

    public struct RootData: Equatable, Sendable {
        public let user: User?
        public let question: Question?
        public let yesterdayQuestion: Question?
        public let hasAnsweredYesterday: Bool
        public let family: MongleGroup?
        public let familyMembers: [User]
        public let hasAnsweredToday: Bool
        public let hasSkippedToday: Bool
        public let memberAnswerStatus: [UUID: Bool]
        public let memberSkippedStatus: [UUID: Bool]
        public let streakDays: Int
        public let allFamilies: [MongleGroup]
        public let hasUnreadNotifications: Bool

        public init(
            user: User?,
            question: Question?,
            yesterdayQuestion: Question? = nil,
            hasAnsweredYesterday: Bool = false,
            family: MongleGroup?,
            familyMembers: [User],
            hasAnsweredToday: Bool = false,
            hasSkippedToday: Bool = false,
            memberAnswerStatus: [UUID: Bool] = [:],
            memberSkippedStatus: [UUID: Bool] = [:],
            streakDays: Int = 0,
            allFamilies: [MongleGroup] = [],
            hasUnreadNotifications: Bool = false
        ) {
            self.user = user
            self.question = question
            self.yesterdayQuestion = yesterdayQuestion
            self.hasAnsweredYesterday = hasAnsweredYesterday
            self.family = family
            self.familyMembers = familyMembers
            self.hasAnsweredToday = hasAnsweredToday
            self.hasSkippedToday = hasSkippedToday
            self.memberAnswerStatus = memberAnswerStatus
            self.memberSkippedStatus = memberSkippedStatus
            self.streakDays = streakDays
            self.allFamilies = allFamilies
            self.hasUnreadNotifications = hasUnreadNotifications
        }
    }

    @ObservableState
    public struct State: Equatable {

        // MARK: App Lifecycle
        public var appState: AppState = .loading
        public var hasSeenOnboarding: Bool

        // MARK: Child Features
        public var onboarding: OnboardingFeature.State
        public var login: LoginFeature.State
        public var groupSelect: GroupSelectFeature.State
        public var mainTab: MainTabFeature.State?
        public var consent: ConsentFeature.State?
        public var emailSignup: EmailSignupFeature.State?
        public var emailLogin: EmailLoginFeature.State?

        // MARK: Auth
        public var currentUser: User?
        public var loginProviderType: SocialProviderType?
        public var selectedQuestion: Question?

        // MARK: Heart Popup
        public var showHeartGrantedPopup: Bool = false

        // MARK: Session Expired Popup
        /// 토큰 만료(refresh 실패)로 강제 로그아웃됐을 때 LoginView 위에 띄울 안내 팝업.
        public var showSessionExpiredPopup: Bool = false

        // MARK: Push Navigation
        public var pendingOpenQuestion: Bool = false

        // MARK: Pending Invite
        public var pendingInviteCode: String? = nil

        // MARK: Modal
        @Presents public var questionDetail: QuestionDetailFeature.State?

        public enum AppState: Equatable {
            case loading
            case onboarding
            case unauthenticated
            case guestBrowsing
            /// 로그인은 됐지만 약관 동의가 필요한 상태
            case consentRequired
            /// 이메일 회원가입 플로우 진행 중 (Consent→입력→코드)
            case emailSignup
            /// 이메일 로그인 플로우 진행 중 (입력 폼)
            case emailLogin
            case groupSelection
            case authenticated
        }

        public init(
            appState: AppState = .loading,
            hasSeenOnboarding: Bool = UserDefaults.standard.bool(forKey: "mongle.hasSeenOnboarding"),
            onboarding: OnboardingFeature.State = OnboardingFeature.State(),
            login: LoginFeature.State = LoginFeature.State(),
            groupSelect: GroupSelectFeature.State = GroupSelectFeature.State(),
            mainTab: MainTabFeature.State? = nil,
            currentUser: User? = nil,
            loginProviderType: SocialProviderType? = nil,
            selectedQuestion: Question? = nil,
            showHeartGrantedPopup: Bool = false,
            questionDetail: QuestionDetailFeature.State? = nil
        ) {
            self.appState = appState
            self.hasSeenOnboarding = hasSeenOnboarding
            self.onboarding = onboarding
            self.login = login
            self.groupSelect = groupSelect
            self.mainTab = mainTab
            self.currentUser = currentUser
            self.loginProviderType = loginProviderType
            self.selectedQuestion = selectedQuestion
            self.showHeartGrantedPopup = showHeartGrantedPopup
            self.questionDetail = questionDetail
        }
    }
}
