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

// MARK: - 첫 실행 / 로그아웃 시 정리 헬퍼

/// iOS 는 앱 uninstall 후 재설치 시 Keychain 항목을 자동으로 지우지 않는다.
/// 첫 실행 마커가 없는 새 install 에서 호출하면 이전 사용자의 토큰을 명시적으로 폐기한다.
/// 앱 entry (MongleApp.init) 에서 호출.
public func clearTokensOnFreshInstall() {
    let storage = KeychainTokenStorage()
    storage.clearToken()
    storage.clearRefreshToken()
}

/// 사용자 단위 UserDefaults 키를 일괄 정리. 로그아웃 / 세션 만료 / 회원 탈퇴 시 호출.
public func clearUserScopedDefaults() {
    UserDefaultsCleanup.clearUserScoped()
}


