//
//  TreeFeature.swift
//  Mongle
//
//  Created by Claude on 2025-01-06.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct TreeFeature {
    @ObservableState
    public struct State: Equatable {
        public var treeProgress: TreeProgress?
        public var familyMembers: [User] = []
        public var isLoading: Bool = false
        public var errorMessage: String?

        // Computed properties
        public var currentStage: TreeStage {
            treeProgress?.stage ?? .seed
        }

        public var totalAnswers: Int {
            treeProgress?.totalAnswers ?? 0
        }

        public var consecutiveDays: Int {
            treeProgress?.consecutiveDays ?? 0
        }

        public var nextStageProgress: Double {
            guard let progress = treeProgress else { return 0 }
            let answersForNextStage = answersRequiredForStage(progress.stage.rawValue + 1)
            let answersForCurrentStage = answersRequiredForStage(progress.stage.rawValue)
            let needed = answersForNextStage - answersForCurrentStage
            let current = progress.totalAnswers - answersForCurrentStage
            return min(1.0, Double(current) / Double(needed))
        }

        public var answersUntilNextStage: Int {
            guard let progress = treeProgress else { return 0 }
            let nextStageAnswers = answersRequiredForStage(progress.stage.rawValue + 1)
            return max(0, nextStageAnswers - progress.totalAnswers)
        }

        public var isMaxStage: Bool {
            currentStage == .flowering
        }

        private func answersRequiredForStage(_ stageValue: Int) -> Int {
            // 각 단계별 필요한 총 답변 수
            switch stageValue {
            case 0: return 0      // seed
            case 1: return 5      // sprout
            case 2: return 15     // sapling
            case 3: return 30     // youngTree
            case 4: return 60     // matureTree
            case 5: return 100    // flowering
            default: return 100
            }
        }

        public init(
            treeProgress: TreeProgress? = nil,
            familyMembers: [User] = [],
            isLoading: Bool = false,
            errorMessage: String? = nil
        ) {
            self.treeProgress = treeProgress
            self.familyMembers = familyMembers
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case onAppear
        case refreshTapped
        case dismissErrorTapped

        // MARK: - Internal Actions
        case loadDataResponse(Result<LoadedData, TreeError>)
    }

    public struct LoadedData: Equatable, Sendable {
        public let treeProgress: TreeProgress
        public let familyMembers: [User]

        public init(treeProgress: TreeProgress, familyMembers: [User]) {
            self.treeProgress = treeProgress
            self.familyMembers = familyMembers
        }
    }

    public enum TreeError: Error, Equatable, Sendable {
        case networkError
        case unknown(String)

        var localizedDescription: String {
            switch self {
            case .networkError:
                return "네트워크 연결을 확인해주세요."
            case .unknown(let message):
                return message
            }
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.treeProgress == nil else { return .none }
                state.isLoading = true
                return .run { send in
                    // TODO: 실제 API 호출로 교체
                    try await Task.sleep(nanoseconds: 500_000_000)

                    let mockTreeProgress = TreeProgress(
                        id: UUID(),
                        familyId: UUID(),
                        stage: .youngTree,
                        totalAnswers: 35,
                        consecutiveDays: 7,
                        badgeIds: [],
                        lastUpdated: .now
                    )

                    let mockMembers = [
                        User(id: UUID(), email: "dad@example.com", name: "아빠", profileImageURL: nil, role: .father, createdAt: .now),
                        User(id: UUID(), email: "mom@example.com", name: "엄마", profileImageURL: nil, role: .mother, createdAt: .now),
                        User(id: UUID(), email: "me@example.com", name: "나", profileImageURL: nil, role: .son, createdAt: .now)
                    ]

                    await send(.loadDataResponse(.success(LoadedData(
                        treeProgress: mockTreeProgress,
                        familyMembers: mockMembers
                    ))))
                }

            case .refreshTapped:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    try await Task.sleep(nanoseconds: 500_000_000)

                    let mockTreeProgress = TreeProgress(
                        id: UUID(),
                        familyId: UUID(),
                        stage: .youngTree,
                        totalAnswers: 35,
                        consecutiveDays: 7,
                        badgeIds: [],
                        lastUpdated: .now
                    )

                    let mockMembers = [
                        User(id: UUID(), email: "dad@example.com", name: "아빠", profileImageURL: nil, role: .father, createdAt: .now),
                        User(id: UUID(), email: "mom@example.com", name: "엄마", profileImageURL: nil, role: .mother, createdAt: .now),
                        User(id: UUID(), email: "me@example.com", name: "나", profileImageURL: nil, role: .son, createdAt: .now)
                    ]

                    await send(.loadDataResponse(.success(LoadedData(
                        treeProgress: mockTreeProgress,
                        familyMembers: mockMembers
                    ))))
                }

            case .dismissErrorTapped:
                state.errorMessage = nil
                return .none

            case .loadDataResponse(.success(let data)):
                state.isLoading = false
                state.treeProgress = data.treeProgress
                state.familyMembers = data.familyMembers
                return .none

            case .loadDataResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}
