//
//  HistoryFeature.swift
//  Mongle
//
//  Created by Claude on 1/9/26.
//

import Foundation
import ComposableArchitecture
import Domain

// MARK: - 히스토리 아이템 (날짜별 질문/답변 요약)
public struct HistoryItem: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let question: Question
    public let answerCount: Int
    public let totalMembers: Int
    public let isCompleted: Bool
    public let userAnswered: Bool

    public init(
        id: UUID = UUID(),
        date: Date,
        question: Question,
        answerCount: Int,
        totalMembers: Int,
        isCompleted: Bool,
        userAnswered: Bool
    ) {
        self.id = id
        self.date = date
        self.question = question
        self.answerCount = answerCount
        self.totalMembers = totalMembers
        self.isCompleted = isCompleted
        self.userAnswered = userAnswered
    }
}

@Reducer
public struct HistoryFeature {
    @ObservableState
    public struct State: Equatable {
        public var selectedDate: Date
        public var currentMonth: Date
        public var historyItems: [Date: HistoryItem] = [:]
        public var selectedItem: HistoryItem?
        public var isLoading = false
        public var errorMessage: String?

        // 달력에 표시할 날짜들
        public var calendarDays: [Date] {
            generateCalendarDays(for: currentMonth)
        }

        // 해당 월의 첫째 날
        public var monthStartDate: Date {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: currentMonth)
            return calendar.date(from: components) ?? currentMonth
        }

        // 해당 월의 이름
        public var monthTitle: String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "yyyy년 M월"
            return formatter.string(from: currentMonth)
        }

        public init(
            selectedDate: Date = Date(),
            currentMonth: Date = Date()
        ) {
            self.selectedDate = selectedDate
            self.currentMonth = currentMonth
        }

        private func generateCalendarDays(for month: Date) -> [Date] {
            let calendar = Calendar.current

            // 해당 월의 첫째 날
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
                  let monthRange = calendar.range(of: .day, in: .month, for: month) else {
                return []
            }

            // 첫째 날의 요일 (일요일 = 1)
            let firstWeekday = calendar.component(.weekday, from: monthStart)

            // 이전 달의 날짜들 (빈 공간 채우기)
            var days: [Date] = []
            let previousDaysCount = firstWeekday - 1
            if previousDaysCount > 0 {
                for i in (1...previousDaysCount).reversed() {
                    if let date = calendar.date(byAdding: .day, value: -i, to: monthStart) {
                        days.append(date)
                    }
                }
            }

            // 해당 월의 날짜들
            for day in monthRange {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                    days.append(date)
                }
            }

            // 다음 달의 날짜들 (6주 맞추기)
            let remainingDays = 42 - days.count
            if remainingDays > 0 {
                guard let monthEnd = calendar.date(byAdding: .day, value: monthRange.count - 1, to: monthStart) else {
                    return days
                }
                for i in 1...remainingDays {
                    if let date = calendar.date(byAdding: .day, value: i, to: monthEnd) {
                        days.append(date)
                    }
                }
            }

            return days
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case onAppear
        case calendarTapped
        case selectDate(Date)
        case previousMonth
        case nextMonth
        case goToToday
        case itemTapped(HistoryItem)
        case dismissError

        // MARK: - Internal Actions
        case setLoading(Bool)
        case setError(String?)
        case historyLoaded([Date: HistoryItem])

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case navigateToQuestionDetail(Question, Date)
            case navigateToHistoryCalendar
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.historyItems.isEmpty else { return .none }
                state.isLoading = true
                // Mock 데이터 로드
                return .run { send in
                    try await Task.sleep(nanoseconds: 500_000_000)
                    let mockData = generateMockHistoryData()
                    await send(.historyLoaded(mockData))
                }

            case .calendarTapped:
                return .send(.delegate(.navigateToHistoryCalendar))

            case .selectDate(let date):
                state.selectedDate = date
                if let item = state.historyItems[Calendar.current.startOfDay(for: date)] {
                    state.selectedItem = item
                } else {
                    state.selectedItem = nil
                }
                return .none

            case .previousMonth:
                let calendar = Calendar.current
                if let newMonth = calendar.date(byAdding: .month, value: -1, to: state.currentMonth) {
                    state.currentMonth = newMonth
                }
                return .none

            case .nextMonth:
                let calendar = Calendar.current
                if let newMonth = calendar.date(byAdding: .month, value: 1, to: state.currentMonth) {
                    state.currentMonth = newMonth
                }
                return .none

            case .goToToday:
                state.currentMonth = Date()
                state.selectedDate = Date()
                return .none

            case .itemTapped(let item):
                return .send(.delegate(.navigateToQuestionDetail(item.question, item.date)))

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

            case .historyLoaded(let items):
                state.historyItems = items
                state.isLoading = false
                // 선택된 날짜의 아이템 업데이트
                if let item = items[Calendar.current.startOfDay(for: state.selectedDate)] {
                    state.selectedItem = item
                }
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Mock Data Generator
private func generateMockHistoryData() -> [Date: HistoryItem] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
    let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) ?? today

    let entries: [HistoryItem] = [
        HistoryItem(
            date: today,
            question: Question(id: UUID(), content: "오늘 당신을 웃게 한 건 무엇인가요?", category: .daily, order: 1),
            answerCount: 3,
            totalMembers: 5,
            isCompleted: false,
            userAnswered: true
        ),
        HistoryItem(
            date: yesterday,
            question: Question(id: UUID(), content: "가족에게 고마운 순간은?", category: .gratitude, order: 2),
            answerCount: 5,
            totalMembers: 5,
            isCompleted: true,
            userAnswered: true
        ),
        HistoryItem(
            date: twoDaysAgo,
            question: Question(id: UUID(), content: "가족에게 고마운 순간은?", category: .gratitude, order: 3),
            answerCount: 4,
            totalMembers: 5,
            isCompleted: false,
            userAnswered: true
        )
    ]

    return Dictionary(uniqueKeysWithValues: entries.map { (calendar.startOfDay(for: $0.date), $0) })
}
