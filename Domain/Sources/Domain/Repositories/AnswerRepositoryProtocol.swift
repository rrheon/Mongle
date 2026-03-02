//
//  AnswerRepositoryProtocol.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation

public protocol AnswerRepositoryInterface: Sendable {
    func create(_ answer: Answer) async throws -> Answer
    func get(id: UUID) async throws -> Answer
    func getByDailyQuestion(dailyQuestionId: UUID) async throws -> [Answer]
    func getByUserAndDailyQuestion(dailyQuestionId: UUID, userId: UUID) async throws -> Answer?
    func hasUserAnswered(dailyQuestionId: UUID, userId: UUID) async throws -> Bool
    func getByUser(userId: UUID) async throws -> [Answer]
    func update(_ answer: Answer) async throws -> Answer
    func delete(id: UUID) async throws
}

public enum AnswerError: Error, Equatable, Sendable {
    case answerNotFound
    case alreadyAnswered
    case cannotModify
    case networkError
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .answerNotFound:
            return "답변을 찾을 수 없습니다."
        case .alreadyAnswered:
            return "이미 답변을 작성했습니다."
        case .cannotModify:
            return "답변을 수정할 수 없습니다."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .unknown(let message):
            return message
        }
    }
}
