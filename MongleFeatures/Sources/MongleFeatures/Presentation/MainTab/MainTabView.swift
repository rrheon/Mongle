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
                    Text("HOME")
                }
                .tag(MainTabFeature.State.Tab.home)

            HistoryView(store: store.scope(state: \.history, action: \.history))
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                    Text("HISTORY")
                }
                .tag(MainTabFeature.State.Tab.history)

            SettingsTabView(store: store.scope(state: \.settings, action: \.settings))
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("MY")
                }
                .tag(MainTabFeature.State.Tab.settings)
        }
        .tint(MongleColor.primary)
    }
}
