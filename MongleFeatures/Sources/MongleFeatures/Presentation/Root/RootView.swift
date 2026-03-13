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
        .sheet(item: $store.scope(state: \.questionDetail, action: \.questionDetail)) { questionDetailStore in
            QuestionDetailView(store: questionDetailStore)
        }
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

