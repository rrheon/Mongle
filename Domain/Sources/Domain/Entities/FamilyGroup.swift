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
    public let createdBy: UUID
    public let createdAt: Date
    public let inviteCode: String
    public let groupProgressID: UUID

    public init(
        id: UUID,
        name: String,
        memberIds: [UUID],
        createdBy: UUID,
        createdAt: Date,
        inviteCode: String,
        treeProgressId: UUID
    ) {
        self.id = id
        self.name = name
        self.memberIds = memberIds
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.inviteCode = inviteCode
        self.groupProgressID = treeProgressId
    }
}
