//
//  QuestionMapper.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Domain

/// Question 엔티티와 QuestionDTO/DailyQuestionResponseDTO 간의 매핑을 담당하는 Mapper
struct QuestionMapper {
    /// 서버 응답 DTO(오늘의 질문)를 Domain Entity로 변환
    static func toDomain(_ dto: DailyQuestionResponseDTO) -> Question {
        let q = dto.question
        let category: QuestionCategory
        switch q.category.uppercased() {
        case "DAILY":       category = .daily
        case "MEMORY":      category = .memory
        case "VALUE":       category = .values
        case "DREAM":       category = .future
        case "GRATITUDE":   category = .gratitude
        default:            category = .daily
        }
        return Question(
            id: UUID(uuidString: q.id) ?? UUID(),
            content: q.content,
            category: category,
            order: 0,
            createdAt: parseISO8601(q.createdAt),
            dailyQuestionId: dto.id,
            familyAnswerCount: dto.familyAnswerCount,
            hasMyAnswer: dto.hasMyAnswer,
            hasMySkipped: dto.hasMySkipped,
            isCustom: q.isCustom ?? false
        )
    }

    /// DTO를 Domain Entity로 변환
    static func toDomain(_ dto: QuestionDTO) -> Question {
        Question(
            id: UUID(uuidString: dto.id) ?? UUID(),
            content: dto.content,
            category: QuestionCategory(rawValue: dto.category) ?? .daily,
            order: dto.order,
            createdAt: parseISO8601(dto.createdAt)
        )
    }

    /// Domain Entity를 DTO로 변환
    static func toDTO(_ domain: Question) -> QuestionDTO {
        QuestionDTO(
            id: domain.id.uuidString,
            content: domain.content,
            category: domain.category.rawValue,
            order: domain.order,
            createdAt: ISO8601DateFormatter().string(from: domain.createdAt)
        )
    }
}
