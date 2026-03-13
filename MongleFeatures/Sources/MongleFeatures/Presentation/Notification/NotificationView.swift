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

    private var headerView: some View {
        ZStack {
            Text("알림")
                .font(MongleFont.heading3().weight(.bold))
                .foregroundColor(MongleColor.textPrimary)

            HStack {
                Button {
                    store.send(.backTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(MongleColor.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                Spacer()

                if store.hasUnread {
                    Button {
                        store.send(.markAllAsRead)
                    } label: {
                        Text("모두 읽음")
                            .font(MongleFont.captionBold())
                            .foregroundColor(MongleColor.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 8)
        .background(Color.white)
    }

    private var notificationList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(store.groupedNotifications, id: \.0) { section, notifications in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(section)
                            .font(MongleFont.captionBold())
                            .foregroundColor(MongleColor.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 6)

                        ForEach(Array(notifications.enumerated()), id: \.element.id) { index, notification in
                            NotificationCard(notification: notification) {
                                store.send(.notificationTapped(notification))
                            } onDelete: {
                                store.send(.deleteNotification(notification))
                            }

                            if index != notifications.count - 1 {
                                Divider()
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .refreshable {
            store.send(.refresh)
        }
    }

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

private struct NotificationCard: View {
    let notification: MongleNotification
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                iconView

                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.title)
                        .font(notification.isRead ? MongleFont.body2() : MongleFont.body2Bold())
                        .foregroundColor(MongleColor.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(timeAgo)
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textPrimary)
                }

                if !notification.isRead {
                    Circle()
                        .fill(MongleColor.primarySoft)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 72, alignment: .leading)
            .background(Color.white)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    private var iconView: some View {
        Group {
            if notification.type == .memberAnswered {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [MongleColor.accentYellowLight, MongleColor.moodHappy],
                                center: .init(x: 0.35, y: 0.35),
                                startRadius: 4,
                                endRadius: 22
                            )
                        )
                    HStack(spacing: 4) {
                        eye
                        eye
                    }
                    .offset(y: 2)
                }
            } else {
                Circle()
                    .fill(iconBackground)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(iconTint)
                    )
            }
        }
        .frame(width: 44, height: 44)
    }

    private var iconName: String {
        switch notification.type {
        case .newQuestion:
            return "questionmark.bubble.fill"
        case .memberAnswered:
            return "bubble.left.and.text.bubble.right.fill"
        case .allAnswered:
            return "checkmark.circle.fill"
        case .answerRequest:
            return "bell.badge.fill"
        case .badgeEarned:
            return "gift.fill"
        }
    }

    private var iconTint: Color {
        switch notification.type {
        case .newQuestion:
            return MongleColor.info
        case .memberAnswered:
            return MongleColor.primary
        case .allAnswered:
            return MongleColor.success
        case .answerRequest:
            return MongleColor.accentOrange
        case .badgeEarned:
            return MongleColor.moodLoved
        }
    }

    private var iconBackground: Color {
        switch notification.type {
        case .newQuestion:
            return MongleColor.bgInfoLight
        case .memberAnswered:
            return MongleColor.primaryLight
        case .allAnswered:
            return MongleColor.bgSuccessLight
        case .answerRequest:
            return MongleColor.bgWarmLight
        case .badgeEarned:
            return MongleColor.bgErrorLight
        }
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.createdAt, relativeTo: Date())
    }

    private var eye: some View {
        Circle()
            .fill(MongleColor.brown)
            .frame(width: 6, height: 7)
            .overlay(Circle().stroke(Color.white, lineWidth: 1))
    }
}

#Preview {
    NotificationView(
        store: Store(initialState: NotificationFeature.State()) {
            NotificationFeature()
        }
    )
}
