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
        @Presents public var mongleCardEdit: MongleCardEditFeature.State?
        @Presents public var supportScreen: SupportScreenFeature.State?
        @Presents public var accountManagement: AccountManagementFeature.State?

        public init(user: User? = nil, familyId: UUID? = nil, familyCreatedById: UUID? = nil) {
            self.user = user
            self.familyId = familyId
            self.familyCreatedById = familyCreatedById
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
        case supportScreen(PresentationAction<SupportScreenFeature.Action>)
        case accountManagement(PresentationAction<AccountManagementFeature.Action>)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case profileUpdated(User)
            case logout
            case groupLeft
            case colorPreview(String)
            case colorPreviewCancelled
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
                return .none

            case .moodSettingTapped:
                state.mongleCardEdit = MongleCardEditFeature.State(user: state.user)
                return .none

            case .moodHistoryTapped:
                state.supportScreen = SupportScreenFeature.State(screen: .moodHistory)
                return .none

            case .notificationSettingsTapped:
                state.supportScreen = SupportScreenFeature.State(screen: .notificationSettings)
                return .none

            case .groupManagementTapped:
                state.supportScreen = SupportScreenFeature.State(
                    screen: .groupManagement,
                    familyId: state.familyId,
                    currentUserId: state.user?.id,
                    familyCreatedById: state.familyCreatedById
                )
                return .none

            case .accountManagementTapped:
                state.accountManagement = AccountManagementFeature.State()
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
                state.mongleCardEdit = nil
                return .send(.delegate(.profileUpdated(user)))

            case .mongleCardEdit(.presented(.delegate(.cancelled))):
                state.mongleCardEdit = nil
                return .send(.delegate(.colorPreviewCancelled))

            case .mongleCardEdit(.presented(.delegate(.colorPreview(let moodId)))):
                return .send(.delegate(.colorPreview(moodId)))

            case .mongleCardEdit:
                return .none

            case .supportScreen(.presented(.delegate(.close))):
                state.supportScreen = nil
                return .none

            case .supportScreen(.presented(.delegate(.groupLeft))):
                state.supportScreen = nil
                return .send(.delegate(.groupLeft))

            case .supportScreen:
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
        .ifLet(\.$supportScreen, action: \.supportScreen) {
            SupportScreenFeature()
        }
        .ifLet(\.$accountManagement, action: \.accountManagement) {
            AccountManagementFeature()
        }
    }
}
