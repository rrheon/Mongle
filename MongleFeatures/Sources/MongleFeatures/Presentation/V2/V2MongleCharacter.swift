//
//  V2MongleCharacter.swift
//  Mongle — v2 design handoff
//
//  The round "몽글" creature: solid body, white-rimmed eyes (centered),
//  optional name pill, status badge, head decoration, halo ring and dog ears.
//  Mirrors the prototype's `Mongle` primitive.
//

import SwiftUI

struct V2Mongle<Decoration: View>: View {
    var color: Color = V2Palette.dad
    var name: String? = nil
    var nameColor: Color = .white
    var badgeIcon: String? = nil          // SF Symbol; nil = no badge
    var badgeColor: Color = V2Palette.mint
    var size: CGFloat = 70
    var eyeSize: CGFloat = 13
    var hideName: Bool = false
    var dogEars: Bool = false
    var ringColor: Color? = nil
    var shadow: Bool = true
    var decoration: () -> Decoration

    private var containerW: CGFloat { size + 20 }
    private var containerH: CGFloat { size + 40 }
    private var eyeY: CGFloat { size * 0.44 }
    private var eyeLX: CGFloat { size * 0.35 - eyeSize / 2 }
    private var eyeRX: CGFloat { size * 0.65 - eyeSize / 2 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // halo ring
            if let ringColor {
                Circle()
                    .strokeBorder(ringColor, lineWidth: 2)
                    .frame(width: size + 14, height: size + 14)
                    .offset(x: 3, y: -6)
            }

            // dog ears (Ben)
            if dogEars {
                RoundedRectangle(cornerRadius: size * 0.05)
                    .fill(V2Palette.brownEar)
                    .frame(width: 8, height: 10)
                    .clipShape(Capsule())
                    .offset(x: size * 0.18, y: size * 0.85)
            }

            // body
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .overlay(Circle().strokeBorder(V2Palette.inkSoft, lineWidth: 1.5))
                .shadow(color: shadow ? Color.black.opacity(0.32) : .clear,
                        radius: shadow ? 7 : 0, x: 0, y: 4)
                .offset(x: 10, y: 0)

            // eyes (white rim + dark pupil), symmetric around the midline
            eye.offset(x: 10 + eyeLX, y: eyeY)
            eye.offset(x: 10 + eyeRX, y: eyeY)

            // status badge
            if let badgeIcon {
                ZStack {
                    Circle()
                        .fill(badgeColor)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
                    Image(systemName: badgeIcon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(V2Palette.ink)
                }
                .frame(width: 18, height: 18)
                .offset(x: 10 + size - 14, y: size * 0.55)
            }

            // name pill
            if let name, !hideName {
                Text(name)
                    .font(MongleFont.label())
                    .fontWeight(.bold)
                    .foregroundStyle(nameColor)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(V2Palette.ink.opacity(0.78), in: RoundedRectangle(cornerRadius: 10))
                    .frame(width: containerW, alignment: .center)
                    .offset(y: size + 8)
            }

            // head decoration — drawn last so it sits in front of the body
            decoration()
                .frame(width: containerW, alignment: .center)
                .offset(y: -size * 0.28)
                .allowsHitTesting(false)
        }
        .frame(width: containerW, height: containerH, alignment: .topLeading)
    }

    private var eye: some View {
        Circle()
            .fill(V2Palette.ink)
            .frame(width: eyeSize, height: eyeSize)
            .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
    }
}

// Convenience initializer for the common (no-decoration) case.
extension V2Mongle where Decoration == EmptyView {
    init(
        color: Color = V2Palette.dad,
        name: String? = nil,
        nameColor: Color = .white,
        badgeIcon: String? = nil,
        badgeColor: Color = V2Palette.mint,
        size: CGFloat = 70,
        eyeSize: CGFloat = 13,
        hideName: Bool = false,
        dogEars: Bool = false,
        ringColor: Color? = nil,
        shadow: Bool = true
    ) {
        self.color = color
        self.name = name
        self.nameColor = nameColor
        self.badgeIcon = badgeIcon
        self.badgeColor = badgeColor
        self.size = size
        self.eyeSize = eyeSize
        self.hideName = hideName
        self.dogEars = dogEars
        self.ringColor = ringColor
        self.shadow = shadow
        self.decoration = { EmptyView() }
    }
}

#Preview("V2 Mongle") {
    ZStack {
        V2Palette.cream.ignoresSafeArea()
        HStack(spacing: 24) {
            V2Mongle(color: V2Palette.dad, name: "아빠", badgeIcon: "checkmark")
            V2Mongle(color: V2Palette.mom, name: "엄마", badgeIcon: "checkmark") {
                V2FlowerCrown()
            }
            V2Mongle(color: V2Palette.ben, name: "벤",
                     badgeIcon: "hourglass", badgeColor: V2Palette.purple, dogEars: true)
            V2Mongle(color: V2Palette.alex, badgeIcon: "bolt.fill",
                     badgeColor: V2Palette.streak, ringColor: V2Palette.mint)
        }
    }
}
