//
//  V2ShopScreens.swift
//  Mongle — v2 design handoff
//
//  Screens 03 (Shop · 배경 catalog) and 04 (Shop · 꾸미기 catalog).
//

import SwiftUI

// MARK: - Shop header (title + hearts + tabs)

struct V2ShopHeader: View {
    enum Tab { case bg, dec }
    var active: Tab

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(V2Palette.ink)
                    .frame(width: 36, height: 36)
                    .background(.white, in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                Text("상점").font(V2Font.suit(22, .heavy)).foregroundStyle(V2Palette.ink)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill").font(.system(size: 16)).foregroundStyle(V2Palette.heartPink)
                    Text("5").font(V2Font.suit(14, .bold)).foregroundStyle(V2Palette.ink)
                    Rectangle().fill(V2Palette.hairline).frame(width: 1, height: 14).padding(.horizontal, 4)
                    Image(systemName: "plus").font(.system(size: 16, weight: .semibold)).foregroundStyle(V2Palette.mintInk)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
            .padding(.horizontal, 20)
            .frame(height: 60)

            HStack(spacing: 24) {
                tab("배경", isActive: active == .bg)
                tab("꾸미기", isActive: active == .dec)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .overlay(alignment: .bottom) {
                Rectangle().fill(V2Palette.hairline).frame(height: 1)
            }
        }
        .padding(.top, 56)
        .background(V2Palette.cream)
    }

    private func tab(_ title: String, isActive: Bool) -> some View {
        Text(title)
            .font(V2Font.suit(14, isActive ? .heavy : .semibold))
            .foregroundStyle(isActive ? V2Palette.ink : V2Palette.muted)
            .padding(.bottom, 12)
            .overlay(alignment: .bottom) {
                if isActive {
                    Capsule().fill(V2Palette.mint).frame(height: 3)
                }
            }
    }
}

// MARK: - Background tile

struct V2BgTile: View {
    enum Badge { case price(String), applied(String), seasonal(String) }
    var name: String
    var sub: String? = nil
    var image: String? = nil
    var swatch: LinearGradient? = nil
    var badge: Badge? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let image {
                Image(image, bundle: .module).resizable().interpolation(.none).scaledToFill()
            } else if let swatch {
                swatch
            }
            LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(V2Font.suit(15, .heavy)).foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
                if let sub {
                    Text(sub).font(V2Font.suit(11, .medium)).foregroundStyle(.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
                }
            }
            .padding(12)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .topTrailing) { badgeView.padding(10) }
        .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
    }

    @ViewBuilder private var badgeView: some View {
        switch badge {
        case .price(let p):
            HStack(spacing: 4) {
                Image(systemName: "heart.fill").font(.system(size: 12)).foregroundStyle(V2Palette.heartPink)
                Text(p).font(V2Font.suit(12, .heavy)).foregroundStyle(V2Palette.ink)
            }
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(.white.opacity(0.92), in: Capsule())
        case .applied(let t):
            Text(t).font(V2Font.suit(12, .heavy)).foregroundStyle(V2Palette.ink)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(V2Palette.mint, in: Capsule())
        case .seasonal(let t):
            Text(t).font(V2Font.suit(9, .heavy)).foregroundStyle(V2Palette.ink).tracking(0.5)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(V2Palette.coral, in: Capsule())
        case .none:
            EmptyView()
        }
    }
}

// MARK: - 03 · Shop 배경

struct V2Screen03ShopBackgrounds: View {
    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        V2ScreenContainer(background: V2Palette.cream) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("가족이 함께 보는 홈 배경 · 7종")
                        .font(V2Font.suit(13, .semibold)).foregroundStyle(V2Palette.muted)
                    LazyVGrid(columns: cols, spacing: 12) {
                        V2BgTile(name: "따뜻한 집", sub: "기본 배경",
                                 swatch: LinearGradient(colors: [Color(hex: "FFE5C2"), Color(hex: "F1C18A"), Color(hex: "C9885A")], startPoint: .topLeading, endPoint: .bottomTrailing),
                                 badge: .applied("적용중"))
                        V2BgTile(name: "봄 들판", image: "V2BgSpringField", badge: .price("20"))
                        V2BgTile(name: "바닷가", image: "V2BgBeach", badge: .price("35"))
                        V2BgTile(name: "우주", image: "V2BgSpace", badge: .price("50"))
                        V2BgTile(name: "숲속",
                                 swatch: LinearGradient(colors: [Color(hex: "15120F"), Color(hex: "1F2A1E"), Color(hex: "233326"), Color(hex: "1A2418")], startPoint: .top, endPoint: .bottom),
                                 badge: .price("45"))
                        V2BgTile(name: "눈오는 마을", image: "V2BgSnowVillage", badge: .seasonal("60"))
                        V2BgTile(name: "벚꽃길", image: "V2BgCherryBlossom", badge: .price("60"))
                        comingSoon
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .padding(.top, 158)

            V2ShopHeader(active: .bg)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var comingSoon: some View {
        VStack(spacing: 6) {
            Image(systemName: "clock").font(.system(size: 28)).foregroundStyle(V2Palette.mutedSoft)
            Text("더 많은 배경이\n곧 추가돼요").font(V2Font.suit(12, .semibold))
                .foregroundStyle(V2Palette.mutedSoft).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
            .foregroundStyle(V2Palette.muted))
    }
}

// MARK: - Decoration slot segments + tile

struct V2SlotSeg: View {
    var title: String
    var active: Bool = false
    var body: some View {
        Text(title)
            .font(V2Font.suit(12, .bold))
            .foregroundStyle(active ? .white : V2Palette.muted)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(active ? V2Palette.ink : .clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct V2DecoTile<Preview: View>: View {
    var name: String
    var price: String? = nil
    var equipped: Bool = false
    @ViewBuilder var preview: () -> Preview

    var body: some View {
        VStack(spacing: 6) {
            preview().frame(height: 56)
            Text(name).font(V2Font.suit(12, .bold)).foregroundStyle(V2Palette.ink)
                .multilineTextAlignment(.center)
            if equipped {
                Text("장착중").font(V2Font.suit(10, .heavy)).foregroundStyle(V2Palette.ink)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(V2Palette.mint, in: Capsule())
            } else if let price {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").font(.system(size: 12)).foregroundStyle(V2Palette.heartPink)
                    Text(price).font(V2Font.suit(11, .heavy)).foregroundStyle(V2Palette.ink)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity).aspectRatio(1 / 1.05, contentMode: .fit)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(equipped ? V2Palette.mint : V2Palette.hairline, lineWidth: equipped ? 2 : 1))
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }
}

// MARK: - 04 · Shop 꾸미기

struct V2Screen04ShopDecorations: View {
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        V2ScreenContainer(background: V2Palette.cream) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        V2SlotSeg(title: "머리", active: true)
                        V2SlotSeg(title: "등")
                        V2SlotSeg(title: "발밑")
                    }
                    .padding(4)
                    .background(V2Palette.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    V2Mongle(color: V2Palette.alex, size: 86, eyeSize: 14, hideName: true) { V2FlowerCrown() }
                        .padding(.top, 16)

                    Text("세그먼트 전환 시 슬롯별 5종이 노출됩니다 (머리 슬롯)")
                        .font(V2Font.suit(12, .medium)).foregroundStyle(V2Palette.muted)
                        .padding(.top, 8)

                    LazyVGrid(columns: cols, spacing: 10) {
                        V2DecoTile(name: "장식 없음", equipped: true) {
                            Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                .foregroundStyle(V2Palette.muted).frame(width: 40, height: 40)
                        }
                        V2DecoTile(name: "들꽃 화관", price: "35") { V2FlowerCrown(small: true) }
                        V2DecoTile(name: "별 후광", price: "40") { V2StarHalo() }
                        V2DecoTile(name: "새틴 리본", price: "25") { V2SatinRibbon() }
                        V2DecoTile(name: "풍선 다발", price: "50") { V2BalloonBunch() }
                        V2DecoTile(name: "산타 모자", price: "60") { V2SantaHat() }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .padding(.top, 158)

            V2ShopHeader(active: .dec)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

#Preview("03 · Shop 배경") { V2Screen03ShopBackgrounds() }
#Preview("04 · Shop 꾸미기") { V2Screen04ShopDecorations() }
