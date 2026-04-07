//
//  LoginFeature.swift
//  Mongle
//
//  Created by 최용헌 on 12/12/25.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct LoginFeature {
    @ObservableState
    public struct State: Equatable {
        public var isLoading: Bool = false
        public var errorMessage: String?
        public var appError: AppError?
        public var lastUsedProviderType: SocialProviderType?

        public init(
            isLoading: Bool = false,
            errorMessage: String? = nil,
            lastUsedProviderType: SocialProviderType? = nil
        ) {
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.lastUsedProviderType = lastUsedProviderType
        }
    }

    public enum Action: Sendable {
        // MARK: - View Actions

        /// 소셜 버튼 탭 (로딩 시작 등 사전 처리)
        case socialLoginTapped(SocialProviderType)

        /// View의 Provider가 자격증명 획득 성공 → Feature에 전달
        case socialCredentialReceived(any SocialLoginCredential)

        /// View의 Provider 인증 실패 (사용자 취소 제외)
        case socialLoginFailed(String)

        case browseTapped
        case dismissError

        // MARK: - Internal Actions

        case loginResponse(Result<User, AuthError>)
        case setAppError(AppError?)

        // MARK: - Delegate Actions

        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case loggedIn(User, SocialProviderType?)
            case browseAsGuest
        }
    }

    @Dependency(\.authRepository) var authRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .socialLoginTapped:
                state.errorMessage = nil
                return .none

            case .socialCredentialReceived(let credential):
                state.isLoading = true
                state.lastUsedProviderType = credential.providerType
                return .run { [credential] send in
                    do {
                        let user = try await authRepository.socialLogin(with: credential)
                        await send(.loginResponse(.success(user)))
                    } catch {
                        await send(.setAppError(AppError.from(error)))
                    }
                }

            case .socialLoginFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .loginResponse(.success(let user)):
                state.isLoading = false
                return .send(.delegate(.loggedIn(user, state.lastUsedProviderType)))

            case .loginResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .browseTapped:
                return .send(.delegate(.browseAsGuest))

            case .setAppError(let error):
                state.appError = error
                state.errorMessage = error?.userMessage
                state.isLoading = false
                return .none

            case .dismissError:
                state.errorMessage = nil
                state.appError = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
