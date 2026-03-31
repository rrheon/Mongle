//
//  DailyQuestionDTO.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation

/// 일일 질문 데이터 전송 객체
struct DailyQuestionDTO: Codable {
    let id: String
    let familyId: String
    let questionId: String
    let questionOrder: Int
    let date: String
    let isCompleted: Bool
    let answerIds: [String]
    let createdAt: String
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case familyId = "family_id"
        case questionId = "question_id"
        case questionOrder = "question_order"
        case date
        case isCompleted = "is_completed"
        case answerIds = "answer_ids"
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }
}
