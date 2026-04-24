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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 앱 실행 시 아이콘 뱃지 초기화
        UNUserNotificationCenter.current().setBadgeCount(0)
        return true
    }

    /// APNs 토큰 등록 성공
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        store?.send(.deviceTokenReceived(deviceToken))
    }

    /// 포그라운드에서 알림 수신 시 배너 표시 + 홈 알림 배지 즉시 갱신
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
        // 포그라운드 push 가 도착했을 때 홈 배지 갱신은 authenticated 상태에서만 의미가 있다.
        // 그룹 선택/초대코드/로그인/동의 화면 중에는 refreshHomeData 가 loadDataResponse 를
        // 통해 appState 를 강제로 .authenticated 로 전환해 현재 화면을 덮어쓰므로 발송 금지.
        // (RootView 의 scenePhase 핸들러 가드와 동일한 규칙)
        if store?.state.appState == .authenticated {
            store?.send(.refreshHomeData)
        }
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
            case "ANSWER_REQUEST", "MEMBER_ANSWERED", "NEW_QUESTION", "REMINDER":
                // REMINDER는 홈으로 보내 오늘의 질문 카드를 즉시 노출.
                // (답변자는 재촉하기 버튼, 미답변자는 답변 작성 CTA로 자연스럽게 유도.)
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

    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                UNUserNotificationCenter.current().setBadgeCount(0)
            }
        }
    }
}
