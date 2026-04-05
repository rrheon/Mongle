//
//  DailyQuestionRepository.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Domain

final class DailyQuestionRepository: DailyQuestionRepositoryInterface {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func create(_ dailyQuestion: DailyQuestion) async throws -> DailyQuestion {
        let formatter = ISO8601DateFormatter()
        let endpoint = DailyQuestionEndpoint.create(
            familyId: dailyQuestion.familyId.uuidString,
            questionId: dailyQuestion.questionId.uuidString,
            questionOrder: dailyQuestion.questionOrder,
            date: formatter.string(from: dailyQuestion.date)
        )
        let dailyQuestionDTO: DailyQuestionDTO = try await apiClient.request(endpoint)
        return DailyQuestionMapper.toDomain(dailyQuestionDTO)
    }

    func get(id: UUID) async throws -> DailyQuestion {
        let endpoint = DailyQuestionEndpoint.get(id: id.uuidString)
        let dailyQuestionDTO: DailyQuestionDTO = try await apiClient.request(endpoint)
        return DailyQuestionMapper.toDomain(dailyQuestionDTO)
    }

    func getByFamilyAndDate(familyId: UUID, date: Date) async throws -> DailyQuestion? {
        let formatter = ISO8601DateFormatter()
        let endpoint = DailyQuestionEndpoint.getByFamilyAndDate(
            familyId: familyId.uuidString,
            date: formatter.string(from: date)
        )
        let dailyQuestionDTO: DailyQuestionDTO? = try? await apiClient.request(endpoint)
        return dailyQuestionDTO.map { DailyQuestionMapper.toDomain($0) }
    }

    func getHistoryByFamily(familyId: UUID, limit: Int?) async throws -> [DailyQuestion] {
        let endpoint = DailyQuestionEndpoint.getHistoryByFamily(
            familyId: familyId.uuidString,
            limit: limit
        )
        let dailyQuestionDTOs: [DailyQuestionDTO] = try await apiClient.request(endpoint)
        return dailyQuestionDTOs.map { DailyQuestionMapper.toDomain($0) }
    }

    func getLastQuestionOrder(familyId: UUID) async throws -> Int? {
        let history = try await getHistoryByFamily(familyId: familyId, limit: 1)
        return history.first?.questionOrder
    }

    func update(_ dailyQuestion: DailyQuestion) async throws -> DailyQuestion {
        let endpoint = DailyQuestionEndpoint.update(
            id: dailyQuestion.id.uuidString,
            isCompleted: dailyQuestion.isCompleted,
            answerIds: dailyQuestion.answerIds.map { $0.uuidString }
        )
        let dailyQuestionDTO: DailyQuestionDTO = try await apiClient.request(endpoint)
        return DailyQuestionMapper.toDomain(dailyQuestionDTO)
    }

    func delete(id: UUID) async throws {
        throw DailyQuestionError.unknown("Delete endpoint not supported")
    }

    func getCompletedByFamily(familyId: UUID) async throws -> [DailyQuestion] {
        let all = try await getHistoryByFamily(familyId: familyId, limit: nil)
        return all.filter { $0.isCompleted }
    }

    func getIncompleteByFamily(familyId: UUID) async throws -> [DailyQuestion] {
        let all = try await getHistoryByFamily(familyId: familyId, limit: nil)
        return all.filter { !$0.isCompleted }
    }
}
