//
//  SearchHistoryFeature.swift
//  MongleFeatures
//

import Foundation
import ComposableArchitecture
import Domain

// MARK: - Search Result

public struct SearchResultItem: Equatable, Identifiable, Sendable {
    public let id: String  // dailyQuestionId
    public let date: Date
    public let questionContent: String
    public let matchedAnswers: [HistoryQuestion.HistoryAnswerSummary]
    public let totalAnswerCount: Int
}

// MARK: - Feature

@Reducer
public struct SearchHistoryFeature {

    @ObservableState
    public struct State: Equatable {
        public var query: String = ""
        public var results: [SearchResultItem] = []
        public var isLoading: Bool = false
        public var showMinLengthHint: Bool = false
        public var errorMessage: String? = nil

        // loaded history cache
        public var allHistory: [HistoryQuestion] = []

        public var resultCount: Int { results.count }

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        case onAppear
        case queryChanged(String)
        case historyLoaded([HistoryQuestion])
        case performSearch(String)
        case setError(String?)
    }

    @Dependency(\.questionRepository) var questionRepository

    private enum SearchDebounceID { case search }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                guard state.allHistory.isEmpty else { return .none }
                state.isLoading = true
                return .run { [questionRepository] send in
                    do {
                        let history = try await questionRepository.getHistory(page: 1, limit: 100)
                        await send(.historyLoaded(history))
                    } catch {
                        await send(.setError(error.localizedDescription))
                    }
                }

            case .historyLoaded(let history):
                state.allHistory = history
                state.isLoading = false
                return .none

            case .queryChanged(let query):
                state.query = query
                state.showMinLengthHint = !query.isEmpty && query.trimmingCharacters(in: .whitespaces).count < 2
                return .run { send in
                    try await Task.sleep(nanoseconds: 400_000_000)
                    await send(.performSearch(query))
                }
                .cancellable(id: SearchDebounceID.search, cancelInFlight: true)

            case .performSearch(let query):
                let trimmed = query.trimmingCharacters(in: .whitespaces)
                guard trimmed.count >= 2 else {
                    state.results = []
                    return .none
                }
                let lowerQuery = trimmed.lowercased()
                var results: [SearchResultItem] = []

                for hq in state.allHistory {
                    let questionMatches = hq.question.content.lowercased().contains(lowerQuery)
                    let matchedAnswers = hq.answers.filter { answer in
                        answer.content.lowercased().contains(lowerQuery) ||
                        answer.userName.lowercased().contains(lowerQuery)
                    }
                    if questionMatches || !matchedAnswers.isEmpty {
                        results.append(SearchResultItem(
                            id: hq.dailyQuestionId,
                            date: hq.date,
                            questionContent: hq.question.content,
                            matchedAnswers: questionMatches ? hq.answers : matchedAnswers,
                            totalAnswerCount: hq.familyAnswerCount
                        ))
                    }
                }

                results.sort { $0.date > $1.date }
                state.results = results
                return .none

            case .setError(let message):
                state.errorMessage = message
                state.isLoading = false
                return .none
            }
        }
    }
}
