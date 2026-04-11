//
//  UserBadge.swift
//  Domain
//
//  v2 PRD §4 — 배지 도메인 모델.
//

import Foundation

public enum BadgeCategory: String, Equatable, Sendable {
    case streak = "STREAK"
    case answerCount = "ANSWER_COUNT"
    case unknown
}

public struct UserBadge: Equatable, Identifiable, Sendable {
    public let code: String
    public let category: BadgeCategory
    public let iconKey: String
    public let thresholdNumeric: Int?
    public let awardedAt: Date
    public var seenAt: Date?

    public var id: String { code }

    public init(
        code: String,
        category: BadgeCategory,
        iconKey: String,
        thresholdNumeric: Int?,
        awardedAt: Date,
        seenAt: Date?
    ) {
        self.code = code
        self.category = category
        self.iconKey = iconKey
        self.thresholdNumeric = thresholdNumeric
        self.awardedAt = awardedAt
        self.seenAt = seenAt
    }
}

public struct BadgeDefinition: Equatable, Identifiable, Sendable {
    public let code: String
    public let category: BadgeCategory
    public let iconKey: String
    public let thresholdNumeric: Int?

    public var id: String { code }

    public init(
        code: String,
        category: BadgeCategory,
        iconKey: String,
        thresholdNumeric: Int?
    ) {
        self.code = code
        self.category = category
        self.iconKey = iconKey
        self.thresholdNumeric = thresholdNumeric
    }
}

public struct BadgeList: Equatable, Sendable {
    public let badges: [UserBadge]
    public let definitions: [BadgeDefinition]

    public init(badges: [UserBadge], definitions: [BadgeDefinition]) {
        self.badges = badges
        self.definitions = definitions
    }
}
