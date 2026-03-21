import Foundation
import ComposableArchitecture

// MARK: - 03-B · Heart Cost Popup (공용)

@Reducer
public struct HeartCostPopupFeature {
    public enum CostType: Equatable, Sendable {
        case writeQuestion   // 나만의 질문 작성하기 - 하트 3개
        case refreshQuestion // 질문 넘기기 (개인 패스) - 하트 3개
    }

    @ObservableState
    public struct State: Equatable {
        public var costType: CostType
        public var hearts: Int

        public var cost: Int { 3 }

        public var title: String {
            switch costType {
            case .writeQuestion: return "나만의 질문 작성하기"
            case .refreshQuestion: return "질문 넘기기"
            }
        }

        public var description: String {
            switch costType {
            case .writeQuestion: return "나만의 질문을 등록하면\n하트 3개가 소모됩니다."
            case .refreshQuestion: return "이 질문을 넘기면 하트 3개가 소모됩니다.\n다른 가족의 답변을 바로 볼 수 있어요."
            }
        }

        public var confirmLabel: String {
            switch costType {
            case .writeQuestion: return "작성하러 가기"
            case .refreshQuestion: return "질문 넘기기"
            }
        }

        public var hasEnoughHearts: Bool { hearts >= cost }

        public init(costType: CostType, hearts: Int = 5) {
            self.costType = costType
            self.hearts = hearts
        }
    }

    public enum Action: Sendable, Equatable {
        case confirmTapped
        case cancelTapped
        case watchAdTapped
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case confirmed(CostType)
            case cancelled
            case watchAdRequested(CostType)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .confirmTapped:
                return .send(.delegate(.confirmed(state.costType)))
            case .cancelTapped:
                return .send(.delegate(.cancelled))
            case .watchAdTapped:
                return .send(.delegate(.watchAdRequested(state.costType)))
            case .delegate:
                return .none
            }
        }
    }
}
