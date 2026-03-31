//
//  AnswerMapper.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Domain

/// Answer 엔티티와 AnswerDTO 간의 매핑을 담당하는 Mapper
struct AnswerMapper {
    /// DTO를 Domain Entity로 변환
    static func toDomain(_ dto: AnswerDTO) -> Answer {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return Answer(
            id: UUID(uuidString: dto.id) ?? UUID(),
            dailyQuestionId: UUID(uuidString: dto.questionId) ?? UUID(),
            userId: UUID(uuidString: dto.user.id) ?? UUID(),
            content: dto.content,
            imageURL: dto.imageUrl,
            createdAt: formatter.date(from: dto.createdAt) ?? Date(),
            updatedAt: formatter.date(from: dto.updatedAt),
            reactionIds: [],
            commentIds: []
        )
    }
}
