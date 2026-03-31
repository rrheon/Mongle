//
//  DailyQuestionMapper.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Domain

/// DailyQuestion 엔티티와 DailyQuestionDTO 간의 매핑을 담당하는 Mapper
struct DailyQuestionMapper {
    /// DTO를 Domain Entity로 변환
    static func toDomain(_ dto: DailyQuestionDTO) -> DailyQuestion {
        let formatter = ISO8601DateFormatter()

        return DailyQuestion(
            id: UUID(uuidString: dto.id) ?? UUID(),
            familyId: UUID(uuidString: dto.familyId) ?? UUID(),
            questionId: UUID(uuidString: dto.questionId) ?? UUID(),
            questionOrder: dto.questionOrder,
            date: formatter.date(from: dto.date) ?? Date(),
            isCompleted: dto.isCompleted,
            answerIds: dto.answerIds.compactMap { UUID(uuidString: $0) },
            createdAt: formatter.date(from: dto.createdAt) ?? Date(),
            completedAt: dto.completedAt.flatMap { formatter.date(from: $0) }
        )
    }

    /// Domain Entity를 DTO로 변환
    static func toDTO(_ domain: DailyQuestion) -> DailyQuestionDTO {
        let formatter = ISO8601DateFormatter()

        return DailyQuestionDTO(
            id: domain.id.uuidString,
            familyId: domain.familyId.uuidString,
            questionId: domain.questionId.uuidString,
            questionOrder: domain.questionOrder,
            date: formatter.string(from: domain.date),
            isCompleted: domain.isCompleted,
            answerIds: domain.answerIds.map { $0.uuidString },
            createdAt: formatter.string(from: domain.createdAt),
            completedAt: domain.completedAt.map { formatter.string(from: $0) }
        )
    }
}
