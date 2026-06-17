//
//  ShopFeature.swift
//  MongleFeatures
//
//  상점 화면 reducer. 최상위 탭(배경/꾸미기) + 꾸미기 슬롯(머리/등/발밑) 을 모두 다룬다.
//
//  - 구매는 서버 권위: 서버가 하트 차감 후 heartsRemaining 반환 (grantAdHearts 패턴).
//  - decorationTapped (꾸미기 탭):
//      · 이미 장착된 아이템 재탭  → 해제(equip nil)
//      · 보유한 아이템           → 장착(equip)
//      · 미보유 + 하트 충분       → 구매 후 장착(purchase → equip)
//      · 미보유 + 하트 부족       → View 가 정보성 안내 팝업만 표시 (충전 흐름 없음)
//  - backgroundTapped (배경 탭):
//      · 보유 배경 → 적용(applyBackground)
//      · 미보유 + 하트 충분 → 구매 후 적용(purchase → applyBackground)
//      · 미보유 + 하트 부족 → View 가 안내 팝업만 표시
//  - 하트 잔액은 서버상 그룹별이지만 iOS 클라는 home.hearts 단일 소스만 갱신한다.
//  - 하트 "충전" UI/흐름은 상점에서 제거됨 (하트는 답변/광고로만 모음).
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct ShopFeature {

    /// 상점 최상위 탭. 배경(가족 공유) / 꾸미기(장식 슬롯) 로 분리.
    public enum ShopTab: String, Equatable, Sendable, CaseIterable {
        case background
        case decoration
    }

    private enum CancelID: Hashable {
        case load
        case mutate
    }

    @ObservableState
    public struct State: Equatable {
        /// 현재 활성 최상위 탭.
        public var activeTab: ShopTab
        /// 꾸미기 탭에서 현재 활성 슬롯 (머리/등/발밑).
        public var activeSlot: DecorationSlot
        public var hearts: Int
        public var catalog: [ShopItem]
        public var inventory: ShopInventory?
        public var isLoading: Bool
        public var appError: AppError?

        public init(
            activeTab: ShopTab = .decoration,
            activeSlot: DecorationSlot = .head,
            hearts: Int = 0,
            catalog: [ShopItem] = [],
            inventory: ShopInventory? = nil
        ) {
            self.activeTab = activeTab
            self.activeSlot = activeSlot
            self.hearts = hearts
            self.catalog = catalog
            self.inventory = inventory
            self.isLoading = false
            self.appError = nil
        }

        /// 현재 활성 슬롯의 장식 아이템들 (sortOrder 순).
        public var slotDecorations: [ShopItem] {
            catalog
                .filter { $0.kind == .decoration && $0.slot == activeSlot }
                .sorted { $0.sortOrder < $1.sortOrder }
        }

        /// 배경 아이템들 (sortOrder 순).
        public var backgrounds: [ShopItem] {
            catalog
                .filter { $0.kind == .background }
                .sorted { $0.sortOrder < $1.sortOrder }
        }

        /// 현재 장착 중인 장식 id (전역 단일).
        public var equippedDecorationId: String? {
            inventory?.equippedDecorationId
        }

        public var appliedBackgroundId: String? {
            inventory?.appliedBackgroundId
        }

        public func isOwned(_ itemId: String) -> Bool {
            inventory?.ownedDecorationIds.contains(itemId) ?? false
        }

        public func isBackgroundOwned(_ itemId: String) -> Bool {
            // 가격 0(기본 배경) 은 항상 보유한 것으로 취급.
            if let item = catalog.first(where: { $0.id == itemId }), item.price == 0 { return true }
            return inventory?.ownedBackgroundIds.contains(itemId) ?? false
        }
    }

    public enum Action: Equatable {
        case onAppear
        case loaded(Result<LoadResult, AppError>)
        case tabSelected(ShopTab)
        case slotSelected(DecorationSlot)
        /// 그리드 타일 탭 (꾸미기). nil 이면 "장식 없음"(해제).
        case decorationTapped(itemId: String?)
        case equipResponse(Result<String?, AppError>)
        case purchaseConfirmed(itemId: String)
        case purchaseResponse(Result<PurchaseResult, AppError>)
        /// 배경 타일 탭 — 보유면 적용, 미보유면 View 의 구매 확인을 거쳐 purchaseBackgroundConfirmed.
        case backgroundTapped(itemId: String)
        case purchaseBackgroundConfirmed(itemId: String)
        case backgroundResponse(Result<BackgroundResult, AppError>)
        case backTapped
        case dismissError
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case close
            case heartsChanged(Int)
            case decorationsChanged(String?)
            /// 가족 공유 배경이 적용됨 — MainTab 이 home.family 의 배경 id 를 갱신한다.
            case backgroundApplied(String?)
        }
    }

    /// onAppear 의 catalog + inventory 동시 로드 결과.
    public struct LoadResult: Equatable, Sendable {
        public let catalog: [ShopItem]
        public let inventory: ShopInventory
    }

    /// 구매 성공 후 자동 장착까지 묶은 결과 (꾸미기).
    public struct PurchaseResult: Equatable, Sendable {
        public let heartsRemaining: Int
        public let equippedDecorationId: String?
    }

    /// 배경 구매/적용 결과. heartsRemaining 이 nil 이면 구매 없이 적용만 한 경우.
    public struct BackgroundResult: Equatable, Sendable {
        public let heartsRemaining: Int?
        public let inventory: ShopInventory
    }

    @Dependency(\.shopRepository) var shopRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                guard state.catalog.isEmpty else { return .none }
                state.isLoading = true
                state.appError = nil
                return .run { [shopRepository] send in
                    do {
                        async let catalog = shopRepository.getCatalog()
                        async let inventory = shopRepository.getInventory()
                        let result = try await LoadResult(catalog: catalog, inventory: inventory)
                        await send(.loaded(.success(result)))
                    } catch {
                        await send(.loaded(.failure(AppError.from(error))))
                    }
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)

            case .loaded(.success(let result)):
                state.isLoading = false
                state.catalog = result.catalog
                state.inventory = result.inventory
                return .none

            case .loaded(.failure(let error)):
                state.isLoading = false
                state.appError = error
                return .none

            case .tabSelected(let tab):
                state.activeTab = tab
                return .none

            case .slotSelected(let slot):
                state.activeSlot = slot
                return .none

            case .decorationTapped(let itemId):
                guard !state.isLoading else { return .none }

                // "장식 없음" 또는 이미 장착된 아이템 재탭 → 해제.
                if itemId == nil || itemId == state.equippedDecorationId {
                    return equip(&state, itemId: nil)
                }

                guard let itemId else { return .none }

                // 이미 보유 → 바로 장착(전역 단일이라 기존 착용분은 서버가 덮어쓴다).
                if state.isOwned(itemId) {
                    return equip(&state, itemId: itemId)
                }

                // 미보유 → 가격 확인 후 구매 흐름.
                guard let item = state.catalog.first(where: { $0.id == itemId }) else {
                    state.appError = AppError.domain(ShopError.itemNotFound.localizedDescription)
                    return .none
                }
                // 하트 부족이면 View 가 안내 팝업만 띄운다 (충전 흐름 없음).
                guard state.hearts >= item.price else { return .none }
                // 충분하면 구매 진행 (확인 팝업은 View 가 띄우고 purchaseConfirmed 로 들어온다).
                return .send(.purchaseConfirmed(itemId: itemId))

            case .purchaseConfirmed(let itemId):
                guard !state.isLoading else { return .none }
                guard let item = state.catalog.first(where: { $0.id == itemId }) else {
                    state.appError = AppError.domain(ShopError.itemNotFound.localizedDescription)
                    return .none
                }
                guard state.hearts >= item.price else { return .none }
                state.isLoading = true
                state.appError = nil
                return .run { [shopRepository] send in
                    do {
                        // 서버 권위 구매 → 잔액 수신, 이어서 장착(서버 purchase 는 equip 안 함).
                        let heartsRemaining = try await shopRepository.purchase(itemId: itemId)
                        let equippedId = try await shopRepository.equipDecoration(itemId: itemId)
                        await send(.purchaseResponse(.success(
                            PurchaseResult(heartsRemaining: heartsRemaining, equippedDecorationId: equippedId)
                        )))
                    } catch {
                        await send(.purchaseResponse(.failure(AppError.from(error))))
                    }
                }
                .cancellable(id: CancelID.mutate, cancelInFlight: true)

            case .purchaseResponse(.success(let result)):
                state.isLoading = false
                state.hearts = result.heartsRemaining
                if var inv = state.inventory {
                    inv.equippedDecorationId = result.equippedDecorationId
                    // 구매한 아이템을 보유 목록에 반영.
                    if let equippedId = result.equippedDecorationId {
                        inv.ownedDecorationIds.insert(equippedId)
                    }
                    state.inventory = inv
                }
                return .merge(
                    .send(.delegate(.heartsChanged(result.heartsRemaining))),
                    .send(.delegate(.decorationsChanged(result.equippedDecorationId)))
                )

            case .purchaseResponse(.failure(let error)):
                state.isLoading = false
                state.appError = error
                return .none

            case .equipResponse(.success(let equippedId)):
                state.isLoading = false
                if var inv = state.inventory {
                    inv.equippedDecorationId = equippedId
                    state.inventory = inv
                }
                return .send(.delegate(.decorationsChanged(equippedId)))

            case .equipResponse(.failure(let error)):
                state.isLoading = false
                state.appError = error
                return .none

            case .backgroundTapped(let itemId):
                guard !state.isLoading else { return .none }
                // 보유 배경(기본 포함) → 바로 적용.
                if state.isBackgroundOwned(itemId) {
                    return applyBackground(&state, itemId: itemId, purchaseFirst: false)
                }
                // 미보유 → 가격 확인. 부족이면 View 가 안내 팝업만.
                guard let item = state.catalog.first(where: { $0.id == itemId }) else {
                    state.appError = AppError.domain(ShopError.itemNotFound.localizedDescription)
                    return .none
                }
                guard state.hearts >= item.price else { return .none }
                // 충분하면 구매 확인 (확인 팝업은 View 가 띄우고 purchaseBackgroundConfirmed 로 들어온다).
                return .send(.purchaseBackgroundConfirmed(itemId: itemId))

            case .purchaseBackgroundConfirmed(let itemId):
                guard !state.isLoading else { return .none }
                guard let item = state.catalog.first(where: { $0.id == itemId }) else {
                    state.appError = AppError.domain(ShopError.itemNotFound.localizedDescription)
                    return .none
                }
                guard state.hearts >= item.price else { return .none }
                return applyBackground(&state, itemId: itemId, purchaseFirst: true)

            case .backgroundResponse(.success(let result)):
                state.isLoading = false
                if let hearts = result.heartsRemaining { state.hearts = hearts }
                state.inventory = result.inventory
                var effects: [Effect<Action>] = [
                    .send(.delegate(.backgroundApplied(result.inventory.appliedBackgroundId)))
                ]
                if let hearts = result.heartsRemaining {
                    effects.append(.send(.delegate(.heartsChanged(hearts))))
                }
                return .merge(effects)

            case .backgroundResponse(.failure(let error)):
                state.isLoading = false
                state.appError = error
                return .none

            case .backTapped:
                return .send(.delegate(.close))

            case .dismissError:
                state.appError = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }

    /// 장착/해제 effect 생성 (중복 제거용). 전역 단일 — itemId nil 이면 해제.
    private func equip(_ state: inout State, itemId: String?) -> Effect<Action> {
        state.isLoading = true
        state.appError = nil
        return .run { [shopRepository] send in
            do {
                let equippedId = try await shopRepository.equipDecoration(itemId: itemId)
                await send(.equipResponse(.success(equippedId)))
            } catch {
                await send(.equipResponse(.failure(AppError.from(error))))
            }
        }
        .cancellable(id: CancelID.mutate, cancelInFlight: true)
    }

    /// 배경 적용 effect 생성. purchaseFirst 면 구매(잔액 수신) 후 적용한다.
    private func applyBackground(_ state: inout State, itemId: String, purchaseFirst: Bool) -> Effect<Action> {
        state.isLoading = true
        state.appError = nil
        return .run { [shopRepository] send in
            do {
                var heartsRemaining: Int? = nil
                if purchaseFirst {
                    heartsRemaining = try await shopRepository.purchase(itemId: itemId)
                }
                let inventory = try await shopRepository.applyBackground(itemId: itemId)
                await send(.backgroundResponse(.success(
                    BackgroundResult(heartsRemaining: heartsRemaining, inventory: inventory)
                )))
            } catch {
                await send(.backgroundResponse(.failure(AppError.from(error))))
            }
        }
        .cancellable(id: CancelID.mutate, cancelInFlight: true)
    }
}
