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
    /// 오늘의 질문 응답에서 내려오는 DailyQuestion ID (서버 PK). 답변 체크에 사용.
    public let dailyQuestionId: String?
    /// 이미 답변한 가족 수 (GET /questions/today 응답의 familyAnswerCount)
    public let familyAnswerCount: Int
    /// 현재 유저가 이미 답변했는지 (GET /questions/today 응답의 hasMyAnswer)
    public let hasMyAnswer: Bool

    public init(
        id: UUID,
        content: String,
        category: QuestionCategory,
        order: Int,
        createdAt: Date = Date(),
        dailyQuestionId: String? = nil,
        familyAnswerCount: Int = 0,
        hasMyAnswer: Bool = false
    ) {
        self.id = id
        self.content = content
        self.category = category
        self.order = order
        self.createdAt = createdAt
        self.dailyQuestionId = dailyQuestionId
        self.familyAnswerCount = familyAnswerCount
        self.hasMyAnswer = hasMyAnswer
    }
}

public enum QuestionCategory: String, Sendable {
    case daily = "일상 & 취미"
    case memory = "추억 & 과거"
    case values = "가치관 & 생각"
    case future = "미래 & 계획"
    case gratitude = "감사 & 애정"
}
