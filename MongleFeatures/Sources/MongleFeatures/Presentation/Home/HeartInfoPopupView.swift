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
                    Text("하트")
                        .font(MongleFont.heading3())
                        .foregroundColor(MongleColor.textPrimary)

                    HStack(spacing: MongleSpacing.xs) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(MongleColor.heartRed)
                        Text("현재 보유 \(store.hearts)개")
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
                        text: "질문 다시받기에 하트 1개가 사용돼요"
                    )
                    heartInfoRow(
                        icon: "pencil.circle.fill",
                        color: MongleColor.accentOrange,
                        text: "나만의 질문 작성에 하트 1개가 사용돼요"
                    )
                    heartInfoRow(
                        icon: "heart.circle.fill",
                        color: MongleColor.heartRed,
                        text: "재촉하기에 하트 1개가 사용돼요"
                    )
                    heartInfoRow(
                        icon: "sun.rise.fill",
                        color: MongleColor.primary,
                        text: "매일 오전 6시에 하트 1개가 충전돼요"
                    )
                    heartInfoRow(
                        icon: "checkmark.circle.fill",
                        color: MongleColor.primary,
                        text: "답변을 완료하면 하트 1개를 얻을 수 있어요"
                    )
                }
                .padding(MongleSpacing.md)
                .background(MongleColor.background)
                .cornerRadius(MongleRadius.large)

                // 닫기 버튼
                MongleButtonPrimary("확인") {
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
