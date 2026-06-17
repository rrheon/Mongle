//
//  MainTabView.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Main Tab View
struct MainTabView: View {
    @Bindable var store: StoreOf<MainTabFeature>
    @State private var peerAnswerSheetHeight: CGFloat = 400
    @State private var questionSheetHeight: CGFloat = 480
    /// 바텀시트 dismiss 시마다 증가 — MongleSceneView가 감지해 모든 캐릭터 이동을 강제
    /// 재개시킨다(MG-18). 시트 present 동안 timer/state가 꼬여 캐릭터가 고정되는 현상 회피.
    @State private var mongleResumeSignal: Int = 0

    // 시트 디텐트 안전 범위. 0/음수/NaN 또는 비정상적으로 큰 값이 .presentationDetents(.height:)에
    // 전달되면 iOS 18에서 런타임 에러가 발생할 수 있어 반드시 클램핑한다.
    private static let minSheetHeight: CGFloat = 240
    private static let maxSheetHeight: CGFloat = 900

    private static func clampedSheetHeight(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return minSheetHeight }
        return max(minSheetHeight, min(value, maxSheetHeight))
    }

    var body: some View {
        tabContent
            .sheet(
                item: $store.scope(state: \.modal?.peerAnswer, action: \.modal.peerAnswer),
                onDismiss: { mongleResumeSignal += 1 }
            ) { peerAnswerStore in
                peerAnswerSheet(store: peerAnswerStore)
            }
            .sheet(
                item: $store.scope(state: \.modal?.questionSheet, action: \.modal.questionSheet),
                onDismiss: { mongleResumeSignal += 1 }
            ) { sheetStore in
                questionSheetView(store: sheetStore)
            }
            .overlay {
                if let popupStore = store.scope(state: \.modal?.answerFirstPopup, action: \.modal.answerFirstPopup) {
                    AnswerFirstPopupView(store: popupStore)
                        .transition(.identity)
                }
            }
            .animation(.none, value: store.modal?.answerFirstPopup != nil)
            .overlay {
                if let popupStore = store.scope(state: \.modal?.heartCostPopup, action: \.modal.heartCostPopup) {
                    HeartCostPopupView(store: popupStore)
                        .transition(.identity)
                }
            }
            .animation(.none, value: store.modal?.heartCostPopup != nil)
            .overlay {
                if let popupStore = store.scope(state: \.modal?.heartInfoPopup, action: \.modal.heartInfoPopup) {
                    HeartInfoPopupView(store: popupStore)
                        .transition(.identity)
                }
            }
            .animation(.none, value: store.modal?.heartInfoPopup != nil)
            .overlay(alignment: .top) {
                toastOverlay
            }
            .overlay {
                if store.showAnswerHeartPopup {
                    MonglePopupView(
                        icon: MonglePopupView.Icon(
                            systemName: "heart.fill",
                            foregroundColor: .red,
                            backgroundColor: Color.red.opacity(0.12)
                        ),
                        title: L10n.tr("heart_earned", 1),
                        description: L10n.tr("toast_answer"),
                        primaryLabel: L10n.tr("common_confirm"),
                        onPrimary: { store.send(.dismissAnswerHeartPopup) }
                    )
                    .transition(.identity)
                }
            }
            .animation(.none, value: store.showAnswerHeartPopup)
    }

    // MARK: - Tab Content

    private var tabContent: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            homeTab
            // MG-140 — History 도 v2 탭바를 사용하도록 NavigationStack 으로 감싸
            // .toolbar(.hidden, for: .tabBar) 가 안정적으로 먹게 한다.
            NavigationStack {
                HistoryView(store: store.scope(state: \.history, action: \.history))
                    .toolbar(.hidden, for: .tabBar)
            }
            .tabItem { Label(L10n.tr("tab_history"), systemImage: "book") }
            .tag(MainTabFeature.State.Tab.history)
            // MG-140 — Search 도 v2 탭바를 사용하도록 NavigationStack 으로 감싸 시스템
            // 탭바를 hidden.
            NavigationStack {
                SearchHistoryView(store: store.scope(state: \.search, action: \.search))
                    .toolbar(.hidden, for: .tabBar)
            }
            .tabItem { Label(L10n.tr("tab_search"), systemImage: "magnifyingglass") }
            .tag(MainTabFeature.State.Tab.search)
//            NotificationView(store: store.scope(state: \.notification, action: \.notification))
//                .tabItem { Label("NOTICE", systemImage: "bell") }
//                .tag(MainTabFeature.State.Tab.notification)
            ProfileEditView(store: store.scope(state: \.profile, action: \.profile))
                .tabItem { Label(L10n.tr("tab_my"), systemImage: "person") }
                .tag(MainTabFeature.State.Tab.settings)
        }
        .accentColor(MongleColor.primaryDeep)
        .toolbarBackground(Color.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        // MG-150/MG-140 — v2 디자인이 적용된 탭(현재 Home·History)에서만 v2 탭바를 띄운다.
        // Home 은 NavigationStack push (QuestionDetail/Notification/PeerNudge/WriteQuestion)
        // 시 컨텐츠와 겹치므로 path 가 비어있을 때만. History 는 push 화면이 없어 조건 단순.
        // search/settings 는 v2 미적용이라 시각 일관성 차원에서 시스템 탭바 유지.
        .overlay(alignment: .bottom) {
            let showV2TabBar: Bool = {
                switch store.selectedTab {
                case .home:     return store.path.isEmpty
                case .history:  return true
                case .search:   return true
                case .settings: return true
                default:        return false
                }
            }()
            if showV2TabBar {
                MainTabBarV2(
                    active: store.selectedTab,
                    onSelect: { store.send(.selectTab($0)) }
                )
            }
        }
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            homeViewSection
                // MG-150 — Home 화면에서 시스템 탭바를 숨기고 V2 탭바를 overlay
                // 로 띄운다. NavigationStack 의 root 콘텐츠에 적용해야 iOS 17
                // 에서도 hidden 이 안정적으로 먹는다.
                .toolbar(.hidden, for: .tabBar)
        } destination: { store in
            switch store.case {
            case let .questionDetail(detailStore):
                QuestionDetailView(store: detailStore)
                    .navigationBarBackButtonHidden(true)
            case let .notification(notificationStore):
                NotificationView(store: notificationStore)
                    .navigationBarBackButtonHidden(true)
            case let .peerNudge(nudgeStore):
                PeerNudgeView(store: nudgeStore)
                    .navigationBarBackButtonHidden(true)
            case let .writeQuestion(writeStore):
                WriteQuestionView(store: writeStore)
                    .navigationBarBackButtonHidden(true)
            case let .shop(shopStore):
                ShopView(store: shopStore)
                    .navigationBarBackButtonHidden(true)
            }
        }
        .toolbarBackground(Color.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tabItem { Label(L10n.tr("tab_home"), systemImage: "house") }
        .tag(MainTabFeature.State.Tab.home)
    }

    // MARK: - Subviews

    // MG-150 — mood → V2Palette 단일 매핑 진실(V2Palette.mood) 사용.
    private static let monggleColors: [Color] = V2Palette.family

    private static func monggleColor(for moodId: String?, fallback index: Int) -> Color {
        if let moodId, ["happy","calm","loved","sad","tired"].contains(moodId) {
            return V2Palette.mood(moodId)
        }
        return V2Palette.family[index % V2Palette.family.count]
    }

    private var homeViewSection: some View {
        let currentUserId = store.home.currentUser?.id
        let memberData: [MongleMember] = store.home.familyMembers
            .enumerated()
            .map { index, user in
                let isCurrentUser = user.id == currentUserId
                let moodId = isCurrentUser ? (store.previewMoodId ?? store.currentUserMoodId ?? user.moodId) : user.moodId
                let eqId = isCurrentUser ? store.home.currentUser?.equippedDecorationId : nil
                // 부착 위치(anchor) 로 3필드 분기: onHead/aboveHead/hand→head, back→back, feet→feet.
                let eqAnchor: DecorationAnchor? = eqId.map { DecorationCatalog.placement(for: $0).anchor }
                return MongleMember(
                    id: user.id,
                    name: user.name,
                    color: Self.monggleColor(for: moodId, fallback: index),
                    moodId: moodId,
                    hasAnswered: store.home.memberAnswerStatus[user.id] ?? false,
                    hasSkipped: store.home.memberSkippedStatus[user.id] ?? false,
                    // 본인 멤버만 전역 단일 착용 1개를 그 장식의 슬롯 자리에 주입 (타인 동기화는 후속).
                    // 상점 장착 시 decorationsChanged delegate 가 currentUser 를 갱신해 즉시 반영된다.
                    headDecorationId: (eqAnchor == .back || eqAnchor == .feet) ? nil : eqId,
                    backDecorationId: eqAnchor == .back ? eqId : nil,
                    feetDecorationId: eqAnchor == .feet ? eqId : nil
                )
            }
        return HomeViewV2(
            topBarState: HomeTopBarState(
                streakDays: store.home.streakDays,
                groupName: store.home.family?.name ?? L10n.tr("home_default_group"),
                groupId: store.home.family?.id,
                hasNotification: store.home.hasUnreadNotifications,
                hearts: store.home.hearts,
                todayQuestion: store.home.todayQuestion.map {
                    TopBarQuestion(id: $0.id, text: $0.content, isAnswered: store.home.hasAnsweredToday)
                } ?? store.home.yesterdayQuestion.map {
                    TopBarQuestion(id: $0.id, text: $0.content, isAnswered: store.home.hasAnsweredYesterday)
                },
                allFamilies: store.home.allFamilies
            ),
            hasCurrentUserAnswered: store.home.hasAnsweredToday,
            hasCurrentUserSkipped: store.home.hasSkippedToday,
            members: memberData,
            currentUserName: store.home.currentUser?.name,
            resumeSignal: mongleResumeSignal,
            actions: HomeViewActions(
                onQuestionTap: { store.send(.home(.questionTapped)) },
                onNotificationTap: { store.send(.home(.notificationTapped)) },
                onHeartsTap: { store.send(.home(.heartsTapped)) },
                onShopTap: { store.send(.home(.shopTapped)) },
                onPeerAnswerTap: { store.send(.home(.peerAnswerTapped($0))) },
                onPeerNudgeTap: { store.send(.home(.peerNudgeTapped($0))) },
                onMyMonggleTap: { store.send(.home(.myMonggleTapped)) },
                onGroupSelected: { store.send(.home(.groupSelected($0))) },
                onNavigateToGroupSelect: { store.send(.home(.navigateToGroupSelectTapped)) },
                onNotificationPermissionAllowed: { store.send(.home(.notificationPermissionAllowed)) },
                onNotificationPermissionSkipped: { store.send(.home(.notificationPermissionSkipped)) },
                onAnswerRequiredTap: { store.send(.home(.answerRequiredTapped($0))) },
                onNudgeUnavailableTap: { store.send(.home(.nudgeUnavailableTapped($0))) }
            ),
            showNotificationPermission: store.home.showNotificationPermission,
            appliedBackgroundId: store.home.family?.appliedBackgroundId
        )
        .equatable()
        .mongleErrorToast(
            error: store.home.appError,
            onDismiss: { store.send(.home(.dismissError)) }
        )
        .overlay {
            if store.home.showGuestLoginPrompt {
                MonglePopupView(
                    icon: .init(
                        systemName: "person.crop.circle.badge.exclamationmark.fill",
                        foregroundColor: MongleColor.primary,
                        backgroundColor: MongleColor.primaryLight
                    ),
                    title: L10n.tr("settings_login_required"),
                    description: L10n.tr("settings_login_required_desc"),
                    primaryLabel: L10n.tr("settings_login_btn"),
                    secondaryLabel: L10n.tr("common_cancel"),
                    onPrimary: { store.send(.home(.guestLoginTapped)) },
                    onSecondary: { store.send(.home(.guestLoginDismissed)) }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: store.home.showGuestLoginPrompt)
            }
        }
    }

    // MARK: - Question Sheet

    private func questionSheetView(store: StoreOf<QuestionSheetFeature>) -> some View {
        QuestionSheetView(store: store)
            .onPreferenceChange(QuestionSheetContentHeightKey.self) { contentHeight in
                let total = contentHeight + 60
                withAnimation(.spring(duration: 0.25)) {
                    questionSheetHeight = Self.clampedSheetHeight(total)
                }
            }
            .presentationDetents([.height(Self.clampedSheetHeight(questionSheetHeight))])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(MongleRadius.xl)
            // 시트 콘텐츠가 v2 cream 톤이므로 presentation 배경도 cream 으로 맞춰 모서리 이음새 제거.
            .presentationBackground(V2Palette.cream)
    }

    // MARK: - Toast Overlay

    @ViewBuilder
    private var toastOverlay: some View {
        VStack(spacing: 8) {
            if store.showRefreshToast {
                MongleToastView(type: .refreshQuestion)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if store.showWriteToast {
                MongleToastView(type: .writeQuestion)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if store.showNudgeToast {
                MongleToastView(type: .nudge)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if store.showEditAnswerToast {
                MongleToastView(type: .editAnswer)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if store.showAnswerSubmittedToast {
                MongleToastView(type: .answerSubmitted)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if store.showCustomQuestionExistsToast {
                MongleToastView(type: .customQuestionExists)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 60)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showRefreshToast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showWriteToast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showNudgeToast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showEditAnswerToast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showAnswerSubmittedToast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showCustomQuestionExistsToast)
    }

    // MARK: - Peer Answer Sheet

    private func peerAnswerSheet(store: StoreOf<PeerAnswerFeature>) -> some View {
        PeerAnswerView(store: store)
            .onPreferenceChange(PeerAnswerContentHeightKey.self) { contentHeight in
                let total = contentHeight + 100
                withAnimation(.spring(duration: 0.25)) {
                    peerAnswerSheetHeight = Self.clampedSheetHeight(total)
                }
            }
            .presentationDetents([.height(Self.clampedSheetHeight(peerAnswerSheetHeight))])
            .presentationDragIndicator(.hidden)
    }
}
