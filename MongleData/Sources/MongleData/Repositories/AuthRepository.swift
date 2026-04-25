//
//  AuthRepository.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation
import Security
import Domain

final class AuthRepository: AuthRepositoryInterface {
    private let apiClient: APIClientProtocol
    private let tokenStorage: TokenStorageProtocol

    init(
        apiClient: APIClientProtocol = APIClient.shared,
        tokenStorage: TokenStorageProtocol = KeychainTokenStorage()
    ) {
        self.apiClient = apiClient
        self.tokenStorage = tokenStorage
    }

    func socialLogin(with credential: any SocialLoginCredential) async throws -> SocialLoginResult {
        let endpoint = AuthEndpoint.socialLogin(
            provider: credential.providerType.rawValue,
            fields: credential.fields
        )
        let response: LoginResponseDTO = try await apiClient.request(endpoint)

        try tokenStorage.saveToken(response.token)
        if let refreshToken = response.refreshToken {
            try tokenStorage.saveRefreshToken(refreshToken)
        }

        let user = UserMapper.toDomain(response.user)
        let required = (response.requiredConsents ?? [])
            .compactMap(LegalDocType.init(rawValue:))
        // 서버가 legalVersions 를 안 내려주면 빈 문자열로 두고 needsConsent=false 로 안전하게 처리
        let versions = LegalVersions(
            terms: response.legalVersions?.terms ?? "",
            privacy: response.legalVersions?.privacy ?? ""
        )
        return SocialLoginResult(
            user: user,
            needsConsent: response.needsConsent ?? false,
            requiredConsents: required,
            legalVersions: versions
        )
    }

    func submitConsent(termsVersion: String?, privacyVersion: String?) async throws {
        let endpoint = AuthEndpoint.submitConsent(
            termsVersion: termsVersion,
            privacyVersion: privacyVersion
        )
        try await apiClient.request(endpoint)
    }

    func logout() async throws {
        // 서버 호출 성공/실패와 무관하게 로컬 토큰을 반드시 정리.
        // 네트워크 오류로 logout API 가 실패해도 사용자 의도는 "로그아웃" 이며,
        // 토큰을 남겨두면 다음 실행에서 만료 토큰으로 401 → sessionExpired 무한
        // 루프가 발생할 수 있다.
        defer {
            tokenStorage.clearToken()
            tokenStorage.clearRefreshToken()
        }
        let endpoint = AuthEndpoint.logout
        try await apiClient.request(endpoint)
    }

    func deleteAccount() async throws {
        // Apple 토큰 revoke는 서버(DELETE /auth/account)에서 처리
        // Kakao unlink / Google disconnect는 클라이언트(SocialLoginProvider)에서 먼저 호출 후 이 메서드 실행
        defer {
            tokenStorage.clearToken()
            tokenStorage.clearRefreshToken()
        }
        let endpoint = AuthEndpoint.deleteAccount
        try await apiClient.request(endpoint)
    }

    func getCurrentUser() async throws -> User? {
        let endpoint = AuthEndpoint.getCurrentUser
        let userDTO: UserDTO = try await apiClient.request(endpoint)
        return UserMapper.toDomain(userDTO)
    }

    // MARK: - Email Auth

    func requestEmailSignupCode(email: String) async throws {
        let endpoint = AuthEndpoint.emailRequestCode(email: email)
        try await apiClient.request(endpoint)
    }

    func emailSignup(
        email: String,
        password: String,
        code: String,
        name: String?,
        termsVersion: String,
        privacyVersion: String
    ) async throws -> SocialLoginResult {
        let endpoint = AuthEndpoint.emailSignup(
            email: email,
            password: password,
            code: code,
            name: name,
            termsVersion: termsVersion,
            privacyVersion: privacyVersion
        )
        let response: LoginResponseDTO = try await apiClient.request(endpoint)
        return try handleLoginResponse(response)
    }

    func emailLogin(email: String, password: String) async throws -> SocialLoginResult {
        let endpoint = AuthEndpoint.emailLogin(email: email, password: password)
        let response: LoginResponseDTO = try await apiClient.request(endpoint)
        return try handleLoginResponse(response)
    }

    // MARK: - 공통 응답 핸들러

    private func handleLoginResponse(_ response: LoginResponseDTO) throws -> SocialLoginResult {
        try tokenStorage.saveToken(response.token)
        if let refreshToken = response.refreshToken {
            try tokenStorage.saveRefreshToken(refreshToken)
        }
        let user = UserMapper.toDomain(response.user)
        let required = (response.requiredConsents ?? [])
            .compactMap(LegalDocType.init(rawValue:))
        let versions = LegalVersions(
            terms: response.legalVersions?.terms ?? "",
            privacy: response.legalVersions?.privacy ?? ""
        )
        return SocialLoginResult(
            user: user,
            needsConsent: response.needsConsent ?? false,
            requiredConsents: required,
            legalVersions: versions
        )
    }
}

// MARK: - Token Storage Protocol

protocol TokenStorageProtocol {
    func saveToken(_ token: String) throws
    func saveRefreshToken(_ token: String) throws
    func getToken() -> String?
    func getRefreshToken() -> String?
    func clearToken()
    func clearRefreshToken()
}

// MARK: - Token Storage Implementation (Keychain)

final class KeychainTokenStorage: TokenStorageProtocol {
    private let service = "com.mongle.auth"
    private let tokenKey = "auth_token"
    private let refreshTokenKey = "refresh_token"

    func saveToken(_ token: String) throws {
        try save(token, forKey: tokenKey)
    }

    func saveRefreshToken(_ token: String) throws {
        try save(token, forKey: refreshTokenKey)
    }

    func getToken() -> String? {
        load(forKey: tokenKey)
    }

    func getRefreshToken() -> String? {
        load(forKey: refreshTokenKey)
    }

    func clearToken() {
        delete(forKey: tokenKey)
    }

    func clearRefreshToken() {
        delete(forKey: refreshTokenKey)
    }

    // MARK: - Private Keychain Helpers

    private func save(_ value: String, forKey key: String) throws {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let updateAttributes: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.saveFailed(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.saveFailed(updateStatus)
        }
    }

    private func load(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
}
