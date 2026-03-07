//
//  Question.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import Foundation

public struct Question: Equatable, Sendable {
    public let id: UUID
    public let content: String
    public let category: QuestionCategory
    public let order: Int
    public let createdAt: Date

    public init(
        id: UUID,
        content: String,
        category: QuestionCategory,
        order: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.category = category
        self.order = order
        self.createdAt = createdAt
    }
}

public enum QuestionCategory: String, Sendable {
    case daily = "일상 & 취미"
    case memory = "추억 & 과거"
    case values = "가치관 & 생각"
    case future = "미래 & 계획"
    case gratitude = "감사 & 애정"
}
