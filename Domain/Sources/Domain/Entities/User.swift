//
//  User.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import Foundation

public struct User: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let email: String
    public let name: String
    public let profileImageURL: String?
    public let role: FamilyRole
    public let hearts: Int
    public let moodId: String?
    public let createdAt: Date
    /// 서버 /users/me?grantDailyHeart=true 응답에서 "이번 요청에 데일리 하트(+1)
    /// 가 발생했는지" 플래그. RootFeature 가 이 값으로만 데일리 하트 팝업을
    /// 띄운다 (UserDefaults 자체 카운터 제거, MG-77). opt-in 미포함 호출
    /// (QuestionDetail/ProfileEdit hearts sync 등)에서는 항상 false.
    public let heartGrantedToday: Bool

    public init(
        id: UUID,
        email: String,
        name: String,
        profileImageURL: String?,
        role: FamilyRole,
        hearts: Int = 0,
        moodId: String? = "loved",
        createdAt: Date,
        heartGrantedToday: Bool = false
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.profileImageURL = profileImageURL
        self.role = role
        self.hearts = hearts
        self.moodId = moodId
        self.createdAt = createdAt
        self.heartGrantedToday = heartGrantedToday
    }
}

public enum FamilyRole: String, Sendable, Equatable {
    case father = "아빠"
    case mother = "엄마"
    case son = "아들"
    case daughter = "딸"
    case other = "기타"
}
