//
//  HistoryView.swift
//  Mongle
//

import SwiftUI
import ComposableArchitecture
import Domain

public struct HistoryView: View {
    @Bindable var store: StoreOf<HistoryFeature>

    private let cal = Calendar.current
    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]

    public init(store: StoreOf<HistoryFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerView

            if store.isLoading {
                Spacer()
                ProgressView().tint(MongleColor.primary)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        calendarGrid
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        if let item = store.selectedItem {
                            VStack(spacing: 10) {
                                questionCard(item)
                                ForEach(item.memberAnswers) { answer in
                                    answerCard(answer)
                                }
                                if item.memberAnswers.isEmpty {
                                    emptyAnswersCard
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color(hex: "F8FAF8"))
        .onAppear { store.send(.onAppear) }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 0) {
            Button { store.send(.previousMonth) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MongleColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(store.monthTitle)
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)

            Spacer()

            Button { store.send(.nextMonth) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MongleColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 56)
        .padding(.horizontal, 8)
        .background(Color.white)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 0) {
            // 요일 헤더
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdays[i])
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(
                            i == 0 ? Color(hex: "F44336") :
                            i == 6 ? Color(hex: "1565C0") :
                            MongleColor.textPrimary
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
            }

            // 주 행
            let days = store.calendarDays
            let weeks = stride(from: 0, to: days.count, by: 7)
                .map { Array(days[$0..<min($0 + 7, days.count)]) }

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(week, id: \.self) { date in
                        dayCell(for: date)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let isCurrentMonth = cal.component(.month, from: date) == cal.component(.month, from: store.currentMonth)
        let isToday = cal.isDateInToday(date)
        let isSelected = cal.isDate(date, inSameDayAs: store.selectedDate)
        let hasRecord = store.historyItems[cal.startOfDay(for: date)] != nil
        let weekday = cal.component(.weekday, from: date)

        let numColor: Color = {
            if isToday { return .white }
            if !isCurrentMonth { return MongleColor.textHint.opacity(0.4) }
            if weekday == 1 { return Color(hex: "F44336") }
            if weekday == 7 { return Color(hex: "1565C0") }
            return MongleColor.textPrimary
        }()

        Button {
            guard isCurrentMonth else { return }
            store.send(.selectDate(date))
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isToday {
                        Circle()
                            .fill(MongleColor.primary)
                            .frame(width: 36, height: 36)
                    } else if isSelected {
                        Circle()
                            .fill(MongleColor.primaryLight)
                            .frame(width: 36, height: 36)
                    }
                    Text(dayString(date))
                        .font(.system(size: 14, weight: hasRecord ? .medium : .regular))
                        .foregroundColor(numColor)
                }
                .frame(width: 36, height: 36)

                if hasRecord && isCurrentMonth {
                    Circle()
                        .fill(MongleColor.primary)
                        .frame(width: 6, height: 6)
                } else {
                    Color.clear.frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Question Card

    private func questionCard(_ item: HistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MongleColor.primary)
                Text(selectedDateLabel)
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.primary)
                Spacer()
                Text("\(item.answerCount)/\(item.totalMembers)명 답변")
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }

            Text(item.question.content)
                .font(MongleFont.body2Bold())
                .foregroundColor(MongleColor.textPrimary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MongleColor.primary, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture { store.send(.itemTapped(item)) }
    }

    // MARK: - Answer Card

    private func answerCard(_ memberAnswer: MemberAnswer) -> some View {
        HStack(alignment: .top, spacing: 12) {
            MongleMonggle(
                color: monggleColor(for: memberAnswer.colorIndex),
                name: memberAnswer.memberName,
                size: 44
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(memberAnswer.memberName)
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.textPrimary)
                Text(memberAnswer.answerContent)
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textSecondary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MongleColor.border, lineWidth: 1)
        )
    }

    private var emptyAnswersCard: some View {
        HStack(spacing: 8) {
            Image(systemName: "bubble.left")
                .font(.system(size: 14))
                .foregroundColor(MongleColor.textHint)
            Text("아직 답변이 없어요")
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textHint)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MongleColor.border, lineWidth: 1)
        )
    }

    private func monggleColor(for index: Int) -> Color {
        let colors: [Color] = [
            MongleColor.monggleGreen,
            MongleColor.monggleYellow,
            MongleColor.mongglePink,
            MongleColor.monggleBlue,
            MongleColor.monggleOrange
        ]
        return colors[index % colors.count]
    }

    // MARK: - Helpers

    private func dayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "d"
        return f.string(from: date)
    }

    private var selectedDateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 EEEE"
        return f.string(from: store.selectedDate)
    }
}

#Preview {
    HistoryView(
        store: Store(initialState: HistoryFeature.State()) {
            HistoryFeature()
        }
    )
}
