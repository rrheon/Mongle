//
//  EmailLoginFeature.swift
//  MongleFeatures
//
//  이메일 + 비밀번호로 기존 계정에 로그인하는 플로우.
//  회원가입(EmailSignupFeature)과 달리 약관/인증코드 단계가 없고 단일 입력 폼이다.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct EmailLoginFeature {

    @ObservableState
    public struct State: Equatable {
        public var email: String = ""
        public var password: String = ""
        public var emailError: String?
        public var passwordError: String?
        public var isSubmitting: Bool = false
        public var errorMessage: String?

        public var isEmailValid: Bool {
            guard email.contains("@"), email.contains(".") else { return false }
            let regex = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
            return email.range(of: regex, options: .regularExpression) != nil
        }

        public var isPasswordValid: Bool {
            !password.isEmpty
        }

        public var canSubmit: Bool {
            isEmailValid && isPasswordValid && !isSubmitting
        }

        public init() {}
    }

    public enum Action: Sendable, BindableAction {
        case binding(BindingAction<State>)

        case submitTapped
        case loginResponse(Result<SocialLoginResult, Error>)

        case dismissError
        case backTapped

        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case completed(SocialLoginResult)
            case cancelled
        }
    }

    @Dependency(\.authRepository) var authRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.email):
                // 타이핑 중에도 형식이 잘못되면 즉시 안내 라벨을 보여준다.
                if state.email.isEmpty {
                    state.emailError = nil
                } else if !state.isEmailValid {
                    state.emailError = L10n.tr("email_auth_email_invalid")
                } else {
                    state.emailError = nil
                }
                return .none

            case .binding(\.password):
                // 로그인에서는 형식 검증이 필요 없다 (가입 시점의 규칙을 기억 못할 수 있음).
                // 빈 값만 체크.
                state.passwordError = nil
                return .none

            case .binding:
                return .none

            case .submitTapped:
                guard state.canSubmit else { return .none }
                state.isSubmitting = true
                state.errorMessage = nil
                let email = state.email
                let password = state.password
                return .run { send in
                    do {
                        let result = try await authRepository.emailLogin(email: email, password: password)
                        await send(.loginResponse(.success(result)))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                    }
                }

            case .loginResponse(.success(let result)):
                state.isSubmitting = false
                return .send(.delegate(.completed(result)))

            case .loginResponse(.failure(let error)):
                state.isSubmitting = false
                state.errorMessage = (error as? AppError)?.userMessage ?? error.localizedDescription
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .backTapped:
                return .send(.delegate(.cancelled))

            case .delegate:
                return .none
            }
        }
    }
}
