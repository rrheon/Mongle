//
//  AppleLoginCredential.swift
//  Mongle
//

import Foundation
import Domain

/// Apple 로그인 자격증명.
/// 새로운 소셜 제공자(Kakao, Naver 등)는 동일한 방식으로 이 파일 옆에 추가합니다.
public struct AppleLoginCredential: SocialLoginCredential {
    public let providerType: SocialProviderType = .apple

    /// Apple이 발급한 JWT identity token
    public let identityToken: String

    /// 서버에서 Apple API로 토큰 검증 시 사용하는 일회성 코드
    public let authorizationCode: String

    /// 최초 로그인 시에만 제공됨. 이후 재로그인 시 nil
    public let name: String?

    /// 최초 로그인 시에만 제공되거나 개인정보 보호 릴레이 주소일 수 있음
    public let email: String?

    public init(
        identityToken: String,
        authorizationCode: String,
        name: String?,
        email: String?
    ) {
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
        self.name = name
        self.email = email
    }

    /// 서버 POST /auth/social 요청 바디에 포함할 필드
    public var fields: [String: String] {
        var dict: [String: String] = [
            "identity_token": identityToken,
            "authorization_code": authorizationCode
        ]
        if let name  { dict["name"]  = name  }
        if let email { dict["email"] = email }
        return dict
    }
}
