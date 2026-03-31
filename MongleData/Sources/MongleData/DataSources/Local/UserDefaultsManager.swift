import Foundation

protocol UserDefaultsManagerProtocol {
    func save<T: Encodable>(_ value: T, forKey key: String) throws
    func load<T: Decodable>(forKey key: String) throws -> T?
    func remove(forKey key: String)
    func exists(forKey key: String) -> Bool
}

final class UserDefaultsManager: UserDefaultsManagerProtocol {
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    func save<T: Encodable>(_ value: T, forKey key: String) throws {
        let data = try encoder.encode(value)
        userDefaults.set(data, forKey: key)
    }

    func load<T: Decodable>(forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        return try decoder.decode(T.self, from: data)
    }

    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }

    func exists(forKey key: String) -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
}

// MARK: - Storage Keys

extension UserDefaultsManager {
    enum Keys {
        static let currentUser = "current_user"
        static let authToken = "auth_token"
        static let contacts = "contacts"
        static let messages = "messages"
        static let sentMessages = "sent_messages"
        static let receivedMessages = "received_messages"
    }
}
