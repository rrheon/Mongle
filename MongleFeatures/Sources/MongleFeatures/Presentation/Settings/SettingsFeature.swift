//
//  SettingsFeature.swift
//  Mongle
//
//  Created by Claude on 2025-01-06.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        public var currentUser: User?
        /// 로그인 시 사용한 소셜 제공자 (nil = 이메일 로그인)
        public var loginProviderType: SocialProviderType?
        public var appVersion: String
        public var notificationsEnabled: Bool
        public var isLoading: Bool
        public var showLogoutConfirmation: Bool
        public var showDeleteAccountConfirmation: Bool
        public var errorMessage: String?

        public init(
            currentUser: User? = nil,
            loginProviderType: SocialProviderType? = nil,
            appVersion: String = "1.0.0",
            notificationsEnabled: Bool = UserDefaults.standard.object(forKey: "mongle_notifications_enabled") as? Bool ?? true,
            isLoading: Bool = false,
            showLogoutConfirmation: Bool = false,
            showDeleteAccountConfirmation: Bool = false,
            errorMessage: String? = nil
        ) {
            self.currentUser = currentUser
            self.loginProviderType = loginProviderType
            self.appVersion = appVersion
            self.notificationsEnabled = notificationsEnabled
            self.isLoading = isLoading
            self.showLogoutConfirmation = showLogoutConfirmation
            self.showDeleteAccountConfirmation = showDeleteAccountConfirmation
            self.errorMessage = errorMessage
        }
    }

    public enum Action: Sendable, Equatable {
        // MARK: - View Actions
        case onAppear
        case profileEditTapped
        case notificationsTapped
        case notificationSettingsTapped
        case groupManagementTapped
        case moodHistoryTapped
        case notificationsToggled(Bool)
        case logoutTapped
        case logoutConfirmed
        case logoutCancelled
        case deleteAccountTapped
        case deleteAccountConfirmed
        case deleteAccountCancelled
        case dismissErrorTapped
        case termsOfServiceTapped
        case privacyPolicyTapped
        case contactUsTapped

        // MARK: - Internal Actions
        case loadUserResponse(Result<User, SettingsError>)
        case deleteAccountSucceeded
        case deleteAccountFailed(String)

        // MARK: - Delegate Actions
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case navigateToProfileEdit
            case navigateToNotifications
            case navigateToNotificationSettings
            case navigateToGroupManagement
            case navigateToMoodHistory
            case logout
            case accountDeleted
            case openURL(URL)
        }
    }

    public enum SettingsError: Error, Equatable, Sendable {
        case networkError
        case unknown(String)

        var localizedDescription: String {
            switch self {
            case .networkError:
                return "네트워크 연결을 확인해주세요."
            case .unknown(let message):
                return message
            }
        }
    }

    @Dependency(\.authRepository) var authRepository

    public init() {}

    /// 기기 언어에 맞는 법적 문서 URL 반환
    /// ko → /ko/path, ja → /ja/path, 그 외 → /en/path
    private static func legalURL(path: String) -> String {
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        let lang: String
        switch langCode {
        case "ko": lang = "ko"
        case "ja": lang = "ja"
        default:   lang = "en"
        }
        return "https://monggle.app/legal/\(lang)/\(path)"
    }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // User data is typically passed from parent, but we can load if needed
                return .none

            case .profileEditTapped:
                return .send(.delegate(.navigateToProfileEdit))

            case .notificationsTapped:
                return .send(.delegate(.navigateToNotifications))

            case .notificationSettingsTapped:
                return .send(.delegate(.navigateToNotificationSettings))

            case .groupManagementTapped:
                return .send(.delegate(.navigateToGroupManagement))

            case .moodHistoryTapped:
                return .send(.delegate(.navigateToMoodHistory))

            case .notificationsToggled(let enabled):
                state.notificationsEnabled = enabled
                UserDefaults.standard.set(enabled, forKey: "mongle_notifications_enabled")
                return .none

            case .logoutTapped:
                state.showLogoutConfirmation = true
                return .none

            case .logoutConfirmed:
                state.showLogoutConfirmation = false
                return .send(.delegate(.logout))

            case .logoutCancelled:
                state.showLogoutConfirmation = false
                return .none

            case .deleteAccountTapped:
                state.showDeleteAccountConfirmation = true
                return .none

            case .deleteAccountCancelled:
                state.showDeleteAccountConfirmation = false
                return .none

            case .deleteAccountConfirmed:
                state.showDeleteAccountConfirmation = false
                state.isLoading = true
                let providerType = state.loginProviderType
                return .run { send in
                    do {
                        // 1. 클라이언트 측 소셜 연결 해제 (Kakao unlink / Google disconnect)
                        //    Apple은 no-op (서버에서 stored refresh_token으로 revoke 처리)
                        if let providerType {
                            try await revokeClientSocialAccess(for: providerType)
                        }
                        // 2. 서버 계정 삭제
                        try await authRepository.deleteAccount()
                        await send(.deleteAccountSucceeded)
                    } catch {
                        await send(.deleteAccountFailed(error.localizedDescription))
                    }
                }

            case .deleteAccountSucceeded:
                state.isLoading = false
                return .send(.delegate(.accountDeleted))

            case .deleteAccountFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .dismissErrorTapped:
                state.errorMessage = nil
                return .none

            case .termsOfServiceTapped:
                let termsURL = Self.legalURL(path: "terms")
                if let url = URL(string: termsURL) {
                    return .send(.delegate(.openURL(url)))
                }
                return .none

            case .privacyPolicyTapped:
                let privacyURL = Self.legalURL(path: "privacy")
                if let url = URL(string: privacyURL) {
                    return .send(.delegate(.openURL(url)))
                }
                return .none

            case .contactUsTapped:
                if let url = URL(string: "mailto:support@famtree.app") {
                    return .send(.delegate(.openURL(url)))
                }
                return .none

            case .loadUserResponse(.success(let user)):
                state.currentUser = user
                return .none

            case .loadUserResponse(.failure(let error)):
                state.errorMessage = error.localizedDescription
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
