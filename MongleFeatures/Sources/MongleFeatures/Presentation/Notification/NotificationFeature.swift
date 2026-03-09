//
//  NotificationFeature.swift
//  Mongle
//
//  Created by Claude on 1/9/26.
//

import Foundation
import ComposableArchitecture
import Domain

// Domain의 Notification과 이름 충돌 방지
public typealias MongleNotification = Domain.Notification

@Reducer
public struct NotificationFeature {
    @ObservableState
    public struct State: Equatable {
        public var notifications: [MongleNotification] = []
        public var isLoading = false
        public var errorMessage: String?

        public var unreadCount: Int {
            notifications.filter { !$0.isRead }.count
        }

        public var hasUnread: Bool {
            unreadCount > 0
        }

        // 그룹화된 알림 (오늘, 이번 주, 이전)
        public var groupedNotifications: [(String, [MongleNotification])] {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

            var todayItems: [MongleNotification] = []
            var thisWeekItems: [MongleNotification] = []
            var olderItems: [MongleNotification] = []

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

            var result: [(String, [MongleNotification])] = []
            if !todayItems.isEmpty { result.append(("오늘", todayItems)) }
            if !thisWeekItems.isEmpty { result.append(("이번 주", thisWeekItems)) }
            if !olderItems.isEmpty { result.append(("이전", olderItems)) }

            return result
        }

        public init(notifications: [MongleNotification] = []) {
            self.notifications = notifications
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case onAppear
        case refresh
        case notificationTapped(MongleNotification)
        case markAsRead(MongleNotification)
        case markAllAsRead
        case deleteNotification(MongleNotification)
        case dismissError

        // MARK: - Internal Actions
        case setLoading(Bool)
        case setError(String?)
        case notificationsLoaded([MongleNotification])
        case notificationUpdated(MongleNotification)
        case notificationDeleted(UUID)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case navigateToQuestion
            case navigateToTree
            case navigateToPeerNotAnsweredNudge(String)
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
                case .answerRequest:
                    let member = extractMemberName(from: notification.title) ?? "가족"
                    return .send(.delegate(.navigateToPeerNotAnsweredNudge(member)))

                case .newQuestion, .allAnswered, .memberAnswered:
                    return .send(.delegate(.navigateToQuestion))
                case .treeGrowth, .badgeEarned:
                    return .send(.delegate(.navigateToTree))
                }

            case .markAsRead(let notification):
                if let index = state.notifications.firstIndex(where: { $0.id == notification.id }) {
                    let updated = MongleNotification(
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
                    MongleNotification(
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
private func generateMockNotifications() -> [MongleNotification] {
    let calendar = Calendar.current
    let userId = UUID()

    return [
        MongleNotification(
            id: UUID(),
            userId: userId,
            type: .memberAnswered,
            title: "Lily가 오늘의 질문에 답변했어요",
            body: "Lily의 생각을 확인하고 하트를 보내보세요.",
            isRead: false,
            createdAt: Date()
        ),
        MongleNotification(
            id: UUID(),
            userId: userId,
            type: .answerRequest,
            title: "Dad가 Mom에게 재촉 알림을 보냈어요",
            body: "Mom이 아직 답변하지 않았어요. 하트 1개가 사용됐어요.",
            isRead: false,
            createdAt: calendar.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
        ),
        MongleNotification(
            id: UUID(),
            userId: userId,
            type: .badgeEarned,
            title: "Mom이 하트 5개를 선물했어요 🎁",
            body: "하트 시스템에서 새 행동을 열어볼 수 있어요.",
            isRead: false,
            createdAt: calendar.date(byAdding: .hour, value: -3, to: Date()) ?? Date()
        ),
        MongleNotification(
            id: UUID(),
            userId: userId,
            type: .allAnswered,
            title: "오늘 모든 가족이 답변을 완료했어요! 🎉",
            body: "가족의 답변을 둘러보고 오늘의 감정을 다시 기록해보세요.",
            isRead: true,
            createdAt: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ),
        MongleNotification(
            id: UUID(),
            userId: userId,
            type: .memberAnswered,
            title: "Mom이 오늘의 질문에 답변했어요",
            body: "Mom의 답변을 보고 공감 버튼을 눌러보세요.",
            isRead: true,
            createdAt: calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        ),
        MongleNotification(
            id: UUID(),
            userId: userId,
            type: .treeGrowth,
            title: "우리만의 감정 공간이 자라고 있어요",
            body: "가족 나무가 한 단계 성장했어요.",
            isRead: true,
            createdAt: calendar.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        ),
        MongleNotification(
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

private func extractMemberName(from title: String) -> String? {
    let separators = ["가", "이", "님"]
    for separator in separators {
        if let range = title.range(of: separator) {
            let name = String(title[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                return name
            }
        }
    }
    return nil
}
