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

            nudgeButton
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .background(MongleColor.background)
        }
        .background(MongleColor.background)
        .mongleErrorToast(
            error: store.appError,
            onDismiss: { store.send(.setAppError(nil)) }
        )
    }

    // MARK: - Navigation Header

    private var navigationHeader: some View {
        MongleNavigationHeader(title: "답변 재촉하기") {
            MongleBackButton { store.send(.closeTapped) }
        } right: {
            EmptyView()
        }
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

    private func monggleColor(for moodId: String?) -> Color {
        switch moodId {
        case "happy":  return MongleColor.monggleYellow
        case "calm":   return MongleColor.monggleGreen
        case "loved":  return MongleColor.mongglePink
        case "sad":    return MongleColor.monggleBlue
        case "tired":  return MongleColor.monggleOrange
        default:       return MongleColor.monggleYellow
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            MongleMonggle(color: monggleColor(for: store.memberMoodId), size: 72)
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

            if store.hearts <= 0 && !store.isSent {
                insufficientHeartsSection
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MongleColor.cardGlass)
        .clipShape(RoundedRectangle(cornerRadius: MongleRadius.xl))
    }

    private var insufficientHeartsSection: some View {
        VStack(spacing: MongleSpacing.xs) {
            Text("하트가 부족해요.")
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.error)

            Button {
                store.send(.watchAdTapped)
            } label: {
                HStack(spacing: 6) {
                    if store.isWatchingAd {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 13))
                        Text("광고 보고 재촉하기")
                            .font(MongleFont.captionBold())
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(MongleColor.primary)
                .clipShape(Capsule())
                .opacity(store.isWatchingAd ? 0.7 : 1)
            }
            .buttonStyle(.plain)
            .disabled(store.isWatchingAd)
        }
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
