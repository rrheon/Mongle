//
//  HistoryView.swift
//  Mongle
//
//  Created by Claude on 1/9/26.
//

import SwiftUI
import ComposableArchitecture
import Domain

public struct HistoryView: View {
    @Bindable var store: StoreOf<HistoryFeature>

    public init(store: StoreOf<HistoryFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerView

            if store.isLoading {
                Spacer()
                ProgressView()
                    .tint(MongleColor.primary)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: MongleSpacing.xl) {
                        let todayItems = itemsForSection(.today)
                        let yesterdayItems = itemsForSection(.yesterday)
                        let olderItems = itemsForSection(.older)

                        if !todayItems.isEmpty {
                            HistorySection(title: "오늘", items: todayItems) { item in
                                store.send(.itemTapped(item))
                            }
                        }
                        if !yesterdayItems.isEmpty {
                            HistorySection(title: "어제", items: yesterdayItems) { item in
                                store.send(.itemTapped(item))
                            }
                        }
                        if !olderItems.isEmpty {
                            HistorySection(title: "이전", items: olderItems) { item in
                                store.send(.itemTapped(item))
                            }
                        }
                        if todayItems.isEmpty && yesterdayItems.isEmpty && olderItems.isEmpty {
                            emptyView
                        }
                    }
                    .padding(.horizontal, MongleSpacing.md)
                    .padding(.vertical, MongleSpacing.md)
                    .padding(.bottom, MongleSpacing.xl)
                }
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
            Text("감정 기록")
                .font(MongleFont.heading2())
                .foregroundColor(MongleColor.textPrimary)

            Spacer()

            Button {
                store.send(.goToToday)
            } label: {
                HStack(spacing: MongleSpacing.xxs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                    Text(currentMonthLabel)
                        .font(MongleFont.captionBold())
                }
                .foregroundColor(MongleColor.primary)
                .padding(.horizontal, MongleSpacing.sm)
                .padding(.vertical, MongleSpacing.xxs)
                .background(MongleColor.primaryLight)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, MongleSpacing.md)
        .padding(.vertical, MongleSpacing.md)
        .background(MongleColor.background)
    }

    private var currentMonthLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: Date())
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: MongleSpacing.md) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundColor(MongleColor.textHint)

            Text("아직 감정 기록이 없어요")
                .font(MongleFont.body1())
                .foregroundColor(MongleColor.textSecondary)

            Text("오늘의 질문에 답변하면 기록이 생겨요")
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textHint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MongleSpacing.xxl)
    }

    // MARK: - Helpers
    enum SectionType { case today, yesterday, older }

    private func itemsForSection(_ section: SectionType) -> [HistoryItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        return store.historyItems.values
            .filter { item in
                let itemDay = calendar.startOfDay(for: item.date)
                switch section {
                case .today: return itemDay == today
                case .yesterday: return itemDay == yesterday
                case .older: return itemDay < yesterday
                }
            }
            .sorted { $0.date > $1.date }
    }
}

// MARK: - History Section
struct HistorySection: View {
    let title: String
    let items: [HistoryItem]
    let onTap: (HistoryItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            Text(title)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textSecondary)
                .padding(.horizontal, MongleSpacing.xxs)

            VStack(spacing: MongleSpacing.sm) {
                ForEach(items) { item in
                    HistoryEntryRow(item: item, onTap: { onTap(item) })
                }
            }
        }
    }
}

// MARK: - History Entry Row
struct HistoryEntryRow: View {
    let item: HistoryItem
    let onTap: () -> Void

    private var moodColor: Color {
        let colors: [Color] = [
            Color(hex: "FFD54F"),
            Color(hex: "F5978E"),
            Color(hex: "A8DFBC"),
            Color(hex: "42A5F5"),
            Color(hex: "AB47BC")
        ]
        return colors[abs(item.question.content.hashValue) % colors.count]
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MongleSpacing.md) {
                // 몽글 무드 아이콘
                ZStack {
                    Circle()
                        .fill(moodColor)
                        .frame(width: 48, height: 48)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: "1A1A1A"))
                            .frame(width: 5, height: 6)
                        Circle()
                            .fill(Color(hex: "1A1A1A"))
                            .frame(width: 5, height: 6)
                    }
                    .offset(y: 2)
                }

                // 내용
                VStack(alignment: .leading, spacing: MongleSpacing.xxs) {
                    Text(item.question.content)
                        .font(MongleFont.body2())
                        .fontWeight(.medium)
                        .foregroundColor(MongleColor.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: MongleSpacing.xs) {
                        if item.userAnswered {
                            Text("답변 완료")
                                .font(MongleFont.caption())
                                .foregroundColor(MongleColor.primary)
                        } else {
                            Text("미답변")
                                .font(MongleFont.caption())
                                .foregroundColor(MongleColor.textHint)
                        }

                        Text("·")
                            .foregroundColor(MongleColor.textHint)

                        Text("\(item.answerCount)/\(item.totalMembers)명")
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MongleColor.textHint)
            }
            .padding(MongleSpacing.md)
            .background(MongleColor.cardBackground)
            .cornerRadius(MongleRadius.large)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    HistoryView(
        store: Store(initialState: HistoryFeature.State()) {
            HistoryFeature()
        }
    )
}
