//
//  AnswerDTO.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation

/// 서버 응답 AnswerResponse DTO
/// POST /answers, GET /answers/family/{id}, GET /answers/my/{id} 응답에 공통 사용
struct AnswerDTO: Codable {
    let id: String
    let content: String
    let imageUrl: String?
    let user: UserDTO
    let questionId: String   // DailyQuestion ID
    let createdAt: String
    let updatedAt: String
}

/// GET /answers/family/{questionId} 응답 DTO
struct FamilyAnswersResponseDTO: Codable {
    let answers: [AnswerDTO]
    let totalCount: Int
    let myAnswer: AnswerDTO?
}
