//
//  QuestionRepositoryProtocol.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation

public protocol QuestionRepositoryInterface: Sendable {
    func create(_ question: Question) async throws -> Question
    func get(id: UUID) async throws -> Question
    func getByOrder(_ order: Int) async throws -> Question?
    func getByCategory(_ category: QuestionCategory) async throws -> [Question]
    func getAll() async throws -> [Question]
    func update(_ question: Question) async throws -> Question
    func delete(id: UUID) async throws
    /// 오늘의 질문을 조회. 질문이 없으면 nil.
    func getTodayQuestion() async throws -> Question?
}

public enum QuestionError: Error, Equatable, Sendable {
    case questionNotFound
    case noQuestionToday
    case networkError
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .questionNotFound:
            return "질문을 찾을 수 없습니다."
        case .noQuestionToday:
            return "오늘의 질문이 아직 없습니다."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .unknown(let message):
            return message
        }
    }
}
