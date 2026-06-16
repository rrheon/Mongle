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
}

/// 기본 "아늑한 집" 배경 — 따뜻한 벽 + 원목 바닥 + 골든아워 창문/커튼 + 러그 + 화분.
/// 단순 그라데이션이 아니라 실제 거실 인테리어처럼 보이도록 리디자인. 가운데(캐릭터가 서는 자리)는
/// 비워 두고 가구는 가장자리에 배치한다.
struct V2CozyHomeBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let floorY = h * 0.64
            let floorH = h - floorY

            ZStack {
                // 1) 벽 — 따뜻한 크림→피치
                LinearGradient(
                    colors: [Color(hex: "FFF3E2"), Color(hex: "FBE6CB"), Color(hex: "F6D8B6")],
                    startPoint: .top, endPoint: .bottom)

                // 2) 원목 바닥
                woodFloor(width: w, height: floorH)
                    .position(x: w / 2, y: floorY + floorH / 2)

                // 3) 걸레받이(벽/바닥 경계)
                Rectangle()
                    .fill(Color(hex: "C18E5E").opacity(0.5))
                    .frame(width: w, height: 4)
                    .position(x: w / 2, y: floorY)

                // 4) 러그 — 캐릭터가 서는 자리 받침
                rug
                    .frame(width: w * 0.6, height: 44)
                    .position(x: w / 2, y: h - 64)

                // 5) 창문 + 커튼 (우상단)
                windowWithCurtains
                    .position(x: w - 86, y: h * 0.26)

                // 6) 화분 (좌하단)
                pottedPlant
                    .position(x: 48, y: floorY + floorH * 0.40)

                // 7) 창에서 들어오는 따뜻한 빛
                Ellipse()
                    .fill(RadialGradient(
                        colors: [Color(hex: "FFEFC9").opacity(0.5), .clear],
                        center: .center, startRadius: 0, endRadius: 160))
                    .frame(width: 340, height: 380)
                    .position(x: w - 60, y: h * 0.34)
                    .blur(radius: 10)
                    .blendMode(.softLight)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }

    // MARK: - 원목 바닥 (가로 판자 이음새)
    private func woodFloor(width w: CGFloat, height floorH: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "DBAA7B"), Color(hex: "C8915F"), Color(hex: "B67C4C")],
                startPoint: .top, endPoint: .bottom)
            VStack(spacing: floorH / 5) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle().fill(Color(hex: "97603A").opacity(0.22)).frame(height: 1.5)
                }
            }
            .padding(.vertical, floorH / 6)
        }
        .frame(width: w, height: floorH)
    }

    // MARK: - 러그
    private var rug: some View {
        ZStack {
            Ellipse().fill(Color(hex: "E2A87C").opacity(0.85))
            Ellipse().strokeBorder(Color(hex: "FFF1DC").opacity(0.7), lineWidth: 3).padding(7)
            Ellipse().strokeBorder(Color(hex: "C68C58").opacity(0.55), lineWidth: 2).padding(15)
        }
    }

    // MARK: - 창문 + 커튼
    private var windowWithCurtains: some View {
        ZStack {
            // 창틀
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: "FFFDF8"))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(hex: "C79A6B"), lineWidth: 3))
                .frame(width: 112, height: 132)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            // 하늘 (골든아워)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: "FFE6AD"), Color(hex: "FFCB93"), Color(hex: "F4AC83")],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: 96, height: 116)
            // 해
            Circle().fill(Color(hex: "FFF3C8")).frame(width: 28, height: 28)
                .offset(x: 16, y: -16).blur(radius: 0.5)
            // 먼 언덕
            Ellipse().fill(Color(hex: "E79A6A").opacity(0.45))
                .frame(width: 120, height: 46).offset(y: 52)
            // 십자 살(muntins)
            Rectangle().fill(Color(hex: "FFFDF8")).frame(width: 4, height: 116)
            Rectangle().fill(Color(hex: "FFFDF8")).frame(width: 96, height: 4)
            // 창턱
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(hex: "D6A576")).frame(width: 126, height: 8).offset(y: 70)
            // 커튼 좌·우
            curtain.offset(x: -64)
            curtain.scaleEffect(x: -1, y: 1).offset(x: 64)
        }
        .frame(width: 150, height: 150)
    }

    private var curtain: some View {
        ZStack {
            UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 16, bottomTrailing: 16))
                .fill(LinearGradient(
                    colors: [Color(hex: "F3CFA7"), Color(hex: "E5B68B")],
                    startPoint: .leading, endPoint: .trailing))
                .frame(width: 30, height: 148)
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(.black.opacity(0.06)).frame(width: 2, height: 132)
                }
            }
        }
        .frame(width: 30, height: 148)
    }

    // MARK: - 화분
    private var pottedPlant: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                leaf(Color(hex: "6B9F4C"), w: 12, h: 42, rot: 0, dx: 0, dy: -34)
                leaf(Color(hex: "7FB35C"), w: 16, h: 30, rot: -28, dx: -9, dy: -24)
                leaf(Color(hex: "8FC369"), w: 16, h: 30, rot: 28, dx: 9, dy: -24)
            }
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 5, bottomLeading: 11, bottomTrailing: 11, topTrailing: 5))
                .fill(LinearGradient(
                    colors: [Color(hex: "C77E4E"), Color(hex: "A0643C")],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: 46, height: 38)
        }
        .frame(width: 64, height: 92, alignment: .bottom)
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
