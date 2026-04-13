//
//  MemberMapper.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Domain

/// Member 엔티티와 MemberDTO 간의 매핑을 담당하는 Mapper
struct MemberMapper {
    /// DTO를 Domain Entity로 변환
    static func toDomain(_ dto: MemberDTO) -> Member {
        Member(
            id: UUID(uuidString: dto.id) ?? UUID(),
            userId: UUID(uuidString: dto.userId) ?? UUID(),
            familyId: UUID(uuidString: dto.familyId) ?? UUID(),
            role: FamilyRole(rawValue: dto.role) ?? .other,
            joinedAt: parseISO8601(dto.joinedAt),
            isActive: dto.isActive
        )
    }

    /// Domain Entity를 DTO로 변환
    static func toDTO(_ domain: Member) -> MemberDTO {
        MemberDTO(
            id: domain.id.uuidString,
            userId: domain.userId.uuidString,
            familyId: domain.familyId.uuidString,
            role: domain.role.rawValue,
            joinedAt: ISO8601DateFormatter().string(from: domain.joinedAt),
            isActive: domain.isActive
        )
    }
}
