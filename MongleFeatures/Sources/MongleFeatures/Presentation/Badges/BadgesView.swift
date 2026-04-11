//
//  BadgesView.swift
//  MongleFeatures
//
//  Created for Mongle v2 — UI-2 (PRD §4)
//

import SwiftUI
import ComposableArchitecture

public struct BadgesView: View {
    @Bindable var store: StoreOf<BadgesFeature>

    public init(store: StoreOf<BadgesFeature>) {
        self.store = store
    }

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: MongleSpacing.md),
        GridItem(.flexible(), spacing: MongleSpacing.md),
        GridItem(.flexible(), spacing: MongleSpacing.md)
    ]

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: MongleSpacing.lg) {
                if store.definitions.isEmpty {
                    Text(L10n.tr("badges_empty"))
                        .font(MongleFont.body2())
                        .foregroundColor(MongleColor.textHint)
                        .padding(.top, MongleSpacing.xl)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    sectionHeader(L10n.tr("badges_section_earned"), count: store.earnedDefinitions.count)
                    if store.earnedDefinitions.isEmpty {
                        Text(L10n.tr("badges_empty"))
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textHint)
                            .padding(.horizontal, MongleSpacing.xs)
                    } else {
                        LazyVGrid(columns: columns, spacing: MongleSpacing.md) {
                            ForEach(store.earnedDefinitions) { def in
                                BadgeCell(
                                    definition: def,
                                    awardedAt: store.state.awardedAt(for: def.code),
                                    isLocked: false
                                )
                            }
                        }
                    }

                    sectionHeader(L10n.tr("badges_section_locked"), count: store.lockedDefinitions.count)
                    LazyVGrid(columns: columns, spacing: MongleSpacing.md) {
                        ForEach(store.lockedDefinitions) { def in
                            BadgeCell(definition: def, awardedAt: nil, isLocked: true)
                        }
                    }
                }
            }
            .padding(.horizontal, MongleSpacing.md)
            .padding(.top, MongleSpacing.md)
            .padding(.bottom, MongleSpacing.xl)
        }
        .background(MongleColor.background)
        .navigationTitle(L10n.tr("badges_title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.send(.onAppear) }
        .overlay {
            if let def = store.currentPopupDefinition {
                BadgeEarnedPopup(definition: def) { store.send(.popupDismissed) }
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.currentPopupCode)
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack(spacing: MongleSpacing.xs) {
            Text(title)
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)
            Text("\(count)")
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.primary)
            Spacer()
        }
        .padding(.horizontal, MongleSpacing.xxs)
    }
}

// MARK: - Badge Cell

private struct BadgeCell: View {
    let definition: BadgesFeature.Definition
    let awardedAt: Date?
    let isLocked: Bool

    private var systemIcon: String {
        switch definition.category {
        case .streak: return "flame.fill"
        case .answerCount: return "text.bubble.fill"
        }
    }

    private var tint: Color {
        switch definition.category {
        case .streak: return MongleColor.accentOrange
        case .answerCount: return MongleColor.primary
        }
    }

    var body: some View {
        VStack(spacing: MongleSpacing.xs) {
            ZStack {
                Circle()
                    .fill(isLocked ? Color.gray.opacity(0.15) : tint.opacity(0.18))
                    .frame(width: 64, height: 64)

                Image(systemName: systemIcon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(isLocked ? Color.gray.opacity(0.55) : tint)

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Circle().fill(Color.gray.opacity(0.7)))
                        .offset(x: 22, y: 22)
                }
            }

            Text(definition.localizedName)
                .font(MongleFont.captionBold())
                .foregroundColor(isLocked ? MongleColor.textHint : MongleColor.textPrimary)
                .lineLimit(1)

            Text(isLocked ? definition.localizedCondition : awardedAtLabel)
                .font(.system(size: 10))
                .foregroundColor(MongleColor.textHint)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 24, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MongleSpacing.sm)
        .background(MongleColor.cardBackgroundSolid)
        .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
    }

    private var awardedAtLabel: String {
        guard let date = awardedAt else { return definition.localizedCondition }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return String(format: L10n.tr("badges_awarded_at"), f.string(from: date))
    }
}

// MARK: - Badge Earned Popup (PRD §4)

private struct BadgeEarnedPopup: View {
    let definition: BadgesFeature.Definition
    let onDismiss: () -> Void

    private var systemIcon: String {
        switch definition.category {
        case .streak: return "flame.fill"
        case .answerCount: return "text.bubble.fill"
        }
    }

    private var tint: Color {
        switch definition.category {
        case .streak: return MongleColor.accentOrange
        case .answerCount: return MongleColor.primary
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: MongleSpacing.lg) {
                Text(L10n.tr("badge_earned_popup_title"))
                    .font(MongleFont.body2Bold())
                    .foregroundColor(MongleColor.textSecondary)

                ZStack {
                    Circle()
                        .fill(tint.opacity(0.18))
                        .frame(width: 120, height: 120)
                    Image(systemName: systemIcon)
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundColor(tint)
                }

                VStack(spacing: MongleSpacing.xs) {
                    Text(definition.localizedName)
                        .font(MongleFont.heading3())
                        .foregroundColor(MongleColor.textPrimary)
                    Text(definition.localizedCondition)
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textHint)
                        .multilineTextAlignment(.center)
                }

                Button(action: onDismiss) {
                    Text(L10n.tr("badge_earned_popup_action"))
                        .font(MongleFont.body2Bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MongleSpacing.md)
                        .background(MongleColor.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(MongleSpacing.xl)
            .background(MongleColor.cardBackgroundSolid)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            .padding(.horizontal, MongleSpacing.xl)
            .shadow(color: .black.opacity(0.18), radius: 18, y: 6)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BadgesView(store: Store(initialState: BadgesFeature.State()) {
            BadgesFeature()
        })
    }
}
