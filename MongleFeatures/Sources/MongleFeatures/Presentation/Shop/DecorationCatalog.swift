//
//  DecorationCatalog.swift
//  MongleFeatures
//
//  장식 id ↔ SwiftUI 뷰 매핑. 상점 미리보기/그리드와 홈 캐릭터 슬롯 overlay 가
//  모두 이 매핑을 공유한다 (단일 진실). 카탈로그 기본값(디자인 값)도 여기서 제공해
//  서버 미구현 동안 Mock/프리뷰가 동일한 데이터로 동작하도록 한다.
//
//  슬롯별 카탈로그 id ↔ 디자인 뷰 (유료 전부 price 50):
//    [머리 head]
//    deco_flower_crown  들꽃 화관  V2FlowerCrown
//    deco_star_halo     별 후광    V2StarHalo (anchor=.aboveHead)
//    deco_satin_ribbon  새틴 리본  V2SatinRibbon
//    deco_santa_hat     산타 모자  V2SantaHat (시즌)
//    [손 hand]
//    deco_balloon_bunch 풍선 다발  V2BalloonBunch (anchor=.hand)
//    [등 back]
//    deco_angel_wings   천사 날개  V2AngelWings (PNG)
//    deco_cape          망토       V2Cape
//    [발밑 feet]
//    deco_sneakers      운동화     V2Sneakers
//    deco_cloud_pad     구름 받침  V2CloudPad
//

import SwiftUI
import Domain

// MARK: - 부착 위치(placement) 모델

/// 장식이 캐릭터의 어디에 붙는지(렌더 좌표 기준점). 슬롯(enum)과 별개로
/// 렌더 레이어가 위치를 분기하는 단일 소스다. slot=head 라도 anchor=.hand 처럼
/// 슬롯과 부착위치가 갈릴 수 있다(예: 풍선 다발은 head 슬롯이지만 손에 든다).
enum DecorationAnchor {
    case onHead     // 머리에 씀 (화관·리본·모자)
    case aboveHead  // 머리 위로 더 띄움 (후광)
    case hand       // 손(측면·하단)에 듦 (풍선)
    case back       // 등 (날개·망토)
    case feet       // 발밑 (운동화·구름)
}

/// 부착 위치 + 추가 nudge 오프셋 + 스케일.
/// `offset` 은 bodySize 비례 단위로 해석한다 — 실제 적용 = offset.width*bodySize, offset.height*bodySize.
/// 레이어별 앵커 baseline 에 이 offset 을 더해 최종 위치를 정한다.
struct DecorationPlacement {
    var anchor: DecorationAnchor
    var offset: CGSize = .zero
    var scale: CGFloat = 1.0
}

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
        ShopItem(id: santaHat, kind: .decoration, name: L10n.tr("shop_item_santa_hat"),
                 price: 50, assetName: santaHat, slot: .head, isSeasonal: true, sortOrder: 5)
    ]

    /// 손(hand) 슬롯 장식 카탈로그. 풍선 다발은 손에 들고 다닌다(anchor=.hand).
    static let handItems: [ShopItem] = [
        ShopItem(id: balloonBunch, kind: .decoration, name: L10n.tr("shop_item_balloon_bunch"),
                 price: 50, assetName: balloonBunch, slot: .hand, sortOrder: 1)
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
    static let allItems: [ShopItem] = headItems + handItems + backItems + feetItems

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

    // MARK: - id → 부착 위치(placement)

    /// 장식 id → 부착 위치. anchor 분류의 단일 소스. 두 렌더 레이어가 모두 이걸 참조한다.
    /// offset 은 bodySize 비례 nudge(레이어 baseline 에 가산), scale 은 배율.
    static func placement(for id: String?) -> DecorationPlacement {
        switch id {
        case flowerCrown, satinRibbon, santaHat:
            return DecorationPlacement(anchor: .onHead, offset: .zero, scale: 1.0)
        case starHalo:
            return DecorationPlacement(anchor: .aboveHead, offset: .zero, scale: 1.0)
        case balloonBunch:
            return DecorationPlacement(anchor: .hand, offset: .zero, scale: 1.0)
        case angelWings, cape:
            return DecorationPlacement(anchor: .back, offset: .zero, scale: 1.0)
        case sneakers, cloudPad:
            return DecorationPlacement(anchor: .feet, offset: .zero, scale: 1.0)
        default:
            // 미상/nil — 무해 기본 (머리에 씀).
            return DecorationPlacement(anchor: .onHead, offset: .zero, scale: 1.0)
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
        case .hand: return handItems
        case .back: return backItems
        case .feet: return feetItems
        }
    }
}
