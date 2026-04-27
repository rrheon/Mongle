import XCTest
import ComposableArchitecture
import Domain
@testable import MongleFeatures

/// MG-14 회귀 방지 — 그룹 진입 실패 경로에서 `appState` 가 `.loading` 으로 고착돼
/// `LoadingView` 가 무한히 표시되던 문제를 검증한다.
@MainActor
final class RootFeatureTests: XCTestCase {

    // MARK: - Helpers

    /// TestStore 에 최소한의 dependency 를 주입한다. 실패 핸들러는 repo 를 직접 호출하지
    /// 않지만, TCA 가 reducer 바디를 구성할 때 `@Dependency` 접근이 발생할 수 있어
    /// 방어적으로 testValue 를 세팅한다.
    private func makeStore(initial: RootFeature.State) -> TestStore<RootFeature.State, RootFeature.Action> {
        TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.notificationRepository = MockNotificationRepository()
        }
    }

    private func stateWithMainTab(
        family: MongleGroup?,
        appState: RootFeature.State.AppState,
        pendingOpenQuestion: Bool = false
    ) -> RootFeature.State {
        var s = RootFeature.State(appState: appState)
        s.mainTab = MainTabFeature.State(
            home: HomeFeature.State(family: family)
        )
        s.pendingOpenQuestion = pendingOpenQuestion
        return s
    }

    // MARK: - MG-14: 무한로딩 방지

    /// 그룹 진입 중(appState == .loading) 네트워크 실패가 발생해도,
    /// mainTab 과 이전 가족이 있으면 `.authenticated` 로 복귀해야 한다.
    func testLoadDataFailure_WhileLoadingWithFamily_RecoversToAuthenticated() async {
        let family = GroupFactory.make()
        let initial = stateWithMainTab(family: family, appState: .loading)
        let store = makeStore(initial: initial)

        let err = URLError(.notConnectedToInternet)
        await store.send(.loadDataResponse(.failure(err))) {
            $0.appState = .authenticated
            $0.mainTab?.home.isLoading = false
            $0.mainTab?.home.isRefreshing = false
            $0.mainTab?.home.appError = .offline
        }
    }

    /// 가족이 한 번도 없던 사용자(가족 탈퇴 직후 등)가 실패한 경우에는
    /// `.groupSelection` 으로 복귀한다.
    func testLoadDataFailure_WhileLoadingWithoutFamily_RecoversToGroupSelection() async {
        let initial = stateWithMainTab(family: nil, appState: .loading)
        let store = makeStore(initial: initial)

        let err = URLError(.notConnectedToInternet)
        await store.send(.loadDataResponse(.failure(err))) {
            $0.appState = .groupSelection
            $0.mainTab?.home.isLoading = false
            $0.mainTab?.home.isRefreshing = false
            $0.mainTab?.home.appError = .offline
        }
    }

    /// 실패 시 `pendingOpenQuestion` 플래그가 정리돼 다음 refresh 에서
    /// 오래된 푸시 딥링크가 의도치 않게 열리지 않아야 한다.
    func testLoadDataFailure_ClearsPendingOpenQuestion() async {
        let family = GroupFactory.make()
        var initial = stateWithMainTab(family: family, appState: .authenticated)
        initial.pendingOpenQuestion = true
        let store = makeStore(initial: initial)

        let err = URLError(.timedOut)
        await store.send(.loadDataResponse(.failure(err))) {
            $0.pendingOpenQuestion = false
            $0.mainTab?.home.isLoading = false
            $0.mainTab?.home.isRefreshing = false
            $0.mainTab?.home.appError = .timeout
        }
    }

    /// 기존 동작 보존 — mainTab 이 nil 이면 `.unauthenticated` 로 폴백한다.
    func testLoadDataFailure_NoMainTab_FallsBackToUnauthenticated() async {
        let initial = RootFeature.State(appState: .loading)
        let store = makeStore(initial: initial)

        let err = URLError(.notConnectedToInternet)
        await store.send(.loadDataResponse(.failure(err))) {
            $0.appState = .unauthenticated
        }
    }

    // MARK: - MG-77: 데일리 하트 팝업은 서버 플래그로만 트리거

    /// User 헬퍼 — 테스트에 필요한 최소 필드 + heartGrantedToday 플래그.
    private func makeUser(heartGrantedToday: Bool) -> User {
        User(
            id: UUID(),
            email: "test@mongle.app",
            name: "테스터",
            profileImageURL: nil,
            role: .other,
            hearts: 5,
            moodId: "loved",
            createdAt: Date(),
            heartGrantedToday: heartGrantedToday
        )
    }

    private func makeRootData(heartGrantedToday: Bool, family: MongleGroup?) -> RootFeature.RootData {
        RootFeature.RootData(
            user: makeUser(heartGrantedToday: heartGrantedToday),
            question: nil,
            family: family,
            familyMembers: []
        )
    }

    /// 서버가 heartGrantedToday=true 를 내리면 loadDataResponse 가 popup 을 켠다.
    /// (scenePhase active 1차 진입 케이스 — refreshHomeData 의 /users/me 가 grant 트리거가 됨)
    func testLoadDataSuccess_HeartGrantedToday_ShowsPopup() async {
        let family = GroupFactory.make()
        let initial = stateWithMainTab(family: family, appState: .authenticated)
        let store = makeStore(initial: initial)
        store.exhaustivity = .off

        let data = makeRootData(heartGrantedToday: true, family: family)
        await store.send(.loadDataResponse(.success(data))) {
            $0.showHeartGrantedPopup = true
        }
    }

    /// heartGrantedToday=false 면 popup 상태는 변하지 않는다 (set-only — 이전 값 보존).
    /// 콜드스타트 2차 호출 시점이면 이미 checkAuthResponse 에서 set 됐을 수 있으므로
    /// 여기서 reset 하지 않는 것이 핵심.
    func testLoadDataSuccess_HeartNotGranted_PreservesExistingPopupState() async {
        let family = GroupFactory.make()
        var initial = stateWithMainTab(family: family, appState: .authenticated)
        initial.showHeartGrantedPopup = true // 콜드스타트 1차에서 켜둔 상태 가정
        let store = makeStore(initial: initial)
        store.exhaustivity = .off

        let data = makeRootData(heartGrantedToday: false, family: family)
        await store.send(.loadDataResponse(.success(data)))
        // showHeartGrantedPopup 는 true 로 보존돼야 함 (set-only)
        XCTAssertTrue(store.state.showHeartGrantedPopup)
    }

    /// checkAuthResponse 에서 user.heartGrantedToday=true 면 popup 이 즉시 켜진다.
    /// 콜드스타트 .onAppear → checkAuthResponse 1차 호출 시 grant 가 발동했을 때의 경로.
    func testCheckAuthResponse_HeartGrantedToday_ShowsPopup() async {
        let initial = RootFeature.State(appState: .loading)
        let store = makeStore(initial: initial)
        store.exhaustivity = .off

        let user = makeUser(heartGrantedToday: true)
        await store.send(.checkAuthResponse(user)) {
            $0.currentUser = user
            $0.showHeartGrantedPopup = true
        }
    }
}
