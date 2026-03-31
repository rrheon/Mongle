//
//  FamilyRepository.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Domain

final class FamilyRepository: MongleRepositoryInterface {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func create(_ family: MongleGroup, nickname: String?, colorId: String?) async throws -> MongleGroup {
        let endpoint = FamilyEndpoint.create(name: family.name, nickname: nickname, colorId: colorId)
        let dto: FamilyResponseDTO = try await apiClient.request(endpoint)
        return FamilyMapper.toDomainWithMembers(dto).0
    }

    func get(id: UUID) async throws -> MongleGroup {
        let endpoint = FamilyEndpoint.get(familyId: id.uuidString)
        let familyDTO: FamilyDTO = try await apiClient.request(endpoint)
        return FamilyMapper.toDomain(familyDTO)
    }

    func findByInviteCode(_ inviteCode: String) async throws -> MongleGroup? {
        let endpoint = FamilyEndpoint.findByInviteCode(inviteCode: inviteCode)
        let familyDTO: FamilyDTO? = try? await apiClient.request(endpoint)
        return familyDTO.map { FamilyMapper.toDomain($0) }
    }

    func getFamiliesByUserId(_ userId: UUID) async throws -> [MongleGroup] {
        let endpoint = FamilyEndpoint.getFamiliesByUserId(userId: userId.uuidString)
        let familyDTOs: [FamilyDTO] = try await apiClient.request(endpoint)
        return familyDTOs.map { FamilyMapper.toDomain($0) }
    }

    func update(_ family: MongleGroup) async throws -> MongleGroup {
        let familyDTO = FamilyMapper.toDTO(family)
        let endpoint = FamilyEndpoint.update(familyId: family.id.uuidString, data: familyDTO)
        let updatedDTO: FamilyDTO = try await apiClient.request(endpoint)
        return FamilyMapper.toDomain(updatedDTO)
    }

    func delete(id: UUID) async throws {
        let endpoint = FamilyEndpoint.delete(familyId: id.uuidString)
        try await apiClient.request(endpoint)
    }

    func addMember(_ member: Member) async throws {
        let endpoint = FamilyEndpoint.addMember(
            familyId: member.familyId.uuidString,
            userId: member.userId.uuidString,
            role: member.role.rawValue
        )
        try await apiClient.request(endpoint)
    }

    /// DELETE /families/leave — JWT 토큰의 유저를 현재 가족에서 제거
    func removeMember(userId: UUID, familyId: UUID) async throws {
        try await apiClient.request(FamilyEndpoint.leave)
    }

    func getMembers(familyId: UUID) async throws -> [Member] {
        let endpoint = FamilyEndpoint.getMembers(familyId: familyId.uuidString)
        let memberDTOs: [MemberDTO] = try await apiClient.request(endpoint)
        return memberDTOs.map { MemberMapper.toDomain($0) }
    }

    func isMember(userId: UUID, familyId: UUID) async throws -> Bool {
        let members = try await getMembers(familyId: familyId)
        return members.contains { $0.userId == userId }
    }

    func getMyFamily() async throws -> (MongleGroup, [User])? {
        let dto: FamilyResponseDTO? = try? await apiClient.request(HomeEndpoint.myFamily)
        return dto.map { FamilyMapper.toDomainWithMembers($0) }
    }

    func joinFamily(inviteCode: String, nickname: String?, colorId: String?) async throws -> MongleGroup {
        let endpoint = FamilyEndpoint.join(inviteCode: inviteCode, nickname: nickname, colorId: colorId)
        let dto: FamilyResponseDTO = try await apiClient.request(endpoint)
        return FamilyMapper.toDomainWithMembers(dto).0
    }

    /// 방장이 특정 멤버를 가족에서 내보내기 — DELETE /families/members/{memberId}
    func kickMember(memberId: UUID) async throws {
        try await apiClient.request(FamilyEndpoint.kickMember(memberId: memberId.uuidString))
    }

    func getMyFamilies() async throws -> [MongleGroup] {
        let response: FamiliesListResponseDTO = try await apiClient.request(FamilyEndpoint.getAll)
        return response.families.map { FamilyMapper.toDomainWithMembers($0).0 }
    }

    func selectFamily(familyId: UUID) async throws -> MongleGroup {
        let dto: FamilyResponseDTO = try await apiClient.request(FamilyEndpoint.selectFamily(familyId: familyId.uuidString))
        return FamilyMapper.toDomainWithMembers(dto).0
    }

    /// 현재 활성 가족에서 나가기 — DELETE /families/leave
    func leaveFamily() async throws {
        try await apiClient.request(FamilyEndpoint.leave)
    }

    /// 방장 위임 — PATCH /families/transfer-creator
    func transferCreator(newCreatorId: UUID) async throws {
        try await apiClient.request(FamilyEndpoint.transferCreator(newCreatorId: newCreatorId.uuidString))
    }

    /// 특정 그룹과 구성원 목록 함께 조회 — GET /families/{familyId}
    func getGroupWithMembers(id: UUID) async throws -> (MongleGroup, [User]) {
        let endpoint = FamilyEndpoint.get(familyId: id.uuidString)
        let dto: FamilyResponseDTO = try await apiClient.request(endpoint)
        return FamilyMapper.toDomainWithMembers(dto)
    }
}
