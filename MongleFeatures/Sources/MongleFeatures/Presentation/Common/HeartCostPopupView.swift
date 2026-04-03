import SwiftUI
import ComposableArchitecture

// MARK: - 03-B · Heart Cost Popup (공용)

public struct HeartCostPopupView: View {
    @Bindable var store: StoreOf<HeartCostPopupFeature>

    public init(store: StoreOf<HeartCostPopupFeature>) {
        self.store = store
    }

    /// `@Presents`로 스코핑된 스토어에서 PresentationAction을 벗겨내는 편의 이니셜라이저
    public init(store: Store<HeartCostPopupFeature.State, PresentationAction<HeartCostPopupFeature.Action>>) {
        self.store = store.scope(state: \.self, action: \.presented)
    }

    public var body: some View {
        MonglePopupView(
            icon: .init(
                systemName: "heart.fill",
                foregroundColor: MongleColor.heartRed,
                backgroundColor: MongleColor.heartRedLight
            ),
            title: store.title,
            description: store.description,
            primaryLabel: store.confirmLabel,
            secondaryLabel: L10n.tr("common_cancel"),
            isPrimaryEnabled: store.hasEnoughHearts,
            onPrimary: { store.send(.confirmTapped) },
            onSecondary: { store.send(.cancelTapped) }
        ) {
            heartCostSection
        }
    }

    // MARK: - Heart Cost Row

    private var heartCostSection: some View {
        VStack(spacing: MongleSpacing.xs) {
            HStack {
                HStack(spacing: MongleSpacing.xs) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(MongleColor.heartRed)
                    Text(L10n.tr("nudge_hearts", store.hearts))
                        .font(MongleFont.body2())
                        .foregroundColor(MongleColor.textSecondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(MongleColor.heartRed)
                    Text("-\(store.cost)")
                        .font(MongleFont.captionBold())
                        .foregroundColor(MongleColor.heartRed)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(MongleColor.heartRedLight)
                .clipShape(Capsule())
            }
            .padding(.horizontal, MongleSpacing.xs)

            if !store.hasEnoughHearts {
                VStack(spacing: MongleSpacing.xs) {
                    Text(L10n.tr("nudge_insufficient"))
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.error)

                    Button {
                        store.send(.watchAdTapped)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 13))
                            Text(L10n.tr("heart_popup_ad"))
                                .font(MongleFont.captionBold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(MongleColor.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
