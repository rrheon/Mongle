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

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch store.selectedTab {
                case .home:
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
                        onAnswerRequiredTap: { store.send(.home(.answerRequiredTapped($0))) },
                        onPeerNudgeTap: { store.send(.home(.peerNudgeTapped($0))) }
                    )
                case .history:
                    HistoryView(store: store.scope(state: \.history, action: \.history))
                case .notification:
                    NotificationView(store: store.scope(state: \.notification, action: \.notification))
                case .settings:
                    SettingsTabView(store: store.scope(state: \.settings, action: \.settings))
                }
            }
            customBottomNav
        }
        .background(MongleColor.background)
        .sheet(item: $store.scope(state: \.profileEdit, action: \.profileEdit)) { profileEditStore in
            ProfileEditView(store: profileEditStore)
        }
        .sheet(item: $store.scope(state: \.peerAnswer, action: \.peerAnswer)) { peerAnswerStore in
            PeerAnswerView(store: peerAnswerStore)
        }
        .sheet(item: $store.scope(state: \.peerNudge, action: \.peerNudge)) { peerNudgeStore in
            PeerNudgeView(store: peerNudgeStore)
        }
        .fullScreenCover(item: $store.scope(state: \.answerFirstPopup, action: \.answerFirstPopup)) { answerFirstStore in
            AnswerFirstPopupView(store: answerFirstStore)
        }
        .sheet(item: $store.scope(state: \.supportScreen, action: \.supportScreen)) { supportScreenStore in
            SupportScreenView(store: supportScreenStore)
        }
        .alert(
            "로그인 후 이용해주세요",
            isPresented: Binding(
                get: { store.showLoginRequiredAlert },
                set: { _ in } // 버튼 액션에서 직접 처리하므로 여기서 중복 dispatch 방지
            )
        ) {
            Button("취소", role: .cancel) {
                store.send(.loginRequiredAlertCancelled)
            }
            Button("확인") {
                store.send(.loginRequiredAlertConfirmed)
            }
        } message: {
            Text("둘러보기에서는 화면만 확인할 수 있어요. 로그인하면 질문 답변과 가족 기능을 사용할 수 있어요.")
        }
    }

    private var customBottomNav: some View {
        HStack(spacing: 0) {
            navItem(tab: .home, icon: "house", label: "HOME")
            navItem(tab: .history, icon: "book", label: "HISTORY")
            navItem(tab: .notification, icon: "bell", label: "NOTICE")
            navItem(tab: .settings, icon: "gearshape", label: "MY")
        }
        .padding(4)
        .frame(height: 62)
        .background(Color.white)
        .overlay(
            Capsule()
                .stroke(MongleColor.border, lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: MongleColor.shadowColor, radius: 12, x: 0, y: -2)
        .padding(.horizontal, 21)
        .padding(.top, 12)
        .padding(.bottom, 21)
        .background(MongleColor.background)
    }

    private func navItem(tab: MainTabFeature.State.Tab, icon: String, label: String) -> some View {
        Button {
            store.send(.selectTab(tab))
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(label)
                    .font(.system(size: 10, weight: store.selectedTab == tab ? .semibold : .medium, design: .rounded))
                    .tracking(0.5)
            }
            .foregroundColor(store.selectedTab == tab ? Color(hex: "2E7D32") : MongleColor.textHint)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(store.selectedTab == tab ? Color(hex: "E8F5E9") : .clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
