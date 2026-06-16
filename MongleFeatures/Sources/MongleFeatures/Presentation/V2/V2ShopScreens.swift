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
    enum Badge { case price(String), applied(String), seasonal(String), owned(String) }
    var name: String
    var sub: String? = nil
    var image: String? = nil
    var swatch: LinearGradient? = nil
    var badge: Badge? = nil

    var body: some View {
        // Color.clear 를 사이즈 기준으로 두면 (flexible) 그리드 셀 폭에 맞춰 정확한 정사각형이
        // 되어, 이미지/스와치 종류와 무관하게 모든 타일이 동일 크기로 보인다. 실제 콘텐츠는
        // overlay 로 얹어 셀 크기를 그대로 따른다. (이전: 콘텐츠 자체에 aspectRatio 를 걸어
        // scaledToFill 이미지의 ideal size 가 새어 타일마다 크기가 달라졌다.)
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            // 이미지/스와치를 셀(정사각)에 채우고 클립한다. scaledToFill 이미지는 프레임 제약이 없으면
            // 뷰가 셀보다 커지는데, 그걸 ZStack 형제로 두면 ZStack 을 늘려 .bottomLeading 이름이
            // 보이는 영역 밖으로 밀려 잘렸다(이미지 셀에서만 이름이 안 보이던 버그). 배경은 셀 크기를
            // 따르는 background 로 깔고, 스크림·이름·배지는 셀 기준 overlay 로 얹어 위치를 고정한다.
            .background {
                if let image {
                    Image(image, bundle: .module).resizable().interpolation(.none).scaledToFill()
                } else if let swatch {
                    swatch
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            // 밝은 픽셀아트 배경에서도 이름이 또렷이 보이도록 하단 스크림을 진하게.
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.20), .black.opacity(0.62)],
                               startPoint: .center, endPoint: .bottom)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(V2Font.suit(15, .heavy)).foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.75), radius: 3, y: 1)
                    if let sub {
                        Text(sub).font(V2Font.suit(11, .medium)).foregroundStyle(.white.opacity(0.85))
                            .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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
        case .owned(let t):
            // 보유중 — 적용중(민트)과 구분되는 중립 흰색 칩.
            Text(t).font(V2Font.suit(12, .heavy)).foregroundStyle(V2Palette.ink)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(.white.opacity(0.92), in: Capsule())
        case .seasonal(let p):
            // 시즌 한정도 하트+가격을 함께 표기(가격만 보이던 문제 수정). coral 배경으로 시즌 구분 유지.
            HStack(spacing: 4) {
                Image(systemName: "heart.fill").font(.system(size: 12)).foregroundStyle(V2Palette.heartPink)
                Text(p).font(V2Font.suit(12, .heavy)).foregroundStyle(V2Palette.ink)
            }
            .padding(.horizontal, 10).padding(.vertical, 4)
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
                    Text("가족이 함께 보는 홈 배경")
                        .font(V2Font.suit(13, .medium)).foregroundStyle(V2Palette.muted)
                    LazyVGrid(columns: cols, spacing: 12) {
                        V2BgTile(name: "따뜻한 집", sub: "기본 배경",
                                 swatch: LinearGradient(colors: [Color(hex: "FFE5C2"), Color(hex: "F1C18A"), Color(hex: "C9885A")], startPoint: .topLeading, endPoint: .bottomTrailing),
                                 badge: .applied("적용중"))
                        V2BgTile(name: "봄 들판", image: "V2BgSpringField", badge: .price("50"))
                        V2BgTile(name: "바닷가", image: "V2BgBeach", badge: .price("50"))
                        V2BgTile(name: "우주", image: "V2BgSpace", badge: .price("50"))
                        V2BgTile(name: "눈오는 마을", image: "V2BgSnowVillage", badge: .price("50"))
                        V2BgTile(name: "벚꽃길", image: "V2BgCherryBlossom", badge: .price("50"))
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
        // 미리보기/이름/상태 영역의 높이를 고정해 콘텐츠(장착중 배지·가격·없음)에 상관없이
        // 모든 타일이 동일한 셀 크기를 갖게 한다 (이전엔 행마다 높이가 달라 셀 크기가 들쭉날쭉했음).
        VStack(spacing: 6) {
            preview().frame(width: 56, height: 56)
            Text(name).font(V2Font.suit(12, .bold)).foregroundStyle(V2Palette.ink)
                .lineLimit(1).minimumScaleFactor(0.8)
                .frame(height: 16)
            statusLabel.frame(height: 20)
        }
        .padding(12)
        .frame(maxWidth: .infinity).aspectRatio(1 / 1.05, contentMode: .fit)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(equipped ? V2Palette.mint : V2Palette.hairline, lineWidth: equipped ? 2 : 1))
        .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
    }

    // 상태 라벨 — 장착중(민트 배지) / 가격(하트+숫자) / 없음(빈 영역). 고정 높이 컨테이너 안에 둔다.
    @ViewBuilder private var statusLabel: some View {
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

                    V2Mongle(color: V2Palette.alex, size: 86, hideName: true) { V2FlowerCrown() }
                        .padding(.top, 16)

                    Text("머리·등·발밑을 바꿔가며 꾸며보세요")
                        .font(V2Font.suit(13, .medium)).foregroundStyle(V2Palette.muted)
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
