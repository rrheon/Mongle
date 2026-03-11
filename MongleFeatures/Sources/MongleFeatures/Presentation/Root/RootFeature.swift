//
//  RootFeature.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct RootFeature {
    @ObservableState
    public struct State: Equatable {
        public var appState: AppState = .loading
        public var hasSeenOnboarding: Bool
        public var onboarding: OnboardingFeature.State
        public var login: LoginFeature.State
        public var groupSelect: GroupSelectFeature.State
        public var mainTab: MainTabFeature.State?
        public var currentUser: User?
        public var loginProviderType: SocialProviderType?
        public var selectedQuestion: Question?

        // Child Feature States
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
            hasSeenOnboarding: Bool = false,
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

    public enum Action: Sendable {
        case onAppear
        case checkAuthResponse(User?)
        case loadDataResponse(Result<RootData, Error>)
        case showLoginScreen
        case onboarding(OnboardingFeature.Action)
        case login(LoginFeature.Action)
        case groupSelect(GroupSelectFeature.Action)
        case mainTab(MainTabFeature.Action)
        case logout

        // Navigation Actions
        case dismissQuestionDetail

        // Child Feature Actions
        case questionDetail(PresentationAction<QuestionDetailFeature.Action>)

        // Data Refresh
        case refreshHomeData
    }

    public struct RootData: Equatable, Sendable {
        public let user: User?
        public let question: Question?
        public let family: MongleGroup?
        public let familyMembers: [User]
        public let hasAnsweredToday: Bool

        public init(
            user: User?,
            question: Question?,
            family: MongleGroup?,
            familyMembers: [User],
            hasAnsweredToday: Bool = false
        ) {
            self.user = user
            self.question = question
            self.family = family
            self.familyMembers = familyMembers
            self.hasAnsweredToday = hasAnsweredToday
        }
    }

    @Dependency(\.authRepository) var authRepository
    @Dependency(\.familyRepository) var familyRepository
    @Dependency(\.questionRepository) var questionRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }

        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }

        Scope(state: \.groupSelect, action: \.groupSelect) {
            GroupSelectFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                state.appState = .loading
                return .run { send in
                    let user = try? await authRepository.getCurrentUser()
                    await send(.checkAuthResponse(user))
                }

            case .refreshHomeData:
                return .run { [currentUser = state.currentUser] send in
                    do {
                        let familyResult = try await familyRepository.getMyFamily()
                        let family = familyResult?.0
                        let familyMembers = familyResult?.1 ?? []

                        let todayQuestion = try await questionRepository.getTodayQuestion()

                        let data = RootData(
                            user: currentUser,
                            question: todayQuestion,
                            family: family,
                            familyMembers: familyMembers,
                            hasAnsweredToday: true // TODO: 실제 API 연동 시 제거
                        )
                        await send(.loadDataResponse(.success(data)))
                    } catch {
                        await send(.loadDataResponse(.failure(error)))
                    }
                }

            case .checkAuthResponse(let user):
                if let user = user {
                    state.currentUser = user
                    state.appState = .loading
                    return .send(.refreshHomeData)
                } else {
                    state.appState = state.hasSeenOnboarding ? .unauthenticated : .onboarding
                    return .none
                }

            case .loadDataResponse(.success(let data)):
                state.currentUser = data.user

                // HomeFeature State 업데이트
                let homeState = HomeFeature.State(
                    todayQuestion: data.question,
                    family: data.family,
                    familyMembers: data.familyMembers,
                    currentUser: data.user,
                    isLoading: false,
                    isRefreshing: false,
                    errorMessage: nil,
                    hasAnsweredToday: data.hasAnsweredToday
                )

                // 기존 MainTab이 있으면 home만 업데이트, 없으면 새로 생성
                let providerType = state.loginProviderType
                if state.mainTab != nil {
                    state.mainTab?.home = homeState
                    state.mainTab?.settings.loginProviderType = providerType
                    state.mainTab?.settings.currentUser = data.user
                } else {
                    state.mainTab = MainTabFeature.State(
                        home: homeState,
                        settings: SettingsFeature.State(
                            currentUser: data.user,
                            loginProviderType: providerType
                        )
                    )
                }
                state.appState = data.family == nil ? .groupSelection : .authenticated
                return .none

            case .loadDataResponse(.failure(let error)):
                // 에러 처리 - Home에 에러 메시지 전달
                if state.mainTab != nil {
                    state.mainTab?.home.isLoading = false
                    state.mainTab?.home.isRefreshing = false
                    state.mainTab?.home.errorMessage = error.localizedDescription
                } else {
                    state.appState = .unauthenticated
                }
                return .none

            case .showLoginScreen:
                state.appState = .unauthenticated
                state.mainTab = nil
                state.questionDetail = nil
                state.selectedQuestion = nil
                return .none

            // MARK: - MainTab Delegate Actions
            case .mainTab(.delegate(.navigateToQuestionDetail(let question))):
                state.selectedQuestion = question
                state.questionDetail = QuestionDetailFeature.State(
                    question: question,
                    currentUser: state.currentUser
                )
                return .none

            case .mainTab(.delegate(.requestRefresh)):
                return .send(.refreshHomeData)

            case .mainTab(.delegate(.requestLogin)):
                return .send(.showLoginScreen)

            case .mainTab(.logout):
                return .send(.logout)

            case .mainTab:
                return .none

            // MARK: - Onboarding Delegate Actions
            case .onboarding(.delegate(.finished)):
                state.hasSeenOnboarding = true
                state.appState = .unauthenticated
                return .none

            case .onboarding:
                return .none

            // MARK: - Login Delegate Actions
            case .login(.delegate(.loggedIn(let user, let providerType))):
                state.loginProviderType = providerType
                return .send(.checkAuthResponse(user))

            case .login(.delegate(.browseAsGuest)):
                state.currentUser = nil
                state.loginProviderType = nil
                state.mainTab = makeGuestMainTabState()
                state.appState = .guestBrowsing
                return .none

            case .login:
                return .none

            // MARK: - Group Select Delegate Actions
            case .groupSelect(.delegate(.completed)):
                state.appState = .authenticated
                return .none

            case .groupSelect:
                return .none

            case .logout:
                state.appState = .unauthenticated
                state.mainTab = nil
                state.currentUser = nil
                state.loginProviderType = nil
                state.login = LoginFeature.State()
                state.groupSelect = GroupSelectFeature.State()
                return .none

            // MARK: - Navigation Dismiss Actions
            case .dismissQuestionDetail:
                state.selectedQuestion = nil
                state.questionDetail = nil
                return .none

            // MARK: - QuestionDetail Delegate Actions
            case .questionDetail(.presented(.delegate(.answerSubmitted(_)))):
                // 답변 제출 후 홈 데이터 새로고침 (답변 완료 상태 업데이트)
                state.mainTab?.home.hasAnsweredToday = true
                return .none

            case .questionDetail(.presented(.delegate(.closed))):
                return .send(.dismissQuestionDetail)

            case .questionDetail:
                return .none
            }
        }
        .ifLet(\.mainTab, action: \.mainTab) {
            MainTabFeature()
        }
        .ifLet(\.$questionDetail, action: \.questionDetail) {
            QuestionDetailFeature()
        }
    }
}

private extension RootFeature {
    func makeGuestMainTabState() -> MainTabFeature.State {
        MainTabFeature.State(
            isGuestMode: true,
            home: HomeFeature.State(
                todayQuestion: Question(
                    id: UUID(),
                    content: "오늘 당신을 웃게 한 건 무엇인가요?",
                    category: .daily,
                    order: 1
                ),
                family: MongleGroup(
                    id: UUID(),
                    name: "Kim Family",
                    memberIds: [],
                    createdBy: UUID(),
                    createdAt: Date(),
                    inviteCode: "MONG-4729"
                ),
                familyMembers: [],
                currentUser: nil,
                isLoading: false,
                isRefreshing: false,
                errorMessage: nil,
                hasAnsweredToday: false,
                familyAnswerCount: 3
            ),
            history: HistoryFeature.State(),
            notification: NotificationFeature.State(),
            settings: SettingsFeature.State(
                currentUser: nil,
                loginProviderType: nil
            )
        )
    }
}
