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
}
