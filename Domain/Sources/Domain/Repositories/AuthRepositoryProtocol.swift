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

    func getCurrentUser() async throws -> User?

    /// 약관/개인정보 동의 저장.
    /// - Parameters:
    ///   - termsVersion: nil 이면 약관 동의 미갱신
    ///   - privacyVersion: nil 이면 개인정보 동의 미갱신
    func submitConsent(termsVersion: String?, privacyVersion: String?) async throws
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
