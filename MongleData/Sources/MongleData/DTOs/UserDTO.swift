//
//  UserDTO.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation

/// 사용자 데이터 전송 객체 (서버 camelCase 형식)
struct UserDTO: Codable {
    let id: String
    let email: String
    let name: String
    let profileImageUrl: String?
    let role: String
    let familyId: String?
    let hearts: Int?
    let moodId: String?
    let createdAt: String
    /// v2 PRD §3.3 — streak 위험 푸시 옵트아웃. nil 이면 서버 기본값(true).
    let streakRiskNotify: Bool?
    /// v2 PRD §9 — 배지 획득 푸시 옵트아웃. 인앱 팝업과 무관하게 푸시 전송 여부만 제어.
    let badgeEarnedNotify: Bool?
}
