//
//  FamilyMapper.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Domain

/// Family 엔티티와 FamilyDTO/FamilyResponseDTO 간의 매핑을 담당하는 Mapper
struct FamilyMapper {
    /// 서버 응답 DTO(구성원 포함)를 (MongleGroup, [User]) 튜플로 변환
    static func toDomainWithMembers(_ dto: FamilyResponseDTO) -> (MongleGroup, [User]) {
        let members = dto.members.map { UserMapper.toDomain($0) }
        let family = MongleGroup(
            id: UUID(uuidString: dto.id) ?? UUID(),
            name: dto.name,
            memberIds: members.map { $0.id },
            createdBy: UUID(uuidString: dto.createdById) ?? UUID(),
            createdAt: ISO8601DateFormatter().date(from: dto.createdAt) ?? Date(),
            inviteCode: dto.inviteCode,
            memberMoodIds: dto.members.map { $0.moodId ?? "loved" },
            streakDays: dto.streakDays ?? 0
        )
        return (family, members)
    }

    /// DTO를 Domain Entity로 변환
    static func toDomain(_ dto: FamilyDTO) -> MongleGroup {
        MongleGroup(
            id: UUID(uuidString: dto.id) ?? UUID(),
            name: dto.name,
            memberIds: dto.memberIds.compactMap { UUID(uuidString: $0) },
            createdBy: UUID(uuidString: dto.createdBy) ?? UUID(),
            createdAt: ISO8601DateFormatter().date(from: dto.createdAt) ?? Date(),
            inviteCode: dto.inviteCode
        )
    }

    /// Domain Entity를 DTO로 변환
    static func toDTO(_ domain: MongleGroup) -> FamilyDTO {
        FamilyDTO(
            id: domain.id.uuidString,
            name: domain.name,
            memberIds: domain.memberIds.map { $0.uuidString },
            createdBy: domain.createdBy.uuidString,
            createdAt: ISO8601DateFormatter().string(from: domain.createdAt),
            inviteCode: domain.inviteCode
        )
    }
}
