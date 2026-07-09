//
//  ShopScreenSnapshotTests.swift
//  MongleFeaturesTests
//
//  상점 실화면 UI 육안검증용 스냅샷. 그리드(꾸미기/배경 탭) + 장식 상세뷰 9종을
//  iPhone 크기(393×852)로 렌더한다. 출력 경로는 로그의 "SHOPSNAPDIR=" 라인.
//

import XCTest
import SwiftUI
import ComposableArchitecture
import Domain
@testable import MongleFeatures

@MainActor
final class ShopScreenSnapshotTests: XCTestCase {

    private let screen = CGSize(width: 393, height: 852)

    private func makeState(
        tab: ShopFeature.ShopTab = .decoration,
        equipped: String? = nil
    ) -> ShopFeature.State {
        ShopFeature.State(
            activeTab: tab,
            hearts: 100,
            catalog: DecorationCatalog.allItems + BackgroundCatalog.items,
            inventory: ShopInventory(
                ownedDecorationIds: [DecorationCatalog.flowerCrown, DecorationCatalog.balloonBunch],
                equippedDecorationId: equipped
            )
        )
    }

    private func makeStore(_ state: ShopFeature.State) -> StoreOf<ShopFeature> {
        Store(initialState: state) { ShopFeature() } withDependencies: {
            $0.shopRepository = MockShopRepository()
        }
    }

    func testRenderShopScreens() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mongle-shop-screens", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // 1) 그리드 — 꾸미기 탭(화관 장착 상태) / 배경 탭
        try render(ShopView(store: makeStore(makeState(equipped: DecorationCatalog.flowerCrown))),
                   to: dir, name: "grid_deco")
        try render(ShopView(store: makeStore(makeState(tab: .background))),
                   to: dir, name: "grid_bg")

        // 2) 장식 상세 9종 — 큰 미리보기의 placement 확인
        for item in DecorationCatalog.allItems {
            let view = ShopDecoDetailView(
                store: makeStore(makeState()),
                item: item,
                onClose: {},
                onInsufficient: {}
            )
            try render(view, to: dir, name: "detail_\(item.id)")
        }

        // 3) 배경 상세 1종 (레이아웃 대표 확인)
        if let bg = BackgroundCatalog.items.first {
            try render(ShopBgDetailView(store: makeStore(makeState(tab: .background)),
                                        item: bg, onClose: {}, onInsufficient: {}),
                       to: dir, name: "detail_bg_first")
        }

        print("SHOPSNAPDIR=\(dir.path)")
    }

    /// LazyVGrid/ScrollView 는 ImageRenderer 로는 레이아웃되지 않아(윈도우 필요)
    /// 실제 UIWindow 에 호스팅한 뒤 레이어를 스냅샷한다.
    private func render<V: View>(_ view: V, to dir: URL, name: String) throws {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: screen))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        window.layoutIfNeeded()
        // lazy 컨테이너가 셀을 실체화할 시간을 준다 (런루프 한 틱).
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        let renderer = UIGraphicsImageRenderer(size: screen, format: {
            let f = UIGraphicsImageRendererFormat()
            f.scale = 2
            return f
        }())
        // headless 테스트 러너에서 drawHierarchy 는 검은 화면을 뱉는다 → layer.render 사용.
        let img = renderer.image { ctx in
            window.layer.render(in: ctx.cgContext)
        }
        guard let data = img.pngData() else {
            XCTFail("render failed: \(name)"); return
        }
        try data.write(to: dir.appendingPathComponent("\(name).png"))
        window.isHidden = true
    }
}
