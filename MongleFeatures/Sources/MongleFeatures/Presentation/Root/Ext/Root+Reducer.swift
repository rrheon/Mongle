//
//  Root+Reducer.swift
//  MongleFeatures
//

import Foundation
import ComposableArchitecture
import Domain
import MongleData
import UserNotifications
import UIKit

extension RootFeature {

    private enum CancelID: Hashable {
        case sessionExpiredObserver
        /// scenePhase 복귀 등으로 refreshHomeData 가 빠르게 재트리거될 때 이전
        /// in-flight 요청을 취소하기 위한 ID. cancelInFlight:true 와 함께 사용.
        case refreshHome
        /// 그룹 빠른 연속 전환 시 이전 in-flight 요청 취소.
        case switchFamily
    }

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
                    return .merge(
                        .run { send in
                            // grantDailyHeart: true — 콜드스타트 1차 /users/me 호출이 같은 KST 일자
                            // 첫 호출이면 서버가 활성 그룹에 +1 지급. 이후 .refreshHomeData 의 2차
                            // 호출은 같은 트리거를 보내도 서버가 idempotent 로 false 반환.
                            // checkAuthResponse 에서 user.heartGrantedToday 로 팝업을 set-only 로 켠다.
                            let user = try? await authRepository.getCurrentUser(grantDailyHeart: true)
                            await send(.checkAuthResponse(user))
                        },
                        .run { send in
                            // APIClient.attemptTokenRefresh 실패 시 post 되는 신호를 구독.
                            // cancelInFlight 로 onAppear 재호출 시 중복 옵저버 방지.
                            let stream = AsyncStream<Void> { continuation in
                                let observer = NotificationCenter.default.addObserver(
                                    forName: .mongleSessionExpired,
                                    object: nil,
                                    queue: .main
                                ) { _ in
                                    continuation.yield(())
                                }
                                continuation.onTermination = { _ in
                                    NotificationCenter.default.removeObserver(observer)
                                }
                            }
                            for await _ in stream {
                                await send(.sessionExpired)
                            }
                        }
                        .cancellable(id: CancelID.sessionExpiredObserver, cancelInFlight: true)
                    )

                case .refreshHomeData:
                    return .run { [authRepository, familyRepository, questionRepository, answerRepository, userRepository, notificationRepository] send in
                        do {
                            let data = try await Self.withTimeout(10) { () -> RootData in
                            // 최신 사용자 정보 조회 (닉네임 변경 등 반영) +
                            // scenePhase active 등으로 본 경로만 진입한 케이스에선 여기서 데일리
                            // 하트 grant 가 발동. user.heartGrantedToday 가 true 면 loadDataResponse
                            // 에서 팝업을 set-only 로 켠다. 콜드스타트 경로(.onAppear → checkAuth)
                            // 는 그쪽에서 이미 +1 처리되므로 본 호출은 idempotent 로 false 반환.
                            let currentUser = try? await authRepository.getCurrentUser(grantDailyHeart: true)
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
                            // OS 앱 아이콘 배지는 사용자 단위(그룹 개념 없음)이므로 전체 그룹 합산.
                            let unreadCountAllGroups = notifications.filter { !$0.isRead }.count

                            return RootData(
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
                                hasUnreadNotifications: hasUnreadNotifications,
                                unreadCountAllGroups: unreadCountAllGroups
                            )
                            }
                            await send(.loadDataResponse(.success(data)))
                        } catch {
                            await send(.loadDataResponse(.failure(error)))
                        }
                    }
                    .cancellable(id: CancelID.refreshHome, cancelInFlight: true)

                case .checkAuthResponse(let user):
                    if let user = user {
                        state.currentUser = user
                        state.appState = .loading
                        // 콜드스타트(.onAppear → checkAuthResponse → refreshHomeData) 경로에서는
                        // 이 1차 호출이 서버 grant 트리거이므로 여기서만 true 가 되고,
                        // 2차 호출(refreshHomeData) 은 false 로 돌아옴. set-only 로 켜둬 두 단계
                        // 사이에 사라지지 않게 한다.
                        if user.heartGrantedToday {
                            state.showHeartGrantedPopup = true
                        }
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

                    // OS 앱 아이콘 배지 동기화 — 전체 그룹 합산 미읽음 수.
                    // refreshHomeData 가 호출되는 모든 경로(앱 콜드 스타트, scenePhase active,
                    // foreground push 수신, mark-read/delete 직후 등)에서 일관되게 갱신된다.
                    let badgeCount = data.unreadCountAllGroups
                    let badgeSyncEffect: Effect<Action> = .run { _ in
                        try? await UNUserNotificationCenter.current().setBadgeCount(badgeCount)
                    }

                    // 데일리 하트 팝업 트리거 — 서버 응답 플래그만 신뢰 (MG-77).
                    // scenePhase active 로 본 경로만 진입한 경우 여기 호출이 grant 트리거가 되며
                    // user.heartGrantedToday 가 true 로 돌아온다. 콜드스타트 경로에서는 이미
                    // checkAuthResponse 에서 set 된 상태이므로 여기 set-only 는 idempotent.
                    // 이전 UserDefaults `mongle.lastHeartPopupDate.<familyId>` 자체 카운터는
                    // 다중 단말 / 그룹 전환 / 서버 grant 실패 케이스에서 거짓 팝업을 유발해 폐기.
                    if data.user?.heartGrantedToday == true {
                        state.showHeartGrantedPopup = true
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
                    // 초대코드 화면(step=.groupCreated) 에 머무는 동안엔 refreshHomeData 가
                    // 어디서 트리거되든 (예: 가족 생성 직후 서버가 NEW_QUESTION 을
                    // assignQuestionToFamily → APNs 로 발송 → foreground willPresent 가
                    // refreshHomeData 호출) authenticated 로 강제 전환하지 않는다.
                    // 사용자가 "홈으로" 를 눌러 step 이 .select 로 리셋된 뒤에만 전환된다.
                    let preserveInviteCodeScreen = wasOnGroupSelect && state.groupSelect.step == .groupCreated
                    // 인증 미완료 상태(consentRequired/emailSignup) 동안 들어온 딥링크가
                    // pendingInviteCode 에 남아있다면, 인증 완료 후 곧장 .authenticated 로
                    // 가지 말고 .groupSelection 으로 한 단계 거쳐 join 화면을 띄운다.
                    // 그렇지 않으면 코드가 영영 소비되지 않고 stale 상태로 남는 버그 (audit High).
                    let hasPendingInvite = state.pendingInviteCode != nil
                    let newAppState: RootFeature.State.AppState = preserveInviteCodeScreen
                        ? .groupSelection
                        : (hasPendingInvite || data.family == nil || isInitialLoad
                           ? .groupSelection
                           : .authenticated)
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
                                familyMembers: data.familyMembers,
                                hearts: data.user?.hearts ?? 0
                            )))
                        }
                        return .merge(
                            .run { _ in
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
                            },
                            badgeSyncEffect
                        )
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
                    return badgeSyncEffect

                case .loadDataResponse(.failure(let error)):
                    let appError = AppError.from(error)
                    if appError.requiresLogin {
                        return .send(.showLoginScreen)
                    }
                    // 실패 시 대기 중이던 푸시 딥링크도 정리 — 다음 refresh 에 의도치 않게
                    // 오래된 질문 화면이 열리는 것을 막는다.
                    state.pendingOpenQuestion = false
                    if state.mainTab != nil {
                        state.mainTab?.home.isLoading = false
                        state.mainTab?.home.isRefreshing = false
                        state.mainTab?.home.appError = appError
                        // 무한로딩 방지:
                        //   .groupSelected 델리게이트는 appState 를 .loading 으로 선전환한 뒤
                        //   selectFamily/refreshHomeData 를 실행한다. 이 체인이 실패하면 기존엔
                        //   appState 가 .loading 으로 남아 LoadingView 가 계속 표시됐다.
                        //   mainTab 이 이미 있으므로 복귀 위치를 (그룹 여부에 따라) 결정한다.
                        if state.appState == .loading {
                            let hasFamily = state.mainTab?.home.family != nil
                            state.appState = hasFamily ? .authenticated : .groupSelection
                        }
                    } else {
                        state.appState = .unauthenticated
                    }
                    return .none

                case .showLoginScreen:
                    // appState만 먼저 전환 → MainTabView가 화면에서 사라짐
                    // mainTab/questionDetail은 다음 tick에서 정리해 in-flight 자식 액션이 안전히 처리되도록 함.
                    // pending push/딥링크 신호는 즉시 비워야 재로그인 시 의도치 않은 자동 이행 방지.
                    state.appState = .unauthenticated
                    state.pendingOpenQuestion = false
                    state.pendingInviteCode = nil
                    return .run { send in
                        // Task.yield() 2회 — in-flight 자식 effect 가 한 번 더 안전히 settle 될 시간 확보.
                        await Task.yield()
                        await Task.yield()
                        await send(.completeLogout)
                    }

                case .sessionExpired:
                    // APIClient 가 이미 토큰을 폐기했으므로 authRepository.logout() 호출 불필요.
                    // .logout cleanup 패턴 재사용 + 안내 팝업 플래그 set.
                    state.showSessionExpiredPopup = true
                    state.appState = .unauthenticated
                    state.currentUser = nil
                    state.loginProviderType = nil
                    state.login = LoginFeature.State()
                    state.groupSelect = GroupSelectFeature.State()
                    // pending push/딥링크 신호도 즉시 비워야 재로그인 시 의도치 않은 자동 이행 방지.
                    // .logout / .showLoginScreen 과 동일한 cleanup 으로 통일.
                    state.pendingOpenQuestion = false
                    state.pendingInviteCode = nil
                    return .run { send in
                        await Task.yield()
                        await send(.completeLogout)
                    }

                case .dismissSessionExpiredPopup:
                    state.showSessionExpiredPopup = false
                    return .none

                case .logout:
                    // appState만 먼저 전환 → MainTabView가 LoginView로 교체되며 ProfileView 등의 onAppear가 더 이상 dispatch되지 않음
                    // mainTab nil 처리는 completeLogout에서 다음 runloop tick에 수행
                    state.appState = .unauthenticated
                    state.currentUser = nil
                    state.loginProviderType = nil
                    state.login = LoginFeature.State()
                    state.groupSelect = GroupSelectFeature.State()
                    state.pendingOpenQuestion = false
                    state.pendingInviteCode = nil
                    return .run { [authRepository] send in
                        try? await authRepository.logout()
                        await Task.yield()
                        await Task.yield()
                        await send(.completeLogout)
                    }

                case .completeLogout:
                    state.mainTab = nil
                    state.questionDetail = nil
                    state.selectedQuestion = nil
                    // 사용자 단위 UserDefaults 키 일괄 정리 — 다음 계정 로그인 시 이전 사용자의
                    // 그룹별 알림 설정 / 리마인더 시간 / 팝업 노출 마커 등이 잘못 적용되는 것을
                    // 방지. mongle.hasSeenOnboarding / mongle.installSentinel 은 보존.
                    clearUserScopedDefaults()
                    // 로그아웃 직전에 in-flight 였던 refreshHome/switchFamily 효과들이
                    // 뒤늦게 settle 되며 nil 이 된 mainTab 에 액션을 dispatch 하지 않도록
                    // 명시 취소 + 소셜 SDK 캐시 토큰 정리 (Kakao logout / Google signOut) 도
                    // best-effort 로 수행. sessionExpiredObserver 는 다음 onAppear 에서 재구독.
                    return .merge(
                        .cancel(id: CancelID.refreshHome),
                        .cancel(id: CancelID.switchFamily),
                        .run { _ in await SocialSDK.clearAllSessions() }
                    )

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
                    // 빠른 연속 전환 시 이전 selectFamily/refreshHomeData chain 을 취소.
                    // 이전엔 두 in-flight 가 임의 순서로 settle 되며 서버/클라 활성 가족이
                    // 어긋나는 케이스가 있었음.
                    .cancellable(id: CancelID.switchFamily, cancelInFlight: true)

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
                    // 새 계정 로그인 시 unauthenticated 상태에서 도착한 푸시 tap 으로
                    // 설정된 pendingOpenQuestion 이 잔존하면 사용자 B 의 첫 로딩에서
                    // 의도치 않은 질문 화면 자동 진입이 발생. 명시 cleanup.
                    state.pendingOpenQuestion = false
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
                    // MG-13: 그룹 전환 시 반드시 Home 탭으로 이동
                    //   loadDataResponse 내부의 wasOnGroupSelect 체크는 .loading 으로 선전환되므로
                    //   항상 false 가 되어 탭 리셋이 누락된다. 여기서 선제적으로 초기화한다.
                    state.mainTab?.selectedTab = .home
                    state.mainTab?.path.removeAll()
                    state.appState = .loading
                    return .run { [familyRepository] send in
                        do {
                            // MG-14: 네트워크 불안정 시 selectFamily 가 무한 대기하지 않도록 10초 타임아웃.
                            try await Self.withTimeout(10) {
                                _ = try await familyRepository.selectFamily(familyId: family.id)
                            }
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
                    // aps-environment entitlement 을 런타임에 읽어 판단. embedded.mobileprovision
                    // 의 Entitlements.aps-environment 가 "development" 면 sandbox, "production" 이면
                    // production. Debug/Release scheme 과 무관하게 provisioning profile 기준이라
                    // Xcode Run(Release scheme 포함) 은 sandbox, TestFlight/App Store 는 production
                    // 으로 정확히 매핑된다.
                    let environment = ApsEnvironmentDetector.current()
                    return .run { [userRepository] _ in
                        try? await userRepository.registerDeviceToken(token: token, environment: environment)
                    }

                case .openQuestion:
                    // 이미 데이터가 로드된 경우 즉시 질문 화면으로 이동
                    if let question = state.mainTab?.home.todayQuestion,
                       state.appState == .authenticated {
                        let currentUser = state.mainTab?.home.currentUser
                        let familyMembers = state.mainTab?.home.familyMembers ?? []
                        let hearts = state.mainTab?.home.hearts ?? 0
                        // 활성 sheet/popup 이 있으면 close 해 navigation push 가 sheet 뒤에
                        // 숨는 race 를 차단. push 도착 즉시 답변 화면 진입을 위해 모달 우선 정리.
                        state.mainTab?.modal = nil
                        state.mainTab?.path.removeAll()
                        state.mainTab?.path.append(.questionDetail(QuestionDetailFeature.State(
                            question: question,
                            currentUser: currentUser,
                            familyMembers: familyMembers,
                            hearts: hearts
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

    // MARK: - Timeout Helper

    /// 그룹 진입·홈 리프레시 경로가 네트워크 불안정으로 무한 대기되지 않도록
    /// 전체 작업을 `seconds` 후 `URLError(.timedOut)` 로 실패시킨다.
    ///
    /// `URLSessionConfiguration.timeoutIntervalForRequest` 가 15초지만
    /// `refreshHomeData` 는 최대 7개의 API 호출을 순차 실행하므로 최악의
    /// 경우 100초 이상 hang 할 수 있다. 리듀서 단에서 10초로 잘라 UX 를
    /// 확보한다.
    static func withTimeout<T: Sendable>(
        _ seconds: Double,
        _ work: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await work() }
            group.addTask { () async throws -> T in
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            defer { group.cancelAll() }
            return try await group.next()!
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
