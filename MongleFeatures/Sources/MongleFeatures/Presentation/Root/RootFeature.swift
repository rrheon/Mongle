//
//  RootFeature.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct RootFeature {

    @Dependency(\.authRepository) var authRepository
    @Dependency(\.familyRepository) var familyRepository
    @Dependency(\.questionRepository) var questionRepository
    @Dependency(\.answerRepository) var answerRepository
    @Dependency(\.userRepository) var userRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        reducer
    }
}
