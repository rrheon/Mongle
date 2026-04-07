//
//  QuestionRepository.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Domain

final class QuestionRepository: QuestionRepositoryInterface {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func create(_ question: Question) async throws -> Question {
        throw QuestionError.unknown("Create endpoint not supported")
    }

    func get(id: UUID) async throws -> Question {
        throw QuestionError.unknown("Get by ID endpoint not supported")
    }

    func getByOrder(_ order: Int) async throws -> Question? {
        let endpoint = QuestionEndpoint.getByOrder(order: order)
        let questionDTO: QuestionDTO? = try? await apiClient.request(endpoint)
        return questionDTO.map { QuestionMapper.toDomain($0) }
    }

    func getByCategory(_ category: QuestionCategory) async throws -> [Question] {
        let endpoint = QuestionEndpoint.getByCategory(category: category.rawValue)
        let questionDTOs: [QuestionDTO] = try await apiClient.request(endpoint)
        return questionDTOs.map { QuestionMapper.toDomain($0) }
    }

    func getAll() async throws -> [Question] {
        let endpoint = QuestionEndpoint.getAll
        let questionDTOs: [QuestionDTO] = try await apiClient.request(endpoint)
        return questionDTOs.map { QuestionMapper.toDomain($0) }
    }

    func update(_ question: Question) async throws -> Question {
        throw QuestionError.unknown("Update endpoint not supported")
    }

    func delete(id: UUID) async throws {
        throw QuestionError.unknown("Delete endpoint not supported")
    }

    func getTodayQuestion() async throws -> Question? {
        let dto: DailyQuestionResponseDTO? = try? await apiClient.request(HomeEndpoint.todayQuestion)
        return dto.map { QuestionMapper.toDomain($0) }
    }

    func skipTodayQuestion() async throws -> Int {
        struct SkipResponse: Decodable {
            let heartsRemaining: Int
        }
        let response: SkipResponse = try await apiClient.request(QuestionEndpoint.skip)
        return response.heartsRemaining
    }

    func createCustomQuestion(content: String) async throws -> (question: Question, heartsRemaining: Int) {
        struct CustomQuestionResponse: Decodable {
            let newQuestion: DailyQuestionResponseDTO
            let heartsRemaining: Int
        }
        let endpoint = QuestionEndpoint.createCustom(content: content)
        let response: CustomQuestionResponse = try await apiClient.request(endpoint)
        return (QuestionMapper.toDomain(response.newQuestion), response.heartsRemaining)
    }

    func getHistory(page: Int, limit: Int) async throws -> [HistoryQuestion] {
        let endpoint = QuestionEndpoint.getHistory(page: page, limit: limit)
        struct PaginatedDTO: Decodable {
            let data: [DailyQuestionResponseDTO]
        }
        let response: PaginatedDTO = try await apiClient.request(endpoint)
        // 서버는 "YYYY-MM-DD" 형식의 KST 날짜 문자열을 반환 (UTC 자정 기준 저장)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return response.data.map { dto in
            let date = dateFormatter.date(from: dto.date) ?? Date()
            let answers = (dto.answers ?? []).map { a in
                HistoryQuestion.HistoryAnswerSummary(
                    id: a.id, userId: a.userId, userName: a.userName,
                    content: a.content, imageUrl: a.imageUrl, moodId: a.moodId
                )
            }
            return HistoryQuestion(
                dailyQuestionId: dto.id,
                question: QuestionMapper.toDomain(dto),
                date: date,
                hasMyAnswer: dto.hasMyAnswer,
                hasMySkipped: dto.hasMySkipped,
                familyAnswerCount: dto.familyAnswerCount,
                answers: answers
            )
        }
    }
}
