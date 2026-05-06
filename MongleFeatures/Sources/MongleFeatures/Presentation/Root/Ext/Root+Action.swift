//
//  Root+Action.swift
//  MongleFeatures
//

import Foundation
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
        /// APIClient refresh 실패 신호 수신 → 토큰 폐기 + 로그인 화면 + 안내 팝업
        case sessionExpired
        case dismissSessionExpiredPopup
        case logout
        /// 로그아웃 후 다음 runloop tick에 mainTab/questionDetail을 정리
        /// (in-flight onAppear 등 자식 액션이 nil 상태에 도달하지 않도록 분리)
        case completeLogout
        case refreshHomeData
        case pendingInviteCode(String?)
        case loadGroupsResponse(Result<[MongleGroup], Error>)
        case dismissHeartPopup
        case switchFamily(MongleGroup)
        case switchFamilyResponse(Result<MongleGroup, Error>)

        // MARK: Child Features
        case onboarding(OnboardingFeature.Action)
        case login(LoginFeature.Action)
        case groupSelect(GroupSelectFeature.Action)
        case mainTab(MainTabFeature.Action)
        case consent(ConsentFeature.Action)
        case emailSignup(EmailSignupFeature.Action)
        case emailLogin(EmailLoginFeature.Action)

        // MARK: Modal
        case questionDetail(PresentationAction<QuestionDetailFeature.Action>)
        case dismissQuestionDetail

        // MARK: Push Notification
        case deviceTokenReceived(Data)
        case openQuestion
        // MG-116 — 알림 탭 시 그룹 home 으로 진입. ANSWER_REQUEST/REMINDER_UNANSWERED 가 아닌
        // 모든 type 이 이 action 을 통해 mainTab.path 를 비우고 home 노출.
        case openHome
    }
}
