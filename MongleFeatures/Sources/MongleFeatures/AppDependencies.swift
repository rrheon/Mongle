//
//  AppDependencies.swift
//  FTFeatures
//
//  TCA @Dependency 등록 — 각 Feature에서 @Dependency(\.authRepository) 등으로 주입받습니다.
//

import ComposableArchitecture
import Domain
import MongleData

// MARK: - AuthRepository

private enum AuthRepositoryKey: DependencyKey {
    static let liveValue: any AuthRepositoryInterface = makeAuthRepository()
}

extension DependencyValues {
    public var authRepository: any AuthRepositoryInterface {
        get { self[AuthRepositoryKey.self] }
        set { self[AuthRepositoryKey.self] = newValue }
    }
}

// MARK: - FamilyRepository

private enum FamilyRepositoryKey: DependencyKey {
    static let liveValue: any MongleRepositoryInterface = makeFamilyRepository()
}

extension DependencyValues {
    public var familyRepository: any MongleRepositoryInterface {
        get { self[FamilyRepositoryKey.self] }
        set { self[FamilyRepositoryKey.self] = newValue }
    }
}

// MARK: - QuestionRepository

private enum QuestionRepositoryKey: DependencyKey {
    static let liveValue: any QuestionRepositoryInterface = makeQuestionRepository()
}

extension DependencyValues {
    public var questionRepository: any QuestionRepositoryInterface {
        get { self[QuestionRepositoryKey.self] }
        set { self[QuestionRepositoryKey.self] = newValue }
    }
}

// MARK: - AnswerRepository

private enum AnswerRepositoryKey: DependencyKey {
    static let liveValue: any AnswerRepositoryInterface = makeAnswerRepository()
}

extension DependencyValues {
    public var answerRepository: any AnswerRepositoryInterface {
        get { self[AnswerRepositoryKey.self] }
        set { self[AnswerRepositoryKey.self] = newValue }
    }
}

// MARK: - UserRepository

private enum UserRepositoryKey: DependencyKey {
    static let liveValue: any UserRepositoryInterface = makeUserRepository()
}

extension DependencyValues {
    public var userRepository: any UserRepositoryInterface {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }
}

// MARK: - DailyQuestionRepository

private enum DailyQuestionRepositoryKey: DependencyKey {
    static let liveValue: any DailyQuestionRepositoryInterface = makeDailyQuestionRepository()
}

extension DependencyValues {
    public var dailyQuestionRepository: any DailyQuestionRepositoryInterface {
        get { self[DailyQuestionRepositoryKey.self] }
        set { self[DailyQuestionRepositoryKey.self] = newValue }
    }
}

// MARK: - NudgeRepository

private enum NudgeRepositoryKey: DependencyKey {
    static let liveValue: any NudgeRepositoryInterface = makeNudgeRepository()
}

extension DependencyValues {
    public var nudgeRepository: any NudgeRepositoryInterface {
        get { self[NudgeRepositoryKey.self] }
        set { self[NudgeRepositoryKey.self] = newValue }
    }
}

// MARK: - MoodRepository

private enum MoodRepositoryKey: DependencyKey {
    static let liveValue: any MoodRepositoryProtocol = makeMoodRepository()
}

extension DependencyValues {
    public var moodRepository: any MoodRepositoryProtocol {
        get { self[MoodRepositoryKey.self] }
        set { self[MoodRepositoryKey.self] = newValue }
    }
}

// MARK: - NotificationRepository

private enum NotificationRepositoryKey: DependencyKey {
    static let liveValue: any NotificationRepositoryProtocol = makeNotificationRepository()
}

extension DependencyValues {
    public var notificationRepository: any NotificationRepositoryProtocol {
        get { self[NotificationRepositoryKey.self] }
        set { self[NotificationRepositoryKey.self] = newValue }
    }
}

// NOTE: ErrorHandler는 ErrorHandlerDependency.swift에서 DependencyKey를 직접 구현합니다.
// @Dependency(\.errorHandler) 로 사용하세요.
