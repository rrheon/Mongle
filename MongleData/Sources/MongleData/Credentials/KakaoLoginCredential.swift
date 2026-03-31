//
//  KakaoLoginCredential.swift
//  Mongle
//

import Foundation
import Domain

/// 카카오 로그인 자격증명.
/// AppleLoginCredential과 동일한 패턴 — 기존 코드 수정 없이 추가만 했습니다.
public struct KakaoLoginCredential: SocialLoginCredential {
    public let providerType: SocialProviderType = .kakao

    /// KakaoSDK가 발급한 액세스 토큰
    public let accessToken: String

    /// OIDC ID 토큰 (서버측 JWT 검증에 사용)
    public let idToken: String?

    /// 카카오 프로필 닉네임 (scope 동의 시 제공)
    public let name: String?

    /// 카카오 계정 이메일 (scope 동의 + 비즈니스 앱 시 제공)
    public let email: String?

    public init(accessToken: String, idToken: String?, name: String?, email: String?) {
        self.accessToken = accessToken
        self.idToken = idToken
        self.name = name
        self.email = email
    }

    /// 서버 POST /auth/social 요청 바디에 포함할 필드
    public var fields: [String: String] {
        var dict: [String: String] = ["access_token": accessToken]
        if let idToken { dict["id_token"] = idToken }
        if let name    { dict["name"]     = name    }
        if let email   { dict["email"]    = email   }
        return dict
    }
}
