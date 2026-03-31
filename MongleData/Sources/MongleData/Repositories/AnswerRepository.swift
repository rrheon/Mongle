//
//  AnswerRepository.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Domain

final class AnswerRepository: AnswerRepositoryInterface {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func create(_ answer: Answer, moodId: String?) async throws -> Answer {
        let endpoint = AnswerEndpoint.create(
            questionId: answer.dailyQuestionId.uuidString,
            content: answer.content,
            imageUrl: answer.imageURL,
            moodId: moodId
        )
        let dto: AnswerDTO = try await apiClient.request(endpoint)
        return AnswerMapper.toDomain(dto)
    }

    func get(id: UUID) async throws -> Answer {
        let endpoint = AnswerEndpoint.get(id: id.uuidString)
        let dto: AnswerDTO = try await apiClient.request(endpoint)
        return AnswerMapper.toDomain(dto)
    }

    /// GET /answers/family/{questionId} — 가족 전체 답변 반환 (내 답변 포함)
    func getByDailyQuestion(dailyQuestionId: UUID) async throws -> [Answer] {
        let endpoint = AnswerEndpoint.getFamilyAnswers(questionId: dailyQuestionId.uuidString)
        let response: FamilyAnswersResponseDTO = try await apiClient.request(endpoint)
        var answers = response.answers.map { AnswerMapper.toDomain($0) }
        if let myAnswer = response.myAnswer {
            let myDomain = AnswerMapper.toDomain(myAnswer)
            if !answers.contains(where: { $0.id == myDomain.id }) {
                answers.insert(myDomain, at: 0)
            }
        }
        return answers
    }

    /// GET /answers/my/{questionId} — 내 답변 조회
    func getByUserAndDailyQuestion(dailyQuestionId: UUID, userId: UUID) async throws -> Answer? {
        let endpoint = AnswerEndpoint.getMyAnswer(questionId: dailyQuestionId.uuidString)
        let dto: AnswerDTO? = try? await apiClient.request(endpoint)
        return dto.map { AnswerMapper.toDomain($0) }
    }

    func hasUserAnswered(dailyQuestionId: UUID, userId: UUID) async throws -> Bool {
        let answer = try await getByUserAndDailyQuestion(
            dailyQuestionId: dailyQuestionId,
            userId: userId
        )
        return answer != nil
    }

    func getByUser(userId: UUID) async throws -> [Answer] {
        fatalError("Get by user endpoint not implemented")
    }

    func update(_ answer: Answer, moodId: String?) async throws -> Answer {
        let endpoint = AnswerEndpoint.update(
            id: answer.id.uuidString,
            content: answer.content,
            imageUrl: answer.imageURL,
            moodId: moodId
        )
        let dto: AnswerDTO = try await apiClient.request(endpoint)
        return AnswerMapper.toDomain(dto)
    }

    func delete(id: UUID) async throws {
        fatalError("Delete endpoint not implemented")
    }
}
