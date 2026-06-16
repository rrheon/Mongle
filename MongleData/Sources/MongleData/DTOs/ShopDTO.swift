//
//  ShopDTO.swift
//  Mongle
//
//  상점(Shop) 데이터 전송 객체. 서버 /shop/* 엔드포인트 응답 형식.
//  서버 스키마가 아직 확정되지 않았으므로 옵셔널을 관대하게 둔다.
//

import Foundation

/// 카탈로그 아이템.
struct ShopItemDTO: Decodable {
    let id: String
    let kind: String          // "background" | "decoration"
    let name: String
    let price: Int
    let assetName: String?
    let slot: String?         // "head" | "back" | "feet"
    let isSeasonal: Bool?
    let sortOrder: Int?
}

/// 슬롯별 장착 장식 id.
struct EquippedDecorationsDTO: Decodable {
    let head: String?
    let back: String?
    let feet: String?
}

/// 사용자 보유/장착 현황.
struct ShopInventoryDTO: Decodable {
    let ownedDecorationIds: [String]?
    let equippedDecorations: EquippedDecorationsDTO?
    let ownedBackgroundIds: [String]?
    let appliedBackgroundId: String?
}

/// 구매 응답. 서버가 하트 차감 후 남은 하트 수를 반환한다.
struct PurchaseResponseDTO: Decodable {
    let heartsRemaining: Int
}

/// 장착 응답. 갱신된 장착 현황을 반환한다.
struct EquipResponseDTO: Decodable {
    let equippedDecorations: EquippedDecorationsDTO?
}
