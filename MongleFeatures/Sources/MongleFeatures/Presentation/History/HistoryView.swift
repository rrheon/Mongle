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
            headerView

            if store.isLoading {
                Spacer()
                ProgressView()
                    .tint(MongleColor.primary)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        if filteredItems.isEmpty {
                            emptyView
                        } else {
                            ForEach(sectionedItems, id: \.title) { section in
                                historySection(title: section.title, items: section.items)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color(hex: "F8FAF8"))
        .onAppear {
            store.send(.onAppear)
        }
    }

    private var headerView: some View {
        HStack {
            Text("감정 기록")
                .font(MongleFont.heading2())
                .foregroundColor(MongleColor.textPrimary)

            Spacer()

            Button {
                store.send(.calendarTapped)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                    Text(monthShortTitle)
                        .font(MongleFont.captionBold())
                }
                .foregroundColor(MongleColor.textSecondary)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(MongleColor.cardGlass)
                .overlay(Capsule().stroke(MongleColor.border, lineWidth: 1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
        .background(Color.white)
    }

    private func historySection(title: String, items: [HistoryItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(MongleFont.body2Bold())
                .foregroundColor(MongleColor.textHint)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button {
                    store.send(.itemTapped(item))
                } label: {
                    HStack(spacing: 16) {
                        historyAvatar(item)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.question.content)
                                .font(MongleFont.body2())
                                .foregroundColor(MongleColor.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(historySubtitle(item))
                                .font(MongleFont.caption())
                                .foregroundColor(MongleColor.textSecondary)
                        }

                        if !item.userAnswered {
                            Circle()
                                .fill(MongleColor.primarySoft)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 88, alignment: .leading)
                    .background(Color.white)
                }
                .buttonStyle(.plain)

                if index != items.count - 1 {
                    Divider()
                        .padding(.leading, 84)
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: MongleSpacing.md) {
            Image(systemName: "calendar.badge.exclamationmark")
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

    private var filteredItems: [HistoryItem] {
        store.historyItems.values.sorted { $0.date > $1.date }
    }

    private var sectionedItems: [(title: String, items: [HistoryItem])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let todayItems = filteredItems.filter { calendar.startOfDay(for: $0.date) == today }
        let yesterdayItems = filteredItems.filter { calendar.startOfDay(for: $0.date) == yesterday }
        let olderItems = filteredItems.filter { calendar.startOfDay(for: $0.date) < yesterday }

        return [
            (!todayItems.isEmpty ? ("오늘", todayItems) : nil),
            (!yesterdayItems.isEmpty ? ("어제", yesterdayItems) : nil),
            (!olderItems.isEmpty ? ("이전", olderItems) : nil)
        ].compactMap { $0 }
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private var monthShortTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월"
        return formatter.string(from: store.currentMonth)
    }

    private func historySubtitle(_ item: HistoryItem) -> String {
        item.userAnswered ? "\(item.answerCount)/\(item.totalMembers)명 답변 완료" : "아직 내 답변이 남아 있어요"
    }

    private func historyAvatar(_ item: HistoryItem) -> some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "FFE8A0"), Color(hex: "FFD54F")],
                            center: .init(x: 0.35, y: 0.35),
                            startRadius: 4,
                            endRadius: 22
                        )
                    )
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "1A1A1A")).frame(width: 6, height: 6).overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    Circle().fill(Color(hex: "1A1A1A")).frame(width: 6, height: 6).overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                }
                .offset(y: 2)
            }
            .frame(width: 44, height: 44)

            Text(historyName(item))
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textPrimary)
        }
    }

    private func historyName(_ item: HistoryItem) -> String {
        switch dayNumber(item.date) {
        case dayNumber(Date()):
            return "Ben"
        default:
            return item.userAnswered ? "Lily" : "Mom"
        }
    }
}

#Preview {
    HistoryView(
        store: Store(initialState: HistoryFeature.State()) {
            HistoryFeature()
        }
    )
}
