//
//  EmailSignupFeature.swift
//  MongleFeatures
//
//  이메일/비밀번호 회원가입 플로우.
//  phase: .consent → .inputForm → .verifyCode → (서버 signup) → delegate(.completed)
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct EmailSignupFeature {

    public enum Phase: Equatable, Sendable {
        /// 약관 동의 (ConsentFeature 재사용, preSignup 모드)
        case consent
        /// 이메일/비밀번호 입력
        case inputForm
        /// 이메일로 발송된 6자리 인증코드 입력
        case verifyCode
    }

    @ObservableState
    public struct State: Equatable {
        public var phase: Phase = .consent

        // Consent
        public var consent: ConsentFeature.State

        // 입력 상태
        public var email: String = ""
        public var password: String = ""
        public var emailError: String?
        public var passwordError: String?

        // 수집된 약관 버전 (consent phase 완료 후 세팅)
        public var acceptedTermsVersion: String = ""
        public var acceptedPrivacyVersion: String = ""

        // 코드 입력 단계
        public var code: String = ""
        public var codeError: String?
        public var isSendingCode: Bool = false
        public var isVerifying: Bool = false
        public var resendCooldownSec: Int = 0

        public var errorMessage: String?

        public var isEmailValid: Bool {
            // 간단한 RFC 5322 근사 검증 — 서버도 동일 규칙
            guard email.contains("@"), email.contains(".") else { return false }
            let regex = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
            return email.range(of: regex, options: .regularExpression) != nil
        }

        public var isPasswordValid: Bool {
            // 10자 이상 + 특수문자 1개 이상
            guard password.count >= 10 else { return false }
            let specialRegex = #"[^A-Za-z0-9]"#
            return password.range(of: specialRegex, options: .regularExpression) != nil
        }

        public var canProceedFromInput: Bool {
            isEmailValid && isPasswordValid && !isSendingCode
        }

        public var canSubmitCode: Bool {
            code.count == 6 && !isVerifying
        }

        public init(legalVersions: LegalVersions) {
            self.consent = ConsentFeature.State(
                requiredConsents: [.terms, .privacy],
                legalVersions: legalVersions,
                mode: .preSignup
            )
        }
    }

    public enum Action: Sendable, BindableAction {
        case binding(BindingAction<State>)

        // Consent child
        case consent(ConsentFeature.Action)

        // Input form
        case sendCodeTapped
        case sendCodeResponse(Result<Void, Error>)
        case resendTimerTick

        // Verify code
        case verifyTapped
        case signupResponse(Result<SocialLoginResult, Error>)
        case resendCodeTapped

        case dismissError
        case backTapped

        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case completed(SocialLoginResult)
            case cancelled
            case openURL(URL)
        }
    }

    @Dependency(\.authRepository) var authRepository
    @Dependency(\.continuousClock) var clock

    public init() {}

    private enum CancelID { case resendTimer }

    public var body: some Reducer<State, Action> {
        BindingReducer()

        Scope(state: \.consent, action: \.consent) {
            ConsentFeature()
        }

        Reduce { state, action in
            switch action {
            case .binding(\.email):
                // 타이핑 중에도 형식이 잘못되면 즉시 안내 라벨을 보여준다.
                // 비어있을 땐 경고를 숨긴다 (첫 진입 시 불필요한 에러 노출 방지).
                if state.email.isEmpty {
                    state.emailError = nil
                } else if !state.isEmailValid {
                    state.emailError = L10n.tr("email_auth_email_invalid")
                } else {
                    state.emailError = nil
                }
                return .none

            case .binding(\.password):
                if state.password.isEmpty {
                    state.passwordError = nil
                } else if !state.isPasswordValid {
                    state.passwordError = L10n.tr("email_auth_password_invalid")
                } else {
                    state.passwordError = nil
                }
                return .none

            case .binding(\.code):
                state.codeError = nil
                state.code = String(state.code.prefix(6))
                return .none

            case .binding:
                return .none

            // MARK: - Consent

            case .consent(.delegate(.preSignupCompleted(let terms, let privacy))):
                state.acceptedTermsVersion = terms
                state.acceptedPrivacyVersion = privacy
                state.phase = .inputForm
                return .none

            case .consent(.delegate(.cancelled)):
                return .send(.delegate(.cancelled))

            case .consent(.delegate(.openURL(let url))):
                return .send(.delegate(.openURL(url)))

            case .consent(.delegate(.completed)):
                // preSignup 모드에선 발생하지 않음 (preSignupCompleted 만 emit)
                return .none

            case .consent:
                return .none

            // MARK: - Input form → 코드 발송

            case .sendCodeTapped:
                // 유효성 검증 + 경고 노출
                if !state.isEmailValid {
                    state.emailError = L10n.tr("email_auth_email_invalid")
                }
                if !state.isPasswordValid {
                    state.passwordError = L10n.tr("email_auth_password_invalid")
                }
                guard state.canProceedFromInput,
                      state.emailError == nil,
                      state.passwordError == nil else {
                    return .none
                }
                state.isSendingCode = true
                let email = state.email
                return .run { send in
                    do {
                        try await authRepository.requestEmailSignupCode(email: email)
                        await send(.sendCodeResponse(.success(())))
                    } catch {
                        await send(.sendCodeResponse(.failure(error)))
                    }
                }

            case .sendCodeResponse(.success):
                state.isSendingCode = false
                state.phase = .verifyCode
                state.resendCooldownSec = 30
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.resendTimerTick)
                    }
                }
                .cancellable(id: CancelID.resendTimer, cancelInFlight: true)

            case .sendCodeResponse(.failure(let error)):
                state.isSendingCode = false
                state.errorMessage = (error as? AppError)?.userMessage ?? error.localizedDescription
                return .none

            case .resendTimerTick:
                if state.resendCooldownSec > 0 {
                    state.resendCooldownSec -= 1
                }
                if state.resendCooldownSec == 0 {
                    return .cancel(id: CancelID.resendTimer)
                }
                return .none

            case .resendCodeTapped:
                guard state.resendCooldownSec == 0, !state.isSendingCode else { return .none }
                state.isSendingCode = true
                let email = state.email
                return .run { send in
                    do {
                        try await authRepository.requestEmailSignupCode(email: email)
                        await send(.sendCodeResponse(.success(())))
                    } catch {
                        await send(.sendCodeResponse(.failure(error)))
                    }
                }

            // MARK: - 인증코드 검증 및 가입

            case .verifyTapped:
                guard state.canSubmitCode else { return .none }
                state.isVerifying = true
                let email = state.email
                let password = state.password
                let code = state.code
                let terms = state.acceptedTermsVersion
                let privacy = state.acceptedPrivacyVersion
                return .run { send in
                    do {
                        let result = try await authRepository.emailSignup(
                            email: email,
                            password: password,
                            code: code,
                            name: nil,
                            termsVersion: terms,
                            privacyVersion: privacy
                        )
                        await send(.signupResponse(.success(result)))
                    } catch {
                        await send(.signupResponse(.failure(error)))
                    }
                }

            case .signupResponse(.success(let result)):
                state.isVerifying = false
                return .merge(
                    .cancel(id: CancelID.resendTimer),
                    .send(.delegate(.completed(result)))
                )

            case .signupResponse(.failure(let error)):
                state.isVerifying = false
                let message = (error as? AppError)?.userMessage ?? error.localizedDescription
                state.codeError = message
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none

            case .backTapped:
                switch state.phase {
                case .consent:
                    return .send(.delegate(.cancelled))
                case .inputForm:
                    state.phase = .consent
                    return .none
                case .verifyCode:
                    state.phase = .inputForm
                    state.code = ""
                    state.codeError = nil
                    return .cancel(id: CancelID.resendTimer)
                }

            case .delegate:
                return .none
            }
        }
    }
}
