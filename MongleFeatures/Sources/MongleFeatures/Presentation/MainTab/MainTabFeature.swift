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
    @Dependency(\.errorHandler) var errorHandler

    public init() {}

    public var body: some ReducerOf<Self> {
        reducer
    }
}
