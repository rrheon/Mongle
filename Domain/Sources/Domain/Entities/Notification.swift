//
//  Notification.swift
//  FamTree
//
//  Created by 최용헌 on 12/10/25.
//

import Foundation

public struct Notification: Equatable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let type: NotificationType
    public let title: String
    public let body: String
    public let isRead: Bool
    public let createdAt: Date

    public init(
        id: UUID,
        userId: UUID,
        type: NotificationType,
        title: String,
        body: String,
        isRead: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.body = body
        self.isRead = isRead
        self.createdAt = createdAt
    }
}

public enum NotificationType: Sendable, Equatable {
    case newQuestion
    case memberAnswered  // 구성원 중 누군가 답변했을 때
    case allAnswered     // 모든 구성원이 답변 완료했을 때
    case answerRequest   // 누군가 나에게 답변 요청할 때
    case treeGrowth
    case badgeEarned
}
