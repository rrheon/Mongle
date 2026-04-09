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
                            // 서버 스케줄러가 KST 정오에 새 질문을 배정하므로 시각 분기 없이 바로 조회.
                            // (과거엔 오전 11시 이전엔 어제 질문을 대신 보여주는 limbo 구간이 있었음)
                            //
                            // detailed 버전을 호출해 질문 + 가족 멤버별 (answered/skipped/not_answered)
                            // 상태를 한 번에 가져온다. 이로써 "멤버가 패스했는데 다른 사람에게는
                            // 미답변으로 보이는" 버그가 해소된다.
                            let todayDetails: TodayQuestionDetails? = try? await questionRepository.getTodayQuestionDetailed()
                            let todayQuestion: Question? = todayDetails?.question

                            // yesterdayQuestion fallback 은 더 이상 필요 없음 — 항상 nil 로 전달
                            let yesterdayQuestion: Question? = nil
                            let hasAnsweredYesterday = false

                            var memberAnswerStatus: [UUID: Bool] = [:]
                            var memberSkippedStatus: [UUID: Bool] = [:]
                            // 서버 memberAnswerStatuses 응답을 최우선으로 사용.
                            if let statuses = todayDetails?.memberStatuses, !statuses.isEmpty {
                                for m in statuses {
                                    switch m.status {
                                    case .answered:    memberAnswerStatus[m.userId] = true
                                    case .skipped:     memberSkippedStatus[m.userId] = true
                                    case .notAnswered: break
                                    }
                                }
                            } else if let questionId = todayQuestion?.id,
                                      todayQuestion?.dailyQuestionId != nil {
                                // 구버전 서버 fallback: answers 로만 answered 상태 채움 (skipped 는 알 수 없음).
                                let answers = (try? await answerRepository.getByDailyQuestion(dailyQuestionId: questionId)) ?? []
                                for answer in answers {
                                    memberAnswerStatus[answer.userId] = true
                                }
                            }
                            // 본인 상태는 answer > skip 우선순위로 결정.
                            // (server 는 answer-after-skip 을 허용하므로 skippedDate 가 남은 채
                            //  hasMyAnswer=true 인 경우가 있을 수 있다. 이때 "답변함" 으로만 표시.)
                            //   1) memberAnswerStatus (서버 memberAnswerStatuses) 에 포함되면 answered
                            //   2) 아니면 todayQuestion.hasMyAnswer 로 fallback
                            //   3) answered 가 아니면서 skipped 조건 만족 시 skipped
                            let myUserId = currentUser?.id
                            let answeredFromMap = myUserId.flatMap { memberAnswerStatus[$0] } ?? false
                            let answeredFromFlag = todayQuestion?.hasMyAnswer ?? false
                            let hasAnsweredToday = answeredFromMap || answeredFromFlag

                            let skippedFromMap = myUserId.flatMap { memberSkippedStatus[$0] } ?? false
                            let skippedFromFlag = todayQuestion?.hasMySkipped ?? false
                            // answered 가 true 이면 skipped 는 강제 false (우선순위 규칙)
                            let hasSkippedToday = !hasAnsweredToday && (skippedFromMap || skippedFromFlag)

                            // 맵과 플래그 간 일관성 강제 — 모든 UI 가 동일한 값을 보도록.
                            if let id = myUserId {
                                if hasAnsweredToday {
                                    memberAnswerStatus[id] = true
                                    memberSkippedStatus[id] = nil
                                } else if hasSkippedToday {
                                    memberSkippedStatus[id] = true
                                    memberAnswerStatus[id] = nil
                                }
                            }

                            let streakDays = (try? await userRepository.getMyStreak()) ?? 0
                            let allFamilies = (try? await familyRepository.getMyFamilies()) ?? []

                            let notifications = (try? await notificationRepository.getNotifications(limit: 50)) ?? []
                            // Home 화면의 알림 배지는 "현재 그룹" 의 미읽음 알림에 한정한다.
                            // (다른 그룹의 알림이 있다고 해서 현재 그룹 홈에 빨간 점이 떠선 안 됨.)
                            let currentFamilyId = family?.id
                            let hasUnreadNotifications = notifications.contains {
                                !$0.isRead && $0.familyId == currentFamilyId
                            }

                            let data = RootData(
                                user: currentUser,
                                question: todayQuestion,
                                yesterdayQuestion: yesterdayQuestion,
                                hasAnsweredYesterday: hasAnsweredYesterday,
                                family: family,
                                familyMembers: familyMembers,
                                hasAnsweredToday: hasAnsweredToday,
                                hasSkippedToday: hasSkippedToday,
                                memberAnswerStatus: memberAnswerStatus,
                                memberSkippedStatus: memberSkippedStatus,
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
                        let isFirstAccessToday = lastPopupDate.map { Calendar.current.startOfDay(for: $0) < todayStart } ?? true
                        if isFirstAccessToday {
                            UserDefaults.standard.set(todayStart, forKey: heartPopupKey)
                            state.showHeartGrantedPopup = true
                        }
                    }

                    // mainTab이 아직 없는 경우 = 자동 로그인(첫 로드)
                    let isInitialLoad = state.mainTab == nil

                    let homeState = HomeFeature.State(
                        todayQuestion: data.question,
                        yesterdayQuestion: data.yesterdayQuestion,
                        hasAnsweredYesterday: data.hasAnsweredYesterday,
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
                        memberSkippedStatus: data.memberSkippedStatus,
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
                            let historyFamilyChanged = state.mainTab?.history.familyId != familyId
                            if historyFamilyChanged || isTodayMissing {
                                state.mainTab?.history.historyItems = [:]
                                state.mainTab?.history.loadedMonths = []
                            }
                            state.mainTab?.history.familyId = familyId
                            state.mainTab?.history.familyMembers = data.familyMembers
                            state.mainTab?.history.currentUser = data.user

                            // 검색 탭도 그룹이 바뀌면 캐시를 무효화 (그룹별 독립 검색)
                            let familyIdString = familyId.uuidString
                            if state.mainTab?.search.loadedFamilyId != familyIdString {
                                state.mainTab?.search.query = ""
                                state.mainTab?.search.results = []
                                state.mainTab?.search.allHistory = []
                                state.mainTab?.search.loadedFamilyId = familyIdString
                            }
                        } else {
                            // 그룹이 없는 상태: 검색 캐시 완전 초기화
                            state.mainTab?.search = SearchHistoryFeature.State()
                        }
                    } else {
                        state.mainTab = MainTabFeature.State(
                            home: homeState,
                            history: HistoryFeature.State(
                                familyId: data.family?.id,
                                familyMembers: data.familyMembers,
                                currentUser: data.user
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
                    // appState만 먼저 전환 → MainTabView가 화면에서 사라짐
                    // mainTab/questionDetail은 다음 tick에서 정리해 in-flight 자식 액션이 안전히 처리되도록 함
                    state.appState = .unauthenticated
                    return .run { send in
                        await Task.yield()
                        await send(.completeLogout)
                    }

                case .logout:
                    // appState만 먼저 전환 → MainTabView가 LoginView로 교체되며 ProfileView 등의 onAppear가 더 이상 dispatch되지 않음
                    // mainTab nil 처리는 completeLogout에서 다음 runloop tick에 수행
                    state.appState = .unauthenticated
                    state.currentUser = nil
                    state.loginProviderType = nil
                    state.login = LoginFeature.State()
                    state.groupSelect = GroupSelectFeature.State()
                    return .run { [authRepository] send in
                        try? await authRepository.logout()
                        await Task.yield()
                        await send(.completeLogout)
                    }

                case .completeLogout:
                    state.mainTab = nil
                    state.questionDetail = nil
                    state.selectedQuestion = nil
                    return .none

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
                case .login(.delegate(.loggedIn(let user, let providerType, let needsConsent, let requiredConsents, let legalVersions))):
                    state.loginProviderType = providerType
                    state.currentUser = user
                    if needsConsent {
                        // 동의 화면으로 라우팅 — 동의 완료 후 .consent(.delegate(.completed))
                        // 에서 checkAuthResponse 로 이어진다.
                        state.consent = ConsentFeature.State(
                            requiredConsents: requiredConsents,
                            legalVersions: legalVersions
                        )
                        state.appState = .consentRequired
                        return .none
                    }
                    return .send(.checkAuthResponse(user))

                // MARK: Consent Delegate
                case .consent(.delegate(.completed)):
                    state.consent = nil
                    let user = state.currentUser
                    return .send(.checkAuthResponse(user))

                case .consent(.delegate(.cancelled)):
                    // 동의 거부 → 세션 정리하고 로그인 화면으로
                    state.consent = nil
                    state.currentUser = nil
                    state.loginProviderType = nil
                    state.login = LoginFeature.State()
                    state.appState = .unauthenticated
                    return .run { [authRepository] _ in
                        try? await authRepository.logout()
                    }

                case .consent(.delegate(.openURL)):
                    // ConsentView 가 자체적으로 SafariViewController 시트를 띄우므로 no-op
                    return .none

                case .consent:
                    return .none

                case .login(.delegate(.browseAsGuest)):
                    state.currentUser = nil
                    state.loginProviderType = nil
                    state.mainTab = makeGuestMainTabState()
                    state.appState = .guestBrowsing
                    return .none

                case .login(.delegate(.emailSignupFlowRequested)):
                    // 현재 서버 약관 버전을 알 수 없으므로 우선 하드코딩된 기본값으로 초기화.
                    // (서버와 버전이 다르면 signup 단계에서 400 이 반환되어 사용자에게 노출됨)
                    state.emailSignup = EmailSignupFeature.State(
                        legalVersions: LegalVersions(terms: "1.0.0", privacy: "1.0.0")
                    )
                    state.appState = .emailSignup
                    return .none

                case .login(.delegate(.emailLoginFlowRequested)):
                    state.emailLogin = EmailLoginFeature.State()
                    state.appState = .emailLogin
                    return .none

                case .login:
                    return .none

                // MARK: EmailSignup Delegate
                case .emailSignup(.delegate(.completed(let result))):
                    state.emailSignup = nil
                    state.currentUser = result.user
                    state.loginProviderType = nil
                    if result.needsConsent {
                        // 이론상 발생하지 않음 (signup 시 버전을 명시) — 방어적 처리
                        state.consent = ConsentFeature.State(
                            requiredConsents: result.requiredConsents,
                            legalVersions: result.legalVersions
                        )
                        state.appState = .consentRequired
                        return .none
                    }
                    return .send(.checkAuthResponse(result.user))

                case .emailSignup(.delegate(.cancelled)):
                    state.emailSignup = nil
                    state.appState = .unauthenticated
                    return .none

                case .emailSignup(.delegate(.openURL)):
                    return .none

                case .emailSignup:
                    return .none

                // MARK: EmailLogin Delegate
                case .emailLogin(.delegate(.completed(let result))):
                    state.emailLogin = nil
                    state.currentUser = result.user
                    state.loginProviderType = nil
                    if result.needsConsent {
                        state.consent = ConsentFeature.State(
                            requiredConsents: result.requiredConsents,
                            legalVersions: result.legalVersions
                        )
                        state.appState = .consentRequired
                        return .none
                    }
                    return .send(.checkAuthResponse(result.user))

                case .emailLogin(.delegate(.cancelled)):
                    state.emailLogin = nil
                    state.appState = .unauthenticated
                    return .none

                case .emailLogin:
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
                    if let code = code {
                        if state.appState == .groupSelection {
                            state.groupSelect.joinCode = code
                            state.groupSelect.step = .joinWithCode
                        } else if state.appState == .authenticated {
                            // 이미 로그인된 상태에서 초대 링크를 열면 그룹 선택 화면으로 이동
                            state.appState = .groupSelection
                            state.groupSelect.joinCode = code
                            state.groupSelect.step = .joinWithCode
                        }
                    }
                    return .none

                case .groupSelect:
                    return .none

                // MARK: QuestionDetail Modal
                case .questionDetail(.presented(.delegate(.answerSubmitted(_, _)))):
                    // 모달(푸시 딥링크) 경로에서 답변 완료 시 본인 상태 전체 동기화.
                    // 과거엔 hasAnsweredToday 만 세팅해서 memberAnswerStatus[me]/hasSkippedToday 가
                    // 남아있어 본인 캐릭터/타인 화면 표시가 불일치했다.
                    if var home = state.mainTab?.home {
                        home.hasAnsweredToday = true
                        home.hasSkippedToday = false
                        if let userId = home.currentUser?.id {
                            home.memberAnswerStatus[userId] = true
                            home.memberSkippedStatus[userId] = nil
                        }
                        state.mainTab?.home = home
                    }
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

        .ifLet(\.consent, action: \.consent) {
            ConsentFeature()
        }

        .ifLet(\.emailSignup, action: \.emailSignup) {
            EmailSignupFeature()
        }

        .ifLet(\.emailLogin, action: \.emailLogin) {
            EmailLoginFeature()
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
