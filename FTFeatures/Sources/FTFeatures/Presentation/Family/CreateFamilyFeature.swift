//
//  CreateFamilyFeature.swift
//  Mongle
//
//  Created by Claude on 2025-01-06.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct CreateFamilyFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Step: Equatable {
            case form    // 가족 이름 + 역할 입력
            case invite  // 생성 완료 + 초대 코드 공유
        }

        public var step: Step = .form
        public var familyName: String = ""
        public var selectedRole: FamilyRole = .father
        public var isLoading: Bool = false
        public var errorMessage: String?
        public var createdFamily: MongleGroup?

        public var isValid: Bool {
            !familyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        public init(
            familyName: String = "",
            selectedRole: FamilyRole = .father,
            isLoading: Bool = false,
            errorMessage: String? = nil
        ) {
            self.familyName = familyName
            self.selectedRole = selectedRole
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case familyNameChanged(String)
        case roleSelected(FamilyRole)
        case createButtonTapped
        case dismissErrorTapped
        case cancelTapped
        case doneTapped   // 초대 화면에서 "시작하기" 탭

        // MARK: - Internal Actions
        case createFamilyResponse(Result<MongleGroup, FamilyCreationError>)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case familyCreated(MongleGroup)
            case cancelled
        }
    }

    public enum FamilyCreationError: Error, Equatable, Sendable {
        case invalidName
        case networkError
        case unknown(String)

        var localizedDescription: String {
            switch self {
            case .invalidName:
                return "가족 이름을 입력해주세요."
            case .networkError:
                return "네트워크 연결을 확인해주세요."
            case .unknown(let message):
                return message
            }
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - View Actions
            case .familyNameChanged(let name):
                state.familyName = name
                state.errorMessage = nil
                return .none

            case .roleSelected(let role):
                state.selectedRole = role
                return .none

            case .createButtonTapped:
                guard state.isValid else {
                    state.errorMessage = "가족 이름을 입력해주세요."
                    return .none
                }

                state.isLoading = true
                state.errorMessage = nil

                let familyName = state.familyName.trimmingCharacters(in: .whitespacesAndNewlines)

                return .run { send in
                    // TODO: 실제 API 호출로 교체
                    try await Task.sleep(nanoseconds: 1_000_000_000)

                    let newFamily = MongleGroup(
                        id: UUID(),
                        name: familyName,
                        memberIds: [UUID()],
                        createdBy: UUID(),
                        createdAt: .now,
                        inviteCode: generateInviteCode(),
                        treeProgressId: UUID()
                    )

                    await send(.createFamilyResponse(.success(newFamily)))
                }

            case .dismissErrorTapped:
                state.errorMessage = nil
                return .none

            case .cancelTapped:
                return .send(.delegate(.cancelled))

            case .doneTapped:
                guard let family = state.createdFamily else { return .none }
                return .send(.delegate(.familyCreated(family)))

            // MARK: - Internal Actions
            case .createFamilyResponse(.success(let family)):
                state.isLoading = false
                state.createdFamily = family
                state.step = .invite  // 초대 화면으로 전환

            return .none

            case .createFamilyResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            // MARK: - Delegate Actions
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Helper Functions
private func generateInviteCode() -> String {
    let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<8).map { _ in characters.randomElement()! })
}
