//
//  TreeRepositoryProtocol.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation

public protocol TreeRepositoryInterface: Sendable {
    func create(_ treeProgress: TreeProgress) async throws -> TreeProgress
    func get(id: UUID) async throws -> TreeProgress
    func getByFamilyId(_ familyId: UUID) async throws -> TreeProgress?
    func update(_ treeProgress: TreeProgress) async throws -> TreeProgress
    func delete(id: UUID) async throws
    func countByStage(_ stage: TreeStage) async throws -> Int
    /// 현재 인증된 유저의 가족 나무 진행도 조회. 없으면 nil.
    func getMyTreeProgress() async throws -> TreeProgress?
}

public enum TreeError: Error, Equatable, Sendable {
    case treeNotFound
    case alreadyExists
    case networkError
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .treeNotFound:
            return "나무 정보를 찾을 수 없습니다."
        case .alreadyExists:
            return "이미 나무가 존재합니다."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .unknown(let message):
            return message
        }
    }
}
