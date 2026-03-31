//
//  GoogleLoginCredential.swift
//  Mongle
//

import Foundation
import Domain

/// 구글 로그인 자격증명.
/// Apple/KakaoLoginCredential과 동일한 패턴 — 기존 코드 수정 없이 추가만 했습니다.
public struct GoogleLoginCredential: SocialLoginCredential {
    public let providerType: SocialProviderType = .google

    /// Google이 발급한 OpenID Connect ID 토큰 (서버에서 검증에 사용)
    public let idToken: String

    /// Google 계정 표시 이름
    public let name: String?

    /// Google 계정 이메일
    public let email: String?

    public init(idToken: String, name: String?, email: String?) {
        self.idToken = idToken
        self.name = name
        self.email = email
    }

    /// 서버 POST /auth/social 요청 바디에 포함할 필드
    public var fields: [String: String] {
        var dict: [String: String] = ["id_token": idToken]
        if let name  { dict["name"]  = name  }
        if let email { dict["email"] = email }
        return dict
    }
}
