//
//  SocialLoginResult.swift
//  Domain
//
//  Created on 2026-04-07.
//

import Foundation

/// 소셜 로그인 응답.
/// 사용자 정보 + 약관 동의 필요 여부 + 현재 약관 버전을 함께 전달한다.
/// 동의가 필요하면 LoginFeature → RootFeature 가 ConsentFeature 로 라우팅한다.
public struct SocialLoginResult: Equatable, Sendable {
    public let user: User
    public let needsConsent: Bool
    public let requiredConsents: [LegalDocType]
    public let legalVersions: LegalVersions

    public init(
        user: User,
        needsConsent: Bool,
        requiredConsents: [LegalDocType],
        legalVersions: LegalVersions
    ) {
        self.user = user
        self.needsConsent = needsConsent
        self.requiredConsents = requiredConsents
        self.legalVersions = legalVersions
    }
}

public enum LegalDocType: String, Sendable, Equatable, CaseIterable {
    case terms
    case privacy
}

public struct LegalVersions: Equatable, Sendable {
    public let terms: String
    public let privacy: String

    public init(terms: String, privacy: String) {
        self.terms = terms
        self.privacy = privacy
    }
}
