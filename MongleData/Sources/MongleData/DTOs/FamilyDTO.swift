//
//  FamilyDTO.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation

/// 가족 그룹 데이터 전송 객체 (레거시)
struct FamilyDTO: Codable {
    let id: String
    let name: String
    let memberIds: [String]
    let createdBy: String
    let createdAt: String
    let inviteCode: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case memberIds = "member_ids"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case inviteCode = "invite_code"
    }
}

/// 서버 응답 형식 가족 DTO — members 포함 (GET /families/my)
struct FamilyResponseDTO: Codable {
    let id: String
    let name: String
    let inviteCode: String
    let createdById: String
    let members: [UserDTO]
    let createdAt: String
    let streakDays: Int?
    /// 가족 공유 홈 배경 id (상점). 서버 미반영/미적용이면 nil → 기본 배경. 홈 배경 영속화에 사용.
    let appliedBackgroundId: String?
}

/// GET /families/all 래퍼 응답 DTO
struct FamiliesListResponseDTO: Codable {
    let families: [FamilyResponseDTO]
}
