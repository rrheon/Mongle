//
//  DecorationCatalog.swift
//  MongleFeatures
//
//  장식 id ↔ SwiftUI 뷰 매핑. 상점 미리보기/그리드와 홈 캐릭터 슬롯 overlay 가
//  모두 이 매핑을 공유한다 (단일 진실). 카탈로그 기본값(디자인 값)도 여기서 제공해
//  서버 미구현 동안 Mock/프리뷰가 동일한 데이터로 동작하도록 한다.
//
//  슬롯별 카탈로그 id ↔ 디자인 뷰:
//    [머리 head]
//    deco_flower_crown  들꽃 화관  35  V2FlowerCrown
//    deco_star_halo     별 후광    40  V2StarHalo
//    deco_satin_ribbon  새틴 리본  25  V2SatinRibbon
//    deco_balloon_bunch 풍선 다발  50  V2BalloonBunch
//    deco_santa_hat     산타 모자  60  V2SantaHat (시즌)
//    [등 back]
//    deco_angel_wings   천사 날개  45  V2AngelWings (PNG)
//    deco_cape          망토       40  V2Cape
//    [발밑 feet]
//    deco_sneakers      운동화     30  V2Sneakers
//    deco_cloud_pad     구름 받침  35  V2CloudPad
//

import SwiftUI
import Domain

enum DecorationCatalog {

    // MARK: - id (head)

    static let flowerCrown = "deco_flower_crown"
    static let starHalo     = "deco_star_halo"
    static let satinRibbon  = "deco_satin_ribbon"
    static let balloonBunch = "deco_balloon_bunch"
    static let santaHat     = "deco_santa_hat"

    // MARK: - id (back)

    static let angelWings   = "deco_angel_wings"
    static let cape         = "deco_cape"

    // MARK: - id (feet)

    static let sneakers     = "deco_sneakers"
    static let cloudPad      = "deco_cloud_pad"

    /// 디자인 기준 머리 슬롯 장식 카탈로그.
    static let headItems: [ShopItem] = [
        ShopItem(id: flowerCrown, kind: .decoration, name: L10n.tr("shop_item_flower_crown"),
                 price: 50, assetName: flowerCrown, slot: .head, sortOrder: 1),
        ShopItem(id: starHalo, kind: .decoration, name: L10n.tr("shop_item_star_halo"),
                 price: 50, assetName: starHalo, slot: .head, sortOrder: 2),
        ShopItem(id: satinRibbon, kind: .decoration, name: L10n.tr("shop_item_satin_ribbon"),
                 price: 50, assetName: satinRibbon, slot: .head, sortOrder: 3),
        ShopItem(id: balloonBunch, kind: .decoration, name: L10n.tr("shop_item_balloon_bunch"),
                 price: 50, assetName: balloonBunch, slot: .head, sortOrder: 4),
        ShopItem(id: santaHat, kind: .decoration, name: L10n.tr("shop_item_santa_hat"),
                 price: 50, assetName: santaHat, slot: .head, isSeasonal: true, sortOrder: 5)
    ]

    /// 등(back) 슬롯 장식 카탈로그.
    static let backItems: [ShopItem] = [
        ShopItem(id: angelWings, kind: .decoration, name: L10n.tr("shop_item_angel_wings"),
                 price: 50, assetName: angelWings, slot: .back, sortOrder: 1),
        ShopItem(id: cape, kind: .decoration, name: L10n.tr("shop_item_cape"),
                 price: 50, assetName: cape, slot: .back, sortOrder: 2)
    ]

    /// 발밑(feet) 슬롯 장식 카탈로그.
    static let feetItems: [ShopItem] = [
        ShopItem(id: sneakers, kind: .decoration, name: L10n.tr("shop_item_sneakers"),
                 price: 50, assetName: sneakers, slot: .feet, sortOrder: 1),
        ShopItem(id: cloudPad, kind: .decoration, name: L10n.tr("shop_item_cloud_pad"),
                 price: 50, assetName: cloudPad, slot: .feet, sortOrder: 2)
    ]

    /// 전체 장식 카탈로그 (모든 슬롯 합본 — 서버 미구현 동안 Mock/프리뷰 기본값).
    static let allItems: [ShopItem] = headItems + backItems + feetItems

    // MARK: - id → 뷰 (슬롯 무관 매핑)

    /// 그리드 타일/홈 캐릭터 위에 얹는 작은 미리보기 뷰. 슬롯 무관하게 id 로 매핑한다.
    @ViewBuilder
    static func preview(for id: String?) -> some View {
        switch id {
        case flowerCrown:  V2FlowerCrown(small: true)
        case starHalo:     V2StarHalo()
        // 새틴 리본: V2SatinRibbon 은 .frame(width:)로 폭만 제약해 높이가 부모 제안만큼 새어
        // 56×56 슬롯을 세로로 넘쳐(다른 셀보다 커 보임/셀 침범) 버린다. 여기선 자산을 양쪽 모두
        // 제약된 정사각 박스에 scaledToFit 시켜 절대 넘치지 않고 다른 장식과 크기를 맞춘다.
        case satinRibbon:
            Image("V2Ribbon", bundle: .module).resizable().scaledToFit().frame(width: 44, height: 44)
        case balloonBunch: V2BalloonBunch()
        case santaHat:     V2SantaHat()
        case angelWings:   V2AngelWings(size: 56)
        case cape:         V2Cape(small: true)
        case sneakers:     V2Sneakers()
        case cloudPad:     V2CloudPad()
        default:           EmptyView()
        }
    }

    /// 캐릭터 머리 위에 얹는 (상점 미리보기/홈 공유) 풀사이즈 뷰.
    @ViewBuilder
    static func headView(for id: String?) -> some View {
        switch id {
        case flowerCrown:  V2FlowerCrown()
        case starHalo:     V2StarHalo()
        case satinRibbon:  V2SatinRibbon()
        case balloonBunch: V2BalloonBunch()
        case santaHat:     V2SantaHat()
        default:           EmptyView()
        }
    }

    /// 캐릭터 본체 뒤(등)에 까는 뷰. 본체보다 **크게** 그려 본체 실루엣 밖으로 삐져나와
    /// 보이게 한다(그대로 그리면 본체 뒤에 완전히 가려져 안 보임). bodySize 에 비례.
    @ViewBuilder
    static func backView(for id: String?, bodySize: CGFloat = 56) -> some View {
        switch id {
        case angelWings:   V2AngelWings(size: bodySize * 1.55)   // 본체보다 넓은 날개 → 양옆으로 보임
        case cape:         V2Cape().scaleEffect(bodySize / 40)   // 본체보다 크게 → 아래/옆으로 보임
        default:           EmptyView()
        }
    }

    /// 캐릭터 본체 하단(발밑)에 까는 풀사이즈 뷰.
    @ViewBuilder
    static func feetView(for id: String?) -> some View {
        switch id {
        case sneakers:     V2Sneakers()
        case cloudPad:     V2CloudPad()
        default:           EmptyView()
        }
    }

    /// 단일 장착 id → 그 장식의 슬롯 역산 (렌더 어댑터용). nil/미상이면 nil.
    static func slotForItem(_ id: String?) -> DecorationSlot? {
        guard let id else { return nil }
        return allItems.first(where: { $0.id == id })?.slot
    }

    /// 슬롯별 카탈로그 아이템 헬퍼.
    static func items(for slot: DecorationSlot) -> [ShopItem] {
        switch slot {
        case .head: return headItems
        case .back: return backItems
        case .feet: return feetItems
        }
    }
}
