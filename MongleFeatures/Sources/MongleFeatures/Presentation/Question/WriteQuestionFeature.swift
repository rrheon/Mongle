import Foundation
import ComposableArchitecture

// MARK: - 04-B · Write Question

@Reducer
public struct WriteQuestionFeature {
    @ObservableState
    public struct State: Equatable {
        public var questionText: String = ""
        public var isSubmitting: Bool = false
        public var appError: AppError?

        public var canSubmit: Bool {
            !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        public init() {}
    }

    public struct SubmitSuccess: Equatable, Sendable {
        public let question: Question
        public let heartsRemaining: Int
    }

    public enum Action: Sendable, Equatable {
        case closeTapped
        case questionTextChanged(String)
        case submitTapped
        case submitResponse(Result<SubmitSuccess, AppError>)
        case setAppError(AppError?)
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
            case questionSubmitted(Question, heartsRemaining: Int)
        }
    }

    @Dependency(\.questionRepository) var questionRepository
    @Dependency(\.errorHandler) var errorHandler

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
                state.appError = nil
                let content = state.questionText.trimmingCharacters(in: .whitespacesAndNewlines)
                return .run { [questionRepository] send in
                    do {
                        let (question, heartsRemaining) = try await questionRepository.createCustomQuestion(content: content)
                        await send(.submitResponse(.success(SubmitSuccess(question: question, heartsRemaining: heartsRemaining))))
                    } catch {
                        await send(.submitResponse(.failure(AppError.from(error))))
                    }
                }

            case .submitResponse(.success(let result)):
                state.isSubmitting = false
                return .send(.delegate(.questionSubmitted(result.question, heartsRemaining: result.heartsRemaining)))

            case .submitResponse(.failure(let error)):
                state.isSubmitting = false
                state.appError = error
                return .none

            case .setAppError(let error):
                state.appError = error
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
