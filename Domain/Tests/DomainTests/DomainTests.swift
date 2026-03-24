import XCTest
@testable import Domain

final class DomainTests: XCTestCase {

    func testUserCreation() {
        let user = User(
            id: UUID(),
            email: "test@example.com",
            name: "테스트",
            profileImageURL: nil,
            role: .father,
            createdAt: Date()
        )

        XCTAssertEqual(user.name, "테스트")
        XCTAssertEqual(user.role, .father)
    }

    func testQuestionCategory() {
        let question = Question(
            id: UUID(),
            content: "오늘 가장 감사한 일은?",
            category: .gratitude,
            order: 1
        )

        XCTAssertEqual(question.category, .gratitude)
    }

    // MARK: - Notification

    func testNotificationCreation() {
        let id = UUID()
        let userId = UUID()
        let familyId = UUID()
        let now = Date()

        let notification = Domain.Notification(
            id: id,
            userId: userId,
            familyId: familyId,
            type: .memberAnswered,
            title: "가족이 답변했어요",
            body: "아빠가 오늘의 질문에 답변했습니다.",
            isRead: false,
            createdAt: now
        )

        XCTAssertEqual(notification.id, id)
        XCTAssertEqual(notification.userId, userId)
        XCTAssertEqual(notification.familyId, familyId)
        XCTAssertEqual(notification.type, Domain.NotificationType.memberAnswered)
        XCTAssertFalse(notification.isRead)
        XCTAssertEqual(notification.createdAt, now)
    }

    func testNotificationWithoutFamilyId() {
        let notification = Domain.Notification(
            id: UUID(),
            userId: UUID(),
            type: .badgeEarned,
            title: "배지 획득",
            body: "새 배지를 얻었습니다.",
            isRead: true,
            createdAt: Date()
        )

        XCTAssertNil(notification.familyId)
        XCTAssertTrue(notification.isRead)
    }

    func testNotificationEquality() {
        let id = UUID()
        let userId = UUID()
        let date = Date()

        let notif1 = Domain.Notification(
            id: id, userId: userId, type: .newQuestion,
            title: "제목", body: "내용", isRead: false, createdAt: date
        )
        let notif2 = Domain.Notification(
            id: id, userId: userId, type: .newQuestion,
            title: "제목", body: "내용", isRead: false, createdAt: date
        )

        XCTAssertEqual(notif1, notif2)
    }

    func testNotificationTypes() {
        let types: [NotificationType] = [.newQuestion, .memberAnswered, .allAnswered, .answerRequest, .badgeEarned]
        XCTAssertEqual(types.count, 5)
        XCTAssertTrue(types.contains(.memberAnswered))
        XCTAssertTrue(types.contains(.allAnswered))
    }
}
