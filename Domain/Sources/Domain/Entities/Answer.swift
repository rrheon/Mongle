//
//  Answer.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import Foundation

public struct Answer: Equatable, Sendable {
    public let id: UUID
    public let dailyQuestionId: UUID
    public let userId: UUID
    public let content: String
    public let imageURL: String?
    public let createdAt: Date
    public let updatedAt: Date?
    public let reactionIds: [UUID]
    public let commentIds: [UUID]

    public init(
        id: UUID,
        dailyQuestionId: UUID,
        userId: UUID,
        content: String,
        imageURL: String?,
        createdAt: Date,
        updatedAt: Date? = nil,
        reactionIds: [UUID] = [],
        commentIds: [UUID] = []
    ) {
        self.id = id
        self.dailyQuestionId = dailyQuestionId
        self.userId = userId
        self.content = content
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reactionIds = reactionIds
        self.commentIds = commentIds
    }
}
