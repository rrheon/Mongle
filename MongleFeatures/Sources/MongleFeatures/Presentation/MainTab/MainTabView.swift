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

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            
            // 1. HOME 탭
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
            }
            .tabItem {
                Label("HOME", systemImage: "house")
            }
            .tag(MainTabFeature.State.Tab.home)

            // 2. HISTORY 탭
            HistoryView(store: store.scope(state: \.history, action: \.history))
                .tabItem {
                    Label("HISTORY", systemImage: "book")
                }
                .tag(MainTabFeature.State.Tab.history)

            // 3. NOTICE 탭
            NotificationView(store: store.scope(state: \.notification, action: \.notification))
                .tabItem {
                    Label("NOTICE", systemImage: "bell")
                }
                .tag(MainTabFeature.State.Tab.notification)

            // 4. MY 탭
            ProfileEditView(
                store: Store(initialState: ProfileEditFeature.State()) {
                    ProfileEditFeature()
                }
            )
            .tabItem {
                Label("MY", systemImage: "gearshape")
            }
            .tag(MainTabFeature.State.Tab.settings)
        }
        // 시스템 탭바의 강조 색상을 지정 (필요시)
        .accentColor(Color(hex: "2E7D32"))
        
        // Sheet 및 Popup 로직 (동일)
        .sheet(item: $store.scope(state: \.profileEdit, action: \.profileEdit)) { profileEditStore in
            ProfileEditView(store: profileEditStore)
        }
        .sheet(item: $store.scope(state: \.peerAnswer, action: \.peerAnswer)) { peerAnswerStore in
            peerAnswerSheet(store: peerAnswerStore)
        }
        .fullScreenCover(item: $store.scope(state: \.answerFirstPopup, action: \.answerFirstPopup)) { answerFirstStore in
            AnswerFirstPopupView(store: answerFirstStore)
        }
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
