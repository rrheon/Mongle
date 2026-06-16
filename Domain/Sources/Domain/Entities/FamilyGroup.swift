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
    public let streakDays: Int
    /// 가족 공유 홈 배경 id (상점). nil 이면 기본(따뜻한 집) 배경.
    /// 후행 기본값 nil 로 두어 기존 호출부(수동 재구성처 포함)는 변경 없이 동작한다.
    public let appliedBackgroundId: String?

    public init(
        id: UUID,
        name: String,
        memberIds: [UUID],
        createdBy: UUID,
        createdAt: Date,
        inviteCode: String,
        memberMoodIds: [String] = [],
        streakDays: Int = 0,
        appliedBackgroundId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.memberIds = memberIds
        self.memberMoodIds = memberMoodIds
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.inviteCode = inviteCode
        self.streakDays = streakDays
        self.appliedBackgroundId = appliedBackgroundId
    }
}
