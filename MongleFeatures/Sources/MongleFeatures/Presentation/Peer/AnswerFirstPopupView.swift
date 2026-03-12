import SwiftUI
import ComposableArchitecture

public struct AnswerFirstPopupView: View {
    @Bindable var store: StoreOf<AnswerFirstPopupFeature>

    public init(store: StoreOf<AnswerFirstPopupFeature>) {
        self.store = store
    }

    public var body: some View {
        MonglePopupView(
            icon: .init(
                systemName: "pencil.circle.fill",
                foregroundColor: MongleColor.accentOrange,
                backgroundColor: Color(hex: "FFF1DE")
            ),
            title: "아직 오늘 답변을 안 했어요!",
            description: store.popupType == .nudge
                ? "\(store.memberName)에게 재촉하려면\n먼저 오늘의 질문에 답해주세요 🌿"
                : "\(store.memberName)의 답변을 보려면\n먼저 오늘의 질문에 답해주세요 🌿",
            note: "답변을 남기면 가족의 마음도 바로 열려요.",
            primaryLabel: "답변하러 가기",
            secondaryLabel: "나중에 할게요",
            onPrimary: { store.send(.answerNowTapped) },
            onSecondary: { store.send(.laterTapped) }
        )
    }
}
