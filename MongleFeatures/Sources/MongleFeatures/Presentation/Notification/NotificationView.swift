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
            } else if isEffectivelyEmpty {
                emptyView
            } else {
                notificationList
            }
        }
        .background(MongleColor.background)
        .onAppear {
            store.send(.onAppear)
        }
        // 데이터 로드 실패 alert — 사용자가 "알림 없음" 으로 오해하지 않도록 노출.
        .alert(
            L10n.tr("error_unknown"),
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.send(.dismissError) } }
            ),
            actions: {
                Button(L10n.tr("common_confirm")) { store.send(.dismissError) }
            },
            message: { Text(store.errorMessage ?? "") }
        )
    }

    /// .filtered 모드에서 현재 그룹 기준으로 결과가 비어 있는 경우에도 emptyView 를 노출하기 위해
    /// 모드 필터링이 적용된 groupedNotifications 기준으로 비어 있는지 판정한다.
    private var isEffectivelyEmpty: Bool {
        store.groupedNotifications.allSatisfy { $0.items.isEmpty } || store.groupedNotifications.isEmpty
    }

    private var headerView: some View {
        VStack(spacing: 0) {
            MongleNavigationHeader(title: L10n.tr("notif_title")) {
                MongleBackButton { store.send(.backTapped) }
            } right: {
                EmptyView()
            }

            if !isEffectivelyEmpty {
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
                ForEach(store.groupedNotifications) { section in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(section.title)
                            .font(MongleFont.captionBold())
                            .foregroundColor(MongleColor.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 6)

                        ForEach(Array(section.items.enumerated()), id: \.element.id) { index, notification in
                            NotificationCard(notification: notification) {
                                store.send(.notificationTapped(notification))
                            } onDelete: {
                                store.send(.deleteNotification(notification))
                            }

                            if index != section.items.count - 1 {
                                Divider()
                                    .padding(.leading, 76)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .id(store.notifications.count)
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
            // 가족 구성원이 트리거한 알림(답변 등록 / 재촉 요청) 은 발신자의 몽글 캐릭터
            // 현재 색상(서버가 저장한 colorId) 으로 렌더링해 "누가" 보낸 알림인지
            // 시각적으로 즉시 알 수 있게 한다.
            if isSenderNotification, let colorId = notification.colorId {
                MongleMonggle(color: Self.monggleColor(for: colorId), size: 44)
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

    private var isSenderNotification: Bool {
        switch notification.type {
        case .memberAnswered, .answerRequest: return true
        default: return false
        }
    }

    private static func monggleColor(for moodId: String) -> Color {
        switch moodId {
        case "calm":  return MongleColor.monggleGreen
        case "happy": return MongleColor.monggleYellow
        case "loved": return MongleColor.mongglePink
        case "sad":   return MongleColor.monggleBlue
        case "tired": return MongleColor.monggleOrange
        default:      return MongleColor.mongglePink
        }
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
        case .reminder:
            return "clock.badge.fill"
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
        case .reminder:
            return MongleColor.accentOrange
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
        case .reminder:
            return MongleColor.bgWarmLight
        }
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = .current
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private var timeAgo: String {
        Self.relativeFormatter.localizedString(for: notification.createdAt, relativeTo: Date())
    }

}

#Preview {
    NotificationView(
        store: Store(initialState: NotificationFeature.State()) {
            NotificationFeature()
        }
    )
}
