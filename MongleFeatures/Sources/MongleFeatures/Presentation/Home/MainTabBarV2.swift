//
//  MainTabBarV2.swift
//  MongleFeatures
//
//  Created for MG-150 — Home v2 하단 탭바.
//
//  V2Chrome 의 V2BottomNav 비주얼을 가져와 MainTabFeature.State.Tab 바인딩과
//  탭 선택 액션을 부착한 Home 전용 탭바. 1차 PR 에서는 Home 탭에서만 그리고,
//  다른 탭은 시스템 탭바를 유지한다.
//

import SwiftUI

struct MainTabBarV2: View {
    let active: MainTabFeature.State.Tab
    let onSelect: (MainTabFeature.State.Tab) -> Void

    private var items: [(MainTabFeature.State.Tab, String, String)] {
        [
            (.home,     "house.fill",       L10n.tr("tab_home")),
            (.history,  "calendar",         L10n.tr("tab_history")),
            (.search,   "magnifyingglass",  L10n.tr("tab_search")),
            (.settings, "person.fill",      L10n.tr("tab_my")),
        ]
    }

    var body: some View {
        HStack {
            ForEach(items, id: \.0) { tab, sf, label in
                let isActive = tab == active
                Button {
                    onSelect(tab)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: sf)
                            .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                        Text(label)
                            .font(V2Font.suit(10, isActive ? .bold : .medium))
                    }
                    .foregroundStyle(.white)
                    .opacity(isActive ? 1 : 0.6)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 64)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().fill(V2Palette.ink.opacity(0.78)))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
