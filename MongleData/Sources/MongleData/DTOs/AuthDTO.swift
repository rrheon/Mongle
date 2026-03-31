//
//  AuthDTO.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation

// MARK: - Login DTOs

/// 로그인 요청 DTO
struct LoginRequestDTO: Codable {
    let email: String
    let password: String
}

/// 로그인 응답 DTO
struct LoginResponseDTO: Codable {
    let user: UserDTO
    let token: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case user
        case token
        case refreshToken = "refresh_token"
    }
}

// MARK: - Signup DTOs

/// 회원가입 요청 DTO
struct SignupRequestDTO: Codable {
    let email: String
    let name: String
    let password: String
    let role: String
}

/// 회원가입 응답 DTO
struct SignupResponseDTO: Codable {
    let user: UserDTO
    let token: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case user
        case token
        case refreshToken = "refresh_token"
    }
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
