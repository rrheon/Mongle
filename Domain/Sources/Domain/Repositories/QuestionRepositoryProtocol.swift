//
//  QuestionRepositoryProtocol.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation

public protocol QuestionRepositoryInterface: Sendable {
    func create(_ question: Question) async throws -> Question
    func get(id: UUID) async throws -> Question
    func getByOrder(_ order: Int) async throws -> Question?
    func getByCategory(_ category: QuestionCategory) async throws -> [Question]
    func getAll() async throws -> [Question]
    func update(_ question: Question) async throws -> Question
    func delete(id: UUID) async throws
    /// 오늘의 질문을 조회. 질문이 없으면 nil.
    func getTodayQuestion() async throws -> Question?
    /// 오늘의 질문 + 가족 멤버 답변 상태를 함께 조회. 질문이 없으면 nil.
    /// - memberStatuses 는 구버전 서버에서는 빈 배열을 반환할 수 있다.
    func getTodayQuestionDetailed() async throws -> TodayQuestionDetails?
    /// 오늘 질문을 개인 패스 (하트 3개 차감, 질문 변경 없음). POST /questions/skip
    /// - returns: 남은 하트 수
    func skipTodayQuestion() async throws -> Int
    /// 가족 질문 히스토리 (답변 포함). GET /questions?page=&limit=
    func getHistory(page: Int, limit: Int) async throws -> [HistoryQuestion]
    /// 나만의 질문 등록 (하트 3개 차감). POST /questions/custom
    func createCustomQuestion(content: String) async throws -> (question: Question, heartsRemaining: Int)
}

/// 오늘의 질문 + 가족 멤버별 답변 상태 (서버 memberAnswerStatuses 응답을 매핑).
public struct TodayQuestionDetails: Equatable, Sendable {
    public let question: Question
    public let memberStatuses: [MemberAnswerStatus]

    public init(question: Question, memberStatuses: [MemberAnswerStatus]) {
        self.question = question
        self.memberStatuses = memberStatuses
    }
}

public struct MemberAnswerStatus: Equatable, Sendable {
    public enum Status: Sendable, Equatable {
        case answered
        case skipped
        case notAnswered
    }
    public let userId: UUID
    public let userName: String
    public let colorId: String
    public let status: Status

    public init(userId: UUID, userName: String, colorId: String, status: Status) {
        self.userId = userId
        self.userName = userName
        self.colorId = colorId
        self.status = status
    }
}

/// 히스토리용 질문 + 답변 요약 도메인 모델
public struct HistoryQuestion: Equatable, Sendable {
    public let dailyQuestionId: String
    public let question: Question
    public let date: Date
    public let hasMyAnswer: Bool
    public let hasMySkipped: Bool
    public let familyAnswerCount: Int
    public let answers: [HistoryAnswerSummary]
    /// 각 가족 멤버의 답변/스킵 상태 (서버 memberAnswerStatuses 응답).
    /// 답변한 멤버는 answers 에도 포함되고 memberStatuses 에는 `.answered` 로 표기된다.
    /// 스킵한 멤버는 answers 에는 없고 memberStatuses 에 `.skipped` 로 표기된다.
    public let memberStatuses: [MemberAnswerStatus]

    public struct HistoryAnswerSummary: Equatable, Sendable {
        public let id: String
        public let userId: String
        public let userName: String
        public let content: String
        public let imageUrl: String?
        public let moodId: String?

        public init(id: String, userId: String, userName: String, content: String, imageUrl: String?, moodId: String? = nil) {
            self.id = id
            self.userId = userId
            self.userName = userName
            self.content = content
            self.imageUrl = imageUrl
            self.moodId = moodId
        }
    }

    public init(
        dailyQuestionId: String,
        question: Question,
        date: Date,
        hasMyAnswer: Bool,
        hasMySkipped: Bool = false,
        familyAnswerCount: Int,
        answers: [HistoryAnswerSummary],
        memberStatuses: [MemberAnswerStatus] = []
    ) {
        self.dailyQuestionId = dailyQuestionId
        self.question = question
        self.date = date
        self.hasMyAnswer = hasMyAnswer
        self.hasMySkipped = hasMySkipped
        self.familyAnswerCount = familyAnswerCount
        self.answers = answers
        self.memberStatuses = memberStatuses
    }
}

public enum QuestionError: Error, Equatable, Sendable {
    case questionNotFound
    case noQuestionToday
    case networkError
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .questionNotFound:
            return "질문을 찾을 수 없습니다."
        case .noQuestionToday:
            return "오늘의 질문이 아직 없습니다."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .unknown(let message):
            return message
        }
    }
}
