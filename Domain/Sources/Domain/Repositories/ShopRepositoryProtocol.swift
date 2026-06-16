//
//  ShopRepositoryProtocol.swift
//  Mongle
//
//  상점 카탈로그/인벤토리 조회 및 구매·장착을 담당하는 Repository 계약.
//  구매는 서버 권위(server-authoritative): 서버가 하트를 차감한 뒤 남은 하트 수
//  (heartsRemaining)를 반환한다 (grantAdHearts 와 동일 패턴).
//

import Foundation

public protocol ShopRepositoryInterface: Sendable {
    /// 판매 중인 전체 아이템 카탈로그.
    func getCatalog() async throws -> [ShopItem]
    /// 현재 사용자의 보유/장착 현황.
    func getInventory() async throws -> ShopInventory
    /// 아이템 구매. 서버가 하트 차감 후 남은 하트 수를 반환한다.
    func purchase(itemId: String) async throws -> Int
    /// 꾸미기를 장착(itemId)하거나 해제(nil)한다. 갱신된 장착 id(미착용 nil)를 반환.
    func equipDecoration(itemId: String?) async throws -> String?
    /// 가족 공유 홈 배경을 적용한다. 갱신된 보유/적용 현황을 반환.
    /// 구매는 기존 purchase(서버 권위) 를 재사용하고, 적용만 이 메서드가 담당한다.
    func applyBackground(itemId: String) async throws -> ShopInventory
}

public enum ShopError: Error, Equatable, Sendable {
    case insufficientHearts
    case alreadyOwned
    case notOwned
    case itemNotFound
    case networkError
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .insufficientHearts:
            return "하트가 부족합니다."
        case .alreadyOwned:
            return "이미 보유한 아이템입니다."
        case .notOwned:
            return "보유하지 않은 아이템입니다."
        case .itemNotFound:
            return "아이템을 찾을 수 없습니다."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .unknown(let message):
            return message
        }
    }
}
