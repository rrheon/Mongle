import SwiftUI
import ComposableArchitecture

public struct HeartInfoPopupView: View {
    @Bindable var store: StoreOf<HeartInfoPopupFeature>

    public init(store: StoreOf<HeartInfoPopupFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { store.send(.closeTapped) }

            VStack(spacing: MongleSpacing.lg) {
                // 아이콘
                Circle()
                    .fill(MongleColor.heartRedLight)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: 32))
                            .foregroundColor(MongleColor.heartRed)
                    )

                // 제목 + 보유 하트
                VStack(spacing: MongleSpacing.sm) {
                    Text(L10n.tr("heart_title"))
                        .font(MongleFont.heading3())
                        .foregroundColor(MongleColor.textPrimary)

                    HStack(spacing: MongleSpacing.xs) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(MongleColor.heartRed)
                        Text(L10n.tr("home_heart_count", store.hearts))
                            .font(MongleFont.body2Bold())
                            .foregroundColor(MongleColor.heartRed)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(MongleColor.heartRedLight)
                    .clipShape(Capsule())
                }

                // 안내 목록
                VStack(spacing: MongleSpacing.sm) {
                    heartInfoRow(
                        icon: "arrow.clockwise.circle.fill",
                        color: MongleColor.secondary,
                        text: L10n.tr("heart_info_replace")
                    )
                    heartInfoRow(
                        icon: "pencil.circle.fill",
                        color: MongleColor.accentOrange,
                        text: L10n.tr("heart_info_write")
                    )
                    heartInfoRow(
                        icon: "heart.circle.fill",
                        color: MongleColor.heartRed,
                        text: L10n.tr("heart_info_nudge")
                    )
                    heartInfoRow(
                        icon: "sun.rise.fill",
                        color: MongleColor.primary,
                        text: L10n.tr("heart_info_daily")
                    )
                    heartInfoRow(
                        icon: "checkmark.circle.fill",
                        color: MongleColor.primary,
                        text: L10n.tr("heart_info_answer")
                    )
                }
                .padding(MongleSpacing.md)
                .background(MongleColor.background)
                .cornerRadius(MongleRadius.large)

                // 닫기 버튼
                MongleButtonPrimary(L10n.tr("common_confirm")) {
                    store.send(.closeTapped)
                }
            }
            .padding(MongleSpacing.lg)
            .frame(maxWidth: 344)
            .background(Color.white)
            .cornerRadius(MongleRadius.xl)
            .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 8)
            .padding(.horizontal, MongleSpacing.lg)
        }
    }

    private func heartInfoRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: MongleSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textSecondary)
            Spacer()
        }
    }
}
