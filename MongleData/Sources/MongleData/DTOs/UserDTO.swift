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
    /// /users/me?grantDailyHeart=true 응답에서 활성 그룹 데일리 하트(+1)가
    /// 이번 요청에 발생했는지 표시. opt-in 미포함 호출이거나 구버전 서버
    /// 응답이면 nil 또는 false. (서버 변경: MG-80, 클라 사용처: MG-77)
    let heartGrantedToday: Bool?
}
