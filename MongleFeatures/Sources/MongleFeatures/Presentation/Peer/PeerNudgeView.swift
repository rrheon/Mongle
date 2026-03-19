import SwiftUI
import ComposableArchitecture

public struct PeerNudgeView: View {
    @Bindable var store: StoreOf<PeerNudgeFeature>

    public init(store: StoreOf<PeerNudgeFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationHeader
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    questionCard
                    emptyState
                    nudgeCard
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(MongleColor.background)
        }
        .background(MongleColor.background)
        .mongleErrorBanner(
            error: store.appError,
            onDismiss: { store.send(.setAppError(nil)) }
        )
    }

    // MARK: - Navigation Header

    private var navigationHeader: some View {
        HStack {
            Button {
                store.send(.closeTapped)
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MongleColor.textPrimary)
                    .frame(width: 24, height: 24)
            }
            Spacer()
            Text("답변 재촉하기")
                .font(MongleFont.heading3())
                .foregroundColor(MongleColor.textPrimary)
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(Color.white)
    }

    // MARK: - Question Card

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            Text("오늘의 질문")
                .font(MongleFont.body2Bold())
                .foregroundColor(MongleColor.primary)
            Text(store.questionText)
                .font(MongleFont.button())
                .foregroundColor(MongleColor.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MongleSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MongleColor.cardGlass)
        .clipShape(RoundedRectangle(cornerRadius: MongleRadius.xl))
    }

    // MARK: - Empty State (몽글 + 미답변 안내)

    private var emptyState: some View {
        VStack(spacing: 16) {
            MongleMonggle(color: MongleColor.monggleYellow, size: 72)
            VStack(spacing: 4) {
                Text("\(store.memberName)가 아직 답변하지 않았어요")
                    .font(MongleFont.button())
                    .foregroundColor(MongleColor.textPrimary)
                    .multilineTextAlignment(.center)
                Text("답변하면 여기서 바로 확인할 수 있어요")
                    .font(.system(size: 13))
                    .foregroundColor(MongleColor.textHint)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Nudge Card

    private var nudgeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("답변을 재촉해볼까요?")
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)

            Text("\(store.memberName)에게 알림을 보내 답변을 재촉할 수 있어요.\n하트 1개가 소모됩니다.")
                .font(.system(size: 13))
                .foregroundColor(MongleColor.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            heartRow

            nudgeButton
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MongleColor.cardGlass)
        .clipShape(RoundedRectangle(cornerRadius: MongleRadius.xl))
    }

    private var heartRow: some View {
        HStack {
            HStack(spacing: MongleSpacing.sm) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(MongleColor.heartRed)
                Text("보유 하트: \(store.hearts)개")
                    .font(.system(size: 13))
                    .foregroundColor(MongleColor.textSecondary)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(MongleColor.heartRed)
                Text(store.isSent ? "전송 완료" : "-1")
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.heartRed)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(MongleColor.heartRedLight)
            .clipShape(Capsule())
        }
    }

    private var nudgeButton: some View {
        Button {
            store.send(.nudgeTapped)
        } label: {
            HStack(spacing: MongleSpacing.sm) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                Text(store.isSent ? "재촉 완료" : "재촉하기")
                    .font(MongleFont.body1Bold())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [MongleColor.coralLight, MongleColor.heartRed],
                    startPoint: UnitPoint(x: 0.15, y: 0.15),
                    endPoint: UnitPoint(x: 0.85, y: 0.85)
                )
            )
            .clipShape(Capsule())
            .opacity((store.isSent || store.hearts <= 0) ? 0.6 : 1)
        }
        .disabled(store.isSent || store.hearts <= 0)
    }
}
