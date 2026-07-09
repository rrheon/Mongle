import Foundation
import Domain

// MARK: - Mock NotificationRepository

final class MockNotificationRepository: NotificationRepositoryProtocol, @unchecked Sendable {
    var getNotificationsResult: [Domain.Notification] = []
    var getNotificationsError: Error?
    var markAsReadResult: Domain.Notification?
    var markAsReadError: Error?
    var markAllAsReadResult: Int = 0
    var deleteError: Error?
    var deleteAllResult: Int = 0

    func getNotifications(limit: Int, familyId: UUID?) async throws -> [Domain.Notification] {
        if let error = getNotificationsError { throw error }
        return getNotificationsResult
    }

    func getUnreadCount() async throws -> Int {
        getNotificationsResult.filter { !$0.isRead }.count
    }

    func markAsRead(id: UUID) async throws -> Domain.Notification {
        if let error = markAsReadError { throw error }
        return markAsReadResult!
    }

    func markAllAsRead(familyId: UUID?) async throws -> Int {
        markAllAsReadResult
    }

    func delete(id: UUID) async throws {
        if let error = deleteError { throw error }
    }

    func deleteAll(familyId: UUID?) async throws -> Int {
        deleteAllResult
    }
}

// MARK: - Mock ShopRepository

final class MockShopRepository: ShopRepositoryInterface, @unchecked Sendable {
    var catalogResult: [ShopItem] = []
    var catalogError: Error?
    var inventoryResult: ShopInventory = ShopInventory()
    var inventoryError: Error?
    /// purchase 후 반환할 잔여 하트.
    var purchaseHeartsRemaining: Int = 0
    var purchaseError: Error?
    /// equipDecoration 이 반환할 장착 id. nil 이면 요청 itemId 를 그대로 반환.
    var equipResult: String?
    var equipError: Error?

    func getCatalog() async throws -> [ShopItem] {
        if let catalogError { throw catalogError }
        return catalogResult
    }

    func getInventory() async throws -> ShopInventory {
        if let inventoryError { throw inventoryError }
        return inventoryResult
    }

    func purchase(itemId: String) async throws -> Int {
        if let purchaseError { throw purchaseError }
        return purchaseHeartsRemaining
    }

    func equipDecoration(itemId: String?) async throws -> String? {
        if let equipError { throw equipError }
        if let equipResult { return equipResult }
        return itemId
    }

    /// applyBackground 가 반환할 인벤토리. nil 이면 inventoryResult 에 itemId 를 적용해 반환.
    var applyBackgroundResult: ShopInventory?
    var applyBackgroundError: Error?

    func applyBackground(itemId: String) async throws -> ShopInventory {
        if let applyBackgroundError { throw applyBackgroundError }
        if let applyBackgroundResult { return applyBackgroundResult }
        var inv = inventoryResult
        inv.ownedBackgroundIds.insert(itemId)
        inv.appliedBackgroundId = itemId
        return inv
    }
}

// MARK: - Factory Helpers

enum NotificationFactory {
    static func make(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        familyId: UUID? = nil,
        type: NotificationType = .newQuestion,
        title: String = "알림 제목",
        body: String = "알림 내용",
        isRead: Bool = false,
        createdAt: Date = Date()
    ) -> Domain.Notification {
        Domain.Notification(
            id: id,
            userId: userId,
            familyId: familyId,
            type: type,
            title: title,
            body: body,
            isRead: isRead,
            createdAt: createdAt
        )
    }
}

enum GroupFactory {
    static func make(
        id: UUID = UUID(),
        name: String = "우리 가족",
        memberIds: [UUID] = [],
        memberMoodIds: [String] = [],
        createdBy: UUID = UUID(),
        createdAt: Date = Date(),
        inviteCode: String = "ABCDEFGH"
    ) -> MongleGroup {
        MongleGroup(
            id: id,
            name: name,
            memberIds: memberIds,
            createdBy: createdBy,
            createdAt: createdAt,
            inviteCode: inviteCode,
            memberMoodIds: memberMoodIds
        )
    }
}

// MARK: - 스로잉 스텁 리포지토리 (RootFeature 테스트용)
//
// RootFeature 의 refreshHomeData 이펙트는 아래 리포지토리들을 모두 접근한다.
// 상태 전이(팝업/복구 경로)만 검증하는 테스트에서는 네트워크 결과가 중요하지
// 않으므로, 모든 메서드가 URLError 를 던지는 스텁을 주입해
// "@Dependency has no test implementation" 실패와 실호출을 동시에 차단한다.

private let stubError = URLError(.notConnectedToInternet)

final class StubAuthRepository: AuthRepositoryInterface, @unchecked Sendable {
    /// getCurrentUser(grantDailyHeart:) 가 반환할 유저. nil 이면 nil 반환(throw 아님).
    var currentUser: User?
    func socialLogin(with credential: any SocialLoginCredential) async throws -> SocialLoginResult { throw stubError }
    func logout() async throws { throw stubError }
    func deleteAccount() async throws { throw stubError }
    func getCurrentUser(grantDailyHeart: Bool) async throws -> User? { currentUser }
    func submitConsent(termsVersion: String?, privacyVersion: String?) async throws { throw stubError }
    func requestEmailSignupCode(email: String) async throws { throw stubError }
    func emailSignup(email: String, password: String, code: String, name: String?,
                     termsVersion: String, privacyVersion: String) async throws -> SocialLoginResult { throw stubError }
    func emailLogin(email: String, password: String) async throws -> SocialLoginResult { throw stubError }
}

final class StubFamilyRepository: MongleRepositoryInterface, @unchecked Sendable {
    func create(_ family: MongleGroup, nickname: String?, colorId: String?) async throws -> MongleGroup { throw stubError }
    func get(id: UUID) async throws -> MongleGroup { throw stubError }
    func findByInviteCode(_ inviteCode: String) async throws -> MongleGroup? { throw stubError }
    func getFamiliesByUserId(_ userId: UUID) async throws -> [MongleGroup] { throw stubError }
    func update(_ family: MongleGroup) async throws -> MongleGroup { throw stubError }
    func delete(id: UUID) async throws { throw stubError }
    func addMember(_ member: Member) async throws { throw stubError }
    func removeMember(userId: UUID, familyId: UUID) async throws { throw stubError }
    func getMembers(familyId: UUID) async throws -> [Member] { throw stubError }
    func isMember(userId: UUID, familyId: UUID) async throws -> Bool { throw stubError }
    func getMyFamily() async throws -> (MongleGroup, [User])? { throw stubError }
    func joinFamily(inviteCode: String, nickname: String?, colorId: String?) async throws -> MongleGroup { throw stubError }
    func kickMember(memberId: UUID) async throws { throw stubError }
    func getMyFamilies() async throws -> [MongleGroup] { throw stubError }
    func selectFamily(familyId: UUID) async throws -> MongleGroup { throw stubError }
    func leaveFamily() async throws { throw stubError }
    func transferCreator(newCreatorId: UUID) async throws { throw stubError }
    func getGroupWithMembers(id: UUID) async throws -> (MongleGroup, [User]) { throw stubError }
}

final class StubQuestionRepository: QuestionRepositoryInterface, @unchecked Sendable {
    func create(_ question: Question) async throws -> Question { throw stubError }
    func get(id: UUID) async throws -> Question { throw stubError }
    func getByOrder(_ order: Int) async throws -> Question? { throw stubError }
    func getByCategory(_ category: QuestionCategory) async throws -> [Question] { throw stubError }
    func getAll() async throws -> [Question] { throw stubError }
    func update(_ question: Question) async throws -> Question { throw stubError }
    func delete(id: UUID) async throws { throw stubError }
    func getTodayQuestion() async throws -> Question? { throw stubError }
    func getTodayQuestionDetailed() async throws -> TodayQuestionDetails? { throw stubError }
    func skipTodayQuestion() async throws -> Int { throw stubError }
    func getHistory(page: Int, limit: Int) async throws -> [HistoryQuestion] { throw stubError }
    func createCustomQuestion(content: String) async throws -> (question: Question, heartsRemaining: Int) { throw stubError }
}

final class StubAnswerRepository: AnswerRepositoryInterface, @unchecked Sendable {
    func create(_ answer: Answer, dailyQuestionId: String?, moodId: String?) async throws -> Answer { throw stubError }
    func get(id: UUID) async throws -> Answer { throw stubError }
    func getByDailyQuestion(dailyQuestionId: UUID) async throws -> [Answer] { throw stubError }
    func getByUserAndDailyQuestion(dailyQuestionId: UUID, userId: UUID) async throws -> Answer? { throw stubError }
    func hasUserAnswered(dailyQuestionId: UUID, userId: UUID) async throws -> Bool { throw stubError }
    func getByUser(userId: UUID) async throws -> [Answer] { throw stubError }
    func update(_ answer: Answer, moodId: String?) async throws -> Answer { throw stubError }
    func delete(id: UUID) async throws { throw stubError }
}

final class StubUserRepository: UserRepositoryInterface, @unchecked Sendable {
    func get(id: UUID) async throws -> User { throw stubError }
    func update(_ user: User) async throws -> User { throw stubError }
    func updateName(_ name: String) async throws { throw stubError }
    func getMyStreak() async throws -> Int { throw stubError }
    func registerDeviceToken(token: String, environment: String) async throws { throw stubError }
    func grantAdHearts(amount: Int) async throws -> Int { throw stubError }
    func getNotificationPreferences() async throws -> NotificationPreferences { throw stubError }
    func updateNotificationPreferences(_ params: [String: Any]) async throws -> NotificationPreferences { throw stubError }
}
