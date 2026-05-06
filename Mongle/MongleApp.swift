//
//  FamTreeApp.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import SwiftUI
import ComposableArchitecture
import MongleData
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

    /// APNs 토큰 등록 실패 — 디버깅 단서 + 서버 측 stale 토큰 유지 방지를 위한 로그.
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        let nsError = error as NSError
        print("[APNs] 토큰 등록 실패: domain=\(nsError.domain) code=\(nsError.code) description=\(nsError.localizedDescription)")
    }

    /// 포그라운드에서 알림 수신 시 배너 표시 + 홈 알림 배지 즉시 갱신
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 기본은 배너+알림센터+사운드+배지 — 콜드스타트 직후 store 가 weak nil 이거나
        // appState 가 아직 .unknown 인 경우에도 알림이 보이도록 한다. 가입/약관/로그인
        // 흐름 도중에만 명시적으로 배너를 숨겨 흐름을 보호. (MG-113)
        // 이전엔 [.list] 도 배너 분기에서 누락돼 사용자가 배너를 위로 스와이프하면
        // 알림 센터에도 안 남던 결함 동반 수정.
        let appState = store?.state.appState
        let isInAuthFlow = appState != nil
            && appState != .authenticated
            && appState != .groupSelection
        if isInAuthFlow {
            completionHandler([.list, .badge])
        } else {
            completionHandler([.banner, .list, .sound, .badge])
        }
        // 포그라운드 push 가 도착했을 때 홈 배지 갱신은 authenticated 상태에서만 의미가 있다.
        // 그룹 선택/초대코드/로그인/동의 화면 중에는 refreshHomeData 가 loadDataResponse 를
        // 통해 appState 를 강제로 .authenticated 로 전환해 현재 화면을 덮어쓰므로 발송 금지.
        if appState == .authenticated {
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

        // 푸시 페이로드의 notificationId 로 서버 알림을 즉시 읽음 처리 + OS 배지 동기화 (MG-111).
        // 서버 측 AnswerService/NudgeService/QuestionService/reminderScheduler 가 페이로드에
        // notificationId 를 실어 보내며, 클라가 알림을 탭한 시점에 in-app 알림함에 진입하지 않아도
        // 미읽음 카운트가 누적되지 않도록 한다. Root+Reducer.loadDataResponse 의 setBadgeCount
        // 동기화는 홈 진입 후에야 실행되므로 여기서 한 번 더 즉시 갱신해 사용자 체감 지연 방지.
        if let notificationIdString = userInfo["notificationId"] as? String,
           let notificationId = UUID(uuidString: notificationIdString) {
            Task.detached {
                let repository = makeNotificationRepository()
                _ = try? await repository.markAsRead(id: notificationId)
                if let unread = try? await repository.getUnreadCount() {
                    try? await UNUserNotificationCenter.current().setBadgeCount(unread)
                }
            }
        }

        if let type = userInfo["type"] as? String {
            switch type {
            // MG-116 — 본인이 즉시 답변해야 하는 알림은 답변 화면(.openQuestion), 그 외
            // 그룹 컨텍스트 정보성 알림은 그룹 홈(.openHome) 으로 분기.
            // - ANSWER_REQUEST: 다른 멤버가 본인을 재촉
            // - REMINDER_UNANSWERED: 서버 reminderScheduler 가 본인 미답변 케이스로 발송
            //   (DB Notification.type 은 'REMINDER' 그대로, push payload type 만 suffix 부여)
            case "ANSWER_REQUEST", "REMINDER_UNANSWERED":
                store?.send(.openQuestion)

            // - NEW_QUESTION: 새 일일 질문 도착 (11시)
            // - REMINDER_ANSWERED: 본인은 답변 완료. 그룹 미답변자 안내
            // - REMINDER: legacy/구버전 페이로드 (suffix 미포함) — 안전 측 home
            // - MEMBER_ANSWERED / ALL_ANSWERED / BADGE_EARNED / ANSWERER_NUDGE: 정보성
            case "NEW_QUESTION", "REMINDER_ANSWERED", "REMINDER",
                 "MEMBER_ANSWERED", "ALL_ANSWERED", "BADGE_EARNED", "ANSWERER_NUDGE":
                store?.send(.openHome)

            default:
                // 알 수 없는 type — 안전한 기본 동작으로 그룹 홈 진입.
                store?.send(.openHome)
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
        // Install sentinel — iOS 는 앱 uninstall 시 Keychain 항목을 자동 정리하지 않아
        // 재설치 사용자가 이전 사용자 토큰으로 자동 로그인되는 케이스가 있다. 첫 실행
        // 마커가 없으면 (= 새 install) 기존 토큰을 명시적으로 폐기한다.
        let installSentinelKey = "mongle.installSentinel"
        if !UserDefaults.standard.bool(forKey: installSentinelKey) {
            clearTokensOnFreshInstall()
            UserDefaults.standard.set(true, forKey: installSentinelKey)
        }

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
