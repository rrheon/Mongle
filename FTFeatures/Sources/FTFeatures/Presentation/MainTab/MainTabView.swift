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
        TabView(selection: $store.selectedTab.sending(\.selectTab)) {
            HomeView(store: store.scope(state: \.home, action: \.home))
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(MainTabFeature.State.Tab.home)

            TreeTabView(store: store.scope(state: \.tree, action: \.tree))
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("나무")
                }
                .tag(MainTabFeature.State.Tab.tree)

            FamilyTabView(store: store.scope(state: \.family, action: \.family))
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("가족")
                }
                .tag(MainTabFeature.State.Tab.family)

            SettingsTabView(store: store.scope(state: \.settings, action: \.settings))
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("설정")
                }
                .tag(MainTabFeature.State.Tab.settings)
        }
        .tint(FTColor.primary)
    }
}
