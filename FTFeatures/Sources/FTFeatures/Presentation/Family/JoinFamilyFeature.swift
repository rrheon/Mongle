//
//  JoinFamilyFeature.swift
//  Mongle
//
//  Created by Claude on 2025-01-06.
//

import Foundation
import ComposableArchitecture
import Domain

// MARK: - Mood Color
public enum MoodColor: String, CaseIterable, Sendable, Equatable {
    case red
    case orange
    case yellow
    case green
    case teal
    case blue
    case purple
    case pink

    public var label: String {
        switch self {
        case .red:    return "활발한"
        case .orange: return "행복한"
        case .yellow: return "기쁜"
        case .green:  return "편안한"
        case .teal:   return "평화로운"
        case .blue:   return "차분한"
        case .purple: return "그리운"
        case .pink:   return "사랑스러운"
        }
    }

    /// 헥스 색상 문자열 (SwiftUI Color(hex:) 사용)
    public var hexString: String {
        switch self {
        case .red:    return "FF6B6B"
        case .orange: return "FF9F43"
        case .yellow: return "FECA57"
        case .green:  return "1DD1A1"
        case .teal:   return "48DBFB"
        case .blue:   return "54A0FF"
        case .purple: return "A29BFE"
        case .pink:   return "FD79A8"
        }
    }

    /// 색상이 선택되지 않았을 때 적용할 기본 헥스
    public static let defaultHex = "4CAF50"
}

@Reducer
public struct JoinFamilyFeature {
    @ObservableState
    public struct State: Equatable {
        public enum Step: Equatable {
            case search   // 초대 코드 검색
            case profile  // 프로필 만들기 (이름 + 기분 색상)
        }

        // MARK: Search Step
        public var step: Step = .search
        public var inviteCode: String = ""
        public var selectedRole: FamilyRole = .son
        public var isLoading: Bool = false
        public var isSearching: Bool = false
        public var foundFamily: MongleGroup?
        public var errorMessage: String?

        // MARK: Profile Step
        public var profileName: String = ""
        public var selectedMoodColor: MoodColor? = nil

        public var isValidCode: Bool {
            inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6
        }

        public var canJoin: Bool {
            foundFamily != nil && !isLoading
        }

        public var canConfirmProfile: Bool {
            !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
        }

        public init(
            inviteCode: String = "",
            selectedRole: FamilyRole = .son,
            isLoading: Bool = false,
            isSearching: Bool = false,
            foundFamily: MongleGroup? = nil,
            errorMessage: String? = nil
        ) {
            self.inviteCode = inviteCode
            self.selectedRole = selectedRole
            self.isLoading = isLoading
            self.isSearching = isSearching
            self.foundFamily = foundFamily
            self.errorMessage = errorMessage
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - Search Step Actions
        case inviteCodeChanged(String)
        case roleSelected(FamilyRole)
        case searchButtonTapped
        case joinButtonTapped
        case dismissErrorTapped
        case cancelTapped
        case clearFoundFamily

        // MARK: - Profile Step Actions
        case profileNameChanged(String)
        case moodColorSelected(MoodColor?)
        case confirmProfileTapped
        case backToSearch

        // MARK: - Internal Actions
        case searchFamilyResponse(Result<MongleGroup?, JoinFamilyError>)
        case joinFamilyResponse(Result<MongleGroup, JoinFamilyError>)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case familyJoined(MongleGroup)
            case cancelled
        }
    }

    public enum JoinFamilyError: Error, Equatable, Sendable {
        case invalidCode
        case familyNotFound
        case alreadyMember
        case networkError
        case unknown(String)

        var localizedDescription: String {
            switch self {
            case .invalidCode:
                return "유효하지 않은 초대 코드입니다."
            case .familyNotFound:
                return "해당 초대 코드의 가족을 찾을 수 없습니다."
            case .alreadyMember:
                return "이미 가입된 가족입니다."
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
            // MARK: - Search Step
            case .inviteCodeChanged(let code):
                state.inviteCode = code.uppercased()
                state.errorMessage = nil
                if state.foundFamily != nil {
                    state.foundFamily = nil
                }
                return .none

            case .roleSelected(let role):
                state.selectedRole = role
                return .none

            case .searchButtonTapped:
                guard state.isValidCode else {
                    state.errorMessage = "초대 코드를 입력해주세요. (6자 이상)"
                    return .none
                }

                state.isSearching = true
                state.errorMessage = nil
                state.foundFamily = nil

                let code = state.inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)

                return .run { send in
                    // TODO: 실제 API 호출로 교체
                    try await Task.sleep(nanoseconds: 1_000_000_000)

                    if code == "TESTCODE" || code.count == 8 {
                        let family = MongleGroup(
                            id: UUID(),
                            name: "행복한 가족",
                            memberIds: [UUID(), UUID()],
                            createdBy: UUID(),
                            createdAt: .now,
                            inviteCode: code,
                            treeProgressId: UUID()
                        )
                        await send(.searchFamilyResponse(.success(family)))
                    } else {
                        await send(.searchFamilyResponse(.failure(.familyNotFound)))
                    }
                }

            case .joinButtonTapped:
                guard state.foundFamily != nil else { return .none }
                // 검색 완료 → 프로필 만들기 단계로 전환
                state.step = .profile
                state.errorMessage = nil
                return .none

            case .dismissErrorTapped:
                state.errorMessage = nil
                return .none

            case .cancelTapped:
                return .send(.delegate(.cancelled))

            case .clearFoundFamily:
                state.foundFamily = nil
                return .none

            // MARK: - Profile Step
            case .profileNameChanged(let name):
                state.profileName = name
                return .none

            case .moodColorSelected(let color):
                // 같은 색상 탭하면 선택 해제
                state.selectedMoodColor = color
                return .none

            case .confirmProfileTapped:
                guard let family = state.foundFamily,
                      state.canConfirmProfile else { return .none }

                state.isLoading = true
                state.errorMessage = nil

                return .run { send in
                    // TODO: 실제 API 호출로 교체 (프로필 이름, 색상, 역할 포함)
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    await send(.joinFamilyResponse(.success(family)))
                }

            case .backToSearch:
                state.step = .search
                state.profileName = ""
                state.selectedMoodColor = nil
                state.errorMessage = nil
                return .none

            // MARK: - Internal Actions
            case .searchFamilyResponse(.success(let family)):
                state.isSearching = false
                state.foundFamily = family
                return .none

            case .searchFamilyResponse(.failure(let error)):
                state.isSearching = false
                state.errorMessage = error.localizedDescription
                return .none

            case .joinFamilyResponse(.success(let family)):
                state.isLoading = false
                return .send(.delegate(.familyJoined(family)))

            case .joinFamilyResponse(.failure(let error)):
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
