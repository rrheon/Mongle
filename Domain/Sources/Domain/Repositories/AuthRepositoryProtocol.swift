//
//  AuthRepositoryProtocol.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation

public protocol AuthRepositoryInterface: Sendable {
    /// 소셜 로그인 단일 진입점.
    /// 새로운 제공자 추가 시 이 프로토콜은 수정하지 않고
    /// SocialLoginCredential을 구현하는 타입만 추가합니다.
    /// 응답에 약관 동의 필요 여부(needsConsent)가 포함되며, true 면
    /// 클라이언트는 동의 화면으로 라우팅 후 submitConsent 를 호출해야 한다.
    func socialLogin(with credential: any SocialLoginCredential) async throws -> SocialLoginResult

    func logout() async throws

    /// 계정 완전 삭제.
    /// - Apple: 서버가 저장된 refresh_token으로 Apple 토큰 revoke 처리
    /// - Kakao/Google: 클라이언트에서 unlink/disconnect 후 이 메서드 호출
    func deleteAccount() async throws

    /// 현재 로그인 사용자 조회.
    /// - Parameter grantDailyHeart: true 인 호출만 서버에서 활성 그룹 데일리
    ///   하트(+1) 지급을 동기 시도하고 응답 user.heartGrantedToday 에 결과를
    ///   실어준다. RootFeature 의 onAppear / refreshHomeData 에서만 켜고,
    ///   QuestionDetail/ProfileEdit 같은 hearts sync 호출은 default false 로
    ///   호출해 거짓 grant 와 팝업 누락을 방지한다 (MG-77/MG-80).
    func getCurrentUser(grantDailyHeart: Bool) async throws -> User?

    /// 약관/개인정보 동의 저장.
    /// - Parameters:
    ///   - termsVersion: nil 이면 약관 동의 미갱신
    ///   - privacyVersion: nil 이면 개인정보 동의 미갱신
    func submitConsent(termsVersion: String?, privacyVersion: String?) async throws

    // MARK: - Email Auth (이메일/비밀번호 회원가입)

    /// 이메일 회원가입 6자리 인증코드 발송. 이미 가입된 이메일이면 에러.
    func requestEmailSignupCode(email: String) async throws

    /// 이메일 회원가입 완료. 인증코드 + 약관 버전 검증 후 유저 생성.
    /// 성공 시 토큰이 저장되며 결과는 소셜 로그인과 동일한 형식으로 반환된다.
    func emailSignup(
        email: String,
        password: String,
        code: String,
        name: String?,
        termsVersion: String,
        privacyVersion: String
    ) async throws -> SocialLoginResult

    /// 이메일/비밀번호 로그인 (기존 회원)
    func emailLogin(email: String, password: String) async throws -> SocialLoginResult
}

/// hearts sync 등 "세션 시작이 아닌" 부수 경로용 편의 메서드.
/// Swift 프로토콜 요구사항은 호출 사이트에 default 값을 전파하지 않으므로,
/// 명시적 opt-in 이 필요 없는 호출처가 매번 `grantDailyHeart: false` 를 적지
/// 않도록 무인자 오버로드를 제공한다 (QuestionDetail/ProfileEdit 등).
public extension AuthRepositoryInterface {
    func getCurrentUser() async throws -> User? {
        try await getCurrentUser(grantDailyHeart: false)
    }
}

public enum AuthError: Error, Equatable, Sendable {
    case networkError
    case userNotFound
    case socialLoginFailed(SocialProviderType)
    case accountDeletionFailed
    case unknown(String)

    public var localizedDescription: String {
        switch self {
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .userNotFound:
            return "사용자를 찾을 수 없습니다."
        case .socialLoginFailed(let provider):
            return "\(provider.rawValue) 로그인에 실패했습니다."
        case .accountDeletionFailed:
            return "계정 삭제에 실패했습니다. 다시 시도해주세요."
        case .unknown(let message):
            return message
        }
    }
}
