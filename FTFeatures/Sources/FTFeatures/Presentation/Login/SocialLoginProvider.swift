//
//  SocialLoginProvider.swift
//  FamTree
//

import Foundation
import AuthenticationServices
import Domain
import FTData

// MARK: - 소셜 로그인 제공자 프로토콜
//
// 새로운 소셜 제공자 추가 순서:
// 1. FTData/Credentials/ 에 XxxLoginCredential: SocialLoginCredential 추가
// 2. 이 파일에 XxxLoginProvider: SocialLoginProvider 추가
// 기존 LoginFeature, AuthRepository 등은 수정 불필요

public protocol SocialLoginProvider {
    associatedtype Credential: SocialLoginCredential
    func authenticate() async throws -> Credential
}

// MARK: - Apple 로그인 제공자

@MainActor
public final class AppleLoginProvider: NSObject, SocialLoginProvider {
    private var continuation: CheckedContinuation<AppleLoginCredential, Error>?

    public func authenticate() async throws -> AppleLoginCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
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

// MARK: - 에러

enum AppleLoginError: Error {
    case invalidCredential
}
