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
}
