import XCTest
import ComposableArchitecture
import Domain
@testable import MongleFeatures

@MainActor
final class ShopFeatureTests: XCTestCase {

    private let flower = "deco_flower_crown"
    private let star = "deco_star_halo"

    private func item(_ id: String, price: Int) -> ShopItem {
        ShopItem(id: id, kind: .decoration, name: id, price: price, slot: .head, sortOrder: 1)
    }

    // MARK: - onAppear

    func testOnAppear_LoadsCatalogAndInventory() async {
        let repo = MockShopRepository()
        let catalog = [item(flower, price: 35), item(star, price: 40)]
        let inventory = ShopInventory(
            ownedDecorationIds: [flower],
            equippedDecorationId: flower
        )
        repo.catalogResult = catalog
        repo.inventoryResult = inventory

        let store = TestStore(initialState: ShopFeature.State(hearts: 50)) {
            ShopFeature()
        } withDependencies: {
            $0.shopRepository = repo
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.loaded(.success(.init(catalog: catalog, inventory: inventory)))) {
            $0.isLoading = false
            $0.catalog = catalog
            $0.inventory = inventory
        }
    }

    func testOnAppear_SkipsWhenCatalogAlreadyLoaded() async {
        let repo = MockShopRepository()
        let store = TestStore(
            initialState: ShopFeature.State(catalog: [item(flower, price: 35)])
        ) {
            ShopFeature()
        } withDependencies: {
            $0.shopRepository = repo
        }

        // 이미 카탈로그가 있으면 effect 없이 .none.
        await store.send(.onAppear)
    }

    // MARK: - decorationTapped: 소유 → equip → decorationsChanged

    func testDecorationTapped_Owned_EquipsAndDelegates() async {
        let repo = MockShopRepository()
        let store = TestStore(
            initialState: ShopFeature.State(
                hearts: 50,
                catalog: [item(flower, price: 35)],
                inventory: ShopInventory(ownedDecorationIds: [flower])
            )
        ) {
            ShopFeature()
        } withDependencies: {
            $0.shopRepository = repo
        }

        await store.send(.decorationTapped(itemId: flower)) {
            $0.isLoading = true
        }
        await store.receive(.equipResponse(.success(flower))) {
            $0.isLoading = false
            $0.inventory?.equippedDecorationId = self.flower
        }
        await store.receive(.delegate(.decorationsChanged(flower)))
    }

    // MARK: - decorationTapped: 미소유 + 하트 충분 → purchase → heartsChanged

    func testDecorationTapped_NotOwned_SufficientHearts_PurchasesAndDelegates() async {
        let repo = MockShopRepository()
        repo.purchaseHeartsRemaining = 15
        let store = TestStore(
            initialState: ShopFeature.State(
                hearts: 50,
                catalog: [item(flower, price: 35)],
                inventory: ShopInventory()
            )
        ) {
            ShopFeature()
        } withDependencies: {
            $0.shopRepository = repo
        }

        // 충분 → purchaseConfirmed 로 위임.
        await store.send(.decorationTapped(itemId: flower))
        await store.receive(.purchaseConfirmed(itemId: flower)) {
            $0.isLoading = true
        }
        await store.receive(.purchaseResponse(.success(.init(heartsRemaining: 15, equippedDecorationId: flower)))) {
            $0.isLoading = false
            $0.hearts = 15
            $0.inventory?.equippedDecorationId = self.flower
            $0.inventory?.ownedDecorationIds = [self.flower]
        }
        await store.receive(.delegate(.heartsChanged(15)))
        await store.receive(.delegate(.decorationsChanged(flower)))
    }

    // MARK: - decorationTapped: 미소유 + 하트 부족 → no-op (View 가 안내 팝업만, 충전 흐름 제거됨)

    func testDecorationTapped_NotOwned_InsufficientHearts_IsNoOp() async {
        let repo = MockShopRepository()
        let store = TestStore(
            initialState: ShopFeature.State(
                hearts: 10,
                catalog: [item(flower, price: 35)],
                inventory: ShopInventory()
            )
        ) {
            ShopFeature()
        } withDependencies: {
            $0.shopRepository = repo
        }

        // 하트 부족 → reducer 는 effect 없이 종료 (안내 팝업은 View 책임).
        await store.send(.decorationTapped(itemId: flower))
    }

    // MARK: - backgroundTapped: 보유 배경 → applyBackground → backgroundApplied

    func testBackgroundTapped_Owned_AppliesAndDelegates() async {
        let bg = "bg_spring_field"
        let repo = MockShopRepository()
        repo.applyBackgroundResult = ShopInventory(
            ownedBackgroundIds: [bg], appliedBackgroundId: bg
        )
        let store = TestStore(
            initialState: ShopFeature.State(
                activeTab: .background,
                hearts: 50,
                catalog: [ShopItem(id: bg, kind: .background, name: bg, price: 20, sortOrder: 1)],
                inventory: ShopInventory(ownedBackgroundIds: [bg])
            )
        ) {
            ShopFeature()
        } withDependencies: {
            $0.shopRepository = repo
        }

        let applied = ShopInventory(ownedBackgroundIds: [bg], appliedBackgroundId: bg)
        await store.send(.backgroundTapped(itemId: bg)) {
            $0.isLoading = true
        }
        await store.receive(.backgroundResponse(.success(.init(heartsRemaining: nil, inventory: applied)))) {
            $0.isLoading = false
            $0.inventory = applied
        }
        await store.receive(.delegate(.backgroundApplied(bg)))
    }

    // MARK: - decorationTapped: 장착중 재탭 → 해제(equip nil)

    func testDecorationTapped_AlreadyEquipped_Unequips() async {
        let repo = MockShopRepository()
        let store = TestStore(
            initialState: ShopFeature.State(
                hearts: 50,
                catalog: [item(flower, price: 35)],
                inventory: ShopInventory(
                    ownedDecorationIds: [flower],
                    equippedDecorationId: flower
                )
            )
        ) {
            ShopFeature()
        } withDependencies: {
            $0.shopRepository = repo
        }

        // 장착중 재탭 → 해제(itemId nil). Mock 은 요청 itemId(nil) 를 그대로 반환.
        await store.send(.decorationTapped(itemId: flower)) {
            $0.isLoading = true
        }
        await store.receive(.equipResponse(.success(nil))) {
            $0.isLoading = false
            $0.inventory?.equippedDecorationId = nil
        }
        await store.receive(.delegate(.decorationsChanged(nil)))
    }
}
