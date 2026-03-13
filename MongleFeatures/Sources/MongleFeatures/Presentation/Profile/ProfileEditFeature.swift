//
//  ProfileEditFeature.swift
//  Mongle
//
//  Created by Claude on 1/9/26.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct ProfileEditFeature {
    @ObservableState
    public struct State: Equatable {
        public var user: User?
        public var isLoading = false
        public var errorMessage: String?
        @Presents public var mongleCardEdit: MongleCardEditFeature.State?

        public init(user: User? = nil) {
            self.user = user
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case onAppear
        case profileCardTapped
        case moodSettingTapped
        case moodHistoryTapped
        case notificationSettingsTapped
        case groupManagementTapped
        case accountManagementTapped
        case dismissError

        // MARK: - Internal Actions
        case userLoaded(User)
        case mongleCardEdit(PresentationAction<MongleCardEditFeature.Action>)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case navigateToMoodSetting
            case navigateToMoodHistory
            case navigateToNotificationSettings
            case navigateToGroupManagement
            case navigateToAccountManagement
            case profileUpdated(User)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if state.user == nil {
                    state.isLoading = true
                    return .run { send in
                        try await Task.sleep(nanoseconds: 300_000_000)
                        let mockUser = User(
                            id: UUID(),
                            email: "user@example.com",
                            name: "홍길동",
                            profileImageURL: nil,
                            role: .son,
                            createdAt: Date()
                        )
                        await send(.userLoaded(mockUser))
                    }
                }
                return .none

            case .profileCardTapped:
                state.mongleCardEdit = MongleCardEditFeature.State(user: state.user)
                return .none

            case .moodSettingTapped:
                return .send(.delegate(.navigateToMoodSetting))

            case .moodHistoryTapped:
                return .send(.delegate(.navigateToMoodHistory))

            case .notificationSettingsTapped:
                return .send(.delegate(.navigateToNotificationSettings))

            case .groupManagementTapped:
                return .send(.delegate(.navigateToGroupManagement))

            case .accountManagementTapped:
                return .send(.delegate(.navigateToAccountManagement))

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .userLoaded(let user):
                state.user = user
                state.isLoading = false
                return .none

            case .mongleCardEdit(.presented(.delegate(.saved(let user)))):
                state.user = user
                state.mongleCardEdit = nil
                return .send(.delegate(.profileUpdated(user)))

            case .mongleCardEdit(.presented(.delegate(.cancelled))):
                state.mongleCardEdit = nil
                return .none

            case .mongleCardEdit:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$mongleCardEdit, action: \.mongleCardEdit) {
            MongleCardEditFeature()
        }
    }
}
