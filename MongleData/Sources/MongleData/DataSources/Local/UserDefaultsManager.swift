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

// MARK: - User-scoped Cleanup

/// 로그아웃 / 세션 만료 / 회원 탈퇴 시 호출. `mongle_*`, `mongle.*`, `notification.*`,
/// `mongle_notifications_enabled` 같은 사용자 단위 키를 일괄 정리해 다른 계정 로그인 시
/// 이전 사용자의 그룹별 팝업/리마인더 시간/뱃지 상태가 새 사용자에게 잘못 적용되는
/// 문제를 방지한다. 단, 디바이스 단위로 보존해야 하는 키는 제외:
///   - `mongle.hasSeenOnboarding` — 디바이스 첫 사용자만 온보딩 보여줌
///   - `mongle.installSentinel` — 첫 실행 마커 (Keychain 잔존 정리용)
public enum UserDefaultsCleanup {
    private static let preserveKeys: Set<String> = [
        "mongle.hasSeenOnboarding",
        "mongle.installSentinel",
    ]

    private static let userScopedPrefixes = [
        "mongle.",
        "mongle_",
        "notification.",
    ]

    public static func clearUserScoped(_ defaults: UserDefaults = .standard) {
        let dict = defaults.dictionaryRepresentation()
        for key in dict.keys {
            if preserveKeys.contains(key) { continue }
            for prefix in userScopedPrefixes {
                if key.hasPrefix(prefix) {
                    defaults.removeObject(forKey: key)
                    break
                }
            }
        }
    }
}
