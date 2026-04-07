//
//  RootView.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import SwiftUI
import ComposableArchitecture
import Domain

public struct RootView: View {
    @Bindable var store: StoreOf<RootFeature>
    @Environment(\.scenePhase) private var scenePhase

    public init(store: StoreOf<RootFeature>) {
        self.store = store
    }

    public var body: some View {
        Group {
            switch store.appState {
            case .loading:
                LoadingView()

            case .onboarding:
                OnboardingView(store: store.scope(state: \.onboarding, action: \.onboarding))

            case .unauthenticated:
                LoginView(store: store.scope(state: \.login, action: \.login))

            case .consentRequired:
                if let consentStore = store.scope(state: \.consent, action: \.consent) {
                    ConsentView(store: consentStore)
                } else {
                    LoadingView()
                }

            case .guestBrowsing:
                if let mainTabStore = store.scope(state: \.mainTab, action: \.mainTab) {
                    MainTabView(store: mainTabStore)
                }

            case .groupSelection:
                GroupSelectView(store: store.scope(state: \.groupSelect, action: \.groupSelect))

            case .authenticated:
                if let mainTabStore = store.scope(state: \.mainTab, action: \.mainTab) {
                    MainTabView(store: mainTabStore)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && store.appState == .authenticated {
                store.send(.refreshHomeData)
            }
        }
        .overlay {
            if store.showHeartGrantedPopup && store.appState == .authenticated {
                MonglePopupView(
                    icon: MonglePopupView.Icon(
                        systemName: "heart.fill",
                        foregroundColor: .red,
                        backgroundColor: Color.red.opacity(0.12)
                    ),
                    title: L10n.tr("heart_granted_title"),
                    description: L10n.tr("heart_granted_desc"),
                    primaryLabel: L10n.tr("common_confirm"),
                    onPrimary: { store.send(.dismissHeartPopup) }
                )
                .transition(.identity)
            }
        }
        .animation(.none, value: store.showHeartGrantedPopup)
        .onOpenURL { url in
            if let code = Self.extractInviteCode(from: url) {
                store.send(.pendingInviteCode(code))
            }
        }
        .sheet(item: $store.scope(state: \.questionDetail, action: \.questionDetail)) { questionDetailStore in
            QuestionDetailView(store: questionDetailStore)
        }
    }

    static func extractInviteCode(from url: URL) -> String? {
        // Handle monggle://join/{code}
        if url.scheme == "monggle", url.host == "join" {
            return url.pathComponents.dropFirst().first?.uppercased()
        }
        // Handle https://mongle.app/invite/{code} 또는 https://monggle.app/join/{code}
        let host = url.host?.lowercased() ?? ""
        if host == "mongle.app" || host == "monggle.app",
           url.pathComponents.count >= 3,
           url.pathComponents[1] == "invite" || url.pathComponents[1] == "join" {
            return url.pathComponents[2].uppercased()
        }
        return nil
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: MongleSpacing.lg) {
            MongleLogo(size: .large)
            ProgressView()
                .tint(MongleColor.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MongleColor.surface)
    }
}



#Preview("Root - Loading") {
    RootView(
        store: Store(initialState: RootFeature.State(appState: .loading)) {
            RootFeature()
        }
    )
}

#Preview("Root - Unauthenticated") {
    RootView(
        store: Store(initialState: RootFeature.State(appState: .unauthenticated)) {
            RootFeature()
        }
    )
}

