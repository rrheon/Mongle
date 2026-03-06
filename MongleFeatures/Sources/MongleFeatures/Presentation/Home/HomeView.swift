//
//  HomeView.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI
import ComposableArchitecture
import Domain

// MARK: - HomeView

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        MeadowHomeView()
    }
}
