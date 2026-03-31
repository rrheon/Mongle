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
    /// 오늘 질문을 개인 패스 (하트 3개 차감, 질문 변경 없음). POST /questions/skip
    /// - returns: 남은 하트 수
    func skipTodayQuestion() async throws -> Int
    /// 가족 질문 히스토리 (답변 포함). GET /questions?page=&limit=
    func getHistory(page: Int, limit: Int) async throws -> [HistoryQuestion]
    /// 나만의 질문 등록 (하트 3개 차감). POST /questions/custom
    func createCustomQuestion(content: String) async throws -> (question: Question, heartsRemaining: Int)
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
        answers: [HistoryAnswerSummary]
    ) {
        self.dailyQuestionId = dailyQuestionId
        self.question = question
        self.date = date
        self.hasMyAnswer = hasMyAnswer
        self.hasMySkipped = hasMySkipped
        self.familyAnswerCount = familyAnswerCount
        self.answers = answers
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
