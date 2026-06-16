//
//  ShopRepository.swift
//  Mongle
//
//  TODO(server): /shop/* 엔드포인트 미구현 — 라이브 동작은 서버 작업 필요.
//  계약(getCatalog/getInventory/purchase/equipDecoration)은 ShopRepositoryInterface
//  를 그대로 따른다. 프리뷰/테스트는 MockShopRepository 로 동작한다.
//

import Foundation
import Domain

final class ShopRepository: ShopRepositoryInterface {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func getCatalog() async throws -> [ShopItem] {
        let dtos: [ShopItemDTO] = try await apiClient.request(ShopEndpoint.getCatalog)
        return dtos.map(ShopMapper.toDomain).sorted { $0.sortOrder < $1.sortOrder }
    }

    func getInventory() async throws -> ShopInventory {
        let dto: ShopInventoryDTO = try await apiClient.request(ShopEndpoint.getInventory)
        return ShopMapper.toDomain(dto)
    }

    func purchase(itemId: String) async throws -> Int {
        let response: PurchaseResponseDTO = try await apiClient.request(ShopEndpoint.purchase(itemId: itemId))
        return response.heartsRemaining
    }

    func equipDecoration(itemId: String?) async throws -> String? {
        let response: EquipResponseDTO = try await apiClient.request(
            ShopEndpoint.equipDecoration(itemId: itemId)
        )
        return response.equippedDecorationId
    }

    // TODO(server): /shop/background/apply 미구현 — 응답은 갱신된 ShopInventory 를 가정한다.
    func applyBackground(itemId: String) async throws -> ShopInventory {
        let dto: ShopInventoryDTO = try await apiClient.request(ShopEndpoint.applyBackground(itemId: itemId))
        return ShopMapper.toDomain(dto)
    }
}
