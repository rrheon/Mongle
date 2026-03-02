//
//  HomeFeature.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct HomeFeature {
    @ObservableState
    public struct State: Equatable {
        public var todayQuestion: Question?
        public var familyTree: TreeProgress = TreeProgress()
        public var family: MongleGroup?
        public var familyMembers: [User] = []
        public var currentUser: User?
        public var isLoading = false
        public var isRefreshing = false
        public var errorMessage: String?
        public var hasFamily: Bool { family != nil }
        public var hasAnsweredToday: Bool = false
        public var familyAnswerCount: Int
        // 각 멤버별 답변 상태 (userId: hasAnswered)
        public var memberAnswerStatus: [UUID: Bool] = [:]

        public init(
            todayQuestion: Question? = nil,
            familyTree: TreeProgress = TreeProgress(),
            family: MongleGroup? = nil,
            familyMembers: [User] = [],
            currentUser: User? = nil,
            isLoading: Bool = false,
            isRefreshing: Bool = false,
            errorMessage: String? = nil,
            hasAnsweredToday: Bool = false,
            familyAnswerCount: Int = 0,
            memberAnswerStatus: [UUID: Bool] = [:]
        ) {
            self.todayQuestion = todayQuestion
            self.familyTree = familyTree
            self.family = family
            self.familyMembers = familyMembers
            self.currentUser = currentUser
            self.isLoading = isLoading
            self.isRefreshing = isRefreshing
            self.errorMessage = errorMessage
            self.hasAnsweredToday = hasAnsweredToday
            self.familyAnswerCount = familyAnswerCount
            self.memberAnswerStatus = memberAnswerStatus
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case onAppear
        case questionTapped
        case refreshData
        case createFamilyTapped
        case joinFamilyTapped
        case dismissError

        // MARK: - Internal Actions
        case setLoading(Bool)
        case setRefreshing(Bool)
        case setError(String?)

        // MARK: - Delegate Actions (상위 Feature에서 처리)
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case navigateToQuestionDetail(Question)
            case navigateToCreateFamily
            case navigateToJoinFamily
            case requestRefresh
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - View Actions
            case .onAppear:
                // 데이터가 없으면 로딩 요청
                if state.todayQuestion == nil && !state.isLoading {
                    state.isLoading = true
                    return .send(.delegate(.requestRefresh))
                }
                return .none

            case .questionTapped:
                guard let question = state.todayQuestion else { return .none }
                return .send(.delegate(.navigateToQuestionDetail(question)))

            case .refreshData:
                guard !state.isRefreshing else { return .none }
                state.isRefreshing = true
                state.errorMessage = nil
                return .send(.delegate(.requestRefresh))

            case .createFamilyTapped:
                return .send(.delegate(.navigateToCreateFamily))

            case .joinFamilyTapped:
                return .send(.delegate(.navigateToJoinFamily))

            case .dismissError:
                state.errorMessage = nil
                return .none

            // MARK: - Internal Actions
            case .setLoading(let isLoading):
                state.isLoading = isLoading
                if !isLoading {
                    state.isRefreshing = false
                }
                return .none

            case .setRefreshing(let isRefreshing):
                state.isRefreshing = isRefreshing
                return .none

            case .setError(let message):
                state.errorMessage = message
                state.isLoading = false
                state.isRefreshing = false
                return .none

            // MARK: - Delegate Actions
            case .delegate:
                // 상위 Feature에서 처리
                return .none
            }
        }
    }
}

