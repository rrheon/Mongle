import Foundation
import ComposableArchitecture

@Reducer
public struct PeerNudgeFeature {
    @ObservableState
    public struct State: Equatable {
        public var targetUserId: String
        public var memberName: String
        public var questionText: String
        public var hearts: Int
        public var isSent: Bool
        public var isLoading: Bool
        public var appError: AppError?

        public init(
            targetUserId: String = "",
            memberName: String,
            questionText: String = "",
            hearts: Int = 5,
            isSent: Bool = false
        ) {
            self.targetUserId = targetUserId
            self.memberName = memberName
            self.questionText = questionText
            self.hearts = hearts
            self.isSent = isSent
            self.isLoading = false
        }
    }

    public enum Action: Sendable, Equatable {
        case nudgeTapped
        case nudgeResponse(Result<Int, AppError>)  // heartsRemaining
        case setAppError(AppError?)
        case closeTapped
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
            case nudgeSent(heartsRemaining: Int)
        }
    }

    @Dependency(\.nudgeRepository) var nudgeRepository
    @Dependency(\.errorHandler) var errorHandler

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .nudgeTapped:
                guard state.hearts > 0, !state.isSent, !state.isLoading else { return .none }
                guard !state.targetUserId.isEmpty else { return .none }
                state.isLoading = true
                state.appError = nil
                let targetUserId = state.targetUserId
                return .run { [nudgeRepository] send in
                    do {
                        let heartsRemaining = try await nudgeRepository.sendNudge(targetUserId: targetUserId)
                        await send(.nudgeResponse(.success(heartsRemaining)))
                    } catch {
                        await send(.nudgeResponse(.failure(AppError.from(error))))
                    }
                }

            case .nudgeResponse(.success(let heartsRemaining)):
                state.isLoading = false
                state.isSent = true
                state.hearts = heartsRemaining
                return .send(.delegate(.nudgeSent(heartsRemaining: heartsRemaining)))

            case .nudgeResponse(.failure(let error)):
                state.isLoading = false
                state.appError = error
                return .none

            case .setAppError(let error):
                state.appError = error
                return .none

            case .closeTapped:
                return .send(.delegate(.close))

            case .delegate:
                return .none
            }
        }
    }
}
