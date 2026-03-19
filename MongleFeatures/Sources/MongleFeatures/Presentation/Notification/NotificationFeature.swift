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
        case backTapped
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
            case close
            case navigateToQuestion
            case navigateToPeerNotAnsweredNudge(String)
        }
    }

    @Dependency(\.notificationRepository) var notificationRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.notifications.isEmpty else { return .none }
                state.isLoading = true
                return .run { [notificationRepository] send in
                    let items = (try? await notificationRepository.getNotifications(limit: 50)) ?? []
                    await send(.notificationsLoaded(items))
                }

            case .backTapped:
                return .send(.delegate(.close))

            case .refresh:
                state.isLoading = true
                return .run { [notificationRepository] send in
                    let items = (try? await notificationRepository.getNotifications(limit: 50)) ?? []
                    await send(.notificationsLoaded(items))
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

                case .newQuestion, .allAnswered, .memberAnswered, .badgeEarned:
                    return .send(.delegate(.navigateToQuestion))
                }

            case .markAsRead(let notification):
                // Optimistic update
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
                return .run { [notificationRepository] _ in
                    _ = try? await notificationRepository.markAsRead(id: notification.id)
                }

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
                return .run { [notificationRepository] _ in
                    _ = try? await notificationRepository.markAllAsRead()
                }

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
