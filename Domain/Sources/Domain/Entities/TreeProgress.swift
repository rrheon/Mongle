//
//  TreeProgress.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import Foundation

public struct TreeProgress: Equatable, Sendable {
    public let id: UUID
    public let familyId: UUID
    public let stage: TreeStage
    public let totalAnswers: Int
    public let consecutiveDays: Int
    public let badgeIds: [UUID]
    public let lastUpdated: Date

    public init(
        id: UUID = UUID(),
        familyId: UUID = UUID(),
        stage: TreeStage = .seed,
        totalAnswers: Int = 0,
        consecutiveDays: Int = 0,
        badgeIds: [UUID] = [],
        lastUpdated: Date = .now
    ) {
        self.id = id
        self.familyId = familyId
        self.stage = stage
        self.totalAnswers = totalAnswers
        self.consecutiveDays = consecutiveDays
        self.badgeIds = badgeIds
        self.lastUpdated = lastUpdated
    }
}

public enum TreeStage: Int, Sendable, Equatable {
    case seed = 0
    case sprout = 1
    case sapling = 2
    case youngTree = 3
    case matureTree = 4
    case flowering = 5
    case bound = 6
}

