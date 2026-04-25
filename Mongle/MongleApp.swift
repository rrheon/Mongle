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
        // 배지 카운트는 사용자가 알림함을 실제로 읽거나 비울 때만 갱신한다.
        // (앱 실행/포그라운드 복귀 시 무조건 0으로 초기화하면 미읽음 17개여도
        //  사용자가 한 번 앱을 열면 OS 배지가 사라져 인앱 미읽음 카운트와
        //  완전히 분리되는 버그가 발생 — Root+Reducer.loadDataResponse 가
        //  refreshHomeData 흐름에서 setBadgeCount(unread) 로 동기화한다.)
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
        // store / UNUserNotificationCenter delegate 를 init 시점에 즉시 연결.
        // 이전엔 .onAppear 에서 할당했는데, cold start 직후 didFinishLaunching 보다
        // .onAppear 가 늦게 발화하는 경우가 있어 didRegisterForRemoteNotificationsWithDeviceToken
        // 콜백이 들어와도 store==nil 이라 deviceTokenReceived 액션이 사실상 누락되던
        // 케이스(APNs 토큰 미등록 → 푸시 안 옴)를 방어.
        appDelegate.store = store
        UNUserNotificationCenter.current().delegate = appDelegate
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
        }
    }
}
