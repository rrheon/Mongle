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
import UIKit
import UserNotifications

// MARK: - App Delegate

class MongleAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    weak var store: StoreOf<RootFeature>?

    /// APNs 토큰 등록 성공
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        store?.send(.deviceTokenReceived(deviceToken))
    }

    /// 포그라운드에서 알림 수신 시 배너 표시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// 알림 탭 처리
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String {
            switch type {
            case "ANSWER_REQUEST", "MEMBER_ANSWERED", "NEW_QUESTION":
                store?.send(.openQuestion)
            default:
                break
            }
        }
        completionHandler()
    }
}

// MARK: - App

@main
struct MongleApp: App {
    @UIApplicationDelegateAdaptor(MongleAppDelegate.self) var appDelegate

    let store = Store(initialState: RootFeature.State()) {
        RootFeature()
    }

    init() {
        MongleFont.registerFonts()
        SocialSDK.initialize()
        // GDPR/CCPA 동의 흐름(UMP). KR·JP 는 건너뛰고 즉시 AdMob 초기화,
        // 그 외 지역은 동의 폼 표시 후 AdMob 초기화한다.
        ConsentManager.shared.startConsentFlowIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .onOpenURL { url in
                    let host = url.host?.lowercased() ?? ""
                    let isInviteLink = host == "mongle.app" || host == "monggle.app" || url.scheme == "monggle"
                    // 초대 링크는 RootView.onOpenURL에서 처리, 소셜 SDK URL만 전달
                    if !isInviteLink {
                        SocialSDK.handle(url: url)
                    }
                }
                .onAppear {
                    appDelegate.store = store
                    UNUserNotificationCenter.current().delegate = appDelegate
                }
        }
    }
}
