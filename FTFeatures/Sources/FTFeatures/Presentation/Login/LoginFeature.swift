//
//  LoginFeature.swift
//  FamTree
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

        public init() {}
    }

    public enum Action: Sendable {
        // MARK: - View Actions

        /// 소셜 버튼 탭 (로딩 시작 등 사전 처리)
        case socialLoginTapped(SocialProviderType)

        /// View의 Provider가 자격증명 획득 성공 → Feature에 전달
        case socialCredentialReceived(any SocialLoginCredential)

        /// View의 Provider 인증 실패 (사용자 취소 제외)
        case socialLoginFailed(String)

        case emailLoginTapped
        case emailSignupTapped
        case dismissError

        // MARK: - Internal Actions

        case loginResponse(Result<User, AuthError>)

        // MARK: - Delegate Actions

        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case loggedIn(User)
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .socialLoginTapped:
                state.errorMessage = nil
                return .none

            case .socialCredentialReceived(let credential):
                state.isLoading = true
                return .run { send in
                    // TODO: FastAPI 연동 후 아래 mock을 실제 호출로 교체
                    // let user = try await authRepository.socialLogin(with: credential)
                    try await Task.sleep(nanoseconds: 800_000_000)
                    let mockUser = User(
                        id: UUID(),
                        email: credential.fields["email"] ?? "\(credential.providerType.rawValue)@example.com",
                        name: credential.fields["name"] ?? "\(credential.providerType.rawValue) 사용자",
                        profileImageURL: nil,
                        role: .other,
                        createdAt: .now
                    )
                    await send(.loginResponse(.success(mockUser)))
                }

            case .socialLoginFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .loginResponse(.success(let user)):
                state.isLoading = false
                return .send(.delegate(.loggedIn(user)))

            case .loginResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .emailLoginTapped:
                return .none

            case .emailSignupTapped:
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
