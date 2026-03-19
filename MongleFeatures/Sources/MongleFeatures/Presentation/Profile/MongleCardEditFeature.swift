//
//  MongleCardEditFeature.swift
//  Mongle
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct MongleCardEditFeature {
    @ObservableState
    public struct State: Equatable {
        public var user: User?
        public var editedName: String = ""
        public var selectedMoodId: String = "loved"
        public var isSaving = false
        public var saveError: AppError? = nil

        public var hasChanges: Bool {
            guard let user = user else { return !editedName.isEmpty }
            return editedName != user.name || selectedMoodId != (user.moodId ?? "loved")
        }

        public var isValid: Bool {
            !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        public init(user: User? = nil) {
            self.user = user
            if let user = user {
                self.editedName = user.name
                self.selectedMoodId = user.moodId ?? "loved"
            }
        }
    }

    public enum Action: Sendable, Equatable {
        case backTapped
        case saveTapped
        case nameChanged(String)
        case moodSelected(String)
        case saveCompleted(User)
        case saveFailed(AppError)
        case dismissSaveError

        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case saved(User)
            case cancelled
            case colorPreview(String)
        }
    }

    @Dependency(\.userRepository) var userRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backTapped:
                return .send(.delegate(.cancelled))

            case .saveTapped:
                guard state.isValid else { return .none }
                guard let user = state.user else { return .none }
                state.isSaving = true
                state.saveError = nil
                let name = state.editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                let moodId = state.selectedMoodId
                let updated = User(
                    id: user.id,
                    email: user.email,
                    name: name,
                    profileImageURL: user.profileImageURL,
                    role: user.role,
                    hearts: user.hearts,
                    moodId: moodId,
                    createdAt: user.createdAt
                )
                return .run { send in
                    do {
                        let saved = try await userRepository.update(updated)
                        await send(.saveCompleted(saved))
                    } catch {
                        await send(.saveFailed(AppError.from(error)))
                    }
                }

            case .nameChanged(let name):
                state.editedName = name
                return .none

            case .moodSelected(let moodId):
                state.selectedMoodId = moodId
                return .send(.delegate(.colorPreview(moodId)))

            case .saveCompleted(let user):
                state.isSaving = false
                state.user = user
                return .send(.delegate(.saved(user)))

            case .saveFailed(let error):
                state.isSaving = false
                state.saveError = error
                return .none

            case .dismissSaveError:
                state.saveError = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
