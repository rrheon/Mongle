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
    /// nil 이면 size 비례(0.18). 명시값을 넘기면 그 값을 그대로 쓴다.
    /// (MongleMonggle 의 눈 비율 0.18 과 통일 — 미리보기 size:86 처럼 커져도 눈이 작아 보이지 않게.)
    var eyeSize: CGFloat? = nil
    var hideName: Bool = false
    var dogEars: Bool = false
    var ringColor: Color? = nil
    var shadow: Bool = true
    /// 등(back) 슬롯 장식 id. 본체 뒤(zIndex 본체보다 뒤)에 깐다. id→뷰는 DecorationCatalog 공유.
    var backDecorationId: String? = nil
    /// 발밑(feet) 슬롯 장식 id. 본체 하단에 깐다.
    var feetDecorationId: String? = nil
    /// 머리계열(head/aboveHead/hand) 장식 id. 있으면 placement 기반으로 렌더하고
    /// 아래 `decoration` 클로저 대신 쓴다. id→뷰는 DecorationCatalog.headView 공유.
    var headDecorationId: String? = nil
    /// 머리(head) 슬롯 장식 — 본체 앞에 얹는 closure (레거시/정적 호출부 호환).
    /// headDecorationId 가 nil 일 때만 이 클로저 경로가 -size*0.28 로 렌더된다.
    var decoration: () -> Decoration

    private var resolvedEye: CGFloat { eyeSize ?? size * 0.18 }
    private var containerW: CGFloat { size + 20 }
    private var containerH: CGFloat { size + 40 }
    private var eyeY: CGFloat { size * 0.44 }
    private var eyeLX: CGFloat { size * 0.35 - resolvedEye / 2 }
    private var eyeRX: CGFloat { size * 0.65 - resolvedEye / 2 }

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

            // back decoration — drawn before the body so it sits behind it. 본체보다 크게
            // (bodySize 비례) 그려 본체 실루엣 밖으로 보이게 한다(안 그러면 뒤에 가려 안 보임).
            if backDecorationId != nil {
                DecorationCatalog.backView(for: backDecorationId, bodySize: size)
                    .frame(width: containerW, alignment: .center)
                    .offset(y: size * 0.12)
                    .allowsHitTesting(false)
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

            // feet decoration — drawn under the body (본체 하단).
            if feetDecorationId != nil {
                DecorationCatalog.feetView(for: feetDecorationId)
                    .frame(width: containerW, alignment: .center)
                    .offset(y: size * 0.84)
                    .allowsHitTesting(false)
            }

            // head 계열 decoration — drawn last so it sits in front of the body.
            // headDecorationId 가 있으면 placement(anchor) 기반으로 위치/스케일을 정하고,
            // 없으면 레거시 클로저를 기존 -size*0.28 로 렌더한다(정적 호출부 호환).
            if let headDecorationId {
                let placement = DecorationCatalog.placement(for: headDecorationId)
                let base = headBaseline(placement.anchor)
                DecorationCatalog.headView(for: headDecorationId)
                    .scaleEffect(placement.scale)
                    .frame(width: containerW, alignment: .center)
                    .offset(x: base.width + placement.offset.width * size,
                            y: base.height + placement.offset.height * size)
                    .allowsHitTesting(false)
            } else {
                decoration()
                    .frame(width: containerW, alignment: .center)
                    .offset(y: -size * 0.28)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: containerW, height: containerH, alignment: .topLeading)
    }

    /// 앵커별 head 계열 baseline 오프셋 (size 비례, V2Mongle 좌표 원점 기준).
    private func headBaseline(_ anchor: DecorationAnchor) -> CGSize {
        switch anchor {
        case .onHead:    return CGSize(width: 0, height: -size * 0.28)   // 현행
        case .aboveHead: return CGSize(width: 0, height: -size * 0.40)   // 머리 위로 살짝 띄움(onHead -0.28 대비)
        case .hand:      return CGSize(width: size * 0.40, height: size * 0.30) // 측면·하단 손
        // back/feet 가 head 경로로 들어올 일은 없지만 안전 기본(현행 onHead).
        case .back, .feet: return CGSize(width: 0, height: -size * 0.28)
        }
    }

    private var eye: some View {
        Circle()
            .fill(V2Palette.ink)
            .frame(width: resolvedEye, height: resolvedEye)
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
        eyeSize: CGFloat? = nil,
        hideName: Bool = false,
        dogEars: Bool = false,
        ringColor: Color? = nil,
        shadow: Bool = true,
        backDecorationId: String? = nil,
        feetDecorationId: String? = nil,
        headDecorationId: String? = nil
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
        self.backDecorationId = backDecorationId
        self.feetDecorationId = feetDecorationId
        self.headDecorationId = headDecorationId
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
