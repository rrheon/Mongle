import SwiftUI
import ComposableArchitecture

// MARK: - 03-B · Heart Cost Popup (공용)

public struct HeartCostPopupView: View {
    @Bindable var store: StoreOf<HeartCostPopupFeature>

    public init(store: StoreOf<HeartCostPopupFeature>) {
        self.store = store
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
            secondaryLabel: "취소",
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
                    Text("보유 하트: \(store.hearts)개")
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
                Text("하트가 부족해요. 답변을 완료하여 하트를 모아보세요!")
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.error)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
