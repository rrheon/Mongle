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
        VStack(spacing: 0) {
            MongleNavigationHeader(title: L10n.tr("notif_title")) {
                MongleBackButton { store.send(.backTapped) }
            } right: {
                EmptyView()
            }

            if !store.notifications.isEmpty {
                HStack(spacing: MongleSpacing.md) {
                    Spacer()

                    Button { store.send(.markAllAsRead) } label: {
                        Text(L10n.tr("notif_mark_all_read"))
                            .font(MongleFont.captionBold())
                            .foregroundColor(MongleColor.textSecondary)
                    }
                    .buttonStyle(MongleScaleButtonStyle())

                    Button { store.send(.deleteAll) } label: {
                        Text(L10n.tr("notif_delete_all"))
                            .font(MongleFont.captionBold())
                            .foregroundColor(MongleColor.error)
                    }
                    .buttonStyle(MongleScaleButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
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

            Text(L10n.tr("notif_loading"))
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

            Text(L10n.tr("notif_empty_title"))
                .font(MongleFont.heading3())
                .foregroundColor(MongleColor.textPrimary)

            Text(L10n.tr("notif_empty_desc"))
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
                Label(L10n.tr("common_delete"), systemImage: "trash")
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

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private var timeAgo: String {
        Self.relativeFormatter.localizedString(for: notification.createdAt, relativeTo: Date())
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
