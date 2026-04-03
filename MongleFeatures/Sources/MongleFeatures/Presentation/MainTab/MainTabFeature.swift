//
//  MainTabFeature.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct MainTabFeature {

    @Dependency(\.questionRepository) var questionRepository
    @Dependency(\.answerRepository) var answerRepository
    @Dependency(\.userRepository) var userRepository
    @Dependency(\.notificationRepository) var notificationRepository
    @Dependency(\.errorHandler) var errorHandler
    @Dependency(\.adClient) var adClient

    public init() {}

    public var body: some ReducerOf<Self> {
        reducer
    }
}
