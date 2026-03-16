//
//  FamTreeApp.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import SwiftUI
import ComposableArchitecture
import MongleFeatures
import GoogleMobileAds

@main
struct MongleApp: App {
  let store = Store(initialState: RootFeature.State()) {
    RootFeature()
  }

  init() {
    MongleFont.registerFonts()
    SocialSDK.initialize()
    GADMobileAds.sharedInstance().start(completionHandler: nil)
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
