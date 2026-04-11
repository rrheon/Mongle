//
//  CharacterStageDTO.swift
//  MongleData
//
//  v2 PRD §2.2 — `GET /users/me/character-stage` 응답 매핑.
//

import Foundation

struct CharacterStageDTO: Decodable {
    let stage: Int
    let stageKey: String
    let streakDays: Int
    let nextStageStreak: Int?
    let sizeMultiplier: Double
}
