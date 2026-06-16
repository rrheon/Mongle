//
//  ShopView.swift
//  MongleFeatures
//
//  상점 화면. 최상위 탭(배경/꾸미기) + 꾸미기 슬롯(머리/등/발밑) + 미리보기 + 그리드.
//  V2Screen03/04 의 구성을 재사용하되 하드코딩 값을 store 바인딩으로 교체했다.
//  하트 "충전" UI 는 제거 — 하트 잔량만 표시하고, 부족 시 정보성 안내 팝업만 띄운다.
//

import SwiftUI
import ComposableArchitecture
import Domain

struct ShopView: View {
    @Bindable var store: StoreOf<ShopFeature>

    /// 미리보기(상세) 화면 대상 — 타일을 탭하면 세팅. nil 이면 미표시.
    /// kind 에 따라 배경/장식 상세 화면을 풀스크린으로 띄운다 (즉시 구매/적용 팝업 대체).
    @State private var previewItem: ShopItem?
    /// 하트 부족 안내 팝업 표시 여부 (충전 버튼 없음).
    @State private var showInsufficient = false
    /// 꾸미기 미리보기 — 탭한 장식을 (구매 전에도) 활성 슬롯에 미리 얹어 캐릭터에 보여준다.
    /// 슬롯 전환 시 해제. nil 이면 장착 상태 그대로 표시.
    @State private var decoPreviewId: String?
    /// 배경 미리보기 — 탭한 배경을 상단 미리보기 패널에 보여준다. nil 이면 적용 중 배경.
    @State private var bgPreviewId: String?

    private let decoCols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    private let bgCols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack(alignment: .top) {
            V2Palette.cream.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                if store.activeTab == .decoration {
                    decorationContent
                } else {
                    backgroundContent
                }
            }
            .padding(.top, 150)

            header
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { store.send(.onAppear) }
        .mongleErrorToast(
            error: store.appError,
            onDismiss: { store.send(.dismissError) }
        )
        .overlay { insufficientPopup }
        // 타일 탭 → 즉시 팝업 대신 미리보기(상세) 화면으로 push (부모 MainTab NavigationStack 에 얹는다).
        // fullScreenCover 모달 대신 네이티브 슬라이드 전환. 닫기/구매/적용은 상세 하단 액션바에서.
        .navigationDestination(item: $previewItem) { item in
            Group {
                if item.kind == .background {
                    ShopBgDetailView(
                        store: store,
                        item: item,
                        onClose: { previewItem = nil },
                        onInsufficient: {
                            previewItem = nil
                            showInsufficient = true
                        }
                    )
                } else {
                    ShopDecoDetailView(
                        store: store,
                        item: item,
                        onClose: { previewItem = nil },
                        onInsufficient: {
                            previewItem = nil
                            showInsufficient = true
                        }
                    )
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Header (탭 전환 + 하트 잔량 표시 — 충전 액션 없음)

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button { store.send(.backTapped) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold)).foregroundStyle(V2Palette.ink)
                        .frame(width: 36, height: 36)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                Text(L10n.tr("shop_title")).font(V2Font.suit(22, .heavy)).foregroundStyle(V2Palette.ink)
                Spacer()
                // 하트 잔량 칩 — 표시 전용 (충전 plus 아이콘/구분선 제거, 탭 동작 없음).
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill").font(.system(size: 16)).foregroundStyle(V2Palette.heartPink)
                    Text("\(store.hearts)").font(V2Font.suit(14, .bold)).foregroundStyle(V2Palette.ink)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
            .padding(.horizontal, 20)
            .frame(height: 60)

            // 배경/꾸미기 탭 — 둘 다 활성, 전환 가능.
            HStack(spacing: 24) {
                Button { store.send(.tabSelected(.background)) } label: {
                    tabLabel(L10n.tr("shop_tab_background"), isActive: store.activeTab == .background)
                }
                .buttonStyle(.plain)
                Button { store.send(.tabSelected(.decoration)) } label: {
                    tabLabel(L10n.tr("shop_tab_decoration"), isActive: store.activeTab == .decoration)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .overlay(alignment: .bottom) {
                Rectangle().fill(V2Palette.hairline).frame(height: 1)
            }
        }
        .padding(.top, 8)
        .background(V2Palette.cream)
    }

    private func tabLabel(_ title: String, isActive: Bool) -> some View {
        Text(title)
            .font(V2Font.suit(14, isActive ? .heavy : .semibold))
            .foregroundStyle(isActive ? V2Palette.ink : V2Palette.muted)
            .padding(.bottom, 12)
            .overlay(alignment: .bottom) {
                if isActive { Capsule().fill(V2Palette.mint).frame(height: 3) }
            }
    }

    // 두 탭(꾸미기/배경) 캡션을 한 스타일로 통일한다 — 좌측 정렬 + 동일 타이포(13 medium muted).
    // 단일 진실로 두어 향후 한쪽만 바뀌는 드리프트를 막는다.
    private func hint(_ text: String) -> some View {
        Text(text)
            .font(V2Font.suit(13, .medium))
            .foregroundStyle(V2Palette.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Decoration tab content

    private var decorationContent: some View {
        VStack(spacing: 0) {
            slotSegments
                .padding(4)
                .background(V2Palette.ink.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            preview
                .padding(.top, 16)

            hint(L10n.tr("shop_slot_hint"))
                .padding(.top, 8)

            decoGrid
                .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 40)
    }

    // 슬롯 세그(머리/등/발밑) — 전부 활성, 탭 전환 가능.
    private var slotSegments: some View {
        HStack(spacing: 8) {
            ForEach(DecorationSlot.allCases, id: \.self) { slot in
                Button {
                    store.send(.slotSelected(slot))
                    decoPreviewId = nil   // 슬롯 바뀌면 미리보기 해제
                } label: {
                    V2SlotSeg(title: slotTitle(slot), active: slot == store.activeSlot)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func slotTitle(_ slot: DecorationSlot) -> String {
        switch slot {
        case .head: return L10n.tr("shop_slot_head")
        case .back: return L10n.tr("shop_slot_back")
        case .feet: return L10n.tr("shop_slot_feet")
        }
    }

    // 미리보기 캐릭터 — 전역 단일 착용 1개를 그 장식의 슬롯 자리에 반영.
    // 탭한 장식(decoPreviewId)이 있으면 구매 전에도 미리 얹어 보여준다.
    private var preview: some View {
        let shownId = decoPreviewId ?? store.equippedDecorationId
        let slot = DecorationCatalog.slotForItem(shownId)
        return V2Mongle(
            color: V2Palette.alex,
            size: 96,
            hideName: true,
            backDecorationId: slot == .back ? shownId : nil,
            feetDecorationId: slot == .feet ? shownId : nil
        ) {
            DecorationCatalog.headView(for: slot == .head ? shownId : nil)
        }
        // 머리/등/발밑 세그먼트 바로 아래라 살짝 답답하지 않도록 캐릭터를 카드 안에서 조금 내린다.
        .offset(y: 14)
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        // 배경 탭 미리보기 카드와 동일한 높이·반경·그림자의 따뜻한 카드를 캐릭터 뒤에 깔아
        // 두 탭의 상단 리듬을 통일한다. 캐릭터는 클립하지 않아(머리 장식이 카드 위로 살짝 솟는
        // 디자인) 키 큰 장식도 잘리지 않는다. 그라데이션은 장식 상세 화면의 따뜻한 톤과 같은 결.
        .background {
            RadialGradient(
                colors: [V2Palette.cream, V2Palette.cream2, V2Palette.cream3],
                center: .center, startRadius: 0, endRadius: 200
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(V2Palette.hairline, lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .animation(.easeInOut(duration: 0.15), value: decoPreviewId)
    }

    private var decoGrid: some View {
        LazyVGrid(columns: decoCols, spacing: 10) {
            // "장식 없음" 타일 — 해제용.
            Button {
                decoPreviewId = nil
                store.send(.decorationTapped(itemId: nil))
            } label: {
                V2DecoTile(name: L10n.tr("shop_deco_none"), equipped: store.equippedDecorationId == nil) {
                    Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        .foregroundStyle(V2Palette.muted).frame(width: 40, height: 40)
                }
            }
            .buttonStyle(.plain)

            ForEach(store.slotDecorations) { item in
                let owned = store.state.isOwned(item.id)
                let equipped = store.equippedDecorationId == item.id
                Button { onDecoTileTapped(item) } label: {
                    V2DecoTile(
                        name: item.name,
                        price: owned ? nil : "\(item.price)",
                        equipped: equipped
                    ) {
                        DecorationCatalog.preview(for: item.id)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func onDecoTileTapped(_ item: ShopItem) {
        // 타일 탭 → 미리보기(상세) 화면으로 진입. 구매/적용/닫기는 상세 하단 액션바에서.
        // (인라인 미리보기 decoPreviewId 는 '장식 없음' 슬롯 해제 동선 유지를 위해 그대로 둔다.)
        previewItem = item
    }

    // MARK: - Background tab content

    private var backgroundContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            bgPreview

            hint(L10n.tr("shop_bg_hint"))

            LazyVGrid(columns: bgCols, spacing: 12) {
                ForEach(store.backgrounds) { item in
                    Button { onBackgroundTileTapped(item) } label: {
                        V2BgTile(
                            name: item.name,
                            image: BackgroundCatalog.tileImage(for: item.id),
                            swatch: BackgroundCatalog.tileSwatch(for: item.id),
                            badge: badge(for: item)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 40)
    }

    // 배경 미리보기 패널 — 탭한 배경(없으면 적용 중 배경)을 큰 화면으로 보여준다.
    private var bgPreview: some View {
        let requested = bgPreviewId ?? store.appliedBackgroundId ?? BackgroundCatalog.defaultId
        // items 에 없는 id(제거된 배경 등 잔재)는 기본 배경으로 폴백 — 항상 좌측 하단에 이름이 보이도록.
        let id = store.backgrounds.contains(where: { $0.id == requested }) ? requested : BackgroundCatalog.defaultId
        let name = store.backgrounds.first(where: { $0.id == id })?.name
        return ZStack {
            if let img = BackgroundCatalog.tileImage(for: id) {
                Image(img, bundle: .module).resizable().interpolation(.none).scaledToFill()
            } else if let sw = BackgroundCatalog.tileSwatch(for: id) {
                sw
            } else {
                BackgroundCatalog.cozyHomeSwatch
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .clipped()
        // 밝은 픽셀아트 배경에서도 이름이 또렷이 보이도록 그리드 타일(V2BgTile)과 동일한 하단 스크림.
        .overlay {
            LinearGradient(colors: [.clear, .black.opacity(0.20), .black.opacity(0.62)],
                           startPoint: .center, endPoint: .bottom)
        }
        .overlay(alignment: .bottomLeading) {
            if let name {
                Text(name)
                    .font(V2Font.suit(15, .heavy)).foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, y: 1)
                    .padding(14)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(.white.opacity(0.5), lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .animation(.easeInOut(duration: 0.15), value: id)
    }

    private func badge(for item: ShopItem) -> V2BgTile.Badge? {
        if store.appliedBackgroundId == item.id
            || (store.appliedBackgroundId == nil && item.id == BackgroundCatalog.defaultId) {
            return .applied(L10n.tr("shop_bg_applied"))
        }
        if store.state.isBackgroundOwned(item.id) {
            return .owned(L10n.tr("shop_bg_owned"))   // 보유했지만 미적용 — "보유중" 표시.
        }
        // 미보유 — 시즌/일반 구분 없이 동일한 하트+가격 배지 (눈오는 마을 등 시즌 배경도 통일).
        return .price("\(item.price)")
    }

    private func onBackgroundTileTapped(_ item: ShopItem) {
        // 타일 탭 → 미리보기(상세) 화면으로 진입. 구매/적용/닫기는 상세 하단 액션바에서.
        previewItem = item
    }

    // MARK: - Popups

    // 하트 부족 안내 — 충전 버튼 없이 확인만 (하트는 답변으로 모음).
    @ViewBuilder
    private var insufficientPopup: some View {
        if showInsufficient {
            MonglePopupView(
                icon: .init(
                    systemName: "heart.slash.fill",
                    foregroundColor: V2Palette.heartPink,
                    backgroundColor: V2Palette.heartPink.opacity(0.12)
                ),
                title: L10n.tr("shop_insufficient_title"),
                description: L10n.tr("shop_insufficient_desc"),
                primaryLabel: L10n.tr("common_confirm"),
                secondaryLabel: nil,
                onPrimary: { showInsufficient = false },
                onSecondary: nil
            )
            .transition(.identity)
        }
    }
}

// MARK: - Preview

#Preview("Shop · 꾸미기") {
    ShopView(
        store: Store(
            initialState: ShopFeature.State(
                hearts: 100,
                catalog: DecorationCatalog.allItems + BackgroundCatalog.items,
                inventory: ShopInventory(
                    ownedDecorationIds: [DecorationCatalog.flowerCrown],
                    equippedDecorationId: DecorationCatalog.flowerCrown
                )
            )
        ) {
            ShopFeature()
        } withDependencies: {
            $0.shopRepository = PreviewShopRepository()
        }
    )
}

#Preview("Shop · 배경") {
    ShopView(
        store: Store(
            initialState: ShopFeature.State(
                activeTab: .background,
                hearts: 100,
                catalog: DecorationCatalog.allItems + BackgroundCatalog.items,
                inventory: ShopInventory(
                    ownedBackgroundIds: [BackgroundCatalog.springField],
                    appliedBackgroundId: BackgroundCatalog.springField
                )
            )
        ) {
            ShopFeature()
        } withDependencies: {
            $0.shopRepository = PreviewShopRepository()
        }
    )
}

/// 프리뷰 전용 in-memory repository (서버 미구현 동안 동작 확인용).
private struct PreviewShopRepository: ShopRepositoryInterface {
    func getCatalog() async throws -> [ShopItem] { DecorationCatalog.allItems + BackgroundCatalog.items }
    func getInventory() async throws -> ShopInventory {
        ShopInventory(
            ownedDecorationIds: [DecorationCatalog.flowerCrown],
            equippedDecorationId: DecorationCatalog.flowerCrown
        )
    }
    func purchase(itemId: String) async throws -> Int { 80 }
    func equipDecoration(itemId: String?) async throws -> String? { itemId }
    func applyBackground(itemId: String) async throws -> ShopInventory {
        ShopInventory(ownedBackgroundIds: [itemId], appliedBackgroundId: itemId)
    }
}
