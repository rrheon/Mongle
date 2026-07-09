//
//  DecoSnapshotTests.swift
//  MongleFeaturesTests
//
//  장식(꾸미기) 부착위치 육안검증용 스냅샷 하네스.
//  각 장식을 상점 레이어(V2Mongle)와 홈 레이어(MongleView) 위에 얹어 PNG 로 렌더한다.
//  실행: xcodebuild test ... -only-testing:MongleFeaturesTests/DecoSnapshotTests
//  출력 경로는 테스트 로그의 "SNAPDIR=" 라인에 절대경로로 찍힌다(호스트에서 직접 읽음).
//

import XCTest
import SwiftUI
import Domain
@testable import MongleFeatures

@MainActor
final class DecoSnapshotTests: XCTestCase {

    /// (id, 라벨) — nil 은 장식 없음(기준선).
    private let cases: [(id: String?, label: String)] = [
        (nil,                              "00_none"),
        (DecorationCatalog.flowerCrown,    "01_flower_crown"),
        (DecorationCatalog.starHalo,       "02_star_halo"),
        (DecorationCatalog.satinRibbon,    "03_satin_ribbon"),
        (DecorationCatalog.santaHat,       "04_santa_hat"),
        (DecorationCatalog.balloonBunch,   "05_balloon_bunch"),
        (DecorationCatalog.angelWings,     "06_angel_wings"),
        (DecorationCatalog.cape,           "07_cape"),
        (DecorationCatalog.sneakers,       "08_sneakers"),
        (DecorationCatalog.cloudPad,       "09_cloud_pad"),
    ]

    func testRenderAllDecorations() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mongle-deco-snaps", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        for c in cases {
            let slot = DecorationCatalog.slotForItem(c.id)
            let headId: String? = (slot == nil || slot == .head || slot == .hand) ? c.id : nil
            let backId: String? = (slot == .back) ? c.id : nil
            let feetId: String? = (slot == .feet) ? c.id : nil

            // 상점 레이어 (V2Mongle, size 86 — 상세 미리보기 근사)
            let shop = ZStack {
                V2Palette.cream
                V2Mongle(color: V2Palette.mom, name: "몽글", size: 86,
                         backDecorationId: backId,
                         feetDecorationId: feetId,
                         headDecorationId: headId)
            }
            .frame(width: 160, height: 200)

            try render(shop, to: dir, name: "shop_\(c.label)")

            // 홈 레이어 (MongleView, bodySize 56 고정)
            let home = ZStack {
                V2Palette.cream
                MongleView(
                    name: "몽글", color: V2Palette.mom, hasAnswered: true,
                    headDecorationId: headId,
                    backDecorationId: backId,
                    feetDecorationId: feetId,
                    hasCurrentUserAnswered: true,
                    isCurrentUser: true,
                    onViewAnswer: {}, onNudge: {}
                )
            }
            .frame(width: 160, height: 200)

            try render(home, to: dir, name: "home_\(c.label)")
        }

        print("SNAPDIR=\(dir.path)")
    }

    private func render<V: View>(_ view: V, to dir: URL, name: String) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        guard let img = renderer.uiImage, let data = img.pngData() else {
            XCTFail("render failed: \(name)"); return
        }
        try data.write(to: dir.appendingPathComponent("\(name).png"))
    }
}
