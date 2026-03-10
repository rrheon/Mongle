import Foundation
import ComposableArchitecture

@Reducer
public struct GroupSelectFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Step: Equatable, Sendable {
            case select
            case createStep1
            case createStep2
            case joinGroup
        }

        public var step: Step = .select
        public var showActionSheet: Bool = false
        public var groupName: String = ""
        public var nickname: String = ""
        public var inviteCode: String = ""
        public var joinCode: String = ""

        public init(
            step: Step = .select,
            groupName: String = "",
            nickname: String = "",
            inviteCode: String = "",
            joinCode: String = ""
        ) {
            self.step = step
            self.groupName = groupName
            self.nickname = nickname
            self.inviteCode = inviteCode
            self.joinCode = joinCode
        }
    }

    public enum Action: Sendable, Equatable {
        case newSpaceButtonTapped
        case actionSheetDismissed
        case actionSheetNewSpaceTapped
        case actionSheetJoinSpaceTapped
        case notificationTapped
        case groupNameChanged(String)
        case nicknameChanged(String)
        case joinCodeChanged(String)
        case createNextTapped
        case createBackTapped
        case completeTapped
        case joinBackTapped
        case joinTapped
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case completed
            case notificationTapped
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .newSpaceButtonTapped:
                state.showActionSheet = true
                return .none

            case .actionSheetDismissed:
                state.showActionSheet = false
                return .none

            case .actionSheetNewSpaceTapped:
                state.showActionSheet = false
                state.step = .createStep1
                return .none

            case .actionSheetJoinSpaceTapped:
                state.showActionSheet = false
                state.step = .joinGroup
                return .none

            case .notificationTapped:
                return .send(.delegate(.notificationTapped))

            case .groupNameChanged(let name):
                state.groupName = name
                return .none

            case .nicknameChanged(let name):
                state.nickname = name
                return .none

            case .joinCodeChanged(let code):
                state.joinCode = code
                return .none

            case .createNextTapped:
                guard !state.groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .none }
                state.step = .createStep2
                state.inviteCode = state.inviteCode.isEmpty ? "MONG-4729" : state.inviteCode
                return .none

            case .createBackTapped:
                state.step = .select
                state.groupName = ""
                state.nickname = ""
                return .none

            case .completeTapped:
                return .send(.delegate(.completed))

            case .joinBackTapped:
                state.step = .select
                state.joinCode = ""
                state.nickname = ""
                return .none

            case .joinTapped:
                return .send(.delegate(.completed))

            case .delegate:
                return .none
            }
        }
    }
}
