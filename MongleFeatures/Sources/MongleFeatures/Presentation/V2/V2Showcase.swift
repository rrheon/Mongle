//
//  V2Showcase.swift
//  Mongle — v2 design handoff
//
//  Review canvas: all implemented v2 screens (Home + Shop, 01a–08) shown in
//  iPhone frames, grouped by section. Mirrors the prototype's design canvas.
//

import SwiftUI

struct V2Showcase: View {
    private struct Item: Identifiable {
        let id = UUID()
        let label: String
        let dark: Bool
        let view: AnyView
    }
    private struct Section: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let items: [Item]
    }

    private let scale: CGFloat = 0.42

    private var sections: [Section] {
        [
            Section(title: "홈", subtitle: "가족 몽글이 모이는 메인 화면", items: [
                Item(label: "01a · 따뜻한 집", dark: false, view: AnyView(V2Screen01HomeDefault())),
                Item(label: "01 · 들판 (Light)", dark: false, view: AnyView(V2Screen01HomeLight())),
                Item(label: "02 · 우주 (Dark)", dark: true, view: AnyView(V2Screen02HomeDark())),
            ]),
            Section(title: "상점 & 구매", subtitle: "배경/꾸미기 카탈로그, 상세, 구매 시트, 하트 부족", items: [
                Item(label: "03 · Shop 배경", dark: false, view: AnyView(V2Screen03ShopBackgrounds())),
                Item(label: "04 · Shop 꾸미기", dark: false, view: AnyView(V2Screen04ShopDecorations())),
                Item(label: "05 · 배경 상세", dark: false, view: AnyView(V2Screen05BgDetail())),
                Item(label: "06 · 장식 상세", dark: false, view: AnyView(V2Screen06DecoDetail())),
                Item(label: "07 · 구매 Sheet", dark: true, view: AnyView(V2Screen07PurchaseSheet())),
                Item(label: "08 · 하트 부족", dark: false, view: AnyView(V2Screen08NotEnoughHearts())),
            ]),
            Section(title: "히스토리 & 마이", subtitle: "캘린더 답변 트래커, 프로필, 알림 설정", items: [
                Item(label: "09 · 히스토리", dark: false, view: AnyView(V2Screen09History())),
                Item(label: "10 · MY / Settings", dark: false, view: AnyView(V2Screen10Settings())),
                Item(label: "11 · 알림 설정 (Dark)", dark: true, view: AnyView(V2Screen11SettingsDark())),
            ]),
            Section(title: "온보딩 · 그룹 · 답변", subtitle: "로그인부터 그룹 생성, 답변 작성까지", items: [
                Item(label: "12 · Auth Login", dark: false, view: AnyView(V2Screen12AuthLogin())),
                Item(label: "13 · Group List", dark: false, view: AnyView(V2Screen13GroupList())),
                Item(label: "14 · Create Group", dark: false, view: AnyView(V2Screen14CreateGroup())),
                Item(label: "15 · Answer Write", dark: false, view: AnyView(V2Screen15AnswerWrite())),
            ]),
            Section(title: "알림", subtitle: "알림 인박스 + 설정", items: [
                Item(label: "16 · Notifications", dark: false, view: AnyView(V2Screen16Notifications())),
                Item(label: "17 · Notification Settings", dark: false, view: AnyView(V2Screen17NotificationSettings())),
            ]),
        ]
    }

    private let columns = [GridItem(.adaptive(minimum: 393 * 0.42 + 16), spacing: 28, alignment: .top)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("몽글 v2").font(V2Font.suit(34, .heavy)).foregroundStyle(V2Palette.ink)
                    Text("17 화면 · iPhone 14 (393×852)")
                        .font(V2Font.suit(14, .medium)).foregroundStyle(V2Palette.muted)
                }

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title).font(V2Font.suit(20, .heavy)).foregroundStyle(V2Palette.ink)
                            Text(section.subtitle).font(V2Font.suit(13, .regular)).foregroundStyle(V2Palette.muted)
                        }
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 28) {
                            ForEach(section.items) { item in
                                VStack(spacing: 10) {
                                    V2PhoneFrame(dark: item.dark) { item.view }
                                        .frame(width: 393, height: 852)
                                        .scaleEffect(scale)
                                        .frame(width: 393 * scale, height: 852 * scale)
                                    Text(item.label).font(V2Font.suit(12, .semibold)).foregroundStyle(V2Palette.mutedSoft)
                                }
                            }
                        }
                    }
                }
            }
            .padding(28)
        }
        .background(Color(hex: "F0EEE9"))
    }
}

#Preview("V2 Showcase — 17 화면") {
    V2Showcase()
}
