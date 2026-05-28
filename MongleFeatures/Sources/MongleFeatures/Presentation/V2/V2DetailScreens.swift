//
//  V2DetailScreens.swift
//  Mongle — v2 design handoff
//
//  Screens 05 (배경 상세), 06 (장식 상세), 07 (구매 확인 sheet), 08 (하트 부족 modal).
//

import SwiftUI

// MARK: - Shared bits

struct V2CloseButton: View {
    var systemName: String = "xmark"
    var dark: Bool = false
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(dark ? .white : V2Palette.ink)
            .frame(width: 40, height: 40)
            .background {
                Circle().fill(.ultraThinMaterial)
                    .overlay(Circle().fill(dark ? Color.black.opacity(0.45) : Color.white.opacity(0.7)))
            }
            .padding(.leading, 16).padding(.top, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct V2SheetHandle: View {
    var body: some View {
        Capsule().fill(.black.opacity(0.25)).frame(width: 40, height: 4)
            .frame(maxWidth: .infinity).padding(.bottom, 12)
    }
}

// MARK: - 05 · 배경 상세 (봄 들판)

struct V2Screen05BgDetail: View {
    var body: some View {
        V2ScreenContainer(background: V2ImageBackground.springField) {
            V2CloseButton()

            // mini preview scene
            ZStack(alignment: .topLeading) {
                mini(V2Palette.dad, x: 60, y: 390)
                miniCrown(V2Palette.mom, x: 150, y: 370)
                mini(V2Palette.lily, x: 240, y: 410)
                mini(V2Palette.ben, x: 310, y: 380, dogEars: true)
                mini(V2Palette.alex, x: 120, y: 470, ring: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // bottom sheet
            VStack(alignment: .leading, spacing: 0) {
                V2SheetHandle()
                Text("봄 들판").font(V2Font.suit(28, .heavy)).foregroundStyle(V2Palette.ink)
                Text("봄날 들판의 들꽃과 민들레 위에서 가족 몽글이 뛰어놀아요. 낮 시간대에 가장 따뜻한 인사를 전합니다.")
                    .font(V2Font.suit(14, .regular)).foregroundStyle(V2Palette.mutedSoft)
                    .lineSpacing(5).padding(.top, 8)
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill").font(.system(size: 14)).foregroundStyle(V2Palette.mutedSoft)
                    Text("그룹 공유 — 구매 시 가족 전원에게 개방")
                        .font(V2Font.suit(12, .regular)).foregroundStyle(V2Palette.mutedSoft)
                }.padding(.top, 14)
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill").font(.system(size: 20)).foregroundStyle(V2Palette.heartPink)
                    Text("하트 20개로 구매하기").font(V2Font.suit(16, .heavy)).foregroundStyle(V2Palette.ink)
                }
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(V2Palette.mint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 16)
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 32)
            .frame(maxWidth: .infinity)
            .background {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: 28, topTrailing: 28))
                    .fill(.ultraThinMaterial)
                    .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 28, topTrailing: 28))
                        .fill(Color.white.opacity(0.85)))
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func mini(_ c: Color, x: CGFloat, y: CGFloat, dogEars: Bool = false, ring: Bool = false) -> some View {
        V2Mongle(color: c, size: 54, eyeSize: 10, hideName: true, dogEars: dogEars,
                 ringColor: ring ? V2Palette.mint : nil)
            .offset(x: x, y: y)
    }
    private func miniCrown(_ c: Color, x: CGFloat, y: CGFloat) -> some View {
        V2Mongle(color: c, size: 54, eyeSize: 10, hideName: true) { V2FlowerCrown(small: true) }
            .offset(x: x, y: y)
    }
}

// MARK: - 06 · 장식 상세 (들꽃 화관)

struct V2Screen06DecoDetail: View {
    var body: some View {
        let bg = LinearGradient(colors: [Color(hex: "FFEEDB"), Color(hex: "FFD9B3"), Color(hex: "F7B68A")],
                                startPoint: .top, endPoint: .bottom)
        return V2ScreenContainer(background: bg) {
            V2CloseButton()

            Text("머리 슬롯 · 화관")
                .font(V2Font.suit(12, .bold)).foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.black.opacity(0.55), in: Capsule())
                .frame(maxWidth: .infinity, alignment: .center).padding(.top, 72)

            // compare with / without
            HStack(spacing: 0) {
                compare(label: "미장착", labelDark: false) {
                    V2Mongle(color: V2Palette.alex, size: 96, eyeSize: 16, hideName: true)
                }
                compare(label: "장착", labelDark: true) {
                    V2Mongle(color: V2Palette.alex, size: 96, eyeSize: 16, hideName: true) { V2FlowerCrown() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 160)

            // bottom sheet
            VStack(alignment: .leading, spacing: 0) {
                V2SheetHandle()
                Text("들꽃 화관").font(V2Font.suit(24, .heavy)).foregroundStyle(V2Palette.ink)
                Text("봄 들녘에서 따온 다섯 송이 화관. 어떤 배경에서도 잘 어울리는 가족 친화 디폴트.")
                    .font(V2Font.suit(14, .regular)).foregroundStyle(V2Palette.mutedSoft)
                    .lineSpacing(5).padding(.top, 8)
                HStack(spacing: 6) {
                    Image(systemName: "person.fill").font(.system(size: 14)).foregroundStyle(V2Palette.mutedSoft)
                    Text("개인 소유 — 내 몽글만 장착")
                        .font(V2Font.suit(12, .regular)).foregroundStyle(V2Palette.mutedSoft)
                }.padding(.top, 12)
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill").font(.system(size: 18)).foregroundStyle(V2Palette.heartPink)
                    Text("35 · 구매 후 바로 장착").font(V2Font.suit(15, .heavy)).foregroundStyle(V2Palette.ink)
                }
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(V2Palette.mint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.top, 14)
                Text("구매 직후 자동 장착").font(V2Font.suit(12, .regular)).foregroundStyle(V2Palette.mutedSoft)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.top, 10)
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 32)
            .frame(maxWidth: .infinity)
            .background {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: 28, topTrailing: 28))
                    .fill(Color.white.opacity(0.95))
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func compare<V: View>(label: String, labelDark: Bool, @ViewBuilder mongle: () -> V) -> some View {
        VStack(spacing: 12) {
            mongle()
            Text(label).font(V2Font.suit(11, .bold))
                .foregroundStyle(labelDark ? .white : V2Palette.ink)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(labelDark ? AnyShapeStyle(V2Palette.ink) : AnyShapeStyle(Color.white.opacity(0.6)), in: Capsule())
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 07 · 구매 확인 Sheet

struct V2Screen07PurchaseSheet: View {
    var body: some View {
        V2ScreenContainer(background: purchaseBackdrop) {
            VStack(alignment: .leading, spacing: 0) {
                V2SheetHandle()
                Text("하트 80개를 사용해\n'우주' 배경을 구매할까요?")
                    .font(V2Font.suit(20, .heavy)).foregroundStyle(V2Palette.ink).lineSpacing(5)

                // product row
                HStack(spacing: 14) {
                    Image("V2BgSpace", bundle: .module).resizable().interpolation(.none).scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("우주").font(V2Font.suit(15, .heavy)).foregroundStyle(V2Palette.ink)
                        Text("그룹 공유 · 영구 이용").font(V2Font.suit(12, .regular)).foregroundStyle(V2Palette.muted)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill").font(.system(size: 18)).foregroundStyle(V2Palette.heartPink)
                        Text("80").font(V2Font.suit(16, .heavy)).foregroundStyle(V2Palette.ink)
                    }
                }
                .padding(14)
                .background(V2Palette.cream, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 16)

                // balance row
                HStack {
                    Text("구매 후 남는 하트").font(V2Font.suit(13, .regular)).foregroundStyle(V2Palette.mutedSoft)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("100").font(V2Font.suit(13, .regular)).foregroundStyle(V2Palette.mutedSoft).strikethrough()
                        Image(systemName: "arrow.right").font(.system(size: 12)).foregroundStyle(V2Palette.muted)
                        Image(systemName: "heart.fill").font(.system(size: 14)).foregroundStyle(V2Palette.heartPink)
                        Text("20").font(V2Font.suit(14, .heavy)).foregroundStyle(V2Palette.ink)
                    }
                }
                .padding(.horizontal, 4).padding(.vertical, 10).padding(.top, 12)

                // CTAs
                HStack(spacing: 10) {
                    Text("취소").font(V2Font.suit(15, .bold)).foregroundStyle(V2Palette.mutedSoft)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Color(hex: "F1ECE3"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Text("구매하기").font(V2Font.suit(15, .heavy)).foregroundStyle(V2Palette.ink)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(V2Palette.mint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .layoutPriority(1)
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 28)
            .frame(maxWidth: .infinity)
            .background {
                UnevenRoundedRectangle(cornerRadii: .init(topLeading: 28, topTrailing: 28)).fill(.white)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var purchaseBackdrop: some View {
        ZStack {
            V2ImageBackground(assetName: "V2BgSpace", opacity: 0.7)
            Color.black.opacity(0.32)
        }
    }
}

// MARK: - 08 · 하트 부족 Modal

struct V2Screen08NotEnoughHearts: View {
    var body: some View {
        let backdrop = ZStack {
            LinearGradient(colors: [Color(hex: "FFE5C2"), Color(hex: "F1A86C")], startPoint: .top, endPoint: .bottom)
                .opacity(0.6)
            Color.black.opacity(0.32)
        }
        return V2ScreenContainer(background: backdrop) {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(Color(hex: "FFEBEE")).frame(width: 64, height: 64)
                    Image(systemName: "heart.slash.fill").font(.system(size: 32)).foregroundStyle(V2Palette.heartPink)
                }
                Text("하트가 부족해요").font(V2Font.suit(20, .heavy)).foregroundStyle(V2Palette.ink).padding(.top, 16)
                Text("현재 5/80 · 75개 더 필요해요\n아래 방법으로 하트를 모아보세요")
                    .font(V2Font.suit(13, .regular)).foregroundStyle(V2Palette.muted)
                    .multilineTextAlignment(.center).lineSpacing(4).padding(.top, 6)

                VStack(spacing: 10) {
                    actionRow(icon: "play.circle.fill", iconBg: Color(hex: "FFE082"),
                              title: "광고 보고 +1 하트", subtitle: "2/3 남음")
                    actionRow(icon: "pencil", iconBg: V2Palette.mint,
                              title: "오늘의 질문에 답변하기", subtitle: "+2 하트")
                }
                .padding(.top, 20)

                Text("나중에 구매하기").font(V2Font.suit(13, .semibold)).foregroundStyle(V2Palette.mutedSoft)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 24).padding(.top, 28).padding(.bottom, 22)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white)
                    .shadow(color: .black.opacity(0.25), radius: 30, y: 24)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func actionRow(icon: String, iconBg: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 22)).foregroundStyle(V2Palette.ink)
                .frame(width: 40, height: 40)
                .background(iconBg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(V2Font.suit(13, .bold)).foregroundStyle(V2Palette.ink)
                Text(subtitle).font(V2Font.suit(11, .medium)).foregroundStyle(V2Palette.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 18)).foregroundStyle(V2Palette.muted)
        }
        .padding(14)
        .background(V2Palette.cream, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview("05 · 배경 상세") { V2Screen05BgDetail() }
#Preview("06 · 장식 상세") { V2Screen06DecoDetail() }
#Preview("07 · 구매 Sheet") { V2Screen07PurchaseSheet() }
#Preview("08 · 하트 부족") { V2Screen08NotEnoughHearts() }
