//
//  UserRepositoryProtocol.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation

public protocol UserRepositoryInterface: Sendable {
    func get(id: UUID) async throws -> User
    func update(_ user: User) async throws -> User
    func updateName(_ name: String) async throws
    func getMyStreak() async throws -> Int
    func registerDeviceToken(token: String) async throws
    /// 광고 시청 보상으로 하트를 지급하고 남은 하트 수를 반환합니다.
    func grantAdHearts(amount: Int) async throws -> Int

    // MARK: - v2 (PRD §2.2 / §4 / §9)

    /// `GET /users/me/character-stage` — 캐릭터 성장 단계 조회.
    func getCharacterStage() async throws -> CharacterStage
    /// `GET /users/me/badges` — 획득 배지 + 전체 정의 조회.
    func getBadges() async throws -> BadgeList
    /// `POST /users/me/badges/mark-seen` — 미확인 배지를 본 것으로 표시.
    func markBadgesSeen(codes: [String]) async throws
    /// Engine-8 — `PUT /users/me` 부분 업데이트로 알림 옵트아웃 토글 동기화.
    func updateNotificationPrefs(streakRisk: Bool?, badgeEarned: Bool?) async throws
}

public enum UserError: Error, Equatable, Sendable {
    case userNotFound
    case updateFailed
    case networkError
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .userNotFound:
            return "사용자를 찾을 수 없습니다."
        case .updateFailed:
            return "사용자 정보 업데이트에 실패했습니다."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .unknown(let message):
            return message
        }
    }
}
