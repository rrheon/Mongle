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
        public var editedName: String = ""
        public var editedRole: FamilyRole = .other
        public var profileImageURL: String?
        public var isLoading = false
        public var isSaving = false
        public var errorMessage: String?
        public var showImagePicker = false
        public var showRolePicker = false

        public var hasChanges: Bool {
            guard let user = user else { return false }
            return editedName != user.name || editedRole != user.role
        }

        public var isValid: Bool {
            !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        public init(user: User? = nil) {
            self.user = user
            if let user = user {
                self.editedName = user.name
                self.editedRole = user.role
                self.profileImageURL = user.profileImageURL
            }
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case onAppear
        case nameChanged(String)
        case roleChanged(FamilyRole)
        case profileImageTapped
        case saveButtonTapped
        case cancelButtonTapped
        case showRolePickerToggled
        case dismissError

        // MARK: - Internal Actions
        case setLoading(Bool)
        case setSaving(Bool)
        case setError(String?)
        case userLoaded(User)
        case saveCompleted(User)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case profileUpdated(User)
            case cancelled
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

            case .nameChanged(let name):
                state.editedName = name
                return .none

            case .roleChanged(let role):
                state.editedRole = role
                state.showRolePicker = false
                return .none

            case .profileImageTapped:
                state.showImagePicker = true
                return .none

            case .saveButtonTapped:
                guard state.isValid, state.hasChanges else { return .none }
                guard let user = state.user else { return .none }

                state.isSaving = true
                let editedName = state.editedName
                let editedRole = state.editedRole

                return .run { send in
                    try await Task.sleep(nanoseconds: 500_000_000)
                    let updatedUser = User(
                        id: user.id,
                        email: user.email,
                        name: editedName.trimmingCharacters(in: .whitespacesAndNewlines),
                        profileImageURL: user.profileImageURL,
                        role: editedRole,
                        createdAt: user.createdAt
                    )
                    await send(.saveCompleted(updatedUser))
                }

            case .cancelButtonTapped:
                return .send(.delegate(.cancelled))

            case .showRolePickerToggled:
                state.showRolePicker.toggle()
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .setLoading(let isLoading):
                state.isLoading = isLoading
                return .none

            case .setSaving(let isSaving):
                state.isSaving = isSaving
                return .none

            case .setError(let message):
                state.errorMessage = message
                state.isLoading = false
                state.isSaving = false
                return .none

            case .userLoaded(let user):
                state.user = user
                state.editedName = user.name
                state.editedRole = user.role
                state.profileImageURL = user.profileImageURL
                state.isLoading = false
                return .none

            case .saveCompleted(let user):
                state.user = user
                state.isSaving = false
                return .send(.delegate(.profileUpdated(user)))

            case .delegate:
                return .none
            }
        }
    }
}
