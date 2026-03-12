import Foundation
import ComposableArchitecture

// MARK: - 04-B · Write Question

@Reducer
public struct WriteQuestionFeature {
    @ObservableState
    public struct State: Equatable {
        public var questionText: String = ""
        public var isSubmitting: Bool = false

        public var canSubmit: Bool {
            !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        public init() {}
    }

    public enum Action: Sendable, Equatable {
        case closeTapped
        case questionTextChanged(String)
        case submitTapped
        case submitCompleted
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
            case questionSubmitted
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .closeTapped:
                return .send(.delegate(.close))

            case .questionTextChanged(let text):
                state.questionText = text
                return .none

            case .submitTapped:
                guard state.canSubmit, !state.isSubmitting else { return .none }
                state.isSubmitting = true
                return .run { send in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await send(.submitCompleted)
                }

            case .submitCompleted:
                state.isSubmitting = false
                return .send(.delegate(.questionSubmitted))

            case .delegate:
                return .none
            }
        }
    }
}
