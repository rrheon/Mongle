import SwiftUI
import ComposableArchitecture

public struct PenPlaceholderView: View {
    @Bindable var store: StoreOf<PenPlaceholderFeature>

    public init(store: StoreOf<PenPlaceholderFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: MongleSpacing.lg) {
                Circle()
                    .fill(MongleColor.primaryLight)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(MongleColor.primary)
                    )

                Text(store.title)
                    .font(MongleFont.heading2())
                    .foregroundColor(MongleColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(store.description)
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MongleSpacing.xl)

                MongleButton("닫기") {
                    store.send(.closeTapped)
                }
                .padding(.horizontal, MongleSpacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MongleColor.background)
            .navigationTitle("MongleUI.pen 정렬")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
