//
//  Root+Action.swift
//  MongleFeatures
//

import ComposableArchitecture
import Domain

extension RootFeature {

    @CasePathable
    public enum Action: Sendable {

        // MARK: Lifecycle
        case onAppear
        case checkAuthResponse(User?)
        case loadDataResponse(Result<RootData, Error>)
        case showLoginScreen
        case logout
        case refreshHomeData

        // MARK: Child Features
        case onboarding(OnboardingFeature.Action)
        case login(LoginFeature.Action)
        case groupSelect(GroupSelectFeature.Action)
        case mainTab(MainTabFeature.Action)

        // MARK: Modal
        case questionDetail(PresentationAction<QuestionDetailFeature.Action>)
        case dismissQuestionDetail
    }
}
