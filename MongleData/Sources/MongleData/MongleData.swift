// The Swift Programming Language
// https://docs.swift.org/swift-book

import Domain

/// FTFeatures/앱 타겟에서 사용할 repository 팩토리 함수.
/// 구체 타입(internal)을 노출하지 않고 프로토콜 타입으로 반환합니다.

public func makeAuthRepository() -> any AuthRepositoryInterface {
    AuthRepository()
}

public func makeFamilyRepository() -> any MongleRepositoryInterface {
    FamilyRepository()
}

public func makeQuestionRepository() -> any QuestionRepositoryInterface {
    QuestionRepository()
}

public func makeAnswerRepository() -> any AnswerRepositoryInterface {
    AnswerRepository()
}

public func makeUserRepository() -> any UserRepositoryInterface {
    UserRepository()
}

public func makeDailyQuestionRepository() -> any DailyQuestionRepositoryInterface {
    DailyQuestionRepository()
}

public func makeNudgeRepository() -> any NudgeRepositoryInterface {
    NudgeRepository()
}

public func makeMoodRepository() -> any MoodRepositoryProtocol {
    MoodRepository()
}

public func makeNotificationRepository() -> any NotificationRepositoryProtocol {
    NotificationRepository()
}


