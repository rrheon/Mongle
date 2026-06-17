//
//  ShopMapper.swift
//  Mongle
//
//  Shop DTO ↔ Domain 매핑. kind/slot 문자열은 enum 으로 switch 변환 (UserMapper 패턴).
//

import Foundation
import Domain

struct ShopMapper {
    static func toDomain(_ dto: ShopItemDTO) -> ShopItem {
        ShopItem(
            id: dto.id,
            kind: kind(from: dto.kind),
            name: dto.name,
            price: dto.price,
            assetName: dto.assetName,
            slot: slot(from: dto.slot),
            isSeasonal: dto.isSeasonal ?? false,
            sortOrder: dto.sortOrder ?? 0
        )
    }

    static func toDomain(_ dto: ShopInventoryDTO) -> ShopInventory {
        ShopInventory(
            ownedDecorationIds: Set(dto.ownedDecorationIds ?? []),
            equippedDecorationId: dto.equippedDecorationId,
            ownedBackgroundIds: Set(dto.ownedBackgroundIds ?? []),
            appliedBackgroundId: dto.appliedBackgroundId
        )
    }

    private static func kind(from raw: String) -> ShopItemKind {
        switch raw.lowercased() {
        case "background": return .background
        default:           return .decoration
        }
    }

    private static func slot(from raw: String?) -> DecorationSlot? {
        guard let raw else { return nil }
        switch raw.lowercased() {
        case "head": return .head
        case "hand": return .hand
        case "back": return .back
        case "feet": return .feet
        default:     return nil
        }
    }
}
