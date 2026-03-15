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
    public let memberAnswers: [MemberAnswer]

    public init(
        id: UUID = UUID(),
        date: Date,
        question: Question,
        answerCount: Int,
        totalMembers: Int,
        isCompleted: Bool,
        userAnswered: Bool,
        memberAnswers: [MemberAnswer] = []
    ) {
        self.id = id
        self.date = date
        self.question = question
        self.answerCount = answerCount
        self.totalMembers = totalMembers
        self.isCompleted = isCompleted
        self.userAnswered = userAnswered
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
                state.isLoading = true
                guard state.familyId != nil else {
                    // familyId 없으면 mock 데이터
                    return .run { send in
                        try await Task.sleep(nanoseconds: 500_000_000)
                        let mockData = generateMockHistoryData()
                        await send(.historyLoaded(mockData))
                    }
                }
                let totalMembers = max(state.familyMembers.count, 1)
                return .run { [questionRepository] send in
                    do {
                        // 단일 API 호출로 질문 + 답변 한꺼번에 가져오기 (N+1 제거)
                        let historyQuestions = try await questionRepository.getHistory(page: 1, limit: 60)
                        let calendar = Calendar.current
                        var historyItems: [Date: HistoryItem] = [:]
                        for hq in historyQuestions {
                            let memberAnswers: [MemberAnswer] = hq.answers.enumerated().map { index, answer in
                                MemberAnswer(
                                    memberName: answer.userName,
                                    answerContent: answer.content,
                                    colorIndex: index % 5
                                )
                            }
                            let item = HistoryItem(
                                id: UUID(uuidString: hq.dailyQuestionId) ?? UUID(),
                                date: hq.date,
                                question: hq.question,
                                answerCount: hq.familyAnswerCount,
                                totalMembers: totalMembers,
                                isCompleted: hq.familyAnswerCount >= totalMembers,
                                userAnswered: hq.hasMyAnswer,
                                memberAnswers: memberAnswers
                            )
                            historyItems[calendar.startOfDay(for: hq.date)] = item
                        }
                        await send(.historyLoaded(historyItems))
                    } catch {
                        await send(.setAppError(errorHandler(error, context: "HistoryFeature.onAppear")))
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
            userAnswered: true,
            memberAnswers: [
                MemberAnswer(memberName: "엄마", answerContent: "아이들이 아침에 처음으로 같이 요리해줬어요. 계란이 좀 타긴 했지만 정말 행복했어요 😊", colorIndex: 0),
                MemberAnswer(memberName: "Lily", answerContent: "아침에 고양이가 제 발 위에서 잠든 것을 발견했어요. 너무 귀여워서 한동안 꼼짝도 못했어요 🐱", colorIndex: 1),
                MemberAnswer(memberName: "Ben", answerContent: "친구들이랑 오랜만에 축구를 했는데 골을 두 개나 넣었어요! ⚽️", colorIndex: 2)
            ]
        ),
        HistoryItem(
            date: yesterday,
            question: Question(id: UUID(), content: "가족에게 가장 고마운 순간은 언제였나요?", category: .gratitude, order: 2),
            answerCount: 5,
            totalMembers: 5,
            isCompleted: true,
            userAnswered: true,
            memberAnswers: [
                MemberAnswer(memberName: "엄마", answerContent: "매일 아침 밥을 챙겨줄 때 정말 감사해요.", colorIndex: 0),
                MemberAnswer(memberName: "아빠", answerContent: "힘들 때 아무 말 없이 옆에 있어줄 때요.", colorIndex: 3),
                MemberAnswer(memberName: "Lily", answerContent: "생일 때 깜짝 파티 준비해줬을 때 너무 감동이었어요 🎂", colorIndex: 1),
                MemberAnswer(memberName: "Ben", answerContent: "시험 끝나고 맛있는 거 사줄 때요 😋", colorIndex: 2),
                MemberAnswer(memberName: "할머니", answerContent: "오랜만에 손자들 얼굴 보는 것만으로도 너무 행복해요 🥰", colorIndex: 4)
            ]
        ),
        HistoryItem(
            date: twoDaysAgo,
            question: Question(id: UUID(), content: "요즘 가장 즐거운 일은 무엇인가요?", category: .gratitude, order: 3),
            answerCount: 4,
            totalMembers: 5,
            isCompleted: false,
            userAnswered: true,
            memberAnswers: [
                MemberAnswer(memberName: "엄마", answerContent: "저녁 산책이 요즘 가장 기다려져요 🌙", colorIndex: 0),
                MemberAnswer(memberName: "아빠", answerContent: "주말에 가족이랑 같이 영화 보는 게 제일 좋아요.", colorIndex: 3),
                MemberAnswer(memberName: "Lily", answerContent: "새로운 드라마 정주행 중이에요. 너무 재밌어요 📺", colorIndex: 1),
                MemberAnswer(memberName: "Ben", answerContent: "요즘 기타 배우는 게 너무 재밌어요 🎸", colorIndex: 2)
            ]
        )
    ]

    return Dictionary(uniqueKeysWithValues: entries.map { (calendar.startOfDay(for: $0.date), $0) })
}
