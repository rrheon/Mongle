//
//  V2Backgrounds.swift
//  Mongle — v2 design handoff
//
//  Pixel-art image backgrounds (rendered with no interpolation for crisp pixels)
//  plus the gradient-drawn "따뜻한 집" cozy-home default background.
//

import SwiftUI

/// Full-bleed pixel-art image background.
struct V2ImageBackground: View {
    let assetName: String
    var tint: Color? = nil
    var opacity: Double = 1

    var body: some View {
        ZStack {
            Image(assetName, bundle: .module)
                .resizable()
                .interpolation(.none)
                .scaledToFill()
                .opacity(opacity)
            if let tint { tint }
        }
        .clipped()
    }
}

extension V2ImageBackground {
    static let springField = V2ImageBackground(assetName: "V2BgSpringField")
    static let beach = V2ImageBackground(assetName: "V2BgBeach")
    static let space = V2ImageBackground(assetName: "V2BgSpace")
    static let snowVillage = V2ImageBackground(assetName: "V2BgSnowVillage")
    static let cherryBlossom = V2ImageBackground(assetName: "V2BgCherryBlossom")
    // Prototype's "forest"/dark home reused the space art.
    static let forest = V2ImageBackground(assetName: "V2BgSpace")
}

/// The warm-home default background — gradient sky, soft floor, a potted plant and a rug.
struct V2CozyHomeBackground: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color(hex: "FFF1DC"), Color(hex: "FFE5C2"),
                         Color(hex: "F8D4A8"), Color(hex: "E9B988")],
                startPoint: .top, endPoint: .bottom
            )

            // floor band
            LinearGradient(
                colors: [.clear, Color(hex: "B47846").opacity(0.18), Color(hex: "A0643C").opacity(0.28)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 220)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // warm ambient light
            Ellipse()
                .fill(RadialGradient(
                    colors: [Color(hex: "FFF3D8").opacity(0.55), Color(hex: "FFF3D8").opacity(0)],
                    center: .center, startRadius: 0, endRadius: 130))
                .frame(width: 220, height: 280)
                .blur(radius: 2)
                .offset(x: V2Canvas.width - 180, y: 140)

            // plant
            plant.offset(x: 24, y: V2Canvas.height - 200)

            // rug
            Capsule()
                .fill(LinearGradient(
                    colors: [Color(hex: "D9A078").opacity(0.5), Color(hex: "F0C8A0").opacity(0.5), Color(hex: "D9A078").opacity(0.5)],
                    startPoint: .leading, endPoint: .trailing))
                .frame(height: 14)
                .padding(.horizontal, 60)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 50)
        }
        .ignoresSafeArea()
    }

    private var plant: some View {
        ZStack(alignment: .bottom) {
            // leaves
            ZStack {
                leaf(Color(hex: "6B9F4C"), w: 10, h: 32, rot: 0, dx: 8, dy: -30)
                leaf(Color(hex: "7FB35C"), w: 14, h: 22, rot: -25, dx: -2, dy: -22)
                leaf(Color(hex: "8FC369"), w: 14, h: 22, rot: 25, dx: 14, dy: -22)
            }
            // pot
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 4, bottomLeading: 8, bottomTrailing: 8, topTrailing: 4))
                .fill(Color(hex: "A0643C").opacity(0.6))
                .frame(width: 38, height: 30)
        }
        .frame(width: 38, height: 70, alignment: .bottom)
    }

    private func leaf(_ c: Color, w: CGFloat, h: CGFloat, rot: Double, dx: CGFloat, dy: CGFloat) -> some View {
        UnevenRoundedRectangle(cornerRadii: .init(topLeading: w / 2, bottomLeading: w * 0.3, bottomTrailing: w * 0.3, topTrailing: w / 2))
            .fill(c)
            .frame(width: w, height: h)
            .rotationEffect(.degrees(rot))
            .offset(x: dx, y: dy)
    }
}

#Preview("V2 Backgrounds") {
    VStack(spacing: 0) {
        V2ImageBackground.springField
        V2CozyHomeBackground()
    }
    .ignoresSafeArea()
}
