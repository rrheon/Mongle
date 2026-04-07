//
//  ConsentFeature.swift
//  MongleFeatures
//
//  약관/개인정보 처리방침 동의 화면.
//  로그인 직후 needsConsent=true 면 RootFeature가 이 화면으로 라우팅한다.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct ConsentFeature {

    @ObservableState
    public struct State: Equatable {
        /// 어떤 동의가 필요한가 (서버 응답 기준)
        public var requiredConsents: [LegalDocType]
        /// 서버가 알려준 현재 약관 버전
        public var legalVersions: LegalVersions

        public var ageAgreed: Bool = false
        public var termsAgreed: Bool = false
        public var privacyAgreed: Bool = false

        public var isSubmitting: Bool = false
        public var errorMessage: String?

        public init(
            requiredConsents: [LegalDocType] = [.terms, .privacy],
            legalVersions: LegalVersions = LegalVersions(terms: "1.0.0", privacy: "1.0.0")
        ) {
            self.requiredConsents = requiredConsents
            self.legalVersions = legalVersions
        }

        public var allAgreed: Bool {
            ageAgreed && termsAgreed && privacyAgreed
        }

        public var canSubmit: Bool {
            allAgreed && !isSubmitting
        }
    }

    public enum Action: Sendable {
        case toggleAll(Bool)
        case toggleAge
        case toggleTerms
        case togglePrivacy
        case viewTermsTapped
        case viewPrivacyTapped
        case submitTapped
        case submitResponse(Result<Void, Error>)
        case dismissError
        case backTapped

        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case completed
            /// 동의를 거부하고 로그인 화면으로 돌아감
            case cancelled
            /// 약관 보기 — View 가 SafariView 등으로 처리
            case openURL(URL)
        }
    }

    @Dependency(\.authRepository) var authRepository

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .toggleAll(let on):
                state.ageAgreed = on
                state.termsAgreed = on
                state.privacyAgreed = on
                return .none

            case .toggleAge:
                state.ageAgreed.toggle()
                return .none

            case .toggleTerms:
                state.termsAgreed.toggle()
                return .none

            case .togglePrivacy:
                state.privacyAgreed.toggle()
                return .none

            case .viewTermsTapped:
                return .send(.delegate(.openURL(LegalLinks.termsURL)))

            case .viewPrivacyTapped:
                return .send(.delegate(.openURL(LegalLinks.privacyURL)))

            case .submitTapped:
                guard state.canSubmit else { return .none }
                state.isSubmitting = true
                let termsVersion = state.legalVersions.terms
                let privacyVersion = state.legalVersions.privacy
                return .run { send in
                    do {
                        try await authRepository.submitConsent(
                            termsVersion: termsVersion,
                            privacyVersion: privacyVersion
                        )
                        await send(.submitResponse(.success(())))
                    } catch {
                        await send(.submitResponse(.failure(error)))
                    }
                }

            case .submitResponse(.success):
                state.isSubmitting = false
                return .send(.delegate(.completed))

            case .submitResponse(.failure(let error)):
                state.isSubmitting = false
                state.errorMessage = error.localizedDescription
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
