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
