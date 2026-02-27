//
//  NotificationView.swift
//  FamTree
//
//  Created by Claude on 1/9/26.
//

import SwiftUI
import ComposableArchitecture
import Domain

public struct NotificationView: View {
    @Bindable var store: StoreOf<NotificationFeature>

    public init(store: StoreOf<NotificationFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerView

            if store.isLoading && store.notifications.isEmpty {
                loadingView
            } else if store.notifications.isEmpty {
                emptyView
            } else {
                notificationList
            }
        }
        .background(FTColor.background)
        .onAppear {
            store.send(.onAppear)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("알림")
                .font(FTFont.heading2())
                .foregroundColor(FTColor.textPrimary)

            if store.hasUnread {
                Text("\(store.unreadCount)")
                    .font(FTFont.captionBold())
                    .foregroundColor(.white)
                    .padding(.horizontal, FTSpacing.xs)
                    .padding(.vertical, 2)
                    .background(FTColor.error)
                    .clipShape(Capsule())
            }

            Spacer()

            if store.hasUnread {
                Button {
                    store.send(.markAllAsRead)
                } label: {
                    Text("모두 읽음")
                        .font(FTFont.buttonSmall())
                        .foregroundColor(FTColor.primary)
                }
            }
        }
        .padding(.horizontal, FTSpacing.md)
        .padding(.vertical, FTSpacing.md)
        .background(FTColor.background)
    }

    // MARK: - Notification List
    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(store.groupedNotifications, id: \.0) { section, notifications in
                    Section {
                        ForEach(notifications, id: \.id) { notification in
                            NotificationRow(notification: notification) {
                                store.send(.notificationTapped(notification))
                            } onDelete: {
                                store.send(.deleteNotification(notification))
                            }
                        }
                    } header: {
                        sectionHeader(section)
                    }
                }
            }
            .padding(.bottom, FTSpacing.xl)
        }
        .refreshable {
            store.send(.refresh)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(FTFont.captionBold())
                .foregroundColor(FTColor.textSecondary)

            Spacer()
        }
        .padding(.horizontal, FTSpacing.md)
        .padding(.vertical, FTSpacing.xs)
        .background(FTColor.background)
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: FTSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("알림을 불러오는 중...")
                .font(FTFont.body2())
                .foregroundColor(FTColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: FTSpacing.md) {
            Image(systemName: "bell.slash")
                .font(.system(size: 56))
                .foregroundColor(FTColor.textHint)

            Text("알림이 없어요")
                .font(FTFont.heading3())
                .foregroundColor(FTColor.textPrimary)

            Text("새로운 소식이 오면 알려드릴게요")
                .font(FTFont.body2())
                .foregroundColor(FTColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: FTNotification
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: FTSpacing.sm) {
                // 아이콘
                notificationIcon
                    .frame(width: 40, height: 40)
                    .background(iconBackgroundColor.opacity(0.15))
                    .clipShape(Circle())

                // 내용
                VStack(alignment: .leading, spacing: FTSpacing.xxs) {
                    HStack {
                        Text(notification.title)
                            .font(notification.isRead ? FTFont.body2() : FTFont.body1Bold())
                            .foregroundColor(FTColor.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(timeAgo)
                            .font(FTFont.caption())
                            .foregroundColor(FTColor.textHint)
                    }

                    Text(notification.body)
                        .font(FTFont.caption())
                        .foregroundColor(FTColor.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // 읽지 않음 표시
                if !notification.isRead {
                    Circle()
                        .fill(FTColor.primary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, FTSpacing.md)
            .padding(.vertical, FTSpacing.sm)
            .background(notification.isRead ? FTColor.background : FTColor.primaryLight.opacity(0.3))
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var notificationIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 18))
            .foregroundColor(iconBackgroundColor)
    }

    private var iconName: String {
        switch notification.type {
        case .newQuestion:
            return "questionmark.bubble.fill"
        case .memberAnswered:
            return "person.fill.checkmark"
        case .allAnswered:
            return "checkmark.circle.fill"
        case .answerRequest:
            return "person.fill.questionmark"
        case .treeGrowth:
            return "leaf.fill"
        case .badgeEarned:
            return "star.fill"
        }
    }

    private var iconBackgroundColor: Color {
        switch notification.type {
        case .newQuestion:
            return FTColor.info
        case .memberAnswered:
            return FTColor.primary
        case .allAnswered:
            return FTColor.success
        case .answerRequest:
            return FTColor.warning
        case .treeGrowth:
            return FTColor.primary
        case .badgeEarned:
            return Color.orange
        }
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.createdAt, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview {
    NotificationView(
        store: Store(initialState: NotificationFeature.State()) {
            NotificationFeature()
        }
    )
}
