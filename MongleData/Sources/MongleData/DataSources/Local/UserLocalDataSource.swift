import Foundation
import Domain

protocol UserLocalDataSourceProtocol {
    func saveUser(_ user: User) throws
    func loadUser(byId id: UUID) throws -> User?
    func clearUser(byId id: UUID)
}

final class UserLocalDataSource: UserLocalDataSourceProtocol {
    private let storage: UserDefaultsManagerProtocol

    init(storage: UserDefaultsManagerProtocol = UserDefaultsManager()) {
        self.storage = storage
    }

    func saveUser(_ user: User) throws {
        let key = makeKey(for: user.id)
        let dto = UserMapper.toDTO(user)
        try storage.save(dto, forKey: key)
    }

    func loadUser(byId id: UUID) throws -> User? {
        let key = makeKey(for: id)
        guard let dto: UserDTO = try storage.load(forKey: key) else {
            return nil
        }
        return UserMapper.toDomain(dto)
    }

    func clearUser(byId id: UUID) {
        let key = makeKey(for: id)
        storage.remove(forKey: key)
    }

    // MARK: - Private Methods

    private func makeKey(for userId: UUID) -> String {
        return "user_\(userId.uuidString)"
    }
}
