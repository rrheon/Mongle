//
//  BackgroundCatalog.swift
//  MongleFeatures
//
//  배경(가족 공유 홈 배경) id ↔ SwiftUI 배경 뷰 매핑 + 디자인 기준 카탈로그.
//  상점 그리드 타일과 홈 배경(HomeViewV2)이 이 매핑을 공유한다 (단일 진실).
//  배경 자산은 V2ImageBackground(springField/beach/space/snowVillage/cherryBlossom)
//  와 기본 V2CozyHomeBackground 를 그대로 사용한다.
//
//  카탈로그 id ↔ 디자인 배경 (기본 1종 + 구매 5종 · 구매가 50 하트로 통일):
//    bg_cozy_home      따뜻한 집    0   V2CozyHomeBackground (기본 · 항상 보유)
//    bg_spring_field   봄 들판      50  V2ImageBackground.springField
//    bg_beach          바닷가       50  V2ImageBackground.beach
//    bg_space          우주         50  V2ImageBackground.space
//    bg_snow_village   눈오는 마을  50  V2ImageBackground.snowVillage (시즌)
//    bg_cherry_blossom 벚꽃길       50  V2ImageBackground.cherryBlossom
//

import SwiftUI
import Domain

enum BackgroundCatalog {

    // MARK: - id

    static let cozyHome      = "bg_cozy_home"
    static let springField   = "bg_spring_field"
    static let beach         = "bg_beach"
    static let space         = "bg_space"
    static let snowVillage   = "bg_snow_village"
    static let cherryBlossom = "bg_cherry_blossom"

    /// 기본 배경 — 항상 보유 상태로 취급. 가격 0.
    static let defaultId = cozyHome

    /// 디자인 기준 배경 카탈로그 (서버 미구현 동안 Mock/프리뷰 기본값).
    static let items: [ShopItem] = [
        ShopItem(id: cozyHome, kind: .background, name: L10n.tr("shop_bg_cozy_home"),
                 price: 0, assetName: cozyHome, sortOrder: 0),
        ShopItem(id: springField, kind: .background, name: L10n.tr("shop_bg_spring_field"),
                 price: 50, assetName: springField, sortOrder: 1),
        ShopItem(id: beach, kind: .background, name: L10n.tr("shop_bg_beach"),
                 price: 50, assetName: beach, sortOrder: 2),
        ShopItem(id: space, kind: .background, name: L10n.tr("shop_bg_space"),
                 price: 50, assetName: space, sortOrder: 3),
        ShopItem(id: snowVillage, kind: .background, name: L10n.tr("shop_bg_snow_village"),
                 price: 50, assetName: snowVillage, isSeasonal: true, sortOrder: 5),
        ShopItem(id: cherryBlossom, kind: .background, name: L10n.tr("shop_bg_cherry_blossom"),
                 price: 50, assetName: cherryBlossom, sortOrder: 6)
    ]

    // MARK: - id → 홈 배경 뷰

    /// 홈(HomeViewV2) 전체 배경. 미적용/미지정/기본이면 cozy home 으로 폴백한다.
    @ViewBuilder
    static func homeBackground(for id: String?) -> some View {
        switch id {
        case springField:   cropped(.springField)
        case beach:         cropped(.beach)
        case space:         cropped(.space)
        case snowVillage:   cropped(.snowVillage)
        case cherryBlossom: cropped(.cherryBlossom)
        default:            V2CozyHomeBackground()   // cozyHome / nil
        }
    }

    /// 이미지 배경은 하단 60pt 를 실제로 잘라낸 뒤 적용한다 — 이미지를 60pt 더 크게 잡고
    /// top 정렬·클립하여 콘텐츠 하단 60pt 를 제거(소스 이미지 하단 띠가 보이는 문제 방지).
    /// 화면 전체를 채우되 cream 빈 띠를 남기지 않는다.
    private static let bottomCrop: CGFloat = 60
    private static func cropped(_ bg: V2ImageBackground) -> some View {
        GeometryReader { geo in
            bg
                .frame(width: geo.size.width, height: geo.size.height + bottomCrop)
                .clipped()
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .clipped()
        }
        .ignoresSafeArea()
    }

    // MARK: - id → 상점 타일

    /// 따뜻한 집은 이미지가 없어 그라데이션 스와치로 그린다.
    static let cozyHomeSwatch = LinearGradient(
        colors: [Color(hex: "FFE5C2"), Color(hex: "F1C18A"), Color(hex: "C9885A")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// 그리드 타일에 쓸 이미지 자산 이름 (스와치로 그리는 항목은 nil).
    static func tileImage(for id: String) -> String? {
        switch id {
        case springField:   return "V2BgSpringField"
        case beach:         return "V2BgBeach"
        case space:         return "V2BgSpace"
        case snowVillage:   return "V2BgSnowVillage"
        case cherryBlossom: return "V2BgCherryBlossom"
        default:            return nil   // cozyHome → swatch
        }
    }

    /// 그리드 타일에 쓸 그라데이션 스와치 (이미지 자산이 있는 항목은 nil).
    static func tileSwatch(for id: String) -> LinearGradient? {
        switch id {
        case cozyHome: return cozyHomeSwatch
        default:       return nil
        }
    }
}
