//
//  Root+Reducer.swift
//  MongleFeatures
//

import Foundation
import ComposableArchitecture
import Domain
import UserNotifications
import UIKit

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
                    return .run { send in
                        do {
                            // 최신 사용자 정보 조회 (닉네임 변경 등 반영)
                            let currentUser = try? await authRepository.getCurrentUser()
                            let familyResult = try await familyRepository.getMyFamily()
                            let family = familyResult?.0
                            let familyMembers = familyResult?.1 ?? []
                            // 오전 12시(정오) 이전에는 오늘의 질문을 가져오지 않음
                            let calendar = Calendar.current
                            let now = Date()
                            let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now) ?? now
                            let todayQuestion: Question? = now >= noon
                                ? try await questionRepository.getTodayQuestion()
                                : nil

                            var memberAnswerStatus: [UUID: Bool] = [:]
                            // 서버 /answers API는 Question.id 기준 (DailyQuestion.id 아님)
                            if let questionId = todayQuestion?.id,
                               todayQuestion?.dailyQuestionId != nil {
                                let answers = (try? await answerRepository.getByDailyQuestion(dailyQuestionId: questionId)) ?? []
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
                            let allFamilies = (try? await familyRepository.getMyFamilies()) ?? []

                            let hasSkippedToday = todayQuestion?.hasMySkipped ?? false

                            let notifications = (try? await notificationRepository.getNotifications(limit: 50)) ?? []
                            let hasUnreadNotifications = notifications.contains { !$0.isRead }

                            let data = RootData(
                                user: currentUser,
                                question: todayQuestion,
                                family: family,
                                familyMembers: familyMembers,
                                hasAnsweredToday: hasAnsweredToday,
                                hasSkippedToday: hasSkippedToday,
                                memberAnswerStatus: memberAnswerStatus,
                                streakDays: streakDays,
                                allFamilies: allFamilies,
                                hasUnreadNotifications: hasUnreadNotifications
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

                case .dismissHeartPopup:
                    state.showHeartGrantedPopup = false
                    return .none

                case .loadDataResponse(.success(let data)):
                    state.currentUser = data.user

                    // 하루 첫 접속 하트 팝업 체크 (그룹별)
                    if let familyId = data.family?.id, data.user != nil {
                        let heartPopupKey = "mongle.lastHeartPopupDate.\(familyId)"
                        let todayStart = Calendar.current.startOfDay(for: Date())
                        let lastPopupDate = UserDefaults.standard.object(forKey: heartPopupKey) as? Date
                        let isFirstAccessToday = lastPopupDate == nil || Calendar.current.startOfDay(for: lastPopupDate!) < todayStart
                        if isFirstAccessToday {
                            UserDefaults.standard.set(todayStart, forKey: heartPopupKey)
                            state.showHeartGrantedPopup = true
                        }
                    }

                    // mainTab이 아직 없는 경우 = 자동 로그인(첫 로드)
                    let isInitialLoad = state.mainTab == nil

                    let homeState = HomeFeature.State(
                        todayQuestion: data.question,
                        family: data.family,
                        familyMembers: data.familyMembers,
                        currentUser: data.user,
                        isLoading: false,
                        isRefreshing: false,
                        errorMessage: nil,
                        hasAnsweredToday: data.hasAnsweredToday,
                        hasSkippedToday: data.hasSkippedToday,
                        hearts: data.user?.hearts ?? 0,
                        familyAnswerCount: data.question?.familyAnswerCount ?? 0,
                        memberAnswerStatus: data.memberAnswerStatus,
                        streakDays: data.streakDays,
                        allFamilies: data.allFamilies,
                        hasUnreadNotifications: data.hasUnreadNotifications
                    )
                    if state.mainTab != nil {
                        state.mainTab?.home = homeState
                        // profile 전체 재생성: supportScreen 등 modal 상태 초기화 포함
                        state.mainTab?.profile = ProfileEditFeature.State(
                            user: data.user,
                            familyId: data.family?.id,
                            familyCreatedById: data.family?.createdBy
                        )
                        if let familyId = data.family?.id {
                            // 그룹이 바뀐 경우 또는 오늘 날짜 히스토리가 캐시에 없는 경우 무효화
                            let today = Calendar.current.startOfDay(for: Date())
                            let isTodayMissing = state.mainTab?.history.historyItems[today] == nil
                            if state.mainTab?.history.familyId != familyId || isTodayMissing {
                                state.mainTab?.history.historyItems = [:]
                                state.mainTab?.history.loadedMonths = []
                            }
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
                    let wasOnGroupSelect = state.appState == .groupSelection
                    let newAppState: RootFeature.State.AppState = (data.family == nil || isInitialLoad) ? .groupSelection : .authenticated
                    // 그룹 선택 화면에서 인증 완료 전환 시 HomeTab으로 리셋
                    if wasOnGroupSelect && newAppState == .authenticated {
                        state.mainTab?.selectedTab = .home
                        state.mainTab?.path.removeAll()
                    }
                    state.appState = newAppState
                    // 최초 로그인 시 푸시 알림 권한 요청 + APNs 등록
                    if newAppState == .authenticated {
                        // pendingOpenQuestion 처리: 데이터가 로드되면 질문 화면으로 이동
                        if state.pendingOpenQuestion, let question = data.question {
                            state.pendingOpenQuestion = false
                            state.mainTab?.path.append(.questionDetail(QuestionDetailFeature.State(
                                question: question,
                                currentUser: data.user,
                                familyMembers: data.familyMembers
                            )))
                        }
                        return .run { _ in
                            let key = "mongle.didRequestPushPermission"
                            if !UserDefaults.standard.bool(forKey: key) {
                                UserDefaults.standard.set(true, forKey: key)
                                _ = try? await UNUserNotificationCenter.current()
                                    .requestAuthorization(options: [.alert, .badge, .sound])
                            }
                            // 항상 APNs 토큰 등록 갱신
                            await MainActor.run {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }
                    if newAppState == .groupSelection {
                        state.groupSelect.groups = data.allFamilies
                        state.groupSelect.currentUserId = data.user?.id
                        // 딥링크로 들어온 초대코드가 있으면 자동으로 참여 화면으로 이동
                        if let code = state.pendingInviteCode {
                            state.groupSelect.joinCode = code
                            state.groupSelect.step = .joinWithCode
                            state.pendingInviteCode = nil
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
                    state.mainTab?.path.removeAll()
                    state.mainTab?.modal = nil
                    state.mainTab?.profile.mongleCardEdit = nil
                    state.mainTab?.profile.accountManagement = nil
                    state.mainTab = nil
                    state.currentUser = nil
                    state.loginProviderType = nil
                    state.login = LoginFeature.State()
                    state.groupSelect = GroupSelectFeature.State()
                    state.appState = .unauthenticated
                    return .run { [authRepository] _ in
                        try? await authRepository.logout()
                    }

                // MARK: MainTab Delegate
                case .mainTab(.delegate(.navigateToQuestionDetail)):
                    // MainTabFeature가 자체 NavigationStack path에서 처리
                    return .none

                case .mainTab(.delegate(.requestRefresh)):
                    return .send(.refreshHomeData)

                case .mainTab(.delegate(.requestLogin)):
                    return .send(.showLoginScreen)

                case .mainTab(.delegate(.groupSelected(let family))):
                    return .send(.switchFamily(family))

                case .mainTab(.delegate(.navigateToGroupSelect(let fromGroupLeft))):
                    // GroupSelect 상태를 리셋하고 현재 그룹 목록을 사전 로드
                    let existingFamilies = state.mainTab?.home.allFamilies ?? []
                    state.groupSelect = GroupSelectFeature.State()
                    state.groupSelect.groups = existingFamilies
                    state.groupSelect.currentUserId = state.currentUser?.id
                    state.groupSelect.showGroupLeftToast = fromGroupLeft
                    state.appState = .groupSelection
                    // Task.yield()으로 한 프레임 양보 후 갱신 → NavigationStack 마운트 완료 후 업데이트
                    return .run { [familyRepository] send in
                        await Task.yield()
                        await send(.loadGroupsResponse(
                            Result { try await familyRepository.getMyFamilies() }
                        ))
                    }

                case .switchFamily(let family):
                    state.mainTab?.home.isLoading = true
                    return .run { [familyRepository] send in
                        do {
                            _ = try await familyRepository.selectFamily(familyId: family.id)
                            await send(.refreshHomeData)
                        } catch {
                            await send(.loadDataResponse(.failure(error)))
                        }
                    }

                case .switchFamilyResponse:
                    return .none

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

                case .groupSelect(.delegate(.createFamily(let name, let nickname, let colorId))):
                    return .run { [currentUser = state.currentUser] send in
                        do {
                            let family = try await familyRepository.create(MongleGroup(
                                id: UUID(),
                                name: name,
                                memberIds: [],
                                createdBy: currentUser?.id ?? UUID(),
                                createdAt: Date(),
                                inviteCode: ""
                            ), nickname: nickname, colorId: colorId)
                            await send(.groupSelect(.setInviteCode(family.inviteCode)))
                        } catch {
                            await send(.groupSelect(.setAppError(AppError.from(error))))
                        }
                    }

                case .groupSelect(.delegate(.joinFamily(let code, let nickname, let colorId))):
                    return .run { send in
                        do {
                            _ = try await familyRepository.joinFamily(inviteCode: code, nickname: nickname, colorId: colorId)
                            await send(.groupSelect(.setJoinSuccess))
                        } catch {
                            let appError = AppError.from(error)
                            if case .serverError(let statusCode) = appError {
                                if statusCode == 409 {
                                    await send(.groupSelect(.showJoinAlreadyMemberToast))
                                    return
                                } else if statusCode == 400 {
                                    await send(.groupSelect(.showJoinInvalidCodeToast))
                                    return
                                }
                            }
                            await send(.groupSelect(.setAppError(appError)))
                        }
                    }

                case .groupSelect(.delegate(.groupSelected(let family))):
                    state.appState = .loading
                    return .run { [familyRepository] send in
                        do {
                            _ = try await familyRepository.selectFamily(familyId: family.id)
                            await send(.refreshHomeData)
                        } catch {
                            await send(.loadDataResponse(.failure(error)))
                        }
                    }

                case .groupSelect(.delegate(.requestMembersForGroup(let group))):
                    return .run { [familyRepository] send in
                        do {
                            let (_, members) = try await familyRepository.getGroupWithMembers(id: group.id)
                            await send(.groupSelect(.setTransferCandidates(members)))
                        } catch {
                            await send(.groupSelect(.setAppError(AppError.from(error))))
                        }
                    }

                case .groupSelect(.delegate(.leaveGroup)):
                    return .run { [familyRepository] send in
                        do {
                            try await familyRepository.leaveFamily()
                            await send(.groupSelect(.delegate(.completed)))
                        } catch {
                            await send(.groupSelect(.setAppError(AppError.from(error))))
                        }
                    }

                case .groupSelect(.delegate(.transferCreatorAndLeave(let newCreatorId, _))):
                    return .run { [familyRepository] send in
                        do {
                            try await familyRepository.transferCreator(newCreatorId: newCreatorId)
                            try await familyRepository.leaveFamily()
                            await send(.groupSelect(.delegate(.completed)))
                        } catch {
                            await send(.groupSelect(.setAppError(AppError.from(error))))
                        }
                    }

                case .loadGroupsResponse(let result):
                    return .send(.groupSelect(.loadGroupsResponse(result)))

                case .pendingInviteCode(let code):
                    state.pendingInviteCode = code
                    if let code = code, state.appState == .groupSelection {
                        state.groupSelect.joinCode = code
                        state.groupSelect.step = .joinWithCode
                    }
                    return .none

                case .groupSelect:
                    return .none

                // MARK: QuestionDetail Modal
                case .questionDetail(.presented(.delegate(.answerSubmitted(_, _)))):
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

                // MARK: Push Notification

                case .deviceTokenReceived(let data):
                    let token = data.map { String(format: "%02x", $0) }.joined()
                    return .run { [userRepository] _ in
                        try? await userRepository.registerDeviceToken(token: token)
                    }

                case .openQuestion:
                    // 이미 데이터가 로드된 경우 즉시 질문 화면으로 이동
                    if let question = state.mainTab?.home.todayQuestion,
                       state.appState == .authenticated {
                        let currentUser = state.mainTab?.home.currentUser
                        let familyMembers = state.mainTab?.home.familyMembers ?? []
                        state.mainTab?.path.removeAll()
                        state.mainTab?.path.append(.questionDetail(QuestionDetailFeature.State(
                            question: question,
                            currentUser: currentUser,
                            familyMembers: familyMembers
                        )))
                    } else {
                        // 아직 데이터 로딩 중 → 로딩 완료 후 이동
                        state.pendingOpenQuestion = true
                    }
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
            profile: ProfileEditFeature.State(isGuest: true)
        )
    }
}
