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
        public let family: MongleGroup?
        public let familyMembers: [User]
        public let hasAnsweredToday: Bool
        public let memberAnswerStatus: [UUID: Bool]

        public init(
            user: User?,
            question: Question?,
            family: MongleGroup?,
            familyMembers: [User],
            hasAnsweredToday: Bool = false,
            memberAnswerStatus: [UUID: Bool] = [:]
        ) {
            self.user = user
            self.question = question
            self.family = family
            self.familyMembers = familyMembers
            self.hasAnsweredToday = hasAnsweredToday
            self.memberAnswerStatus = memberAnswerStatus
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

        // MARK: Auth
        public var currentUser: User?
        public var loginProviderType: SocialProviderType?
        public var selectedQuestion: Question?

        // MARK: Modal
        @Presents public var questionDetail: QuestionDetailFeature.State?

        public enum AppState: Equatable {
            case loading
            case onboarding
            case unauthenticated
            case guestBrowsing
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
            self.questionDetail = questionDetail
        }
    }
}
