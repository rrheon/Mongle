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
