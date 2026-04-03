import SwiftUI
import ComposableArchitecture

public struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    public init(store: StoreOf<OnboardingFeature>) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            MongleBackground()

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

            MongleLogo(size: .large, type: .MongleLogo)

            Spacer().frame(height: 44)

            // 텍스트
            VStack(spacing: 12) {
                Text(L10n.tr("onboarding_welcome_title"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(MongleColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(L10n.tr("onboarding_welcome_desc"))
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
                groupName: L10n.tr("onboarding_sample_group"),
                memberColors: [
                    MongleColor.monggleOrange,
                    MongleColor.monggleYellow,
                    MongleColor.monggleGreen,
                    MongleColor.mongglePink,
                    MongleColor.monggleBlue
                ]
            )

            Spacer().frame(height: 44)

            // 텍스트
            VStack(spacing: 12) {
                Text(L10n.tr("onboarding_group_title"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(MongleColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(L10n.tr("onboarding_group_desc"))
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
            MongleCardQuestion(question: L10n.tr("onboarding_sample_question"))

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
                Text(L10n.tr("onboarding_question_title"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(MongleColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(L10n.tr("onboarding_question_desc"))
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

            Button {
                store.send(.neverShowAgainTapped)
            } label: {
                Text(L10n.tr("onboarding_never_show"))
                    .font(MongleFont.body2())
                    .foregroundStyle(MongleColor.textHint)
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
                    .fill(page.index == store.currentIndex ? MongleColor.primary : MongleColor.pageIndicatorInactive)
                    .frame(width: page.index == store.currentIndex ? 28 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: store.currentIndex)
            }
        }
    }

    private var buttonTitle: String {
        if store.currentIndex == 0 {
            return L10n.tr("onboarding_start")
        } else if store.isLastPage {
            return L10n.tr("onboarding_get_started")
        } else {
            return L10n.tr("common_next")
        }
    }


}

#Preview("Onboarding") {
    OnboardingView(
        store: Store(initialState: OnboardingFeature.State()) {
            OnboardingFeature()
        }
    )
}
