//
//  AuthDTO.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation

// MARK: - Login DTOs

/// 로그인 응답 DTO (소셜 로그인 공통)
struct LoginResponseDTO: Codable {
    let user: UserDTO
    let token: String
    let refreshToken: String?
    /// 약관 동의 필요 여부 — 신규 가입 또는 약관 버전 변경 시 true
    let needsConsent: Bool?
    /// 동의가 필요한 약관 종류 ("terms", "privacy")
    let requiredConsents: [String]?
    /// 서버가 알려주는 현재 약관 버전
    let legalVersions: LegalVersionsDTO?

    enum CodingKeys: String, CodingKey {
        case user
        case token
        case refreshToken = "refresh_token"
        case needsConsent
        case requiredConsents
        case legalVersions
    }
}

struct LegalVersionsDTO: Codable {
    let terms: String
    let privacy: String
}

/// 약관 동의 요청 DTO
struct ConsentRequestDTO: Codable {
    let termsVersion: String?
    let privacyVersion: String?
}

// MARK: - Token Refresh DTOs

/// 토큰 갱신 요청 DTO
struct RefreshTokenRequestDTO: Codable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

/// 토큰 갱신 응답 DTO
struct RefreshTokenResponseDTO: Codable {
    let token: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case token
        case refreshToken = "refresh_token"
    }
}
