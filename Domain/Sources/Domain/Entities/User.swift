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

    public init(
        id: UUID,
        email: String,
        name: String,
        profileImageURL: String?,
        role: FamilyRole,
        hearts: Int = 0,
        moodId: String? = "loved",
        createdAt: Date
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.profileImageURL = profileImageURL
        self.role = role
        self.hearts = hearts
        self.moodId = moodId
        self.createdAt = createdAt
    }
}

public enum FamilyRole: String, Sendable, Equatable {
    case father = "아빠"
    case mother = "엄마"
    case son = "아들"
    case daughter = "딸"
    case other = "기타"
}
