//
//  Family.swift
//  Mongle
//
//  Created by 최용헌 on 12/10/25.
//

import Foundation

public struct MongleGroup: Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let memberIds: [UUID]
    public let memberMoodIds: [String]
    public let createdBy: UUID
    public let createdAt: Date
    public let inviteCode: String

    public init(
        id: UUID,
        name: String,
        memberIds: [UUID],
        createdBy: UUID,
        createdAt: Date,
        inviteCode: String,
        memberMoodIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.memberIds = memberIds
        self.memberMoodIds = memberMoodIds
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.inviteCode = inviteCode
    }
}
