//
//  File.swift
//  MongleFeatures
//
//  Created by 최용헌 on 3/12/26.
//

import ComposableArchitecture
import Domain

extension MainTabFeature {

    @Reducer(state: .equatable, action: .equatable)
    public enum Path {

        case questionDetail(QuestionDetailFeature)
        case notification(NotificationFeature)
        case peerNudge(PeerNudgeFeature)
        case writeQuestion(WriteQuestionFeature)

    }
}
