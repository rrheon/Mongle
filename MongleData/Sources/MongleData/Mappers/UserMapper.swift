//
//  UserMapper.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Domain

/// User 엔티티와 UserDTO 간의 매핑을 담당하는 Mapper
struct UserMapper {
    /// DTO를 Domain Entity로 변환
    static func toDomain(_ dto: UserDTO) -> User {
        User(
            id: UUID(uuidString: dto.id) ?? UUID(),
            email: dto.email,
            name: dto.name,
            profileImageURL: dto.profileImageUrl,
            role: familyRole(from: dto.role),
            hearts: dto.hearts ?? 0,
            moodId: dto.moodId ?? "loved",
            createdAt: parseISO8601(dto.createdAt)
        )
    }

    /// 서버 영문 역할값(FATHER/MOTHER/SON/DAUGHTER)을 FamilyRole로 변환
    private static func familyRole(from serverRole: String) -> FamilyRole {
        switch serverRole.uppercased() {
        case "FATHER":   return .father
        case "MOTHER":   return .mother
        case "SON":      return .son
        case "DAUGHTER": return .daughter
        default:         return .other
        }
    }

    /// Domain Entity를 DTO로 변환
    static func toDTO(_ domain: User) -> UserDTO {
        UserDTO(
            id: domain.id.uuidString,
            email: domain.email,
            name: domain.name,
            profileImageUrl: domain.profileImageURL,
            role: serverRole(from: domain.role),
            familyId: nil,
            hearts: nil,
            moodId: domain.moodId,
            createdAt: ISO8601DateFormatter().string(from: domain.createdAt),
            streakRiskNotify: nil,
            badgeEarnedNotify: nil
        )
    }

    /// Domain FamilyRole을 서버 영문 열거값으로 변환
    private static func serverRole(from role: FamilyRole) -> String {
        switch role {
        case .father:   return "FATHER"
        case .mother:   return "MOTHER"
        case .son:      return "SON"
        case .daughter: return "DAUGHTER"
        case .other:    return "OTHER"
        }
    }
}
