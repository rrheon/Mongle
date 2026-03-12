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
            .sheet(item: $store.scope(state: \.profileEdit, action: \.profileEdit)) { profileEditStore in
                ProfileEditView(store: profileEditStore)
            }
            .sheet(item: $store.scope(state: \.peerAnswer, action: \.peerAnswer)) { peerAnswerStore in
                peerAnswerSheet(store: peerAnswerStore)
            }
            .sheet(item: $store.scope(state: \.questionSheet, action: \.questionSheet)) { sheetStore in
                questionSheetView(store: sheetStore)
            }
            .overlay {
                if let popupStore = $store.scope(state: \.answerFirstPopup, action: \.answerFirstPopup).wrappedValue {
                    AnswerFirstPopupView(store: popupStore)
                        .transition(.identity)
                }
            }
            .animation(.none, value: store.answerFirstPopup != nil)
            .overlay {
                if let popupStore = $store.scope(state: \.heartCostPopup, action: \.heartCostPopup).wrappedValue {
                    HeartCostPopupView(store: popupStore)
                        .transition(.identity)
                }
            }
            .animation(.none, value: store.heartCostPopup != nil)
            .overlay(alignment: .top) {
                toastOverlay
            }
    }

    // MARK: - Tab Content

    private var tabContent: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            homeTab
            HistoryView(store: store.scope(state: \.history, action: \.history))
                .tabItem { Label("HISTORY", systemImage: "book") }
                .tag(MainTabFeature.State.Tab.history)
            NotificationView(store: store.scope(state: \.notification, action: \.notification))
                .tabItem { Label("NOTICE", systemImage: "bell") }
                .tag(MainTabFeature.State.Tab.notification)
            SettingsTabView(store: store.scope(state: \.settings, action: \.settings))
                .tabItem { Label("MY", systemImage: "gearshape") }
                .tag(MainTabFeature.State.Tab.settings)
        }
        .accentColor(Color(hex: "2E7D32"))
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        NavigationStack {
            homeViewSection
                .navigationDestination(
                    item: $store.scope(state: \.peerNudge, action: \.peerNudge)
                ) { nudgeStore in
                    PeerNudgeView(store: nudgeStore)
                        .navigationBarBackButtonHidden(true)
                }
                .navigationDestination(
                    item: $store.scope(state: \.homeQuestionDetail, action: \.homeQuestionDetail)
                ) { detailStore in
                    QuestionDetailView(store: detailStore)
                        .navigationBarBackButtonHidden(true)
                }
                .navigationDestination(
                    item: $store.scope(state: \.writeQuestion, action: \.writeQuestion)
                ) { writeStore in
                    WriteQuestionView(store: writeStore)
                        .navigationBarBackButtonHidden(true)
                }
        }
        .tabItem { Label("HOME", systemImage: "house") }
        .tag(MainTabFeature.State.Tab.home)
    }

    // MARK: - Subviews (동일)
    private var homeViewSection: some View {
        HomeView(
            topBarState: HomeTopBarState(
                streakDays: 0,
                groupName: store.home.family?.name ?? "우리 가족",
                hasNotification: false,
                todayQuestion: store.home.todayQuestion.map {
                    TopBarQuestion(id: $0.id, text: $0.content, isAnswered: store.home.hasAnsweredToday)
                }
            ),
            hasCurrentUserAnswered: store.home.hasAnsweredToday,
            onQuestionTap: { store.send(.home(.questionTapped)) },
            onNotificationTap: { store.send(.home(.notificationTapped)) },
            onHeartsTap: { store.send(.home(.heartsTapped)) },
            onPeerAnswerTap: { store.send(.home(.peerAnswerTapped($0))) },
            onPeerNudgeTap: { store.send(.home(.peerNudgeTapped($0))) }
        )
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
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if store.showWriteToast {
                MongleToastView(type: .writeQuestion)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 60)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showRefreshToast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showWriteToast)
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
