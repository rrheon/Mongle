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
    }

    // MARK: - Tab Content

    private var tabContent: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            homeTab
            HistoryView(store: store.scope(state: \.history, action: \.history))
                .tabItem { Label("HISTORY", systemImage: "book") }
                .tag(MainTabFeature.State.Tab.history)
//            NotificationView(store: store.scope(state: \.notification, action: \.notification))
//                .tabItem { Label("NOTICE", systemImage: "bell") }
//                .tag(MainTabFeature.State.Tab.notification)
            ProfileEditView(store: store.scope(state: \.profile, action: \.profile))
                .tabItem { Label("MY", systemImage: "person") }
                .tag(MainTabFeature.State.Tab.settings)
        }
        .accentColor(MongleColor.primaryDeep)
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
        .tabItem { Label("HOME", systemImage: "house") }
        .tag(MainTabFeature.State.Tab.home)
    }

    // MARK: - Subviews

    private var homeViewSection: some View {
        HomeView(
            topBarState: HomeTopBarState(
                streakDays: 0,
                groupName: store.home.family?.name ?? "우리 가족",
                hasNotification: false,
                hearts: store.home.hearts,
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
