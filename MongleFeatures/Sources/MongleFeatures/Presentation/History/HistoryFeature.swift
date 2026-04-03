//
//  HistoryFeature.swift
//  Mongle
//
//  Created by Claude on 1/9/26.
//

import Foundation
import ComposableArchitecture
import Domain

// MARK: - 멤버 답변
public struct MemberAnswer: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let memberName: String
    public let answerContent: String
    public let colorIndex: Int // 0~4, MongleMonggle 색상 인덱스

    public init(id: UUID = UUID(), memberName: String, answerContent: String, colorIndex: Int) {
        self.id = id
        self.memberName = memberName
        self.answerContent = answerContent
        self.colorIndex = colorIndex
    }
}

// MARK: - 히스토리 아이템 (날짜별 질문/답변 요약)
public struct HistoryItem: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let question: Question
    public let answerCount: Int
    public let totalMembers: Int
    public let isCompleted: Bool
    public let userAnswered: Bool
    public let userSkipped: Bool
    public let memberAnswers: [MemberAnswer]

    public init(
        id: UUID = UUID(),
        date: Date,
        question: Question,
        answerCount: Int,
        totalMembers: Int,
        isCompleted: Bool,
        userAnswered: Bool,
        userSkipped: Bool = false,
        memberAnswers: [MemberAnswer] = []
    ) {
        self.id = id
        self.date = date
        self.question = question
        self.answerCount = answerCount
        self.totalMembers = totalMembers
        self.isCompleted = isCompleted
        self.userAnswered = userAnswered
        self.userSkipped = userSkipped
        self.memberAnswers = memberAnswers
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
        public var errorMessage: String?   // 하위 호환 (기존 뷰에서 사용)
        public var appError: AppError?     // 새 통합 에러 타입
        public var familyId: UUID?
        public var familyMembers: [User] = []
        /// 이미 로드한 월 목록 (캐시). 같은 월은 재요청하지 않음.
        public var loadedMonths: Set<String> = []

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
            currentMonth: Date = Date(),
            familyId: UUID? = nil,
            familyMembers: [User] = []
        ) {
            self.selectedDate = selectedDate
            self.currentMonth = currentMonth
            self.familyId = familyId
            self.familyMembers = familyMembers
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
        case forceReload
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
        case setAppError(AppError?)
        case historyLoaded([Date: HistoryItem])

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case navigateToQuestionDetail(Question, Date)
            case navigateToHistoryCalendar
        }
    }

    @Dependency(\.questionRepository) var questionRepository
    @Dependency(\.errorHandler) var errorHandler

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.historyItems.isEmpty else { return .none }
                return .send(.forceReload)

            case .forceReload:
                state.historyItems = [:]
                state.loadedMonths = []
                state.isLoading = true
                guard state.familyId != nil else {
                    state.isLoading = false
                    return .none
                }
                let totalMembers = max(state.familyMembers.count, 1)
                return .run { [questionRepository] send in
                    do {
                        let historyQuestions = try await questionRepository.getHistory(page: 1, limit: 60)
                        let calendar = Calendar.current
                        var historyItems: [Date: HistoryItem] = [:]
                        for hq in historyQuestions {
                            let isToday = calendar.isDateInToday(hq.date)
                            let canViewAnswers = hq.hasMyAnswer || hq.hasMySkipped
                            // 오늘 미답변이어도 질문은 노출하되, 가족 답변 내용은 답변/스킵 후에만 표시
                            let memberAnswers: [MemberAnswer] = canViewAnswers ? hq.answers.map { answer in
                                MemberAnswer(
                                    memberName: answer.userName,
                                    answerContent: answer.content,
                                    colorIndex: colorIndexFromMoodId(answer.moodId)
                                )
                            } : []
                            let item = HistoryItem(
                                id: UUID(uuidString: hq.dailyQuestionId) ?? UUID(),
                                date: hq.date,
                                question: hq.question,
                                answerCount: hq.familyAnswerCount,
                                totalMembers: totalMembers,
                                isCompleted: hq.familyAnswerCount >= totalMembers,
                                userAnswered: hq.hasMyAnswer,
                                userSkipped: hq.hasMySkipped,
                                memberAnswers: memberAnswers
                            )
                            historyItems[calendar.startOfDay(for: hq.date)] = item
                        }
                        await send(.historyLoaded(historyItems))
                    } catch {
                        await send(.setAppError(errorHandler(error, context: "HistoryFeature.forceReload")))
                    }
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
                state.selectedItem = state.historyItems[Calendar.current.startOfDay(for: Date())]
                return .none

            case .itemTapped(let item):
                return .send(.delegate(.navigateToQuestionDetail(item.question, item.date)))

            case .dismissError:
                state.errorMessage = nil
                state.appError = nil
                return .none

            case .setLoading(let isLoading):
                state.isLoading = isLoading
                return .none

            case .setError(let message):
                state.errorMessage = message
                state.isLoading = false
                return .none

            case .setAppError(let error):
                state.appError = error
                state.errorMessage = error?.userMessage
                state.isLoading = false
                return .none

            case .historyLoaded(let items):
                state.historyItems = items
                state.isLoading = false
                state.selectedItem = items[Calendar.current.startOfDay(for: state.selectedDate)]
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Helpers

private func colorIndexFromMoodId(_ moodId: String?) -> Int {
    switch moodId {
    case "calm":  return 0 // green
    case "happy": return 1 // yellow
    case "loved": return 2 // pink
    case "sad":   return 3 // blue
    case "tired": return 4 // orange
    default:      return 2 // default: pink
    }
}

