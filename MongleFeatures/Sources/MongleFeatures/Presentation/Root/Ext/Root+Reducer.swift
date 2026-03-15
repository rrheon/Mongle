//
//  Root+Reducer.swift
//  MongleFeatures
//

import Foundation
import ComposableArchitecture
import Domain
import UserNotifications

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

                            var memberAnswerStatus: [UUID: Bool] = [:]
                            if let dqIdString = todayQuestion?.dailyQuestionId,
                               let dqId = UUID(uuidString: dqIdString) {
                                let answers = (try? await answerRepository.getByDailyQuestion(dailyQuestionId: dqId)) ?? []
                                for answer in answers {
                                    memberAnswerStatus[answer.userId] = true
                                }
                            }
                            // 서버 hasMyAnswer를 fallback으로 사용 (answers 로드 실패 시)
                            let hasAnsweredToday: Bool
                            if let userId = currentUser?.id, memberAnswerStatus[userId] != nil {
                                hasAnsweredToday = memberAnswerStatus[userId] == true
                            } else {
                                hasAnsweredToday = todayQuestion?.hasMyAnswer ?? false
                            }

                            let streakDays = (try? await userRepository.getMyStreak()) ?? 0

                            let data = RootData(
                                user: currentUser,
                                question: todayQuestion,
                                family: family,
                                familyMembers: familyMembers,
                                hasAnsweredToday: hasAnsweredToday,
                                memberAnswerStatus: memberAnswerStatus,
                                streakDays: streakDays
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
                        hasAnsweredToday: data.hasAnsweredToday,
                        hearts: data.user?.hearts ?? 0,
                        familyAnswerCount: data.question?.familyAnswerCount ?? 0,
                        memberAnswerStatus: data.memberAnswerStatus,
                        streakDays: data.streakDays
                    )
                    if state.mainTab != nil {
                        state.mainTab?.home = homeState
                        state.mainTab?.profile.user = data.user
                        state.mainTab?.profile.familyId = data.family?.id
                        state.mainTab?.profile.familyCreatedById = data.family?.createdBy
                        if let familyId = data.family?.id {
                            state.mainTab?.history.familyId = familyId
                            state.mainTab?.history.familyMembers = data.familyMembers
                        }
                    } else {
                        state.mainTab = MainTabFeature.State(
                            home: homeState,
                            history: HistoryFeature.State(
                                familyId: data.family?.id,
                                familyMembers: data.familyMembers
                            ),
                            notification: NotificationFeature.State(),
                            profile: ProfileEditFeature.State(user: data.user, familyId: data.family?.id, familyCreatedById: data.family?.createdBy)
                        )
                    }
                    let newAppState: RootFeature.State.AppState = data.family == nil ? .groupSelection : .authenticated
                    state.appState = newAppState
                    // 최초 로그인 시 푸시 알림 권한 요청
                    if newAppState == .authenticated {
                        return .run { _ in
                            let key = "mongle.didRequestPushPermission"
                            guard !UserDefaults.standard.bool(forKey: key) else { return }
                            UserDefaults.standard.set(true, forKey: key)
                            _ = try? await UNUserNotificationCenter.current()
                                .requestAuthorization(options: [.alert, .badge, .sound])
                        }
                    }
                    return .none

                case .loadDataResponse(.failure(let error)):
                    let appError = AppError.from(error)
                    if appError.requiresLogin {
                        return .send(.showLoginScreen)
                    }
                    if state.mainTab != nil {
                        state.mainTab?.home.isLoading = false
                        state.mainTab?.home.isRefreshing = false
                        state.mainTab?.home.appError = appError
                        state.mainTab?.home.errorMessage = appError.userMessage
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
                    return .send(.refreshHomeData)

                case .groupSelect(.delegate(.createFamily(let name))):
                    return .run { [currentUser = state.currentUser] send in
                        do {
                            let family = try await familyRepository.create(MongleGroup(
                                id: UUID(),
                                name: name,
                                memberIds: [],
                                createdBy: currentUser?.id ?? UUID(),
                                createdAt: Date(),
                                inviteCode: ""
                            ))
                            await send(.groupSelect(.setInviteCode(family.inviteCode)))
                        } catch {
                            await send(.groupSelect(.setAppError(AppError.from(error))))
                        }
                    }

                case .groupSelect(.delegate(.joinFamily(let code))):
                    return .run { send in
                        do {
                            _ = try await familyRepository.joinFamily(inviteCode: code)
                            await send(.groupSelect(.delegate(.completed)))
                        } catch {
                            await send(.groupSelect(.setAppError(AppError.from(error))))
                        }
                    }

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
