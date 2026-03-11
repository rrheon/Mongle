import Foundation
import ComposableArchitecture

@Reducer
public struct AnswerFirstPopupFeature {
    public enum PopupType: Equatable, Sendable {
        case viewAnswer  // 답변완료 캐릭터 탭: 답변 후 볼 수 있음
        case nudge       // 미답변 캐릭터 탭: 답변 후 재촉 가능
    }

    @ObservableState
    public struct State: Equatable {
        public var memberName: String
        public var popupType: PopupType

        public init(memberName: String, popupType: PopupType = .viewAnswer) {
            self.memberName = memberName
            self.popupType = popupType
        }
    }

    public enum Action: Sendable, Equatable {
        case answerNowTapped
        case laterTapped
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case answerNow
            case close
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .answerNowTapped:
                return .send(.delegate(.answerNow))
            case .laterTapped:
                return .send(.delegate(.close))
            case .delegate:
                return .none
            }
        }
    }
}
