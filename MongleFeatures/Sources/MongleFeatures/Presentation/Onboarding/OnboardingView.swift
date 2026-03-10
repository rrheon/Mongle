import SwiftUI
import ComposableArchitecture

public struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                TabView(selection: $store.currentIndex.sending(\.pageChanged)) {
                    ob1View.tag(0)
                    ob2View.tag(1)
                    ob3View.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomBar
            }
        }
    }

    // MARK: - OB1: Welcome

    private var ob1View: some View {
        VStack(spacing: 0) {
            Spacer()

            // 몽글 캐릭터 (글로우 포함)
            ZStack {
                Circle()
                    .fill(MongleColor.monggleGreen.opacity(0.25))
                    .frame(width: 210, height: 210)
                    .blur(radius: 40)
                    .offset(y: 12)

                MongleMonggle.green(size: 160)
            }

            Spacer().frame(height: 44)

            // 텍스트
            VStack(spacing: 12) {
                Text("몽글에 오신 걸 환영해요 🌿")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(MongleColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("가족, 친구와 매일 마음을 나누는\n따뜻한 소통 공간")
                    .font(MongleFont.body1())
                    .foregroundColor(MongleColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
        }
        .padding(.horizontal, MongleSpacing.lg)
    }

    // MARK: - OB2: Group

    private var ob2View: some View {
        VStack(spacing: 0) {
            Spacer()

            // 그룹 카드
            MongleCardGroup(
                groupName: "우리 가족 🩷",
                level: 3,
                levelName: "Cozy Forest",
                xpCurrent: 120,
                xpTotal: 500,
                memberColors: [
                    MongleColor.monggleOrange,
                    MongleColor.monggleYellow,
                    MongleColor.monggleGreen,
                    MongleColor.mongglePink
                ]
            )

            Spacer().frame(height: 44)

            // 텍스트
            VStack(spacing: 12) {
                Text("나만의 공간을\n만들어보세요")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(MongleColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("가족, 친구, 커플 등\n함께하고 싶은 사람들을 초대해요")
                    .font(MongleFont.body1())
                    .foregroundColor(MongleColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
        }
        .padding(.horizontal, MongleSpacing.lg)
    }

    // MARK: - OB3: Question

    private var ob3View: some View {
        VStack(spacing: 0) {
            Spacer()

            // 오늘의 질문 카드
            MongleCardQuestion(question: "오늘 당신을 웃게 한 건 무엇인가요?")

            Spacer().frame(height: 20)

            // 몽글 캐릭터 5개
            HStack(spacing: 4) {
                Spacer()
                MongleMonggle.yellow(size: 52)
                MongleMonggle.green(size: 52)
                MongleMonggle.pink(size: 52)
                MongleMonggle.blue(size: 52)
                MongleMonggle.orange(size: 52)
                Spacer()
            }

            Spacer().frame(height: 44)

            // 텍스트
            VStack(spacing: 12) {
                Text("매일 함께\n마음을 나눠요")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(MongleColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text("매일 새로운 질문에 답하고\n서로의 마음을 들여다보세요")
                    .font(MongleFont.body1())
                    .foregroundColor(MongleColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
        }
        .padding(.horizontal, MongleSpacing.lg)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 20) {
            pageIndicator

            MongleButtonPrimary(buttonTitle) {
                store.send(store.isLastPage ? .getStartedTapped : .nextTapped)
            }
        }
        .padding(.horizontal, MongleSpacing.md)
        .padding(.top, MongleSpacing.md)
        .padding(.bottom, MongleSpacing.xl)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(store.pages) { page in
                Capsule()
                    .fill(page.index == store.currentIndex ? MongleColor.primary : Color(hex: "E7DED5"))
                    .frame(width: page.index == store.currentIndex ? 28 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: store.currentIndex)
            }
        }
    }

    private var buttonTitle: String {
        if store.currentIndex == 0 {
            return "시작하기"
        } else if store.isLastPage {
            return "몽글 시작하기 🌿"
        } else {
            return "다음"
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [Color(hex: "FFF8F0"), Color(hex: "FFF2EB"), Color(hex: "EFF8F1")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

#Preview("Onboarding") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
}
