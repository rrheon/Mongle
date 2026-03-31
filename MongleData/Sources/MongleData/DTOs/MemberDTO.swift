//
//  MemberDTO.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation

/// 가족 구성원 데이터 전송 객체
struct MemberDTO: Codable {
    let id: String
    let userId: String
    let familyId: String
    let role: String
    let joinedAt: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case familyId = "family_id"
        case role
        case joinedAt = "joined_at"
        case isActive = "is_active"
    }
}
