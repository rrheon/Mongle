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
import KakaoSDKUser
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

    /// 모든 소셜 SDK 의 로컬 세션 토큰을 비웁니다 (logout). unlink/disconnect 와는 별개.
    /// 동일 디바이스에서 다른 계정 로그인 시 SDK 캐시로 인한 자동 로그인 방지용.
    /// 로그아웃 / 세션 만료 / 회원 탈퇴 후 일관 호출.
    public static func clearAllSessions() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            UserApi.shared.logout { _ in
                continuation.resume()
            }
        }
        GIDSignIn.sharedInstance.signOut()
    }
}
