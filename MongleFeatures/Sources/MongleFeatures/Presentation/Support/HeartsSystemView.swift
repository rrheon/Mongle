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
                    title: "하트는 관계를 움직이는 작은 자원이에요",
                    description: "재촉, 질문 교체 같은 행동에만 제한적으로 사용돼요."
                )

                VStack(alignment: .leading, spacing: MongleSpacing.md) {
                    Text("하트 💗")
                        .font(MongleFont.heading2())
                        .foregroundColor(.white)

                    Text("가족에게 마음을 더 전하고 싶을 때 쓰는 작은 응원이에요.")
                        .font(MongleFont.body2())
                        .foregroundColor(.white.opacity(0.88))
                        .lineSpacing(3)

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
                            Text("\(store.heartBalance)")
                                .font(MongleFont.heading1())
                                .foregroundColor(.white)
                            Text("보유 중인 하트")
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
                    Text("오늘 기준")
                        .font(MongleFont.captionBold())
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, MongleSpacing.sm)
                        .padding(.vertical, MongleSpacing.xxs)
                        .background(.white.opacity(0.16))
                        .clipShape(Capsule())
                        .padding(MongleSpacing.md)
                }

                VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                    sectionTitle("하트 얻는 방법", subtitle: "매일 쌓이는 하트 규칙")
                    HStack(spacing: MongleSpacing.sm) {
                        miniHeartCard(title: "오늘 접속하기", subtitle: "매일 1회", value: "+1", tint: MongleColor.heartPastel)
                        miniHeartCard(title: "질문에 답변하기", subtitle: "답변 1회당", value: "+3", tint: MongleColor.heartPastelLight)
                    }
                }

                VStack(alignment: .leading, spacing: MongleSpacing.sm) {
                    sectionTitle("하트 사용처", subtitle: "필요한 순간에만 선택적으로 써요")
                    heartsSection(items: [
                        ("답변 재촉하기", "미답변 멤버에게 알림 전송", "하트 1개"),
                        ("다른 질문 받기", "오늘 질문을 새 질문으로 교체", "하트 3개"),
                        ("강제 질문 넘기기", "미답변 인원 있어도 다음 질문으로", "하트 5개"),
                    ])
                }

                infoStrip(
                    icon: "sparkles",
                    title: "하트는 아껴 쓰는 구조예요",
                    description: "답변을 꾸준히 남길수록 더 안정적으로 모을 수 있어요."
                )
            }
            .padding(MongleSpacing.md)
            .padding(.bottom, MongleSpacing.xl)
        }
        .background(MongleColor.background)
        .navigationTitle("하트 💗")
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
