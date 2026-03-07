//
//  DailyQuestionRepositoryProtocol.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation

public protocol DailyQuestionRepositoryInterface: Sendable {
    func create(_ dailyQuestion: DailyQuestion) async throws -> DailyQuestion
    func get(id: UUID) async throws -> DailyQuestion
    func getByFamilyAndDate(familyId: UUID, date: Date) async throws -> DailyQuestion?
    func getHistoryByFamily(familyId: UUID, limit: Int?) async throws -> [DailyQuestion]
    func getLastQuestionOrder(familyId: UUID) async throws -> Int?
    func update(_ dailyQuestion: DailyQuestion) async throws -> DailyQuestion
    func delete(id: UUID) async throws
    func getCompletedByFamily(familyId: UUID) async throws -> [DailyQuestion]
    func getIncompleteByFamily(familyId: UUID) async throws -> [DailyQuestion]
}

public enum DailyQuestionError: Error, Equatable, Sendable {
    case dailyQuestionNotFound
    case alreadyExists
    case networkError
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .dailyQuestionNotFound:
            return "오늘의 질문을 찾을 수 없습니다."
        case .alreadyExists:
            return "오늘의 질문이 이미 존재합니다."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .unknown(let message):
            return message
        }
    }
}
