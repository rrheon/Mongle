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
        public var login: LoginFeature.State
        public var mainTab: MainTabFeature.State?
        public var currentUser: User?
        public var loginProviderType: SocialProviderType?
        public var selectedQuestion: Question?

        // Child Feature States
        @Presents public var createFamily: CreateFamilyFeature.State?
        @Presents public var joinFamily: JoinFamilyFeature.State?
        @Presents public var questionDetail: QuestionDetailFeature.State?

        public enum AppState: Equatable {
            case loading
            case unauthenticated
            case authenticated
        }

        public init(
            appState: AppState = .loading,
            login: LoginFeature.State = LoginFeature.State(),
            mainTab: MainTabFeature.State? = nil,
            currentUser: User? = nil,
            loginProviderType: SocialProviderType? = nil,
            selectedQuestion: Question? = nil,
            createFamily: CreateFamilyFeature.State? = nil,
            joinFamily: JoinFamilyFeature.State? = nil,
            questionDetail: QuestionDetailFeature.State? = nil
        ) {
            self.appState = appState
            self.login = login
            self.mainTab = mainTab
            self.currentUser = currentUser
            self.loginProviderType = loginProviderType
            self.selectedQuestion = selectedQuestion
            self.createFamily = createFamily
            self.joinFamily = joinFamily
            self.questionDetail = questionDetail
        }
    }

    public enum Action: Sendable {
        case onAppear
        case checkAuthResponse(User?)
        case loadDataResponse(Result<RootData, Error>)
        case login(LoginFeature.Action)
        case mainTab(MainTabFeature.Action)
        case logout

        // Navigation Actions
        case dismissQuestionDetail

        // Child Feature Actions
        case createFamily(PresentationAction<CreateFamilyFeature.Action>)
        case joinFamily(PresentationAction<JoinFamilyFeature.Action>)
        case questionDetail(PresentationAction<QuestionDetailFeature.Action>)

        // Data Refresh
        case refreshHomeData
    }

    public struct RootData: Equatable, Sendable {
        public let user: User?
        public let question: Question?
        public let tree: TreeProgress
        public let family: MongleGroup?
        public let familyMembers: [User]
        public let hasAnsweredToday: Bool

        public init(
            user: User?,
            question: Question?,
            tree: TreeProgress,
            family: MongleGroup?,
            familyMembers: [User],
            hasAnsweredToday: Bool = false
        ) {
            self.user = user
            self.question = question
            self.tree = tree
            self.family = family
            self.familyMembers = familyMembers
            self.hasAnsweredToday = hasAnsweredToday
        }
    }

    @Dependency(\.authRepository) var authRepository
    @Dependency(\.familyRepository) var familyRepository
    @Dependency(\.questionRepository) var questionRepository
    @Dependency(\.treeRepository) var treeRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.login, action: \.login) {
            LoginFeature()
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
                        let tree = try await treeRepository.getMyTreeProgress() ?? TreeProgress()

                        let data = RootData(
                            user: currentUser,
                            question: todayQuestion,
                            tree: tree,
                            family: family,
                            familyMembers: familyMembers,
                            hasAnsweredToday: false
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
                    state.appState = .unauthenticated
                    return .none
                }

            case .loadDataResponse(.success(let data)):
                state.currentUser = data.user

                // HomeFeature State 업데이트
                let homeState = HomeFeature.State(
                    todayQuestion: data.question,
                    familyTree: data.tree,
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
                } else {
                    state.mainTab = MainTabFeature.State(
                        home: homeState,
                        settings: SettingsFeature.State(loginProviderType: providerType)
                    )
                }
                state.appState = .authenticated
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

            // MARK: - MainTab Delegate Actions
            case .mainTab(.delegate(.navigateToQuestionDetail(let question))):
                state.selectedQuestion = question
                state.questionDetail = QuestionDetailFeature.State(
                    question: question,
                    currentUser: state.currentUser
                )
                return .none

            case .mainTab(.delegate(.navigateToCreateFamily)):
                state.createFamily = CreateFamilyFeature.State()
                return .none

            case .mainTab(.delegate(.navigateToJoinFamily)):
                state.joinFamily = JoinFamilyFeature.State()
                return .none

            case .mainTab(.delegate(.requestRefresh)):
                return .send(.refreshHomeData)

            case .mainTab(.logout):
                state.appState = .unauthenticated
                state.mainTab = nil
                state.currentUser = nil
                return .none

            case .mainTab:
                return .none

            // MARK: - Login Delegate Actions
            case .login(.delegate(.loggedIn(let user, let providerType))):
                state.loginProviderType = providerType
                return .send(.checkAuthResponse(user))

            case .login:
                return .none

            case .logout:
                state.appState = .unauthenticated
                state.mainTab = nil
                state.currentUser = nil
                state.loginProviderType = nil
                state.login = LoginFeature.State()
                return .none

            // MARK: - Navigation Dismiss Actions
            case .dismissQuestionDetail:
                state.selectedQuestion = nil
                return .none

            // MARK: - CreateFamily Delegate Actions
            case .createFamily(.presented(.delegate(.familyCreated(let family)))):
                state.createFamily = nil
                // 가족 생성 후 홈 데이터 새로고침
                if state.mainTab != nil {
                    state.mainTab?.home.family = family
                }
                return .send(.refreshHomeData)

            case .createFamily(.presented(.delegate(.cancelled))):
                state.createFamily = nil
                return .none

            case .createFamily:
                return .none

            // MARK: - JoinFamily Delegate Actions
            case .joinFamily(.presented(.delegate(.familyJoined(let family)))):
                state.joinFamily = nil
                // 가족 참여 후 홈 데이터 새로고침
                if state.mainTab != nil {
                    state.mainTab?.home.family = family
                }
                return .send(.refreshHomeData)

            case .joinFamily(.presented(.delegate(.cancelled))):
                state.joinFamily = nil
                return .none

            case .joinFamily:
                return .none

            // MARK: - QuestionDetail Delegate Actions
            case .questionDetail(.presented(.delegate(.answerSubmitted(_)))):
                // 답변 제출 후 홈 데이터 새로고침 (답변 완료 상태 업데이트)
                state.mainTab?.home.hasAnsweredToday = true
                return .none

            case .questionDetail(.presented(.delegate(.closed))):
                state.questionDetail = nil
                state.selectedQuestion = nil
                return .none

            case .questionDetail:
                return .none
            }
        }
        .ifLet(\.mainTab, action: \.mainTab) {
            MainTabFeature()
        }
        .ifLet(\.$createFamily, action: \.createFamily) {
            CreateFamilyFeature()
        }
        .ifLet(\.$joinFamily, action: \.joinFamily) {
            JoinFamilyFeature()
        }
        .ifLet(\.$questionDetail, action: \.questionDetail) {
            QuestionDetailFeature()
        }
    }
}
