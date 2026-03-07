//
//  NotificationView.swift
//  Mongle
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
        .background(MongleColor.background)
        .onAppear {
            store.send(.onAppear)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("알림")
                .font(MongleFont.heading2())
                .foregroundColor(MongleColor.textPrimary)

            if store.hasUnread {
                Text("\(store.unreadCount)")
                    .font(MongleFont.captionBold())
                    .foregroundColor(.white)
                    .padding(.horizontal, MongleSpacing.xs)
                    .padding(.vertical, 2)
                    .background(MongleColor.error)
                    .clipShape(Capsule())
            }

            Spacer()

            if store.hasUnread {
                Button {
                    store.send(.markAllAsRead)
                } label: {
                    Text("모두 읽음")
                        .font(MongleFont.buttonSmall())
                        .foregroundColor(MongleColor.primary)
                }
            }
        }
        .padding(.horizontal, MongleSpacing.md)
        .padding(.vertical, MongleSpacing.md)
        .background(MongleColor.background)
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
            .padding(.bottom, MongleSpacing.xl)
        }
        .refreshable {
            store.send(.refresh)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)

            Spacer()
        }
        .padding(.horizontal, MongleSpacing.md)
        .padding(.vertical, MongleSpacing.xs)
        .background(MongleColor.background)
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: MongleSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("알림을 불러오는 중...")
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: MongleSpacing.md) {
            Image(systemName: "bell.slash")
                .font(.system(size: 56))
                .foregroundColor(MongleColor.textHint)

            Text("알림이 없어요")
                .font(MongleFont.heading3())
                .foregroundColor(MongleColor.textPrimary)

            Text("새로운 소식이 오면 알려드릴게요")
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: MongleNotification
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: MongleSpacing.sm) {
                // 아이콘
                notificationIcon
                    .frame(width: 40, height: 40)
                    .background(iconBackgroundColor.opacity(0.15))
                    .clipShape(Circle())

                // 내용
                VStack(alignment: .leading, spacing: MongleSpacing.xxs) {
                    HStack {
                        Text(notification.title)
                            .font(notification.isRead ? MongleFont.body2() : MongleFont.body1Bold())
                            .foregroundColor(MongleColor.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(timeAgo)
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textHint)
                    }

                    Text(notification.body)
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // 읽지 않음 표시
                if !notification.isRead {
                    Circle()
                        .fill(MongleColor.primary)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, MongleSpacing.md)
            .padding(.vertical, MongleSpacing.sm)
            .background(notification.isRead ? MongleColor.background : MongleColor.primaryLight.opacity(0.3))
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
            return MongleColor.info
        case .memberAnswered:
            return MongleColor.primary
        case .allAnswered:
            return MongleColor.success
        case .answerRequest:
            return MongleColor.warning
        case .treeGrowth:
            return MongleColor.primary
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
