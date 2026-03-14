//
//  Root+Reducer.swift
//  MongleFeatures
//

import Foundation
import ComposableArchitecture
import Domain

extension RootFeature {

    var reducer: some ReducerOf<Self> {

        CombineReducers {

            Scope(state: \.onboarding, action: \.onboarding) { OnboardingFeature() }
            Scope(state: \.login, action: \.login) { LoginFeature() }
            Scope(state: \.groupSelect, action: \.groupSelect) { GroupSelectFeature() }

            Reduce { state, action in
                switch action {

                // MARK: Lifecycle
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
                    if state.mainTab != nil {
                        state.mainTab?.home = homeState
                        state.mainTab?.profile.user = data.user
                    } else {
                        state.mainTab = MainTabFeature.State(
                            home: homeState,
                            profile: ProfileEditFeature.State(user: data.user)
                        )
                    }
                    state.appState = data.family == nil ? .groupSelection : .authenticated
                    return .none

                case .loadDataResponse(.failure(let error)):
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

                case .logout:
                    state.appState = .unauthenticated
                    state.mainTab = nil
                    state.currentUser = nil
                    state.loginProviderType = nil
                    state.login = LoginFeature.State()
                    state.groupSelect = GroupSelectFeature.State()
                    return .none

                // MARK: MainTab Delegate
                case .mainTab(.delegate(.navigateToQuestionDetail)):
                    // MainTabFeature가 자체 NavigationStack path에서 처리
                    return .none

                case .mainTab(.delegate(.requestRefresh)):
                    return .send(.refreshHomeData)

                case .mainTab(.delegate(.requestLogin)):
                    return .send(.showLoginScreen)

                case .mainTab(.logout):
                    return .send(.logout)

                case .mainTab:
                    return .none

                // MARK: Onboarding Delegate
                case .onboarding(.delegate(.finished)):
                    state.hasSeenOnboarding = true
                    state.appState = .unauthenticated
                    return .none

                case .onboarding(.delegate(.neverShowAgain)):
                    UserDefaults.standard.set(true, forKey: "mongle.hasSeenOnboarding")
                    state.hasSeenOnboarding = true
                    state.appState = .unauthenticated
                    return .none

                case .onboarding:
                    return .none

                // MARK: Login Delegate
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

                // MARK: GroupSelect Delegate
                case .groupSelect(.delegate(.completed)):
                    state.appState = .authenticated
                    return .none

                case .groupSelect:
                    return .none

                // MARK: QuestionDetail Modal
                case .questionDetail(.presented(.delegate(.answerSubmitted(_)))):
                    state.mainTab?.home.hasAnsweredToday = true
                    return .none

                case .questionDetail(.presented(.delegate(.closed))):
                    return .send(.dismissQuestionDetail)

                case .questionDetail:
                    return .none

                case .dismissQuestionDetail:
                    state.selectedQuestion = nil
                    state.questionDetail = nil
                    return .none
                }
            }
        }

        .ifLet(\.mainTab, action: \.mainTab) {
            MainTabFeature()
        }

        .ifLet(\.$questionDetail, action: \.questionDetail) {
            QuestionDetailFeature()
        }
    }

    func makeGuestMainTabState() -> MainTabFeature.State {
        MainTabFeature.State(
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
            profile: ProfileEditFeature.State()
        )
    }
}
