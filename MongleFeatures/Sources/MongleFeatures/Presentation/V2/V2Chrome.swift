//
//  V2Chrome.swift
//  Mongle — v2 design handoff
//
//  Shared UI chrome: glass backgrounds, top bar, bottom nav, banner, question
//  card, and an iPhone device frame (status bar + dynamic island + home bar).
//  Glass surfaces use SwiftUI Materials for the iOS blur over pixel-art scenes.
//

import SwiftUI

// MARK: - Glass

/// Translucent blurred surface tinted light or dark, matching the prototype's glass pills.
struct V2Glass: View {
    var dark: Bool = false
    var cornerRadius: CGFloat = 24
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(dark ? Color.black.opacity(0.45) : Color.white.opacity(0.55))
            )
    }
}

// MARK: - Screen frame

/// Wraps screen content into the 393×852 logical artboard with a background.
struct V2ScreenContainer<Content: View>: View {
    var background: AnyView
    @ViewBuilder var content: () -> Content

    init<B: View>(background: B, @ViewBuilder content: @escaping () -> Content) {
        self.background = AnyView(background)
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            background
            content()
        }
        .frame(width: V2Canvas.width, height: V2Canvas.height, alignment: .topLeading)
        .clipped()
    }
}

// MARK: - Top bar

struct V2HeaderTopBar: View {
    var familyName: String = "박씨네"
    var dark: Bool = false
    private var ink: Color { dark ? .white : V2Palette.ink }
    private var chipBg: Color { dark ? Color.white.opacity(0.10) : V2Palette.ink.opacity(0.08) }

    var body: some View {
        HStack {
            HStack(spacing: 2) {
                Text(familyName).font(V2Font.suit(16, .bold)).foregroundStyle(ink)
                Image(systemName: "chevron.down").font(.system(size: 14, weight: .semibold)).foregroundStyle(ink)
            }
            Spacer()
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    icon("heart.fill", 14, V2Palette.heartPink)
                    Text("5").font(V2Font.suit(13, .bold)).foregroundStyle(ink)
                    icon("flame.fill", 14, V2Palette.streak)
                    Text("12").font(V2Font.suit(13, .bold)).foregroundStyle(ink)
                    icon("bell.fill", 14, dark ? .white : V2Palette.mutedSoft)
                        .overlay(alignment: .topTrailing) {
                            Circle().fill(V2Palette.notif)
                                .frame(width: 6, height: 6)
                                .overlay(Circle().strokeBorder(dark ? V2Palette.dark : .white, lineWidth: 1))
                                .offset(x: 1, y: -1)
                        }
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(chipBg, in: Capsule())

                HStack(spacing: 4) {
                    icon("bag.fill", 14, V2Palette.ink)
                    Text("상점").font(V2Font.suit(13, .bold)).foregroundStyle(V2Palette.ink)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(V2Palette.mint, in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(V2Glass(dark: dark, cornerRadius: 24))
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 60)
    }

    private func icon(_ name: String, _ size: CGFloat, _ color: Color) -> some View {
        Image(systemName: name).font(.system(size: size, weight: .semibold)).foregroundStyle(color)
    }
}

// MARK: - Banner

struct V2Banner: View {
    var text: String
    var dark: Bool = false
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(V2Palette.mint).frame(width: 6, height: 6)
            Text(text).font(V2Font.suit(13, .medium)).foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background(Color.black.opacity(dark ? 0.40 : 0.30), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 124)
    }
}

// MARK: - Question card

struct V2QuestionCard: View {
    var label: String = "오늘의 질문"
    var question: String = "엄마가 제일 행복했던 순간은?"
    var status: String = "가족 5명 중 3명 답변 완료"
    var cta: String = "답변 작성하기"
    var dark: Bool = false
    var bottomInset: CGFloat = 132

    private var ink: Color { dark ? .white : V2Palette.ink }
    private var muted: Color { dark ? Color.white.opacity(0.6) : V2Palette.muted }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(V2Palette.coral).frame(width: 6, height: 6)
                Text(label).font(V2Font.suit(12, .bold)).foregroundStyle(V2Palette.coral).tracking(0.3)
            }
            Text(question).font(V2Font.suit(20, .bold)).foregroundStyle(ink)
                .lineSpacing(4).fixedSize(horizontal: false, vertical: true).padding(.top, 8)
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill").font(.system(size: 12)).foregroundStyle(muted)
                Text(status).font(V2Font.suit(13, .medium)).foregroundStyle(muted)
            }.padding(.top, 10)
            HStack(spacing: 6) {
                Text(cta).font(V2Font.suit(15, .bold)).foregroundStyle(V2Palette.ink)
                Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold)).foregroundStyle(V2Palette.ink)
            }
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(V2Palette.mint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.top, 14)
        }
        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(dark ? V2Palette.dark.opacity(0.7) : Color.white.opacity(0.82)))
                .shadow(color: .black.opacity(dark ? 0.5 : 0.10), radius: 15, x: 0, y: 8)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, bottomInset)
    }
}

// MARK: - Bottom nav

struct V2BottomNav: View {
    enum Tab { case home, history, search, my }
    var active: Tab = .home
    var dark: Bool = false

    private let items: [(Tab, String, String)] = [
        (.home, "house.fill", "홈"),
        (.history, "calendar", "히스토리"),
        (.search, "magnifyingglass", "검색"),
        (.my, "person.fill", "MY"),
    ]

    var body: some View {
        HStack {
            ForEach(items, id: \.0) { tab, sf, label in
                let isActive = tab == active
                VStack(spacing: 2) {
                    Image(systemName: sf).font(.system(size: 20, weight: isActive ? .semibold : .regular))
                    Text(label).font(V2Font.suit(10, isActive ? .bold : .medium))
                }
                .foregroundStyle(.white)
                .opacity(isActive ? 1 : 0.6)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 64)
        .background {
            Capsule().fill(.ultraThinMaterial)
                .overlay(Capsule().fill((dark ? V2Palette.dark : V2Palette.ink).opacity(0.78)))
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 50)
    }
}

// MARK: - Device frame (status bar / dynamic island / home indicator)

struct V2StatusBar: View {
    var dark: Bool = false
    var time: String = "9:41"
    private var c: Color { dark ? .white : .black }
    var body: some View {
        HStack {
            Text(time).font(.system(size: 16, weight: .semibold)).foregroundStyle(c)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "cellularbars").font(.system(size: 12, weight: .semibold))
                Image(systemName: "wifi").font(.system(size: 12, weight: .semibold))
                Image(systemName: "battery.75").font(.system(size: 15, weight: .regular))
            }.foregroundStyle(c)
        }
        .padding(.horizontal, 30)
        .frame(height: 54, alignment: .center)
    }
}

/// An iPhone 14-style frame wrapping a v2 screen, used by the showcase gallery.
struct V2PhoneFrame<Content: View>: View {
    var dark: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            content()
                .frame(width: V2Canvas.width, height: V2Canvas.height)
                .clipShape(RoundedRectangle(cornerRadius: 47, style: .continuous))

            V2StatusBar(dark: dark)

            // dynamic island
            Capsule().fill(.black).frame(width: 126, height: 37).padding(.top, 11)

            // home indicator
            Capsule()
                .fill(dark ? Color.white.opacity(0.7) : Color.black.opacity(0.25))
                .frame(width: 139, height: 5)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 9)
        }
        .frame(width: V2Canvas.width, height: V2Canvas.height)
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 47, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 47, style: .continuous).strokeBorder(.black.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 30, x: 0, y: 30)
    }
}

#Preview("V2 Chrome") {
    V2ScreenContainer(background: V2ImageBackground.springField) {
        V2HeaderTopBar()
        V2Banner(text: "엄마가 배경을 '들판'으로 바꿨어요")
        V2QuestionCard()
        V2BottomNav()
    }
}
