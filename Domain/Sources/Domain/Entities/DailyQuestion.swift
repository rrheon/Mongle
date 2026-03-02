//
//  DailyQuestion.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import Foundation

public struct DailyQuestion: Equatable, Sendable {
    public let id: UUID
    public let familyId: UUID
    public let questionId: UUID
    public let questionOrder: Int
    public let date: Date
    public let isCompleted: Bool
    public let answerIds: [UUID]
    public let createdAt: Date
    public let completedAt: Date?

    public init(
        id: UUID,
        familyId: UUID,
        questionId: UUID,
        questionOrder: Int,
        date: Date,
        isCompleted: Bool,
        answerIds: [UUID],
        createdAt: Date,
        completedAt: Date?
    ) {
        self.id = id
        self.familyId = familyId
        self.questionId = questionId
        self.questionOrder = questionOrder
        self.date = date
        self.isCompleted = isCompleted
        self.answerIds = answerIds
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}
