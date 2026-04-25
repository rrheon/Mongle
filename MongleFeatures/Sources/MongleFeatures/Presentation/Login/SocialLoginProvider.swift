//
//  SocialLoginProvider.swift
//  Mongle
//

import Foundation
import AuthenticationServices
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser
import GoogleSignIn
import Domain
import MongleData

// MARK: - 소셜 로그인 제공자 프로토콜
//
// 새로운 소셜 제공자 추가 순서:
// 1. FTData/Credentials/ 에 XxxLoginCredential: SocialLoginCredential 추가
// 2. 이 파일에 XxxLoginProvider: SocialLoginProvider 추가
// 기존 LoginFeature, AuthRepository 등은 수정 불필요

public protocol SocialLoginProvider {
    associatedtype Credential: SocialLoginCredential
    func authenticate() async throws -> Credential

    /// 클라이언트 측 소셜 연결 해제.
    /// - Apple: no-op (서버가 저장된 refresh_token으로 Apple 토큰 revoke)
    /// - Kakao: unlink (앱 연결 해제)
    /// - Google: disconnect (앱 접근 권한 해제)
    func revokeClientAccess() async throws

    /// 클라이언트 측 SDK 토큰만 정리 (logout — unlink 와 별개).
    /// 동일 디바이스에서 다른 계정 로그인 시 SDK 가 캐시된 토큰으로 자동 로그인되어
    /// 이전 계정 컨텍스트가 노출되는 것을 방어한다.
    /// - Apple: no-op (Apple SDK 가 자체 캐시 미보관)
    /// - Kakao: UserApi.shared.logout
    /// - Google: GIDSignIn.sharedInstance.signOut
    func clearClientSession() async
}

public extension SocialLoginProvider {
    func clearClientSession() async {}
}

// MARK: - Apple 로그인 제공자

@MainActor
public final class AppleLoginProvider: NSObject, SocialLoginProvider {
    private var continuation: CheckedContinuation<AppleLoginCredential, Error>?
    // ASAuthorizationController을 strong reference로 유지해야 delegate 콜백이 호출됨
    private var authController: ASAuthorizationController?

    public func authenticate() async throws -> AppleLoginCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.authController = controller  // 강한 참조 유지
            controller.performRequests()
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleLoginProvider: ASAuthorizationControllerDelegate {
    nonisolated public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = appleCredential.identityToken,
            let identityToken = String(data: tokenData, encoding: .utf8),
            let codeData = appleCredential.authorizationCode,
            let authorizationCode = String(data: codeData, encoding: .utf8)
        else {
            Task { @MainActor [weak self] in
                self?.continuation?.resume(throwing: AppleLoginError.invalidCredential)
                self?.continuation = nil
            }
            return
        }

        let fullName = appleCredential.fullName
        let nameParts = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        let name = nameParts.isEmpty ? nil : nameParts.joined(separator: " ")

        let credential = AppleLoginCredential(
            identityToken: identityToken,
            authorizationCode: authorizationCode,
            name: name,
            email: appleCredential.email
        )

        Task { @MainActor [weak self] in
            self?.continuation?.resume(returning: credential)
            self?.continuation = nil
        }
    }

    nonisolated public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor [weak self] in
            self?.continuation?.resume(throwing: error)
            self?.continuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleLoginProvider: ASAuthorizationControllerPresentationContextProviding {
    nonisolated public func presentationAnchor(
        for controller: ASAuthorizationController
    ) -> ASPresentationAnchor {
#if canImport(UIKit)
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
        else { return UIWindow() }
        return window
#else
        return NSApplication.shared.windows.first ?? NSWindow()
#endif
    }
}

// MARK: - revokeClientAccess

extension AppleLoginProvider {
    /// Apple 토큰 revoke는 서버 측에서 처리하므로 클라이언트에서는 no-op.
    public func revokeClientAccess() async throws {}
}

// MARK: - 에러

enum AppleLoginError: Error {
    case invalidCredential
}

// MARK: - 카카오 로그인 제공자
//
// 사전 설정 필요:
// 1. 카카오 개발자 콘솔에서 앱 등록 → Native App Key 발급
// 2. Info.plist에 URL Scheme 추가: kakao{NATIVE_APP_KEY}
// 3. AppDelegate/App에서 SDK 초기화: KakaoSDK.initSDK(appKey: "NATIVE_APP_KEY")
// 4. SceneDelegate 또는 onOpenURL에서 handle: AuthController.handleOpenUrl(url:)

@MainActor
public final class KakaoLoginProvider: SocialLoginProvider {
    public init() {}

    public func authenticate() async throws -> KakaoLoginCredential {
        let token = try await login()
        let (name, email) = try await fetchUserInfo()
        return KakaoLoginCredential(
            accessToken: token.accessToken,
            idToken: token.idToken,
            name: name,
            email: email
        )
    }

    // 카카오톡 앱이 설치되어 있으면 앱 로그인, 없으면 웹 로그인
    private func login() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            let completion: (OAuthToken?, Error?) -> Void = { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: KakaoLoginError.tokenUnavailable)
                }
            }

            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk(completion: completion)
            } else {
                UserApi.shared.loginWithKakaoAccount(completion: completion)
            }
        }
    }

    // 닉네임, 이메일 조회 (카카오 개발자 콘솔에서 scope 동의 필요)
    private func fetchUserInfo() async throws -> (name: String?, email: String?) {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.me { user, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let name  = user?.kakaoAccount?.profile?.nickname
                    let email = user?.kakaoAccount?.email
                    continuation.resume(returning: (name, email))
                }
            }
        }
    }

    /// 카카오 앱 연결 해제 (unlink).
    /// 연결 해제 후 재로그인 시 동의 화면이 다시 표시됩니다.
    public func revokeClientAccess() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UserApi.shared.unlink { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// 카카오 SDK 의 로컬 OAuthToken 만 비움 (unlink 와 별개).
    /// 같은 기기에서 다른 카카오 계정으로 로그인 시 캐시된 토큰으로 자동 로그인되어
    /// 이전 계정의 카카오 ID 가 그대로 사용되던 문제 방어. 실패해도 무시 (best-effort).
    public func clearClientSession() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            UserApi.shared.logout { _ in
                continuation.resume()
            }
        }
    }
}

enum KakaoLoginError: Error {
    case tokenUnavailable
}

// MARK: - 구글 로그인 제공자
//
// 사전 설정 필요:
// 1. Google Cloud Console에서 iOS OAuth 클라이언트 ID 발급
// 2. Info.plist에 CFBundleURLTypes 추가: REVERSED_CLIENT_ID (GoogleService-Info.plist에서 복사)
// 3. FamTreeApp.swift의 onOpenURL에서 handle:
//    GIDSignIn.sharedInstance.handle(url)

@MainActor
public final class GoogleLoginProvider: SocialLoginProvider {
    public init() {}

    public func authenticate() async throws -> GoogleLoginCredential {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { throw GoogleLoginError.noRootViewController }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleLoginError.noIdToken
        }

        let name  = result.user.profile?.name
        let email = result.user.profile?.email

        return GoogleLoginCredential(idToken: idToken, name: name, email: email)
    }


    /// Google 앱 접근 권한 해제 (disconnect).
    /// 연결 해제 후 재로그인 시 동의 화면이 다시 표시됩니다.
    public func revokeClientAccess() async throws {
        try await GIDSignIn.sharedInstance.disconnect()
    }

    /// Google SDK 의 currentUser 만 sign-out (disconnect 와 별개).
    /// 같은 기기에서 다른 계정 로그인 시 이전 계정 자동 로그인 방어.
    public func clearClientSession() async {
        GIDSignIn.sharedInstance.signOut()
    }
}

enum GoogleLoginError: Error {
    case noRootViewController
    case noIdToken
}

// MARK: - 클라이언트 연결 해제 헬퍼

/// SettingsFeature에서 소셜 제공자별 클라이언트 연결 해제를 호출하는 단일 진입점.
/// Apple은 서버에서 처리하므로 no-op.
@MainActor
public func revokeClientSocialAccess(for providerType: SocialProviderType) async throws {
    switch providerType {
    case .kakao:
        try await KakaoLoginProvider().revokeClientAccess()
    case .google:
        try await GoogleLoginProvider().revokeClientAccess()
    case .apple:
        break
    }
}
