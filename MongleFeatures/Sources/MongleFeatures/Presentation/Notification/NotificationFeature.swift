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

    // MARK: - Mode

    public enum Mode: Equatable, Sendable {
        /// HomeView에서 진입: 특정 그룹 알림만 필터해서 날짜별 표시
        case filtered(familyId: UUID, familyName: String)
        /// GroupSelect에서 진입: 모든 그룹 알림을 그룹명 섹션으로 표시
        case grouped
        /// 기본(하위 호환)
        case all
    }

    @ObservableState
    public struct State: Equatable {
        public var mode: Mode = .all
        /// .grouped 모드에서 familyId → 그룹명 매핑
        public var groupNameMap: [UUID: String] = [:]
        public var notifications: [MongleNotification] = []
        public var isLoading = false
        public var errorMessage: String?

        public var unreadCount: Int {
            notifications.filter { !$0.isRead }.count
        }

        public var hasUnread: Bool {
            unreadCount > 0
        }

        /// 모드에 따라 다른 방식으로 그룹화된 알림 반환
        public var groupedNotifications: [(String, [MongleNotification])] {
            switch mode {
            case .filtered(let familyId, _):
                let filtered = notifications.filter { $0.familyId == familyId }
                return dateGrouped(filtered)

            case .grouped:
                var byFamily: [UUID: [MongleNotification]] = [:]
                var noFamily: [MongleNotification] = []
                for n in notifications {
                    if let fid = n.familyId {
                        byFamily[fid, default: []].append(n)
                    } else {
                        noFamily.append(n)
                    }
                }
                var result: [(String, [MongleNotification])] = []
                // 최신 알림 기준으로 그룹 정렬
                let sortedFamilies = byFamily.sorted {
                    ($0.value.first?.createdAt ?? .distantPast) > ($1.value.first?.createdAt ?? .distantPast)
                }
                for (familyId, items) in sortedFamilies {
                    let name = groupNameMap[familyId] ?? "기타 그룹"
                    result.append((name, items.sorted { $0.createdAt > $1.createdAt }))
                }
                if !noFamily.isEmpty {
                    result.append(("기타", noFamily.sorted { $0.createdAt > $1.createdAt }))
                }
                return result

            case .all:
                return dateGrouped(notifications)
            }
        }

        private func dateGrouped(_ items: [MongleNotification]) -> [(String, [MongleNotification])] {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

            var todayItems: [MongleNotification] = []
            var thisWeekItems: [MongleNotification] = []
            var olderItems: [MongleNotification] = []

            for n in items {
                let day = calendar.startOfDay(for: n.createdAt)
                if day == today {
                    todayItems.append(n)
                } else if day > weekAgo {
                    thisWeekItems.append(n)
                } else {
                    olderItems.append(n)
                }
            }

            var result: [(String, [MongleNotification])] = []
            if !todayItems.isEmpty { result.append(("오늘", todayItems)) }
            if !thisWeekItems.isEmpty { result.append(("이번 주", thisWeekItems)) }
            if !olderItems.isEmpty { result.append(("이전", olderItems)) }
            return result
        }

        public init(
            notifications: [MongleNotification] = [],
            mode: Mode = .all,
            groupNameMap: [UUID: String] = [:]
        ) {
            self.notifications = notifications
            self.mode = mode
            self.groupNameMap = groupNameMap
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
            case navigateToGroup(UUID)
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
                // 읽음 처리 + 네비게이션 동시 처리
                let navigateEffect: Effect<Action> = {
                    switch state.mode {
                    case .grouped:
                        guard let familyId = notification.familyId else { return .none }
                        return .send(.delegate(.navigateToGroup(familyId)))
                    default:
                        return .send(.delegate(.navigateToQuestion))
                    }
                }()

                if notification.isRead {
                    return navigateEffect
                } else {
                    return .merge(.send(.markAsRead(notification)), navigateEffect)
                }

            case .markAsRead(let notification):
                // Optimistic update
                if let index = state.notifications.firstIndex(where: { $0.id == notification.id }) {
                    state.notifications[index] = MongleNotification(
                        id: notification.id,
                        userId: notification.userId,
                        familyId: notification.familyId,
                        type: notification.type,
                        title: notification.title,
                        body: notification.body,
                        isRead: true,
                        createdAt: notification.createdAt
                    )
                }
                return .run { [notificationRepository] _ in
                    _ = try? await notificationRepository.markAsRead(id: notification.id)
                }

            case .markAllAsRead:
                state.notifications = state.notifications.map { n in
                    MongleNotification(
                        id: n.id,
                        userId: n.userId,
                        familyId: n.familyId,
                        type: n.type,
                        title: n.title,
                        body: n.body,
                        isRead: true,
                        createdAt: n.createdAt
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
