import SwiftUI
import ComposableArchitecture

public struct HeartsSystemView: View {
    @Bindable var store: StoreOf<HeartsSystemFeature>

    public init(store: StoreOf<HeartsSystemFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MongleSpacing.md) {
                infoStrip(
                    icon: "heart.text.square.fill",
                    title: L10n.tr("heart_info_title"),
                    description: L10n.tr("heart_info_desc")
                )

                VStack(alignment: .leading, spacing: MongleSpacing.md) {
                    Text(L10n.tr("hearts_title"))
                        .font(MongleFont.heading2())
                        .foregroundColor(.white)

                    Text(L10n.tr("hearts_desc"))
                        .font(MongleFont.body2())
                        .foregroundColor(.white.opacity(0.88))
                        .lineSpacing(3)

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
                            Text("\(store.heartBalance)")
                                .font(MongleFont.heading1())
                                .foregroundColor(.white)
                            Text(L10n.tr("heart_title"))
                                .font(MongleFont.body2())
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(0..<store.heartBalance, id: \.self) { _ in
                                Image(systemName: "heart.fill").foregroundColor(.white)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MongleSpacing.xl)
                .background(
                    LinearGradient(
                        colors: [MongleColor.heartPink, MongleColor.heartPinkLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.xl))
                .overlay(alignment: .topTrailing) {
                    Text(L10n.tr("hearts_today"))
                        .font(MongleFont.captionBold())
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, MongleSpacing.sm)
                        .padding(.vertical, MongleSpacing.xxs)
                        .background(.white.opacity(0.16))
                        .clipShape(Capsule())
                        .padding(MongleSpacing.md)
                }

                VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                    sectionTitle(L10n.tr("hearts_earn_title"), subtitle: L10n.tr("hearts_earn_subtitle"))
                    HStack(spacing: MongleSpacing.sm) {
                        miniHeartCard(title: L10n.tr("hearts_earn_login"), subtitle: L10n.tr("hearts_earn_login_sub"), value: "+1", tint: MongleColor.heartPastel)
                        miniHeartCard(title: L10n.tr("hearts_earn_answer"), subtitle: L10n.tr("hearts_earn_answer_sub"), value: "+3", tint: MongleColor.heartPastelLight)
                    }
                }

                VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                    sectionTitle(L10n.tr("hearts_use_title"), subtitle: L10n.tr("hearts_use_subtitle"))
                    heartsSection(items: [
                        (L10n.tr("hearts_use_nudge"), L10n.tr("hearts_use_nudge_desc"), L10n.tr("hearts_use_nudge_cost")),
                        (L10n.tr("hearts_use_replace"), L10n.tr("hearts_use_replace_desc"), L10n.tr("hearts_use_replace_cost")),
                        (L10n.tr("hearts_use_skip"), L10n.tr("hearts_use_skip_desc"), L10n.tr("hearts_use_skip_cost")),
                    ])
                }

                infoStrip(
                    icon: "sparkles",
                    title: L10n.tr("hearts_save_title"),
                    description: L10n.tr("hearts_save_desc")
                )
            }
            .padding(MongleSpacing.md)
            .padding(.bottom, MongleSpacing.xl)
        }
        .background(MongleColor.background)
        .navigationTitle(L10n.tr("hearts_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    store.send(.closeTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(MongleColor.textPrimary)
                }
                .buttonStyle(MongleScaleButtonStyle())
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Helpers

    private func miniHeartCard(title: String, subtitle: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            HStack {
                Image(systemName: "heart.fill").foregroundColor(MongleColor.heartRed)
                Spacer()
                Text(value)
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.heartRed)
            }
            Text(title)
                .font(MongleFont.body2Bold())
                .foregroundColor(MongleColor.textPrimary)
            Text(subtitle)
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MongleSpacing.md)
        .background(tint)
        .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
    }

    private func heartsSection(items: [(String, String, String)]) -> some View {
        VStack(spacing: MongleSpacing.sm) {
            ForEach(items, id: \.0) { item in
                HStack(spacing: MongleSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.0).font(MongleFont.body2Bold()).foregroundColor(MongleColor.textPrimary)
                        Text(item.1).font(MongleFont.caption()).foregroundColor(MongleColor.textSecondary)
                    }
                    Spacer()
                    Text(item.2)
                        .font(MongleFont.captionBold())
                        .foregroundColor(MongleColor.heartRed)
                        .padding(.horizontal, MongleSpacing.sm)
                        .padding(.vertical, MongleSpacing.xxs)
                        .background(MongleColor.heartRedLight)
                        .clipShape(Capsule())
                }
                .padding(MongleSpacing.md)
                .background(MongleColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: MongleRadius.large)
                        .stroke(MongleColor.borderWarm, lineWidth: 1)
                )
            }
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(MongleFont.body1Bold()).foregroundColor(MongleColor.textPrimary)
            Text(subtitle).font(MongleFont.caption()).foregroundColor(MongleColor.textSecondary)
        }
    }

    private func infoStrip(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: MongleSpacing.sm) {
            Circle()
                .fill(MongleColor.primaryLight)
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: icon).foregroundColor(MongleColor.primary))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(MongleFont.body2Bold()).foregroundColor(MongleColor.textPrimary)
                Text(description).font(MongleFont.caption()).foregroundColor(MongleColor.textSecondary).lineSpacing(2)
            }
            Spacer()
        }
        .padding(MongleSpacing.md)
        .monglePanel(background: MongleColor.bgCreamy, cornerRadius: MongleRadius.large, shadowOpacity: 0.02)
    }
}
