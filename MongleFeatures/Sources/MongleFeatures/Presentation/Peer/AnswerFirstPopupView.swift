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
                backgroundColor: MongleColor.bgYellowSoft
            ),
            title: L10n.tr("home_answer_first_answer_desc"),
            description: store.popupType == .nudge
                ? L10n.tr("home_answer_first_nudge", store.memberName)
                : L10n.tr("home_answer_first_view", store.memberName),
            note: L10n.tr("home_answer_first_note"),
            primaryLabel: L10n.tr("home_answer_first_go"),
            secondaryLabel: L10n.tr("home_answer_first_later"),
            onPrimary: { store.send(.answerNowTapped) },
            onSecondary: { store.send(.laterTapped) }
        )
    }
}
