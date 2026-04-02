import Foundation
import ComposableArchitecture

// MARK: - 03-B · Heart Cost Popup (공용)

@Reducer
public struct HeartCostPopupFeature {
    public enum CostType: Equatable, Sendable {
        case writeQuestion   // 나만의 질문 작성하기 - 하트 3개
        case refreshQuestion // 질문 넘기기 (개인 패스) - 하트 3개
        case editAnswer      // 답변 수정하기 - 하트 1개

        public var cost: Int {
            switch self {
            case .writeQuestion, .refreshQuestion: return 3
            case .editAnswer: return 1
            }
        }
    }

    @ObservableState
    public struct State: Equatable {
        public var costType: CostType
        public var hearts: Int

        public var cost: Int { costType.cost }

        public var title: String {
            switch costType {
            case .writeQuestion: return L10n.tr("heart_cost_write")
            case .refreshQuestion: return L10n.tr("heart_cost_skip")
            case .editAnswer: return L10n.tr("heart_cost_edit")
            }
        }

        public var description: String {
            switch costType {
            case .writeQuestion: return L10n.tr("heart_cost_write_desc")
            case .refreshQuestion: return L10n.tr("heart_cost_skip_desc")
            case .editAnswer: return L10n.tr("heart_cost_edit_desc")
            }
        }

        public var confirmLabel: String {
            switch costType {
            case .writeQuestion: return L10n.tr("heart_cost_write_btn")
            case .refreshQuestion: return L10n.tr("heart_cost_skip_btn")
            case .editAnswer: return L10n.tr("heart_cost_edit_btn")
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
