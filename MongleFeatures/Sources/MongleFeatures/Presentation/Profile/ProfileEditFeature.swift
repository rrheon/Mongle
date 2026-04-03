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
        public var familyId: UUID?
        public var familyCreatedById: UUID?
        public var isLoading = false
        public var errorMessage: String?
        public var appError: AppError?
        public var isGuest: Bool = false
        public var showGuestLoginPrompt: Bool = false
        @Presents public var mongleCardEdit: MongleCardEditFeature.State?
        @Presents public var notificationSettings: NotificationSettingsFeature.State?
        @Presents public var groupManagement: GroupManagementFeature.State?
        @Presents public var moodHistory: MoodHistoryFeature.State?
        @Presents public var accountManagement: AccountManagementFeature.State?

        public init(user: User? = nil, familyId: UUID? = nil, familyCreatedById: UUID? = nil, isGuest: Bool = false) {
            self.user = user
            self.familyId = familyId
            self.familyCreatedById = familyCreatedById
            self.isGuest = isGuest
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
        case guestLoginTapped
        case guestLoginDismissed

        // MARK: - Internal Actions
        case userLoaded(User)
        case mongleCardEdit(PresentationAction<MongleCardEditFeature.Action>)
        case notificationSettings(PresentationAction<NotificationSettingsFeature.Action>)
        case groupManagement(PresentationAction<GroupManagementFeature.Action>)
        case moodHistory(PresentationAction<MoodHistoryFeature.Action>)
        case accountManagement(PresentationAction<AccountManagementFeature.Action>)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case profileUpdated(User)
            case logout
            case groupLeft
            case memberKicked
            case colorPreview(String)
            case colorPreviewCancelled
            case requestLogin
        }
    }

    @Dependency(\.authRepository) var authRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if state.user == nil {
                    state.isLoading = true
                    return .run { send in
                        let user = try? await authRepository.getCurrentUser()
                        if let user {
                            await send(.userLoaded(user))
                        }
                    }
                }
                return .none

            case .profileCardTapped:
                return .none

            case .moodSettingTapped:
                if state.isGuest { state.showGuestLoginPrompt = true; return .none }
                state.mongleCardEdit = MongleCardEditFeature.State(user: state.user)
                return .none

            case .moodHistoryTapped:
                if state.isGuest { state.showGuestLoginPrompt = true; return .none }
                state.moodHistory = MoodHistoryFeature.State()
                return .none

            case .notificationSettingsTapped:
                if state.isGuest { state.showGuestLoginPrompt = true; return .none }
                state.notificationSettings = NotificationSettingsFeature.State()
                return .none

            case .groupManagementTapped:
                if state.isGuest { state.showGuestLoginPrompt = true; return .none }
                state.groupManagement = GroupManagementFeature.State(
                    familyId: state.familyId,
                    currentUserId: state.user?.id,
                    familyCreatedById: state.familyCreatedById
                )
                return .none

            case .accountManagementTapped:
                if state.isGuest { state.showGuestLoginPrompt = true; return .none }
                state.accountManagement = AccountManagementFeature.State()
                return .none

            case .guestLoginTapped:
                state.showGuestLoginPrompt = false
                return .send(.delegate(.requestLogin))

            case .guestLoginDismissed:
                state.showGuestLoginPrompt = false
                return .none

            case .dismissError:
                state.errorMessage = nil
                state.appError = nil
                return .none

            case .userLoaded(let user):
                state.user = user
                state.isLoading = false
                return .none

            case .mongleCardEdit(.presented(.delegate(.saved(let user)))):
                state.user = user
                return .send(.delegate(.profileUpdated(user)))

            case .mongleCardEdit(.presented(.delegate(.cancelled))):
                return .send(.delegate(.colorPreviewCancelled))

            case .mongleCardEdit(.presented(.delegate(.colorPreview(let moodId)))):
                return .send(.delegate(.colorPreview(moodId)))

            case .mongleCardEdit:
                return .none

            case .notificationSettings(.presented(.delegate(.close))):
                state.notificationSettings = nil
                return .none

            case .notificationSettings:
                return .none

            case .groupManagement(.presented(.delegate(.close))):
                state.groupManagement = nil
                return .none

            case .groupManagement(.presented(.delegate(.groupLeft))):
                return .send(.delegate(.groupLeft))

            case .groupManagement(.presented(.delegate(.memberKicked))):
                return .send(.delegate(.memberKicked))

            case .groupManagement:
                return .none

            case .moodHistory(.presented(.delegate(.close))):
                state.moodHistory = nil
                return .none

            case .moodHistory:
                return .none

            case .accountManagement(.presented(.delegate(.close))):
                state.accountManagement = nil
                return .none

            case .accountManagement(.presented(.delegate(.logout))):
                state.accountManagement = nil
                return .send(.delegate(.logout))

            case .accountManagement(.presented(.delegate(.accountDeleted))):
                state.accountManagement = nil
                return .send(.delegate(.logout))

            case .accountManagement:
                return .none

            case .delegate:
                return .none
            }
        }
        .ifLet(\.$mongleCardEdit, action: \.mongleCardEdit) {
            MongleCardEditFeature()
        }
        .ifLet(\.$notificationSettings, action: \.notificationSettings) {
            NotificationSettingsFeature()
        }
        .ifLet(\.$groupManagement, action: \.groupManagement) {
            GroupManagementFeature()
        }
        .ifLet(\.$moodHistory, action: \.moodHistory) {
            MoodHistoryFeature()
        }
        .ifLet(\.$accountManagement, action: \.accountManagement) {
            AccountManagementFeature()
        }
    }
}
