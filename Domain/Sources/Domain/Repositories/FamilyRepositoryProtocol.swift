//
//  FamilyRepositoryProtocol.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation

public protocol MongleRepositoryInterface: Sendable {
    func create(_ family: MongleGroup) async throws -> MongleGroup
    func get(id: UUID) async throws -> MongleGroup
    func findByInviteCode(_ inviteCode: String) async throws -> MongleGroup?
    func getFamiliesByUserId(_ userId: UUID) async throws -> [MongleGroup]
    func update(_ family: MongleGroup) async throws -> MongleGroup
    func delete(id: UUID) async throws
    func addMember(_ member: Member) async throws
    func removeMember(userId: UUID, familyId: UUID) async throws
    func getMembers(familyId: UUID) async throws -> [Member]
    func isMember(userId: UUID, familyId: UUID) async throws -> Bool
    /// 현재 인증된 유저의 가족을 구성원 목록과 함께 조회. 가족이 없으면 nil.
    func getMyFamily() async throws -> (MongleGroup, [User])?
    /// 초대 코드로 가족에 참여. 서버가 JWT 토큰의 userId를 멤버로 추가함.
    func joinFamily(inviteCode: String) async throws -> MongleGroup
    /// 방장이 특정 멤버를 가족에서 내보내기. DELETE /families/members/{memberId}
    func kickMember(memberId: UUID) async throws
    /// 내 모든 가족 목록 조회 (최대 3개)
    func getMyFamilies() async throws -> [MongleGroup]
    /// 활성 가족 전환
    func selectFamily(familyId: UUID) async throws -> MongleGroup
}

public enum MongleError: Error, Equatable, Sendable {
    case familyNotFound
    case invalidInviteCode
    case alreadyMember
    case notMember
    case cannotLeaveAsOnlyAdmin
    case networkError
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .familyNotFound:
            return "가족을 찾을 수 없습니다."
        case .invalidInviteCode:
            return "유효하지 않은 초대 코드입니다."
        case .alreadyMember:
            return "이미 가족 구성원입니다."
        case .notMember:
            return "가족 구성원이 아닙니다."
        case .cannotLeaveAsOnlyAdmin:
            return "유일한 관리자는 가족을 떠날 수 없습니다."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .unknown(let message):
            return message
        }
    }
}
