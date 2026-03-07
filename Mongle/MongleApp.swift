//
//  FamTreeApp.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import SwiftUI
import ComposableArchitecture
import MongleFeatures

@main
struct MongleApp: App {
  let store = Store(initialState: RootFeature.State()) {
    RootFeature()
  }

  init() {
    SocialSDK.initialize()
  }

  var body: some Scene {
    WindowGroup {
      RootView(store: store)
        .onOpenURL { url in
          SocialSDK.handle(url: url)
        }
    }
  }
}
