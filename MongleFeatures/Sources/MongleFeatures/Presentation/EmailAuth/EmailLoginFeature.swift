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
        /// 잘못된 이메일/비밀번호 입력 시 사용자에게 안내하는 팝업 상태.
        /// 기존엔 alert 에 "MongleData.APIError 오류 7" 같은 raw 문자열이 노출되던 것을
        /// 사용자 친화 팝업으로 분리.
        public var showInvalidCredentialsAlert: Bool = false

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
        case dismissInvalidCredentialsAlert
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
                // 모든 raw error → AppError 로 변환해 사용자 노출 메시지를 일관화.
                // (이전엔 raw APIError 가 cast 실패해 localizedDescription 으로 넘어가
                // "MongleData.APIError 오류 7" 같은 Foundation 자동 메시지 노출됐음)
                let appError = error as? AppError ?? AppError.from(error)
                // 이메일 로그인 컨텍스트의 401 = 잘못된 자격증명. 다른 화면의 "세션 만료"
                // 의미와 분리해 명시적인 안내 팝업으로 처리.
                if appError == .unauthorized {
                    state.showInvalidCredentialsAlert = true
                } else {
                    state.errorMessage = appError.userMessage
                }
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .dismissInvalidCredentialsAlert:
                state.showInvalidCredentialsAlert = false
                return .none

            case .backTapped:
                return .send(.delegate(.cancelled))

            case .delegate:
                return .none
            }
        }
    }
}
