//
//  Member.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import Foundation

public struct Member: Equatable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let familyId: UUID
    public let role: FamilyRole
    public let joinedAt: Date
    public let isActive: Bool

    public init(
        id: UUID,
        userId: UUID,
        familyId: UUID,
        role: FamilyRole,
        joinedAt: Date,
        isActive: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.familyId = familyId
        self.role = role
        self.joinedAt = joinedAt
        self.isActive = isActive
    }
}
