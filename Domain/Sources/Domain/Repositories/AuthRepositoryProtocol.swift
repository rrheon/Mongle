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
    func socialLogin(with credential: any SocialLoginCredential) async throws -> User

    func logout() async throws

    /// 계정 완전 삭제.
    /// - Apple: 서버가 저장된 refresh_token으로 Apple 토큰 revoke 처리
    /// - Kakao/Google: 클라이언트에서 unlink/disconnect 후 이 메서드 호출
    func deleteAccount() async throws

    func getCurrentUser() async throws -> User?
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
