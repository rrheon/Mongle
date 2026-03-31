//
//  QuestionDTO.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation

/// 서버 응답 형식 질문 DTO (GET /questions/today 내 question 필드)
struct QuestionResponseDTO: Codable {
    let id: String
    let content: String
    let category: String
    let createdAt: String
    let isCustom: Bool?  // 구버전 서버 호환을 위해 optional (nil = false)
}

/// GET /questions 히스토리 응답의 답변 요약 DTO
struct HistoryAnswerSummaryDTO: Codable {
    let id: String
    let userId: String
    let userName: String
    let content: String
    let imageUrl: String?
    let moodId: String?
}

/// 서버 응답 형식 오늘의 질문 DTO (GET /questions/today, POST /questions/skip)
struct DailyQuestionResponseDTO: Codable {
    let id: String
    let question: QuestionResponseDTO
    let date: String
    let familyId: String
    let isSkipped: Bool
    let skippedAt: String?
    let hasMyAnswer: Bool
    let hasMySkipped: Bool
    let familyAnswerCount: Int
    /// GET /questions 히스토리에서만 포함 (N+1 제거용)
    let answers: [HistoryAnswerSummaryDTO]?
}

/// 질문 데이터 전송 객체 (레거시)
struct QuestionDTO: Codable {
    let id: String
    let content: String
    let category: String
    let order: Int
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case category
        case order
        case createdAt = "created_at"
    }
}
