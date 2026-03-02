//
//  FamilyFeature.swift
//  Mongle
//
//  Created by Claude on 2025-01-06.
//

import Foundation
import ComposableArchitecture
import Domain
#if canImport(UIKit)
import UIKit
#endif

@Reducer
public struct FamilyFeature {
    @ObservableState
    public struct State: Equatable {
        public var family: MongleGroup?
        public var members: [User] = []
        public var currentUser: User?
        public var isLoading: Bool = false
        public var errorMessage: String?
        public var showInviteCodeCopied: Bool = false

        public var hasFamily: Bool {
            family != nil
        }

        public var inviteCode: String {
            family?.inviteCode ?? ""
        }

        public var isCreator: Bool {
            guard let family = family, let currentUser = currentUser else { return false }
            return family.createdBy == currentUser.id
        }

        public init(
            family: MongleGroup? = nil,
            members: [User] = [],
            currentUser: User? = nil,
            isLoading: Bool = false,
            errorMessage: String? = nil,
            showInviteCodeCopied: Bool = false
        ) {
            self.family = family
            self.members = members
            self.currentUser = currentUser
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.showInviteCodeCopied = showInviteCodeCopied
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case onAppear
        case refreshTapped
        case copyInviteCodeTapped
        case dismissCopiedToast
        case dismissErrorTapped
        case createFamilyTapped
        case joinFamilyTapped
        case leaveFamilyTapped

        // MARK: - Internal Actions
        case loadDataResponse(Result<LoadedData, FamilyError>)
        case leaveFamilySuccess
        case leaveFamilyFailure(FamilyError)
        case setShowInviteCodeCopied(Bool)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case navigateToCreateFamily
            case navigateToJoinFamily
            case leftFamily
        }
    }

    public struct LoadedData: Equatable, Sendable {
        public let family: MongleGroup?
        public let members: [User]
        public let currentUser: User?

        public init(family: MongleGroup?, members: [User], currentUser: User?) {
            self.family = family
            self.members = members
            self.currentUser = currentUser
        }
    }

    public enum FamilyError: Error, Equatable, Sendable {
        case networkError
        case cannotLeave
        case unknown(String)

        var localizedDescription: String {
            switch self {
            case .networkError:
                return "네트워크 연결을 확인해주세요."
            case .cannotLeave:
                return "가족을 떠날 수 없습니다."
            case .unknown(let message):
                return message
            }
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.family == nil && !state.isLoading else { return .none }
                state.isLoading = true
                return .run { send in
                    // TODO: 실제 API 호출로 교체
                    try await Task.sleep(nanoseconds: 500_000_000)

                    let mockCurrentUser = User(
                        id: UUID(),
                        email: "me@example.com",
                        name: "나",
                        profileImageURL: nil,
                        role: .son,
                        createdAt: .now
                    )

                    let mockMembers = [
                        User(id: UUID(), email: "dad@example.com", name: "아빠", profileImageURL: nil, role: .father, createdAt: .now),
                        User(id: UUID(), email: "mom@example.com", name: "엄마", profileImageURL: nil, role: .mother, createdAt: .now),
                        mockCurrentUser
                    ]

                    let mockFamily = MongleGroup(
                        id: UUID(),
                        name: "우리 가족",
                        memberIds: mockMembers.map { $0.id },
                        createdBy: mockMembers[0].id,
                        createdAt: .now,
                        inviteCode: "ABC12345",
                        treeProgressId: UUID()
                    )

                    await send(.loadDataResponse(.success(LoadedData(
                        family: mockFamily,
                        members: mockMembers,
                        currentUser: mockCurrentUser
                    ))))
                }

            case .refreshTapped:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    try await Task.sleep(nanoseconds: 500_000_000)

                    let mockCurrentUser = User(
                        id: UUID(),
                        email: "me@example.com",
                        name: "나",
                        profileImageURL: nil,
                        role: .son,
                        createdAt: .now
                    )

                    let mockMembers = [
                        User(id: UUID(), email: "dad@example.com", name: "아빠", profileImageURL: nil, role: .father, createdAt: .now),
                        User(id: UUID(), email: "mom@example.com", name: "엄마", profileImageURL: nil, role: .mother, createdAt: .now),
                        mockCurrentUser
                    ]

                    let mockFamily = MongleGroup(
                        id: UUID(),
                        name: "우리 가족",
                        memberIds: mockMembers.map { $0.id },
                        createdBy: mockMembers[0].id,
                        createdAt: .now,
                        inviteCode: "ABC12345",
                        treeProgressId: UUID()
                    )

                    await send(.loadDataResponse(.success(LoadedData(
                        family: mockFamily,
                        members: mockMembers,
                        currentUser: mockCurrentUser
                    ))))
                }

            case .copyInviteCodeTapped:
                guard let inviteCode = state.family?.inviteCode else { return .none }
                // Copy to clipboard (UIPasteboard in iOS)
                #if canImport(UIKit)
                UIPasteboard.general.string = inviteCode
                #endif
                state.showInviteCodeCopied = true
                return .run { send in
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    await send(.setShowInviteCodeCopied(false))
                }

            case .setShowInviteCodeCopied(let show):
                state.showInviteCodeCopied = show
                return .none

            case .dismissCopiedToast:
                state.showInviteCodeCopied = false
                return .none

            case .dismissErrorTapped:
                state.errorMessage = nil
                return .none

            case .createFamilyTapped:
                return .send(.delegate(.navigateToCreateFamily))

            case .joinFamilyTapped:
                return .send(.delegate(.navigateToJoinFamily))

            case .leaveFamilyTapped:
                // TODO: 확인 다이얼로그 추가
                state.isLoading = true
                return .run { send in
                    try await Task.sleep(nanoseconds: 500_000_000)
                    await send(.leaveFamilySuccess)
                }

            case .loadDataResponse(.success(let data)):
                state.isLoading = false
                state.family = data.family
                state.members = data.members
                state.currentUser = data.currentUser
                return .none

            case .loadDataResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .leaveFamilySuccess:
                state.isLoading = false
                state.family = nil
                state.members = []
                return .send(.delegate(.leftFamily))

            case .leaveFamilyFailure(let error):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
