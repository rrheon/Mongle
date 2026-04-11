//
//  CharacterStageMapper.swift
//  MongleData
//

import Foundation
import Domain

struct CharacterStageMapper {
    static func toDomain(_ dto: CharacterStageDTO) -> CharacterStage {
        CharacterStage(
            stage: dto.stage,
            stageKey: dto.stageKey,
            streakDays: dto.streakDays,
            nextStageStreak: dto.nextStageStreak,
            sizeMultiplier: dto.sizeMultiplier
        )
    }
}
