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
        apiClient: APIClientProtocol = APIClient(),
        tokenStorage: TokenStorageProtocol = KeychainTokenStorage()
    ) {
        self.apiClient = apiClient
        self.tokenStorage = tokenStorage
    }

    func socialLogin(with credential: any SocialLoginCredential) async throws -> User {
        let endpoint = AuthEndpoint.socialLogin(
            provider: credential.providerType.rawValue,
            fields: credential.fields
        )
        let response: LoginResponseDTO = try await apiClient.request(endpoint)

        try tokenStorage.saveToken(response.token)
        if let refreshToken = response.refreshToken {
            try tokenStorage.saveRefreshToken(refreshToken)
        }

        return UserMapper.toDomain(response.user)
    }

    func logout() async throws {
        let endpoint = AuthEndpoint.logout
        try await apiClient.request(endpoint)

        // 로컬 토큰 삭제
        tokenStorage.clearToken()
        tokenStorage.clearRefreshToken()
    }

    func deleteAccount() async throws {
        // Apple 토큰 revoke는 서버(DELETE /auth/account)에서 처리
        // Kakao unlink / Google disconnect는 클라이언트(SocialLoginProvider)에서 먼저 호출 후 이 메서드 실행
        let endpoint = AuthEndpoint.deleteAccount
        try await apiClient.request(endpoint)

        // 로컬 토큰 삭제
        tokenStorage.clearToken()
        tokenStorage.clearRefreshToken()
    }

    func getCurrentUser() async throws -> User? {
        let endpoint = AuthEndpoint.getCurrentUser
        let userDTO: UserDTO = try await apiClient.request(endpoint)
        return UserMapper.toDomain(userDTO)
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
