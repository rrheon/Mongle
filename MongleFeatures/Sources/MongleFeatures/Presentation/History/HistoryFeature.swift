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

// MARK: - 질문을 넘긴 멤버 표시용
public struct SkippedMember: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let memberName: String
    public let colorIndex: Int

    public init(id: UUID = UUID(), userId: UUID, memberName: String, colorIndex: Int) {
        self.id = id
        self.userId = userId
        self.memberName = memberName
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
    /// 본인을 제외한, 해당 날짜에 질문을 넘긴 다른 가족들 (서버 memberAnswerStatuses 기반)
    public let otherSkippedMembers: [SkippedMember]

    public init(
        id: UUID = UUID(),
        date: Date,
        question: Question,
        answerCount: Int,
        totalMembers: Int,
        isCompleted: Bool,
        userAnswered: Bool,
        userSkipped: Bool = false,
        memberAnswers: [MemberAnswer] = [],
        otherSkippedMembers: [SkippedMember] = []
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
        self.otherSkippedMembers = otherSkippedMembers
    }
}

// MARK: - 달력 셀 메타정보 (View 렌더링 부담 감소용 사전 계산값)
public struct CalendarDayInfo: Equatable, Identifiable, Sendable {
    public let id: Date         // startOfDay → ForEach 안정 키 + historyItems 조회 키
    public let date: Date
    public let dayString: String
    public let weekday: Int     // 1=Sun ~ 7=Sat
    public let isCurrentMonth: Bool
    public let isToday: Bool
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
        /// 현재 로그인 사용자. 질문 넘김 카드를 렌더링할 때 이름/컬러를 표기하기 위해 사용한다.
        public var currentUser: User?
        /// 이미 로드한 월 목록 (캐시). 같은 월은 재요청하지 않음.
        public var loadedMonths: Set<String> = []

        // MARK: - Cached derived values
        // computed property 였던 값들을 reducer 변경 시점에만 재계산하도록 캐시.
        // 매 body 호출마다 DateFormatter/Calendar 연산을 수십~수백 번 반복하던 비용을 제거.

        /// 달력 그리드용 사전 계산된 일자 정보 (요일·라벨·오늘여부 등)
        public var calendarDays: [CalendarDayInfo] = []
        /// 해당 월의 첫째 날 (00:00:00)
        public var monthStartDate: Date
        /// 로케일에 맞춘 "년/월" 문자열
        public var monthTitle: String = ""
        /// 최근 14일 무드별 답변 수 (인덱스 0~4)
        public var mood14DayCounts: [Int] = [0, 0, 0, 0, 0]

        public init(
            selectedDate: Date = Date(),
            currentMonth: Date = Date(),
            familyId: UUID? = nil,
            familyMembers: [User] = [],
            currentUser: User? = nil
        ) {
            self.selectedDate = selectedDate
            self.currentMonth = currentMonth
            self.familyId = familyId
            self.familyMembers = familyMembers
            self.currentUser = currentUser
            self.monthStartDate = Self.computeMonthStart(for: currentMonth)
            self.calendarDays = Self.computeCalendarDays(for: currentMonth)
            self.monthTitle = Self.computeMonthTitle(for: currentMonth)
        }

        // MARK: - Pure compute helpers (reducer 에서 호출)

        static func computeMonthStart(for month: Date) -> Date {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: month)
            return calendar.date(from: components) ?? month
        }

        static func computeMonthTitle(for month: Date) -> String {
            // formatter 인스턴스 재사용 — 매 렌더링마다 신규 할당 제거.
            Self.monthTitleFormatter.string(from: month)
        }

        static func computeCalendarDays(for month: Date) -> [CalendarDayInfo] {
            let calendar = Calendar.current
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
                  let monthRange = calendar.range(of: .day, in: .month, for: month) else {
                return []
            }
            let monthComponent = calendar.component(.month, from: monthStart)
            let firstWeekday = calendar.component(.weekday, from: monthStart)
            let previousDaysCount = firstWeekday - 1

            var infos: [CalendarDayInfo] = []
            infos.reserveCapacity(42)

            // 이전 달
            if previousDaysCount > 0 {
                for i in (1...previousDaysCount).reversed() {
                    if let d = calendar.date(byAdding: .day, value: -i, to: monthStart) {
                        infos.append(makeInfo(for: d, monthComponent: monthComponent, calendar: calendar))
                    }
                }
            }
            // 해당 월
            for day in monthRange {
                if let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                    infos.append(makeInfo(for: d, monthComponent: monthComponent, calendar: calendar))
                }
            }
            // 다음 달 (6주 = 42칸 채우기)
            let remaining = 42 - infos.count
            if remaining > 0,
               let monthEnd = calendar.date(byAdding: .day, value: monthRange.count - 1, to: monthStart) {
                for i in 1...remaining {
                    if let d = calendar.date(byAdding: .day, value: i, to: monthEnd) {
                        infos.append(makeInfo(for: d, monthComponent: monthComponent, calendar: calendar))
                    }
                }
            }
            return infos
        }

        private static func makeInfo(for date: Date, monthComponent: Int, calendar: Calendar) -> CalendarDayInfo {
            CalendarDayInfo(
                id: calendar.startOfDay(for: date),
                date: date,
                dayString: Self.dayNumberFormatter.string(from: date),
                weekday: calendar.component(.weekday, from: date),
                isCurrentMonth: calendar.component(.month, from: date) == monthComponent,
                isToday: calendar.isDateInToday(date)
            )
        }

        static func computeMood14Counts(items: [Date: HistoryItem]) -> [Int] {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            var counts = [0, 0, 0, 0, 0]
            for dayOffset in 0..<14 {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today),
                      let item = items[date] else { continue }
                for answer in item.memberAnswers {
                    counts[answer.colorIndex % 5] += 1
                }
            }
            return counts
        }

        // MARK: - 정적 Formatter (인스턴스 재사용)

        private static let monthTitleFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = .current
            f.setLocalizedDateFormatFromTemplate("yyyyMMM")
            return f
        }()

        private static let dayNumberFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = .current
            f.dateFormat = "d"
            return f
        }()
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
                state.mood14DayCounts = [0, 0, 0, 0, 0]
                state.isLoading = true
                guard state.familyId != nil else {
                    state.isLoading = false
                    return .none
                }
                let totalMembers = max(state.familyMembers.count, 1)
                let currentUserId = state.currentUser?.id
                return .run { [questionRepository] send in
                    do {
                        let historyQuestions = try await questionRepository.getHistory(page: 1, limit: 60)
                        let calendar = Calendar.current
                        var historyItems: [Date: HistoryItem] = [:]
                        for hq in historyQuestions {
                            let canViewAnswers = hq.hasMyAnswer || hq.hasMySkipped
                            // 오늘 미답변이어도 질문은 노출하되, 가족 답변 내용은 답변/스킵 후에만 표시
                            let memberAnswers: [MemberAnswer] = canViewAnswers ? hq.answers.map { answer in
                                MemberAnswer(
                                    memberName: answer.userName,
                                    answerContent: answer.content,
                                    colorIndex: colorIndexFromMoodId(answer.moodId)
                                )
                            } : []
                            // 본인을 제외한 "질문을 넘긴" 멤버 목록. 본인은 view 의 skippedSelfCard 로 별도 처리.
                            let otherSkipped: [SkippedMember] = hq.memberStatuses
                                .filter { $0.status == .skipped && $0.userId != currentUserId }
                                .map { m in
                                    SkippedMember(
                                        userId: m.userId,
                                        memberName: m.userName,
                                        colorIndex: colorIndexFromMoodId(m.colorId)
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
                                userSkipped: hq.hasMySkipped,
                                memberAnswers: memberAnswers,
                                otherSkippedMembers: otherSkipped
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
                    Self.recomputeMonthDerived(&state)
                }
                return .none

            case .nextMonth:
                let calendar = Calendar.current
                if let newMonth = calendar.date(byAdding: .month, value: 1, to: state.currentMonth) {
                    state.currentMonth = newMonth
                    Self.recomputeMonthDerived(&state)
                }
                return .none

            case .goToToday:
                state.currentMonth = Date()
                state.selectedDate = Date()
                state.selectedItem = state.historyItems[Calendar.current.startOfDay(for: Date())]
                Self.recomputeMonthDerived(&state)
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
                state.mood14DayCounts = State.computeMood14Counts(items: items)
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private static func recomputeMonthDerived(_ state: inout State) {
        state.monthStartDate = State.computeMonthStart(for: state.currentMonth)
        state.calendarDays = State.computeCalendarDays(for: state.currentMonth)
        state.monthTitle = State.computeMonthTitle(for: state.currentMonth)
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
