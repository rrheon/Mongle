//
//  AppLifecycleSupport.swift
//  FTFeatures
//
//  FamTreeApp.swift에서 SDK 초기화 및 URL 핸들링을 위한 퍼사드.
//  앱 타겟이 Kakao/Google SDK를 직접 의존하지 않도록 FTFeatures 내부에서 래핑.
//

import Foundation
import KakaoSDKCommon
import KakaoSDKAuth
import GoogleSignIn

public enum SocialSDK {
    /// 앱 시작 시 소셜 SDK들을 초기화합니다.
    public static func initialize() {
        KakaoSDK.initSDK(appKey: Secrets.kakaoNativeAppKey)
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Secrets.googleClientID)
    }

    /// SceneDelegate / onOpenURL에서 수신한 URL을 각 SDK에 전달합니다.
  @MainActor @discardableResult
    public static func handle(url: URL) -> Bool {
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        return GIDSignIn.sharedInstance.handle(url)
    }
}
