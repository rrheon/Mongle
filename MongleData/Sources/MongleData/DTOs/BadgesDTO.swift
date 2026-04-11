//
//  BadgesDTO.swift
//  MongleData
//
//  v2 PRD §4 — GET /users/me/badges, POST /users/me/badges/mark-seen 응답 매핑.
//

import Foundation

struct UserBadgeDTO: Decodable {
    let code: String
    let category: String
    let iconKey: String
    let thresholdNumeric: Int?
    let awardedAt: String
    let seenAt: String?
}

struct BadgeDefinitionDTO: Decodable {
    let code: String
    let category: String
    let iconKey: String
    let thresholdNumeric: Int?
}

struct BadgeListResponseDTO: Decodable {
    let badges: [UserBadgeDTO]
    let definitions: [BadgeDefinitionDTO]
}

struct OkResponseDTO: Decodable {
    let ok: Bool
}
