import Foundation
import ComposableArchitecture

@Reducer
public struct QuestionSheetFeature {
    @ObservableState
    public struct State: Equatable {
        public var questionText: String
        public var isAnswered: Bool
        public var isSkipped: Bool

        public init(questionText: String, isAnswered: Bool = false, isSkipped: Bool = false) {
            self.questionText = questionText
            self.isAnswered = isAnswered
            self.isSkipped = isSkipped
        }
    }

    public enum Action: Sendable, Equatable {
        case closeTapped
        case answerTapped
        case writeQuestionTapped
        case refreshQuestionTapped
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
            case navigateToAnswer
            case showWriteQuestionCost
            case showRefreshQuestionCost
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .closeTapped:
                return .send(.delegate(.close))
            case .answerTapped:
                return .send(.delegate(.navigateToAnswer))
            case .writeQuestionTapped:
                return .send(.delegate(.showWriteQuestionCost))
            case .refreshQuestionTapped:
                return .send(.delegate(.showRefreshQuestionCost))
            case .delegate:
                return .none
            }
        }
    }
}
