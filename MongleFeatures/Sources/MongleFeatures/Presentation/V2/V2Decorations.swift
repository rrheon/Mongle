//
//  V2Decorations.swift
//  Mongle — v2 design handoff
//
//  Head/back/feet decorations. PNG-backed ones (flower crown, ribbon) use the
//  uploaded assets; the rest are redrawn as SwiftUI shapes to match the prototype.
//

import SwiftUI

// MARK: - PNG-backed

struct V2FlowerCrown: View {
    var small: Bool = false
    var body: some View {
        Image("V2FlowerCrown", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: small ? 50 : 64)
    }
}

struct V2SatinRibbon: View {
    var size: CGFloat = 38
    var body: some View {
        Image("V2Ribbon", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: size)
    }
}

struct V2AngelWings: View {
    var size: CGFloat = 80
    var body: some View {
        Image("V2AngelWings", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: size)
    }
}

// MARK: - Shape-drawn

/// A five-pointed star, point-up, normalized to its frame.
struct V2Star: Shape {
    var points: Int = 5
    var innerRatio: CGFloat = 0.42
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var path = Path()
        let step = .pi / CGFloat(points)
        for i in 0..<(points * 2) {
            let r = i.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(i) * step - .pi / 2
            let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

struct V2StarHalo: View {
    var small: Bool = false
    private var s: CGFloat { small ? 0.7 : 1 }
    var body: some View {
        ZStack {
            Ellipse()
                .strokeBorder(V2Palette.lily, lineWidth: 1.5)
                .frame(width: 42 * s, height: 12 * s)
            V2Star()
                .fill(V2Palette.lily)
                .overlay(V2Star().stroke(V2Palette.star, lineWidth: 1))
                .frame(width: 14 * s, height: 14 * s)
                .offset(y: -8 * s)
        }
        .frame(width: 42 * s, height: 20 * s)
    }
}

struct V2BalloonBunch: View {
    var body: some View {
        ZStack {
            balloon(V2Palette.pinkSoft).offset(x: -11, y: 0)
            balloon(V2Palette.lily).offset(x: 1, y: -4)
            balloon(V2Palette.blueSat).offset(x: 13, y: 0)
        }
        .frame(width: 42, height: 32)
    }
    private func balloon(_ c: Color) -> some View {
        Ellipse()
            .fill(c)
            .overlay(Ellipse().strokeBorder(V2Palette.inkSoft, lineWidth: 1))
            .frame(width: 12, height: 16)
    }
}

struct V2SantaHat: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            SantaCap()
                .fill(Color(hex: "E53935"))
                .overlay(SantaCap().stroke(V2Palette.inkSoft, lineWidth: 1))
                .frame(width: 36, height: 18)
                .offset(x: 2, y: 0)
            Capsule()
                .fill(.white)
                .overlay(Capsule().strokeBorder(V2Palette.inkSoft, lineWidth: 0.8))
                .frame(width: 34, height: 5)
                .offset(x: 2, y: 14)
            Circle()
                .fill(.white)
                .overlay(Circle().strokeBorder(V2Palette.inkSoft, lineWidth: 0.8))
                .frame(width: 7, height: 7)
                .offset(x: 31, y: 5)
        }
        .frame(width: 42, height: 22, alignment: .topLeading)
    }
    private struct SantaCap: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addQuadCurve(to: CGPoint(x: rect.maxX * 0.78, y: rect.minY + rect.height * 0.33),
                           control: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX * 0.88, y: rect.maxY))
            p.closeSubpath()
            return p
        }
    }
}

#Preview("V2 Decorations") {
    HStack(spacing: 20) {
        V2FlowerCrown()
        V2StarHalo()
        V2SatinRibbon()
        V2BalloonBunch()
        V2SantaHat()
    }
    .padding(40)
    .background(V2Palette.cream)
}
