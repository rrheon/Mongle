//
//  V2HomeScreens.swift
//  Mongle — v2 design handoff
//
//  Screens 01a (cozy-home default), 01 (light · field), 02 (dark · space).
//  The family Mongles are scattered at the prototype's absolute coordinates.
//

import SwiftUI

/// One placed family member on the home scene.
private struct V2FamilyMember: Identifiable {
    let id = UUID()
    var color: Color
    var name: String?
    var nameColor: Color = .white
    var badgeIcon: String
    var badgeColor: Color = V2Palette.mint
    var dogEars: Bool = false
    var ringColor: Color? = nil
    var crown: Bool = false
    var x: CGFloat
    var y: CGFloat
}

private struct V2FamilyScatter: View {
    var members: [V2FamilyMember]
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(members) { m in
                Group {
                    if m.crown {
                        V2Mongle(color: m.color, name: m.name, nameColor: m.nameColor,
                                 badgeIcon: m.badgeIcon, badgeColor: m.badgeColor,
                                 dogEars: m.dogEars, ringColor: m.ringColor) { V2FlowerCrown() }
                    } else {
                        V2Mongle(color: m.color, name: m.name, nameColor: m.nameColor,
                                 badgeIcon: m.badgeIcon, badgeColor: m.badgeColor,
                                 dogEars: m.dogEars, ringColor: m.ringColor)
                    }
                }
                .offset(x: m.x, y: m.y)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - 01a · Home (기본 · 따뜻한 집)

struct V2Screen01HomeDefault: View {
    var body: some View {
        V2ScreenContainer(background: V2CozyHomeBackground()) {
            V2HeaderTopBar()
            V2Banner(text: "모두 따뜻한 집에 모였어요")
            V2FamilyScatter(members: [
                .init(color: V2Palette.dad, name: "아빠", badgeIcon: "checkmark", x: 60, y: 300),
                .init(color: V2Palette.mom, name: "엄마", badgeIcon: "checkmark", crown: true, x: 240, y: 280),
                .init(color: V2Palette.lily, name: "릴리", badgeIcon: "hourglass", badgeColor: V2Palette.muted, x: 30, y: 420),
                .init(color: V2Palette.ben, name: "벤", badgeIcon: "hourglass", badgeColor: V2Palette.purple, dogEars: true, x: 270, y: 440),
                .init(color: V2Palette.alex, name: "나 (알렉스)", nameColor: V2Palette.mint, badgeIcon: "bolt.fill", badgeColor: V2Palette.streak, ringColor: V2Palette.mint, x: 150, y: 480),
            ])
            V2QuestionCard()
            V2BottomNav(active: .home)
        }
    }
}

// MARK: - 01 · Home (Light · 들판)

struct V2Screen01HomeLight: View {
    var body: some View {
        V2ScreenContainer(background: V2ImageBackground.springField) {
            V2HeaderTopBar()
            V2Banner(text: "엄마가 배경을 '들판'으로 바꿨어요")
            V2FamilyScatter(members: [
                .init(color: V2Palette.dad, name: "아빠", badgeIcon: "checkmark", x: 60, y: 290),
                .init(color: V2Palette.mom, name: "엄마", badgeIcon: "checkmark", crown: true, x: 240, y: 260),
                .init(color: V2Palette.lily, name: "릴리", badgeIcon: "hourglass", badgeColor: V2Palette.muted, x: 30, y: 400),
                .init(color: V2Palette.ben, name: "벤", badgeIcon: "hourglass", badgeColor: V2Palette.purple, dogEars: true, x: 270, y: 420),
                .init(color: V2Palette.alex, name: "나 (알렉스)", nameColor: V2Palette.mint, badgeIcon: "bolt.fill", badgeColor: V2Palette.streak, ringColor: V2Palette.mint, x: 150, y: 460),
            ])
            V2QuestionCard()
            V2BottomNav(active: .home)
        }
    }
}

// MARK: - 02 · Home (Dark · 우주)

struct V2Screen02HomeDark: View {
    var body: some View {
        V2ScreenContainer(background: V2ImageBackground.space) {
            V2HeaderTopBar(dark: true)
            V2Banner(text: "릴리가 답변을 남겼어요", dark: true)
            V2FamilyScatter(members: [
                .init(color: V2Palette.dad, name: "아빠", badgeIcon: "checkmark", x: 60, y: 290),
                .init(color: V2Palette.mom, name: "엄마", badgeIcon: "checkmark", crown: true, x: 240, y: 260),
                .init(color: V2Palette.lily, name: "릴리", badgeIcon: "checkmark", x: 30, y: 400),
                .init(color: V2Palette.ben, name: "벤", badgeIcon: "hourglass", badgeColor: V2Palette.purple, dogEars: true, x: 270, y: 420),
                .init(color: V2Palette.alex, name: "나 (알렉스)", nameColor: V2Palette.mint, badgeIcon: "bolt.fill", badgeColor: V2Palette.streak, ringColor: V2Palette.mint, x: 150, y: 460),
            ])
            V2QuestionCard(dark: true)
            V2BottomNav(active: .home, dark: true)
        }
    }
}

#Preview("01a · 따뜻한 집") { V2Screen01HomeDefault() }
#Preview("01 · 들판") { V2Screen01HomeLight() }
#Preview("02 · 우주") { V2Screen02HomeDark() }
