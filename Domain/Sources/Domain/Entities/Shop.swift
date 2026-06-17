//
//  Shop.swift
//  Mongle
//
//  상점(Shop) 도메인 모델. 배경(background)과 장식(decoration) 두 종류를 표현하지만
//  MVP 기능 범위는 "꾸미기(장식) · 머리(head) 슬롯" 만 노출한다. 데이터 모델은
//  배경/등/발밑까지 확장 가능하게 둔다 (2차 작업 대비).
//

import Foundation

/// 상점 아이템의 종류.
public enum ShopItemKind: String, Sendable, Equatable {
    case background
    case decoration
}

/// 장식이 얹히는 캐릭터 슬롯. MVP 에서는 head 만 활성, back/feet 는 노출만 하고 비활성.
public enum DecorationSlot: String, Sendable, Equatable, CaseIterable {
    case head
    case back
    case feet
}

/// 상점에서 판매되는 단일 아이템.
public struct ShopItem: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let kind: ShopItemKind
    public let name: String
    public let price: Int
    /// PNG/asset 이름 또는 SwiftUI 뷰 매핑 키. nil 이면 클라가 id 로 매핑한다.
    public let assetName: String?
    /// kind == .decoration 일 때 어느 슬롯인지. background 면 nil.
    public let slot: DecorationSlot?
    /// 시즌 한정 아이템 여부 (산타 모자 등).
    public let isSeasonal: Bool
    /// 그리드 정렬 순서.
    public let sortOrder: Int

    public init(
        id: String,
        kind: ShopItemKind,
        name: String,
        price: Int,
        assetName: String? = nil,
        slot: DecorationSlot? = nil,
        isSeasonal: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.price = price
        self.assetName = assetName
        self.slot = slot
        self.isSeasonal = isSeasonal
        self.sortOrder = sortOrder
    }
}

/// 사용자의 상점 보유/장착 현황.
public struct ShopInventory: Equatable, Sendable {
    public var ownedDecorationIds: Set<String>
    /// 현재 장착 중인 꾸미기 1개(전역 단일). nil = 미착용. slot 은 카탈로그 item.slot 에서 조회.
    public var equippedDecorationId: String?
    public var ownedBackgroundIds: Set<String>
    public var appliedBackgroundId: String?

    public init(
        ownedDecorationIds: Set<String> = [],
        equippedDecorationId: String? = nil,
        ownedBackgroundIds: Set<String> = [],
        appliedBackgroundId: String? = nil
    ) {
        self.ownedDecorationIds = ownedDecorationIds
        self.equippedDecorationId = equippedDecorationId
        self.ownedBackgroundIds = ownedBackgroundIds
        self.appliedBackgroundId = appliedBackgroundId
    }
}
