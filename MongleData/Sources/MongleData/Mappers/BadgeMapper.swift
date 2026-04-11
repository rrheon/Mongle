//
//  BadgeMapper.swift
//  MongleData
//

import Foundation
import Domain

struct BadgeMapper {
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoFallback: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static func parse(_ s: String) -> Date {
        isoFormatter.date(from: s) ?? isoFallback.date(from: s) ?? Date()
    }

    static func category(from raw: String) -> BadgeCategory {
        BadgeCategory(rawValue: raw) ?? .unknown
    }

    static func toDomain(_ dto: UserBadgeDTO) -> UserBadge {
        UserBadge(
            code: dto.code,
            category: category(from: dto.category),
            iconKey: dto.iconKey,
            thresholdNumeric: dto.thresholdNumeric,
            awardedAt: parse(dto.awardedAt),
            seenAt: dto.seenAt.map(parse)
        )
    }

    static func toDomain(_ dto: BadgeDefinitionDTO) -> BadgeDefinition {
        BadgeDefinition(
            code: dto.code,
            category: category(from: dto.category),
            iconKey: dto.iconKey,
            thresholdNumeric: dto.thresholdNumeric
        )
    }

    static func toDomain(_ dto: BadgeListResponseDTO) -> BadgeList {
        BadgeList(
            badges: dto.badges.map(toDomain),
            definitions: dto.definitions.map(toDomain)
        )
    }
}
