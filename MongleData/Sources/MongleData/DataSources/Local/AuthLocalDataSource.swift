import Foundation

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

    init(storage: UserDefaultsManagerProtocol = UserDefaultsManager()) {
        self.storage = storage
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
        UserDefaults.standard.set(token, forKey: UserDefaultsManager.Keys.authToken)
    }

    func loadAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: UserDefaultsManager.Keys.authToken)
    }

    func clearAuthToken() {
        storage.remove(forKey: UserDefaultsManager.Keys.authToken)
    }
}
