import Foundation
import Security

protocol AuthLocalDataSourceProtocol {
    func saveCurrentUser(_ user: UserDTO) throws
    func loadCurrentUser() throws -> UserDTO?
    func clearCurrentUser()
    func saveAuthToken(_ token: String)
    func loadAuthToken() -> String?
    func clearAuthToken()
}

final class AuthLocalDataSource: AuthLocalDataSourceProtocol {
    private let storage: UserDefaultsManagerProtocol
    private static let keychainService = "app.monggle.mongle"
    private static let keychainAccount = "authToken"

    init(storage: UserDefaultsManagerProtocol = UserDefaultsManager()) {
        self.storage = storage
        migrateTokenToKeychainIfNeeded()
    }

    func saveCurrentUser(_ user: UserDTO) throws {
        try storage.save(user, forKey: UserDefaultsManager.Keys.currentUser)
    }

    func loadCurrentUser() throws -> UserDTO? {
        return try storage.load(forKey: UserDefaultsManager.Keys.currentUser)
    }

    func clearCurrentUser() {
        storage.remove(forKey: UserDefaultsManager.Keys.currentUser)
    }

    func saveAuthToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func loadAuthToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func clearAuthToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// UserDefaults에 저장된 토큰을 Keychain으로 마이그레이션
    private func migrateTokenToKeychainIfNeeded() {
        if let legacyToken = UserDefaults.standard.string(forKey: UserDefaultsManager.Keys.authToken) {
            saveAuthToken(legacyToken)
            UserDefaults.standard.removeObject(forKey: UserDefaultsManager.Keys.authToken)
        }
    }
}
