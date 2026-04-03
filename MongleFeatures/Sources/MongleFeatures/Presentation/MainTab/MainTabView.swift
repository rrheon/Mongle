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

    var body: some View {
        tabContent
            .sheet(item: $store.scope(state: \.modal?.peerAnswer, action: \.modal.peerAnswer)) { peerAnswerStore in
                peerAnswerSheet(store: peerAnswerStore)
            }
            .sheet(item: $store.scope(state: \.modal?.questionSheet, action: \.modal.questionSheet)) { sheetStore in
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
            .overlay(alignment: .bottom) {
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
                        title: L10n.tr("heart_cost", 1),
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
            HistoryView(store: store.scope(state: \.history, action: \.history))
                .tabItem { Label("HISTORY", systemImage: "book") }
                .tag(MainTabFeature.State.Tab.history)
            SearchHistoryView(store: store.scope(state: \.search, action: \.search))
                .tabItem { Label("SEARCH", systemImage: "magnifyingglass") }
                .tag(MainTabFeature.State.Tab.search)
//            NotificationView(store: store.scope(state: \.notification, action: \.notification))
//                .tabItem { Label("NOTICE", systemImage: "bell") }
//                .tag(MainTabFeature.State.Tab.notification)
            ProfileEditView(store: store.scope(state: \.profile, action: \.profile))
                .tabItem { Label("MY", systemImage: "person") }
                .tag(MainTabFeature.State.Tab.settings)
        }
        .accentColor(MongleColor.primaryDeep)
        .toolbarBackground(Color.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            homeViewSection
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
            }
        }
        .toolbarBackground(Color.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tabItem { Label("HOME", systemImage: "house") }
        .tag(MainTabFeature.State.Tab.home)
    }

    // MARK: - Subviews

    private static let monggleColors: [Color] = [
        MongleColor.monggleYellow,
        MongleColor.monggleGreen,
        MongleColor.mongglePink,
        MongleColor.monggleBlue,
        MongleColor.monggleOrange
    ]

    private static func monggleColor(for moodId: String?, fallback index: Int) -> Color {
        switch moodId {
        case "happy":  return MongleColor.monggleYellow
        case "calm":   return MongleColor.monggleGreen
        case "loved":  return MongleColor.mongglePink
        case "sad":    return MongleColor.monggleBlue
        case "tired":  return MongleColor.monggleOrange
        default:       return MongleColor.mongglePink
        }
    }

    private var homeViewSection: some View {
        let currentUserId = store.home.currentUser?.id
        let memberData: [(name: String, color: Color, hasAnswered: Bool)] = store.home.familyMembers
            .enumerated()
            .map { index, user in
                let isCurrentUser = user.id == currentUserId
                let moodId = isCurrentUser ? (store.previewMoodId ?? store.currentUserMoodId ?? user.moodId) : user.moodId
                return (
                    name: user.name,
                    color: Self.monggleColor(for: moodId, fallback: index),
                    hasAnswered: store.home.memberAnswerStatus[user.id] ?? false
                )
            }
        return HomeView(
            topBarState: HomeTopBarState(
                streakDays: store.home.streakDays,
                groupName: store.home.family?.name ?? L10n.tr("home_default_group"),
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
            actions: HomeViewActions(
                onQuestionTap: { store.send(.home(.questionTapped)) },
                onNotificationTap: { store.send(.home(.notificationTapped)) },
                onHeartsTap: { store.send(.home(.heartsTapped)) },
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
            showNotificationPermission: store.home.showNotificationPermission
        )
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
                    questionSheetHeight = min(total, UIScreen.main.bounds.height * 0.88)
                }
            }
            .presentationDetents([.height(questionSheetHeight)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(MongleRadius.xl)
            .presentationBackground(MongleColor.cardBackgroundSolid)
    }

    // MARK: - Toast Overlay

    @ViewBuilder
    private var toastOverlay: some View {
        VStack(spacing: 8) {
            if store.showRefreshToast {
                MongleToastView(type: .refreshQuestion)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if store.showWriteToast {
                MongleToastView(type: .writeQuestion)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if store.showNudgeToast {
                MongleToastView(type: .nudge)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if store.showEditAnswerToast {
                MongleToastView(type: .editAnswer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if store.showAnswerSubmittedToast {
                MongleToastView(type: .answerSubmitted)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, 90)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showRefreshToast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showWriteToast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showNudgeToast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showEditAnswerToast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showAnswerSubmittedToast)
    }

    // MARK: - Peer Answer Sheet

    private func peerAnswerSheet(store: StoreOf<PeerAnswerFeature>) -> some View {
        PeerAnswerView(store: store)
            .onPreferenceChange(PeerAnswerContentHeightKey.self) { contentHeight in
                let total = contentHeight + 100
                withAnimation(.spring(duration: 0.25)) {
                    peerAnswerSheetHeight = min(total, UIScreen.main.bounds.height * 0.88)
                }
            }
            .presentationDetents([.height(peerAnswerSheetHeight)])
            .presentationDragIndicator(.hidden)
    }
}
