//
//  Notification.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import Foundation

public struct Notification: Equatable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let familyId: UUID?
    public let type: NotificationType
    public let title: String
    public let body: String
    public let isRead: Bool
    public let createdAt: Date
    /// 알림을 트리거한 사용자의 moodId (= 몽글 캐릭터 색상).
    /// 서버에서 알림 생성 시점에 저장되며, 앱은 이 값으로 몽글 캐릭터 색상을 렌더링한다.
    /// - "calm" | "happy" | "loved" | "sad" | "tired"
    public let colorId: String?

    public init(
        id: UUID,
        userId: UUID,
        familyId: UUID? = nil,
        type: NotificationType,
        title: String,
        body: String,
        isRead: Bool,
        createdAt: Date,
        colorId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.familyId = familyId
        self.type = type
        self.title = title
        self.body = body
        self.isRead = isRead
        self.createdAt = createdAt
        self.colorId = colorId
    }
}

public enum NotificationType: Sendable, Equatable {
    case newQuestion
    case memberAnswered  // 구성원 중 누군가 답변했을 때
    case allAnswered     // 모든 구성원이 답변 완료했을 때
    case answerRequest   // 누군가 나에게 답변 요청할 때
    case badgeEarned
    case reminder        // 저녁 7시 미답변자 리마인더 (MG-19)
}
