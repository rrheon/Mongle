//
//  NotificationFeature.swift
//  FamTree
//
//  Created by Claude on 1/9/26.
//

import Foundation
import ComposableArchitecture
import Domain

// Domain의 Notification과 이름 충돌 방지
public typealias FTNotification = Domain.Notification

@Reducer
public struct NotificationFeature {
    @ObservableState
    public struct State: Equatable {
        public var notifications: [FTNotification] = []
        public var isLoading = false
        public var errorMessage: String?

        public var unreadCount: Int {
            notifications.filter { !$0.isRead }.count
        }

        public var hasUnread: Bool {
            unreadCount > 0
        }

        // 그룹화된 알림 (오늘, 이번 주, 이전)
        public var groupedNotifications: [(String, [FTNotification])] {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

            var todayItems: [FTNotification] = []
            var thisWeekItems: [FTNotification] = []
            var olderItems: [FTNotification] = []

            for notification in notifications {
                let notificationDay = calendar.startOfDay(for: notification.createdAt)
                if notificationDay == today {
                    todayItems.append(notification)
                } else if notificationDay > weekAgo {
                    thisWeekItems.append(notification)
                } else {
                    olderItems.append(notification)
                }
            }

            var result: [(String, [FTNotification])] = []
            if !todayItems.isEmpty { result.append(("오늘", todayItems)) }
            if !thisWeekItems.isEmpty { result.append(("이번 주", thisWeekItems)) }
            if !olderItems.isEmpty { result.append(("이전", olderItems)) }

            return result
        }

        public init(notifications: [FTNotification] = []) {
            self.notifications = notifications
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case onAppear
        case refresh
        case notificationTapped(FTNotification)
        case markAsRead(FTNotification)
        case markAllAsRead
        case deleteNotification(FTNotification)
        case dismissError

        // MARK: - Internal Actions
        case setLoading(Bool)
        case setError(String?)
        case notificationsLoaded([FTNotification])
        case notificationUpdated(FTNotification)
        case notificationDeleted(UUID)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case navigateToQuestion
            case navigateToTree
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.notifications.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    try await Task.sleep(nanoseconds: 500_000_000)
                    let mockData = generateMockNotifications()
                    await send(.notificationsLoaded(mockData))
                }

            case .refresh:
                state.isLoading = true
                return .run { send in
                    try await Task.sleep(nanoseconds: 500_000_000)
                    let mockData = generateMockNotifications()
                    await send(.notificationsLoaded(mockData))
                }

            case .notificationTapped(let notification):
                // 읽음 처리
                if !notification.isRead {
                    return .send(.markAsRead(notification))
                }

                // 타입에 따라 네비게이션
                switch notification.type {
                case .newQuestion, .answerRequest, .allAnswered, .memberAnswered:
                    return .send(.delegate(.navigateToQuestion))
                case .treeGrowth, .badgeEarned:
                    return .send(.delegate(.navigateToTree))
                }

            case .markAsRead(let notification):
                if let index = state.notifications.firstIndex(where: { $0.id == notification.id }) {
                    let updated = FTNotification(
                        id: notification.id,
                        userId: notification.userId,
                        type: notification.type,
                        title: notification.title,
                        body: notification.body,
                        isRead: true,
                        createdAt: notification.createdAt
                    )
                    state.notifications[index] = updated
                }
                return .none

            case .markAllAsRead:
                state.notifications = state.notifications.map { notification in
                    FTNotification(
                        id: notification.id,
                        userId: notification.userId,
                        type: notification.type,
                        title: notification.title,
                        body: notification.body,
                        isRead: true,
                        createdAt: notification.createdAt
                    )
                }
                return .none

            case .deleteNotification(let notification):
                state.notifications.removeAll { $0.id == notification.id }
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .setLoading(let isLoading):
                state.isLoading = isLoading
                return .none

            case .setError(let message):
                state.errorMessage = message
                state.isLoading = false
                return .none

            case .notificationsLoaded(let notifications):
                state.notifications = notifications.sorted { $0.createdAt > $1.createdAt }
                state.isLoading = false
                return .none

            case .notificationUpdated(let notification):
                if let index = state.notifications.firstIndex(where: { $0.id == notification.id }) {
                    state.notifications[index] = notification
                }
                return .none

            case .notificationDeleted(let id):
                state.notifications.removeAll { $0.id == id }
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Mock Data Generator
private func generateMockNotifications() -> [FTNotification] {
    let calendar = Calendar.current
    let userId = UUID()

    return [
        FTNotification(
            id: UUID(),
            userId: userId,
            type: .newQuestion,
            title: "오늘의 질문이 도착했어요!",
            body: "오늘 가장 감사했던 순간은 언제인가요?",
            isRead: false,
            createdAt: Date()
        ),
        FTNotification(
            id: UUID(),
            userId: userId,
            type: .memberAnswered,
            title: "엄마가 답변했어요",
            body: "엄마가 오늘의 질문에 답변을 남겼어요. 확인해보세요!",
            isRead: false,
            createdAt: calendar.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        ),
        FTNotification(
            id: UUID(),
            userId: userId,
            type: .allAnswered,
            title: "가족 모두 답변 완료!",
            body: "어제 질문에 가족 모두가 답변했어요. 확인해보세요!",
            isRead: false,
            createdAt: calendar.date(byAdding: .hour, value: -3, to: Date()) ?? Date()
        ),
        FTNotification(
            id: UUID(),
            userId: userId,
            type: .answerRequest,
            title: "엄마가 답변을 기다리고 있어요",
            body: "아직 오늘의 질문에 답변하지 않았어요",
            isRead: true,
            createdAt: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ),
        FTNotification(
            id: UUID(),
            userId: userId,
            type: .treeGrowth,
            title: "나무가 자랐어요!",
            body: "가족 나무가 3단계로 성장했습니다",
            isRead: true,
            createdAt: calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        ),
        FTNotification(
            id: UUID(),
            userId: userId,
            type: .badgeEarned,
            title: "새 배지 획득!",
            body: "'7일 연속 답변' 배지를 획득했어요",
            isRead: true,
            createdAt: calendar.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        ),
        FTNotification(
            id: UUID(),
            userId: userId,
            type: .newQuestion,
            title: "오늘의 질문이 도착했어요!",
            body: "가족과 함께 한 가장 행복한 기억은 무엇인가요?",
            isRead: true,
            createdAt: calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date()
        ),
    ]
}
