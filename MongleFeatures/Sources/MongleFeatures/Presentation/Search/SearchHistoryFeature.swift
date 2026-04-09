//
//  SearchHistoryFeature.swift
//  MongleFeatures
//

import Foundation
import ComposableArchitecture
import Domain

// MARK: - Search Helpers

private extension String {
    /// 검색 매칭용 정규화: 한글 NFC 변환 + 소문자.
    /// iOS 한글 입력은 종종 NFD(자모 분해) 로 들어오는데, 서버 저장값은 NFC(완성형) 이어서
    /// `.contains` 만으로는 매칭이 실패할 수 있다. 양쪽 모두 NFC 로 맞춰 substring 매칭을 안정화한다.
    func normalizedForSearch() -> String {
        return self.precomposedStringWithCanonicalMapping.lowercased()
    }
}

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

        // loaded history cache — 그룹별로 분리되어야 하므로 familyId 함께 보관
        public var allHistory: [HistoryQuestion] = []
        public var loadedFamilyId: String? = nil

        public var resultCount: Int { results.count }

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        case onAppear
        case performLoad
        case queryChanged(String)
        case historyLoaded([HistoryQuestion])
        case performSearch(String)
        case setError(String?)
        /// 외부(그룹 전환 등) 에서 검색 캐시를 무효화할 때 사용
        case reset
        /// 현재 활성 familyId 를 알려주고, 다르면 재로드
        case setActiveFamily(String?)
    }

    @Dependency(\.questionRepository) var questionRepository

    private enum SearchDebounceID { case search }
    private enum LoadID { case load }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                // 항상 최신 히스토리로 재로드. (다른 탭에서 답변/그룹 변경 후 돌아온 경우 대응)
                return .send(.performLoad)

            case .performLoad:
                state.isLoading = true
                state.errorMessage = nil
                return .run { [questionRepository] send in
                    do {
                        let history = try await questionRepository.getHistory(page: 1, limit: 100)
                        await send(.historyLoaded(history))
                    } catch {
                        await send(.setError(error.localizedDescription))
                    }
                }
                .cancellable(id: LoadID.load, cancelInFlight: true)

            case .historyLoaded(let history):
                state.allHistory = history
                state.isLoading = false
                // 로드 중에 사용자가 이미 검색어를 입력해 뒀다면 재검색
                let pending = state.query.trimmingCharacters(in: .whitespaces)
                if pending.count >= 2 {
                    return .send(.performSearch(state.query))
                }
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
                // 아직 히스토리 로딩 중이라면 결과를 비우지 않고 대기 (historyLoaded 후 재검색됨)
                if state.isLoading && state.allHistory.isEmpty {
                    return .none
                }
                // 한글 NFC/NFD 차이로 매칭이 실패하는 것을 막기 위해 양쪽 모두 NFC + 소문자 정규화
                let normalizedQuery = trimmed.normalizedForSearch()
                var results: [SearchResultItem] = []

                #if DEBUG
                print("[SearchHistory] performSearch query=\(trimmed) allHistory.count=\(state.allHistory.count)")
                #endif

                for hq in state.allHistory {
                    // 오늘 질문: "내가 답변" 하지 않았으면 검색 결과에서 제외.
                    // (답변 했거나, 건너뛴(skip) 경우에는 검색에 노출)
                    if Calendar.current.isDateInToday(hq.date) && !(hq.hasMyAnswer || hq.hasMySkipped) {
                        continue
                    }

                    let questionMatches = hq.question.content.normalizedForSearch().contains(normalizedQuery)
                    let matchedAnswers = hq.answers.filter { answer in
                        answer.content.normalizedForSearch().contains(normalizedQuery) ||
                        answer.userName.normalizedForSearch().contains(normalizedQuery)
                    }
                    // 질문이 매칭되든, 답변이 매칭되든 — 하나라도 걸리면 결과 카드를 만든다.
                    // 카드는 항상 질문(questionContent) 을 노출하고, 매칭된 답변이 있으면 함께 보여준다.
                    if questionMatches || !matchedAnswers.isEmpty {
                        #if DEBUG
                        print("[SearchHistory] match: q=\"\(hq.question.content)\" answersCount=\(hq.answers.count) matchedAnswers=\(matchedAnswers.count) questionMatches=\(questionMatches)")
                        #endif
                        results.append(SearchResultItem(
                            id: hq.dailyQuestionId,
                            date: hq.date,
                            questionContent: hq.question.content,
                            // 질문이 매칭되면 모든 답변 노출, 아니면 매칭된 답변만 노출
                            matchedAnswers: questionMatches ? hq.answers : matchedAnswers,
                            totalAnswerCount: hq.familyAnswerCount
                        ))
                    }
                }

                #if DEBUG
                print("[SearchHistory] total results: \(results.count)")
                #endif

                results.sort { $0.date > $1.date }
                state.results = results
                return .none

            case .setError(let message):
                state.errorMessage = message
                state.isLoading = false
                return .none

            case .reset:
                state.query = ""
                state.results = []
                state.allHistory = []
                state.loadedFamilyId = nil
                state.isLoading = false
                state.showMinLengthHint = false
                state.errorMessage = nil
                return .merge(
                    .cancel(id: LoadID.load),
                    .cancel(id: SearchDebounceID.search)
                )

            case .setActiveFamily(let familyId):
                // 그룹이 바뀌었다면 캐시를 비우고 재로드. 동일 그룹이면 no-op.
                guard state.loadedFamilyId != familyId else { return .none }
                state.allHistory = []
                state.results = []
                state.loadedFamilyId = familyId
                guard familyId != nil else {
                    state.isLoading = false
                    return .none
                }
                return .send(.performLoad)
            }
        }
    }
}
