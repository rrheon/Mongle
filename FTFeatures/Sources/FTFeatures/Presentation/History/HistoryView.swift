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

            ScrollView {
                VStack(spacing: FTSpacing.lg) {
                    // 달력
                    calendarView

                    // 선택된 날짜의 질문 카드
                    if let item = store.selectedItem {
                        selectedItemCard(item)
                    } else {
                        emptySelectionView
                    }
                }
                .padding(.horizontal, FTSpacing.md)
                .padding(.bottom, FTSpacing.xl)
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
            Text("히스토리")
                .font(FTFont.heading2())
                .foregroundColor(FTColor.textPrimary)

            Spacer()

            Button {
                store.send(.goToToday)
            } label: {
                Text("오늘")
                    .font(FTFont.buttonSmall())
                    .foregroundColor(FTColor.primary)
                    .padding(.horizontal, FTSpacing.sm)
                    .padding(.vertical, FTSpacing.xxs)
                    .background(FTColor.primaryLight)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, FTSpacing.md)
        .padding(.vertical, FTSpacing.md)
        .background(FTColor.background)
    }

    // MARK: - Calendar View
    private var calendarView: some View {
        VStack(spacing: FTSpacing.md) {
            // 월 네비게이션
            HStack {
                Button {
                    store.send(.previousMonth)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(FTColor.textSecondary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text(store.monthTitle)
                    .font(FTFont.heading3())
                    .foregroundColor(FTColor.textPrimary)

                Spacer()

                Button {
                    store.send(.nextMonth)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(FTColor.textSecondary)
                        .frame(width: 44, height: 44)
                }
            }

            // 요일 헤더
            weekdayHeader

            // 날짜 그리드
            calendarGrid
        }
        .padding(FTSpacing.md)
        .background(FTColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FTRadius.large))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .font(FTFont.caption())
                    .foregroundColor(day == "일" ? FTColor.error : (day == "토" ? FTColor.info : FTColor.textSecondary))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: FTSpacing.xs) {
            ForEach(store.calendarDays, id: \.self) { date in
                CalendarDayCell(
                    date: date,
                    currentMonth: store.currentMonth,
                    selectedDate: store.selectedDate,
                    historyItem: store.historyItems[Calendar.current.startOfDay(for: date)]
                ) {
                    store.send(.selectDate(date))
                }
            }
        }
    }

    // MARK: - Selected Item Card
    private func selectedItemCard(_ item: HistoryItem) -> some View {
        VStack(alignment: .leading, spacing: FTSpacing.md) {
            // 날짜 및 상태
            HStack {
                Text(formatDate(item.date))
                    .font(FTFont.body1Bold())
                    .foregroundColor(FTColor.textPrimary)

                Spacer()

                // 완료 상태 뱃지
                HStack(spacing: FTSpacing.xxs) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(item.isCompleted ? FTColor.success : FTColor.textHint)

                    Text("\(item.answerCount)/\(item.totalMembers)")
                        .font(FTFont.captionBold())
                        .foregroundColor(item.isCompleted ? FTColor.success : FTColor.textSecondary)
                }
                .padding(.horizontal, FTSpacing.sm)
                .padding(.vertical, FTSpacing.xxs)
                .background(item.isCompleted ? FTColor.success.opacity(0.1) : FTColor.surface)
                .clipShape(Capsule())
            }

            // 카테고리
            Text(item.question.category.rawValue)
                .font(FTFont.caption())
                .foregroundColor(FTColor.primary)
                .padding(.horizontal, FTSpacing.xs)
                .padding(.vertical, 2)
                .background(FTColor.primaryLight)
                .clipShape(Capsule())

            // 질문 내용
            Text(item.question.content)
                .font(FTFont.body1())
                .foregroundColor(FTColor.textPrimary)
                .lineLimit(3)

            // 내 답변 상태
            HStack {
                Image(systemName: item.userAnswered ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.userAnswered ? FTColor.primary : FTColor.textHint)

                Text(item.userAnswered ? "답변 완료" : "답변하지 않음")
                    .font(FTFont.caption())
                    .foregroundColor(item.userAnswered ? FTColor.primary : FTColor.textHint)

                Spacer()

                // 상세보기 버튼
                Button {
                    store.send(.itemTapped(item))
                } label: {
                    HStack(spacing: FTSpacing.xxs) {
                        Text("자세히 보기")
                        Image(systemName: "chevron.right")
                    }
                    .font(FTFont.buttonSmall())
                    .foregroundColor(FTColor.primary)
                }
            }
        }
        .padding(FTSpacing.md)
        .background(FTColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FTRadius.large))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Empty Selection View
    private var emptySelectionView: some View {
        VStack(spacing: FTSpacing.md) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(FTColor.textHint)

            Text("이 날은 질문이 없어요")
                .font(FTFont.body1())
                .foregroundColor(FTColor.textSecondary)

            Text("다른 날짜를 선택해보세요")
                .font(FTFont.caption())
                .foregroundColor(FTColor.textHint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FTSpacing.xxl)
        .background(FTColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FTRadius.large))
    }

    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let date: Date
    let currentMonth: Date
    let selectedDate: Date
    let historyItem: HistoryItem?
    let onTap: () -> Void

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    private var isSelected: Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // 날짜 숫자
                Text(dayNumber)
                    .font(FTFont.body2())
                    .foregroundColor(dayTextColor)

                // 상태 인디케이터
                if let item = historyItem, isCurrentMonth {
                    Circle()
                        .fill(item.isCompleted ? FTColor.success : (item.userAnswered ? FTColor.primary : FTColor.warning))
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40, height: 44)
            .background(backgroundView)
        }
        .buttonStyle(.plain)
    }

    private var dayTextColor: Color {
        if !isCurrentMonth {
            return FTColor.textHint.opacity(0.5)
        }
        if isSelected {
            return .white
        }
        if isToday {
            return FTColor.primary
        }

        let weekday = Calendar.current.component(.weekday, from: date)
        if weekday == 1 { return FTColor.error }
        if weekday == 7 { return FTColor.info }

        return FTColor.textPrimary
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            Circle()
                .fill(FTColor.primary)
        } else if isToday {
            Circle()
                .stroke(FTColor.primary, lineWidth: 1.5)
        } else {
            Color.clear
        }
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
