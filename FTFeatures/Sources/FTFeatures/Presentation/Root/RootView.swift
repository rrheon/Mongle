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

            case .unauthenticated:
                LoginView(store: store.scope(state: \.login, action: \.login))

            case .authenticated:
                if let mainTabStore = store.scope(state: \.mainTab, action: \.mainTab) {
                    MainTabView(store: mainTabStore)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.createFamily, action: \.createFamily)) { createFamilyStore in
            CreateFamilyView(store: createFamilyStore)
        }
        .sheet(item: $store.scope(state: \.joinFamily, action: \.joinFamily)) { joinFamilyStore in
            JoinFamilyView(store: joinFamilyStore)
        }
        .sheet(item: $store.scope(state: \.questionDetail, action: \.questionDetail)) { questionDetailStore in
            QuestionDetailView(store: questionDetailStore)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: FTSpacing.lg) {
            FTLogo(size: .large)
            ProgressView()
                .tint(FTColor.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FTColor.surface)
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

//#Preview("Root - Authenticated") {
//    RootView(
//        store: Store(
//            initialState: RootFeature.State(
//                appState: .authenticated,
//                mainTab: MainTabFeature.State(
//                    home: HomeFeature.State(
//                        todayQuestion: Question(
//                            id: UUID(),
//                            content: "오늘 가장 감사했던 순간은 언제인가요?",
//                            category: .gratitude,
//                            order: 1
//                        ),
//                        familyTree: TreeProgress(
//                            stage: .youngTree,
//                            totalAnswers: 12,
//                            consecutiveDays: 5
//                        )
//                    )
//                )
//            )
//        ) {
//            RootFeature()
//        }
//    )
//}
