//
//  ShopDetailView.swift
//  MongleFeatures
//
//  상점 상세(미리보기) 화면. 그리드 타일을 탭하면 즉시 구매/적용 팝업 대신
//  '적용된 모습'을 풀스크린으로 보여주고, 하단 액션바에서 구매/적용/닫기 한다.
//  디자인 v2 screens-detail.jsx 의 Screen05_BgDetail / Screen06_DecoDetail /
//  PreviewActionBar / CloseBtn 을 SwiftUI 로 옮긴 것.
//
//  - 배경(05): 풀블리드 홈 배경 + 미리보기 뱃지 + 본인 몽글 1마리 + 하단 액션바.
//  - 장식(06): 라디얼 그라데이션 배경 + 슬롯 뱃지 + 큰 몽글(착용) + 전/후 비교 + 액션바.
//  - reducer 변경 0건. 기존 액션(slotSelected/purchaseConfirmed/decorationTapped/
//    purchaseBackgroundConfirmed/backgroundTapped) 만 재사용한다.
//  - 하트 부족은 View 가 선판정해 onInsufficient() 로 분기 (reducer 까지 가지 않음).
//

import SwiftUI
import ComposableArchitecture
import Domain

// MARK: - 슬롯 타이틀 (ShopView 와 동일 매핑 — 상세 뱃지에서 재사용)

func shopSlotTitle(_ slot: DecorationSlot) -> String {
    switch slot {
    case .head: return L10n.tr("shop_slot_head")
    case .back: return L10n.tr("shop_slot_back")
    case .feet: return L10n.tr("shop_slot_feet")
    }
}

// MARK: - 슬롯별 장식 착용 몽글 빌더

/// V2Mongle 의 슬롯별 init 분기를 한 곳으로 모은다.
/// - head: 제네릭 trailing closure(decoration:) 로 head 뷰를 얹는다.
/// - back/feet: EmptyView convenience init 의 backDecorationId/feetDecorationId 파라미터.
@ViewBuilder
func decoratedMongle(slot: DecorationSlot, itemId: String, size: CGFloat, eyeSize: CGFloat) -> some View {
    switch slot {
    case .head:
        V2Mongle(color: V2Palette.alex, size: size, eyeSize: eyeSize, hideName: true) {
            DecorationCatalog.headView(for: itemId)
        }
    case .back:
        V2Mongle(color: V2Palette.alex, size: size, eyeSize: eyeSize, hideName: true,
                 backDecorationId: itemId)
    case .feet:
        V2Mongle(color: V2Palette.alex, size: size, eyeSize: eyeSize, hideName: true,
                 feetDecorationId: itemId)
    }
}

// MARK: - 닫기 버튼 (디자인 CloseBtn)

/// 좌상단 원형 닫기 버튼. dark=true 면 어두운 반투명(밝은 배경 위), false 면 흰 반투명.
struct ShopCloseBtn: View {
    var dark: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(dark ? .white : V2Palette.ink)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(dark ? Color.black.opacity(0.55) : Color.white.opacity(0.85))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 미리보기 뱃지 (상단 중앙 'eye + 텍스트')

private struct ShopPreviewBadge: View {
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "eye.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            Text(text)
                .font(V2Font.suit(12, .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.55), in: Capsule())
    }
}

// MARK: - 하단 액션바 (디자인 PreviewActionBar 상태머신)

/// 미리보기 화면 하단 부착 액션바. 좌측 닫기 + 우측 상태별 버튼(적용중/적용하기/구매하기),
/// 우상단에 (미보유시만) 하트·가격을 노출한다.
struct PreviewActionBar: View {
    let name: String
    let sub: String
    /// 가격 표시용 정수 (구매 버튼 라벨 "%d개로 구매하기" 인자로도 사용).
    let price: Int
    let owned: Bool
    let applied: Bool
    /// 적용중 라벨 — bg="적용중"(shop_bg_applied), deco="장착중"(shop_equipped).
    let appliedLabel: String
    /// 적용 버튼 라벨 — bg=shop_apply_bg_confirm, deco=shop_apply_confirm.
    let applyLabel: String
    let onClose: () -> Void
    let onPrimary: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // 상단 행: 이름·서브 / (미보유시) 하트·가격
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(V2Font.suit(22, .heavy))
                        .foregroundStyle(V2Palette.ink)
                    Text(sub)
                        .font(V2Font.suit(12, .regular))
                        .foregroundStyle(V2Palette.mutedSoft)
                }
                Spacer()
                if !owned && !applied {
                    HStack(spacing: 5) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(V2Palette.heartPink)
                        Text("\(price)")
                            .font(V2Font.suit(20, .black))
                            .foregroundStyle(V2Palette.ink)
                    }
                }
            }

            // 하단 행: 닫기 + 상태별 우측 버튼
            HStack(spacing: 10) {
                Button(action: onClose) {
                    Text(L10n.tr("common_close"))
                        .font(V2Font.suit(15, .bold))
                        .foregroundStyle(V2Palette.mutedSoft)
                        .frame(width: 96, height: 54)
                        .background(Color(hex: "F1ECE3"),
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onPrimary) {
                    primaryContent
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(primaryBackground,
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(applied)   // 적용중이면 우측 버튼 비활성
            }
        }
        .padding(.init(top: 16, leading: 20, bottom: 30, trailing: 20))
        // 디자인의 backdrop-filter blur(30px) 의도 — 불투명 흰색 대신 반투명 프로스트 머티리얼로
        // 깔아 뒤의 캐릭터/배경이 비쳐 보이게 한다 (하단 섹션이 콘텐츠를 덜 가린다).
        .background(.ultraThinMaterial)
        .clipShape(.rect(topLeadingRadius: 28, topTrailingRadius: 28))
        .shadow(color: .black.opacity(0.1), radius: 30, y: -8)
    }

    @ViewBuilder
    private var primaryContent: some View {
        if applied {
            HStack(spacing: 6) {
                Image(systemName: "checkmark").font(.system(size: 18, weight: .bold))
                Text(appliedLabel).font(V2Font.suit(16, .heavy))
            }
            .foregroundStyle(V2Palette.mintInk)
        } else if owned {
            Text(applyLabel)
                .font(V2Font.suit(16, .heavy))
                .foregroundStyle(V2Palette.ink)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(V2Palette.heartPink)
                Text(L10n.tr("shop_buy_with_price", price))
                    .font(V2Font.suit(16, .heavy))
                    .foregroundStyle(V2Palette.ink)
            }
        }
    }

    private var primaryBackground: Color {
        applied ? Color(hex: "E7EFE9") : V2Palette.mint
    }
}

// MARK: - 배경 상세 (Screen05_BgDetail)

struct ShopBgDetailView: View {
    @Bindable var store: StoreOf<ShopFeature>
    let item: ShopItem
    let onClose: () -> Void
    let onInsufficient: () -> Void

    /// 현재 적용 중 배경인가 (미적용 + 기본 배경이면 기본을 적용중으로 취급).
    private var isApplied: Bool {
        store.appliedBackgroundId == item.id
            || (store.appliedBackgroundId == nil && item.id == BackgroundCatalog.defaultId)
    }

    private var isOwned: Bool { store.state.isBackgroundOwned(item.id) }

    var body: some View {
        ZStack(alignment: .top) {
            // 풀블리드 배경 — 실제 홈 렌더(homeBackground)와 동일하게 그린다.
            // 이미지 자산이 있는 배경은 cropped 이미지로, 자산이 없는 cozyHome 은 swatch 폴백.
            backgroundLayer
                .ignoresSafeArea()

            ShopPreviewBadge(text: L10n.tr("shop_preview_badge_home"))
                .padding(.top, 8)

            // 적용된 모습 — 본인 몽글 1마리를 배경 위에 얹는다 (가족 roster 데이터 없음 → 발명 금지).
            V2Mongle(color: V2Palette.alex, size: 58, eyeSize: 11,
                     hideName: true, ringColor: V2Palette.mint)
                .frame(maxHeight: .infinity)
        }
        .overlay(alignment: .topLeading) {
            ShopCloseBtn(dark: true, onTap: onClose)
                .padding(.leading, 16)
        }
        .overlay(alignment: .bottom) {
            PreviewActionBar(
                name: item.name,
                sub: L10n.tr("shop_bg_detail_sub"),
                price: item.price,
                owned: isOwned,
                applied: isApplied,
                appliedLabel: L10n.tr("shop_bg_applied"),
                applyLabel: L10n.tr("shop_apply_bg_confirm"),
                onClose: onClose,
                onPrimary: onPrimary
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        // 자산이 있는 배경은 실제 홈 렌더와 동일하게 homeBackground 로 그려 미리보기 정확도를 맞춘다.
        // cozyHome 은 자산이 없어 swatch 폴백 (homeBackground 도 cozyHome 폴백).
        switch item.id {
        case BackgroundCatalog.springField, BackgroundCatalog.beach, BackgroundCatalog.space,
             BackgroundCatalog.snowVillage, BackgroundCatalog.cherryBlossom:
            BackgroundCatalog.homeBackground(for: item.id)
        default:   // cozyHome
            V2CozyHomeBackground()
        }
    }

    private func onPrimary() {
        if !isOwned {
            // 미보유 — 하트 부족이면 안내, 충분하면 구매(서버 권위) 후 닫기.
            if store.hearts < item.price {
                onInsufficient()
            } else {
                store.send(.purchaseBackgroundConfirmed(itemId: item.id))
                onClose()
            }
        } else if !isApplied {
            // 보유 · 미적용 → 적용 후 닫기.
            store.send(.backgroundTapped(itemId: item.id))
            onClose()
        }
        // 적용중이면 버튼 비활성이라 여기 도달하지 않음.
    }
}

// MARK: - 장식 상세 (Screen06_DecoDetail)

struct ShopDecoDetailView: View {
    @Bindable var store: StoreOf<ShopFeature>
    let item: ShopItem
    let onClose: () -> Void
    let onInsufficient: () -> Void

    var body: some View {
        // 장식 아이템은 항상 slot 이 있으나(nil 도달 불가), 컴파일 가능한 안전 분기를 둔다.
        if let slot = item.slot {
            content(slot: slot)
        } else {
            // 도달 불가 경로 — 부수효과로 닫는다 (View 라 return 불가).
            Color.clear.onAppear { onClose() }
        }
    }

    private func content(slot: DecorationSlot) -> some View {
        let isOwned = store.state.isOwned(item.id)
        // 적용 판정은 reducer 의 activeSlot 의존(equippedSlotId) 을 쓰지 않고 슬롯 직접 판정.
        let isApplied = store.inventory?.equippedDecorations.id(for: slot) == item.id

        return ZStack(alignment: .top) {
            // 라디얼 그라데이션 배경.
            RadialGradient(
                colors: [Color(hex: "FFF3E0"), Color(hex: "FCE0CB"), Color(hex: "F5C9A8")],
                center: UnitPoint(x: 0.5, y: 0.32),
                startRadius: 0,
                endRadius: 520
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ShopPreviewBadge(text: L10n.tr("shop_preview_badge_slot", shopSlotTitle(slot)))
                    .padding(.top, 8)

                Spacer()

                // 적용된 모습 — 큰 몽글 (슬롯 착용).
                decoratedMongle(slot: slot, itemId: item.id, size: 130, eyeSize: 20)

                Spacer()

                // 전/후 비교 패널.
                comparePanels(slot: slot)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                // 액션바 자리 확보 (아래 overlay 로 부착).
                Color.clear.frame(height: 150)
            }
        }
        .overlay(alignment: .topLeading) {
            ShopCloseBtn(dark: false, onTap: onClose)
                .padding(.leading, 16)
        }
        .overlay(alignment: .bottom) {
            PreviewActionBar(
                name: item.name,
                sub: L10n.tr("shop_deco_detail_sub"),
                price: item.price,
                owned: isOwned,
                applied: isApplied,
                appliedLabel: L10n.tr("shop_equipped"),
                applyLabel: L10n.tr("shop_apply_confirm"),
                onClose: onClose,
                onPrimary: { onPrimary(slot: slot, isOwned: isOwned, isApplied: isApplied) }
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // 전(반투명)/후(민트 하이라이트) 2패널 + 가운데 검정 원형 화살표.
    private func comparePanels(slot: DecorationSlot) -> some View {
        HStack(spacing: 12) {
            // 전 — 장식 없는 몽글.
            VStack(spacing: 12) {
                Text(L10n.tr("shop_compare_before"))
                    .font(V2Font.suit(11, .heavy))
                    .foregroundStyle(V2Palette.mutedSoft)
                    .padding(.horizontal, 12).padding(.vertical, 3)
                    .background(V2Palette.ink.opacity(0.10),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                V2Mongle(color: V2Palette.alex, size: 56, eyeSize: 11, hideName: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white.opacity(0.55),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1.5))

            // 화살표 디바이더.
            ZStack {
                Circle().fill(V2Palette.ink).frame(width: 28, height: 28)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

            // 후 — 장식 착용 몽글 (하이라이트).
            VStack(spacing: 12) {
                Text(L10n.tr("shop_compare_after"))
                    .font(V2Font.suit(11, .heavy))
                    .foregroundStyle(V2Palette.ink)
                    .padding(.horizontal, 12).padding(.vertical, 3)
                    .background(V2Palette.mint,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                decoratedMongle(slot: slot, itemId: item.id, size: 56, eyeSize: 11)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(V2Palette.mint.opacity(0.30),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(V2Palette.mint, lineWidth: 1.5))
        }
    }

    private func onPrimary(slot: DecorationSlot, isOwned: Bool, isApplied: Bool) {
        if !isOwned {
            if store.hearts < item.price {
                onInsufficient()
            } else {
                // reducer 의 구매/장착은 activeSlot 기준 → 해당 슬롯 선전송 후 구매.
                store.send(.slotSelected(slot))
                store.send(.purchaseConfirmed(itemId: item.id))
                onClose()
            }
        } else if !isApplied {
            store.send(.slotSelected(slot))
            store.send(.decorationTapped(itemId: item.id))
            onClose()
        }
        // 적용중이면 버튼 비활성이라 도달하지 않음.
    }
}

// MARK: - Preview

#Preview("배경 상세") {
    ShopBgDetailView(
        store: Store(
            initialState: ShopFeature.State(
                activeTab: .background,
                hearts: 100,
                catalog: BackgroundCatalog.items
            )
        ) { ShopFeature() },
        item: BackgroundCatalog.items.first { $0.id == BackgroundCatalog.springField }!,
        onClose: {},
        onInsufficient: {}
    )
}

#Preview("장식 상세") {
    ShopDecoDetailView(
        store: Store(
            initialState: ShopFeature.State(
                hearts: 100,
                catalog: DecorationCatalog.allItems
            )
        ) { ShopFeature() },
        item: DecorationCatalog.headItems.first { $0.id == DecorationCatalog.flowerCrown }!,
        onClose: {},
        onInsufficient: {}
    )
}
