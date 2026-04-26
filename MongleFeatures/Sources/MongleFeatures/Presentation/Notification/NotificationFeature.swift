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

/// 알림 리스트의 섹션 단위 (날짜 또는 가족 그룹).
/// `(String, [MongleNotification])` 튜플 대신 명명 구조체로 노출하여 State Equatable 자동합성과
/// View 의 ForEach Identifiable 매칭을 동시에 만족.
public struct NotificationSection: Equatable, Identifiable, Sendable {
    public let id: String           // 섹션 라벨 (오늘/이번 주/그룹명 등)을 안정 키로 사용
    public let title: String
    public let items: [MongleNotification]

    public init(title: String, items: [MongleNotification]) {
        self.id = title
        self.title = title
        self.items = items
    }
}

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

        /// notifications/mode 변경 시점에만 reducer 가 갱신하는 캐시.
        /// 매 SwiftUI body 호출마다 filter/sort/grouping 을 반복하던 비용을 제거.
        public var groupedNotifications: [NotificationSection] = []
        /// 미읽음 개수 — notifications 가 바뀔 때만 reducer 가 재계산.
        public var unreadCount: Int = 0

        public var hasUnread: Bool { unreadCount > 0 }

        /// 특정 가족 그룹에 한정된 미읽음 여부.
        /// Home 화면 닫을 때처럼 "현재 그룹 한정" 으로 다시 계산해야 할 때 사용.
        public func hasUnread(forFamily familyId: UUID?) -> Bool {
            guard let familyId else { return hasUnread }
            return notifications.contains { !$0.isRead && $0.familyId == familyId }
        }

        public init(
            notifications: [MongleNotification] = [],
            mode: Mode = .all,
            groupNameMap: [UUID: String] = [:]
        ) {
            self.notifications = notifications
            self.mode = mode
            self.groupNameMap = groupNameMap
            self.unreadCount = notifications.reduce(0) { $0 + ($1.isRead ? 0 : 1) }
            self.groupedNotifications = NotificationFeature.makeGrouped(
                notifications: notifications,
                mode: mode,
                groupNameMap: groupNameMap
            )
        }
    }

    // MARK: - Grouping (reducer 단일 진입점)

    /// notifications 가 이미 createdAt 내림차순 정렬되어 있다고 가정.
    /// (notificationsLoaded 에서 한 번 정렬한 뒤 변경 작업은 순서를 보존)
    fileprivate static func makeGrouped(
        notifications: [MongleNotification],
        mode: Mode,
        groupNameMap: [UUID: String]
    ) -> [NotificationSection] {
        switch mode {
        case .filtered(let familyId, _):
            let filtered = notifications.filter { $0.familyId == familyId }
            return dateGrouped(filtered)

        case .grouped:
            // 단일 패스: 가족별 버킷에 append (이미 정렬되어 있으므로 내부 재정렬 불필요).
            // 출력 순서는 "각 가족의 첫 알림 등장 순" → 사실상 최신 알림이 있는 가족이 위로.
            var byFamily: [(familyId: UUID, items: [MongleNotification])] = []
            var familyIndex: [UUID: Int] = [:]
            var noFamily: [MongleNotification] = []
            for n in notifications {
                if let fid = n.familyId {
                    if let idx = familyIndex[fid] {
                        byFamily[idx].items.append(n)
                    } else {
                        familyIndex[fid] = byFamily.count
                        byFamily.append((fid, [n]))
                    }
                } else {
                    noFamily.append(n)
                }
            }
            var result: [NotificationSection] = []
            result.reserveCapacity(byFamily.count + 1)
            let olderLabel = L10n.tr("notif_date_older")
            for entry in byFamily {
                let name = groupNameMap[entry.familyId] ?? olderLabel
                result.append(NotificationSection(title: name, items: entry.items))
            }
            if !noFamily.isEmpty {
                result.append(NotificationSection(title: olderLabel, items: noFamily))
            }
            return result

        case .all:
            return dateGrouped(notifications)
        }
    }

    fileprivate static func dateGrouped(_ items: [MongleNotification]) -> [NotificationSection] {
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

        var result: [NotificationSection] = []
        if !todayItems.isEmpty { result.append(NotificationSection(title: L10n.tr("notif_date_today"), items: todayItems)) }
        if !thisWeekItems.isEmpty { result.append(NotificationSection(title: L10n.tr("notif_date_this_week"), items: thisWeekItems)) }
        if !olderItems.isEmpty { result.append(NotificationSection(title: L10n.tr("notif_date_older"), items: olderItems)) }
        return result
    }

    fileprivate static func refreshDerived(_ state: inout State) {
        state.unreadCount = state.notifications.reduce(0) { $0 + ($1.isRead ? 0 : 1) }
        state.groupedNotifications = makeGrouped(
            notifications: state.notifications,
            mode: state.mode,
            groupNameMap: state.groupNameMap
        )
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
                state.errorMessage = nil
                let scopeFamilyId = state.mode.scopeFamilyId
                return .run { [notificationRepository] send in
                    // try? 로 silent fallback 하던 것을 do-catch 로 변경 — 실패 시
                    // 사용자가 "알림 없음" 으로 오해하지 않도록 errorMessage 노출.
                    do {
                        let items = try await notificationRepository.getNotifications(limit: 50, familyId: scopeFamilyId)
                        await send(.notificationsLoaded(items))
                    } catch {
                        await send(.setError(AppError.from(error).userMessage))
                    }
                }

            case .backTapped:
                return .send(.delegate(.close))

            case .refresh:
                state.isLoading = true
                state.errorMessage = nil
                let scopeFamilyId = state.mode.scopeFamilyId
                return .run { [notificationRepository] send in
                    do {
                        let items = try await notificationRepository.getNotifications(limit: 50, familyId: scopeFamilyId)
                        await send(.notificationsLoaded(items))
                    } catch {
                        await send(.setError(AppError.from(error).userMessage))
                    }
                }

            case .notificationTapped(let notification):
                // 터치한 알림을 리스트에서 즉시 제거하고, 서버 삭제 완료 후 화면 이동.
                // 서버 삭제 실패 시 errorMessage 로 안내 — 다음 refresh 에 알림이 다시
                // 나타날 수 있으니 사용자가 인지하도록.
                let deleteId = notification.id
                state.notifications = state.notifications.filter { $0.id != notification.id }
                Self.refreshDerived(&state)
                let mode = state.mode
                return .run { [notificationRepository] send in
                    do {
                        try await notificationRepository.delete(id: deleteId)
                    } catch {
                        await send(.setError(AppError.from(error).userMessage))
                    }
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
                // Optimistic update — 서버 실패 시 errorMessage 만 노출하고 UI 는 유지.
                // 다음 refresh 에 서버 상태로 자동 동기화. (rollback 으로 false 복원 시
                // "방금 읽었던 알림이 다시 안읽음 표시" 라 오히려 혼란 큼.)
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
                    Self.refreshDerived(&state)
                }
                return .run { [notificationRepository] send in
                    do {
                        _ = try await notificationRepository.markAsRead(id: notification.id)
                    } catch {
                        await send(.setError(AppError.from(error).userMessage))
                    }
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
                Self.refreshDerived(&state)
                return .run { [notificationRepository] send in
                    do {
                        _ = try await notificationRepository.markAllAsRead(familyId: scopeFamilyId)
                    } catch {
                        await send(.setError(AppError.from(error).userMessage))
                    }
                    await Self.syncAppIconBadge(notificationRepository)
                }
                .cancellable(id: CancelID.badgeSync, cancelInFlight: true)

            case .deleteNotification(let notification):
                state.notifications = state.notifications.filter { $0.id != notification.id }
                Self.refreshDerived(&state)
                return .run { [notificationRepository] send in
                    do {
                        _ = try await notificationRepository.delete(id: notification.id)
                    } catch {
                        await send(.setError(AppError.from(error).userMessage))
                    }
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
                Self.refreshDerived(&state)
                return .run { [notificationRepository] send in
                    // markAllAsRead + deleteAll 두 단계. 어느 한쪽이라도 실패하면 안내.
                    do {
                        _ = try await notificationRepository.markAllAsRead(familyId: scopeFamilyId)
                        _ = try await notificationRepository.deleteAll(familyId: scopeFamilyId)
                    } catch {
                        await send(.setError(AppError.from(error).userMessage))
                    }
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
                Self.refreshDerived(&state)
                return .none

            case .notificationUpdated(let notification):
                if let index = state.notifications.firstIndex(where: { $0.id == notification.id }) {
                    state.notifications[index] = notification
                    Self.refreshDerived(&state)
                }
                return .none

            case .notificationDeleted(let id):
                state.notifications = state.notifications.filter { $0.id != id }
                Self.refreshDerived(&state)
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
