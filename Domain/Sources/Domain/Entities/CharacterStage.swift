//
//  CharacterStage.swift
//  Domain
//
//  v2 PRD §2.2 — 캐릭터 성장 단계 도메인 모델.
//

import Foundation

public struct CharacterStage: Equatable, Sendable {
    public let stage: Int
    public let stageKey: String
    public let streakDays: Int
    public let nextStageStreak: Int?
    public let sizeMultiplier: Double

    public init(
        stage: Int,
        stageKey: String,
        streakDays: Int,
        nextStageStreak: Int?,
        sizeMultiplier: Double
    ) {
        self.stage = stage
        self.stageKey = stageKey
        self.streakDays = streakDays
        self.nextStageStreak = nextStageStreak
        self.sizeMultiplier = sizeMultiplier
    }
}
