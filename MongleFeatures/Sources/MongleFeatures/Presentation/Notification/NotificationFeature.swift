//
//  NotificationFeature.swift
//  Mongle
//
//  Created by Claude on 1/9/26.
//

import Foundation
import ComposableArchitecture
import Domain
import UserNotifications

// Domain의 Notification과 이름 충돌 방지
public typealias MongleNotification = Domain.Notification

@Reducer
public struct NotificationFeature {

    private enum CancelID: Hashable {
        /// markRead/delete 등이 빠르게 연쇄될 때 syncAppIconBadge 가 N개 동시 in-flight 가
        /// 되며 마지막 응답이 stale 한 카운트로 OS 배지를 덮어쓰는 race 방지.
        case badgeSync
    }

    // MARK: - Mode

    public enum Mode: Equatable, Sendable {
        /// HomeView에서 진입: 특정 그룹 알림만 필터해서 날짜별 표시
        case filtered(familyId: UUID, familyName: String)
        /// GroupSelect에서 진입: 모든 그룹 알림을 그룹명 섹션으로 표시
        case grouped
        /// 기본(하위 호환)
        case all

        /// 서버 API에 전달할 그룹 스코프. `.filtered`만 특정 그룹으로 제한.
        var scopeFamilyId: UUID? {
            switch self {
            case .filtered(let familyId, _): return familyId
            case .grouped, .all: return nil
            }
        }
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

        /// 특정 가족 그룹에 한정된 미읽음 여부.
        /// Home 화면 닫을 때처럼 "현재 그룹 한정" 으로 다시 계산해야 할 때 사용.
        public func hasUnread(forFamily familyId: UUID?) -> Bool {
            guard let familyId else { return hasUnread }
            return notifications.contains { !$0.isRead && $0.familyId == familyId }
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
                    let name = groupNameMap[familyId] ?? L10n.tr("notif_date_older")
                    result.append((name, items.sorted { $0.createdAt > $1.createdAt }))
                }
                if !noFamily.isEmpty {
                    result.append((L10n.tr("notif_date_older"), noFamily.sorted { $0.createdAt > $1.createdAt }))
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
            if !todayItems.isEmpty { result.append((L10n.tr("notif_date_today"), todayItems)) }
            if !thisWeekItems.isEmpty { result.append((L10n.tr("notif_date_this_week"), thisWeekItems)) }
            if !olderItems.isEmpty { result.append((L10n.tr("notif_date_older"), olderItems)) }
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
        case deleteAll
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
            case navigateToQuestion(markAsReadId: UUID?)
            case navigateToGroup(UUID, markAsReadId: UUID?)
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
                let scopeFamilyId = state.mode.scopeFamilyId
                return .run { [notificationRepository] send in
                    let items = (try? await notificationRepository.getNotifications(limit: 50, familyId: scopeFamilyId)) ?? []
                    await send(.notificationsLoaded(items))
                }

            case .backTapped:
                return .send(.delegate(.close))

            case .refresh:
                state.isLoading = true
                let scopeFamilyId = state.mode.scopeFamilyId
                return .run { [notificationRepository] send in
                    let items = (try? await notificationRepository.getNotifications(limit: 50, familyId: scopeFamilyId)) ?? []
                    await send(.notificationsLoaded(items))
                }

            case .notificationTapped(let notification):
                // 터치한 알림을 리스트에서 즉시 제거하고, 서버 삭제 완료 후 화면 이동
                let deleteId = notification.id
                // 새 배열 할당으로 @ObservableState 뷰 갱신 보장
                state.notifications = state.notifications.filter { $0.id != notification.id }
                let mode = state.mode
                return .run { [notificationRepository] send in
                    try? await notificationRepository.delete(id: deleteId)
                    await Self.syncAppIconBadge(notificationRepository)
                    switch mode {
                    case .grouped:
                        if let familyId = notification.familyId {
                            await send(.delegate(.navigateToGroup(familyId, markAsReadId: nil)))
                        }
                    default:
                        await send(.delegate(.navigateToQuestion(markAsReadId: nil)))
                    }
                }
                .cancellable(id: CancelID.badgeSync, cancelInFlight: true)

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
                    await Self.syncAppIconBadge(notificationRepository)
                }
                .cancellable(id: CancelID.badgeSync, cancelInFlight: true)

            case .markAllAsRead:
                let scopeFamilyId = state.mode.scopeFamilyId
                state.notifications = state.notifications.map { n in
                    // .filtered 모드에서는 해당 그룹 알림만 읽음 처리, 그 외는 전체
                    let shouldMark = scopeFamilyId == nil || n.familyId == scopeFamilyId
                    guard shouldMark else { return n }
                    return MongleNotification(
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
                    _ = try? await notificationRepository.markAllAsRead(familyId: scopeFamilyId)
                    await Self.syncAppIconBadge(notificationRepository)
                }
                .cancellable(id: CancelID.badgeSync, cancelInFlight: true)

            case .deleteNotification(let notification):
                state.notifications = state.notifications.filter { $0.id != notification.id }
                return .run { [notificationRepository] _ in
                    _ = try? await notificationRepository.delete(id: notification.id)
                    await Self.syncAppIconBadge(notificationRepository)
                }
                .cancellable(id: CancelID.badgeSync, cancelInFlight: true)

            case .deleteAll:
                let scopeFamilyId = state.mode.scopeFamilyId
                if let scopeFamilyId {
                    state.notifications = state.notifications.filter { $0.familyId != scopeFamilyId }
                } else {
                    state.notifications = []
                }
                return .run { [notificationRepository] _ in
                    _ = try? await notificationRepository.markAllAsRead(familyId: scopeFamilyId)
                    _ = try? await notificationRepository.deleteAll(familyId: scopeFamilyId)
                    await Self.syncAppIconBadge(notificationRepository)
                }
                .cancellable(id: CancelID.badgeSync, cancelInFlight: true)

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
                state.notifications = state.notifications.filter { $0.id != id }
                return .none

            case .delegate:
                return .none
            }
        }
    }

    /// 인앱 알림 mutation(읽음/삭제) 직후 OS 앱 아이콘 배지를 전체 그룹 합산
    /// 미읽음 수로 동기화한다. NotificationFeature.state.notifications 는
    /// .filtered 모드에서는 단일 그룹 데이터만 들고 있어 자체 계산이 부정확하므로,
    /// 서버의 unread-count 라우트(MG-54)를 사용해 정확한 수치 조회 (50건 캡 제거).
    /// 서버 호출 실패 시 기존 getNotifications limit 50 fallback 으로 점진 동작.
    private static func syncAppIconBadge(_ repository: NotificationRepositoryProtocol) async {
        if let unread = try? await repository.getUnreadCount() {
            try? await UNUserNotificationCenter.current().setBadgeCount(unread)
            return
        }
        let all = (try? await repository.getNotifications(limit: 50, familyId: nil)) ?? []
        let unread = all.filter { !$0.isRead }.count
        try? await UNUserNotificationCenter.current().setBadgeCount(unread)
    }
}
