//
//  SocialLoginCredential.swift
//  Mongle
//

import Foundation

// MARK: - 소셜 로그인 제공자 타입

public enum SocialProviderType: String, Sendable, Equatable, CaseIterable {
    case apple
    case kakao
    case google
}

// MARK: - 소셜 로그인 자격증명 프로토콜
//
// 새로운 소셜 로그인 제공자 추가 시 이 프로토콜을 구현하는 타입만 추가하면 됩니다.
// 기존 코드(AuthRepositoryInterface, LoginFeature 등)는 수정 불필요합니다.

public protocol SocialLoginCredential: Sendable {
    /// 어떤 소셜 제공자의 자격증명인지
    var providerType: SocialProviderType { get }

    /// 서버에 전송할 제공자별 페이로드 (key-value)
    /// - Apple: identity_token, authorization_code, name?, email?
    /// - Kakao:  access_token, name?, email?
    /// - Google: id_token, name?, email?
    var fields: [String: String] { get }
}
