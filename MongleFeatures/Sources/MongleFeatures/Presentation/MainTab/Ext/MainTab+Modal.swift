//
//  File.swift
//  MongleFeatures
//
//  Created by 최용헌 on 3/12/26.
//

import ComposableArchitecture

extension MainTabFeature {

    @Reducer
    public struct Modal {

        public enum State: Equatable {

            case peerAnswer(PeerAnswerFeature.State)
            case answerFirstPopup(AnswerFirstPopupFeature.State)
            case peerNudge(PeerNudgeFeature.State)
            case supportScreen(SupportScreenFeature.State)
            case questionSheet(QuestionSheetFeature.State)
            case heartCostPopup(HeartCostPopupFeature.State)
            case writeQuestion(WriteQuestionFeature.State)

        }

        public enum Action: Equatable {

            case peerAnswer(PeerAnswerFeature.Action)
            case answerFirstPopup(AnswerFirstPopupFeature.Action)
            case peerNudge(PeerNudgeFeature.Action)
            case supportScreen(SupportScreenFeature.Action)
            case questionSheet(QuestionSheetFeature.Action)
            case heartCostPopup(HeartCostPopupFeature.Action)
            case writeQuestion(WriteQuestionFeature.Action)

        }

        public var body: some Reducer<State, Action> {

            Scope(state: \.peerAnswer, action: \.peerAnswer) {
                PeerAnswerFeature()
            }

            Scope(state: \.answerFirstPopup, action: \.answerFirstPopup) {
                AnswerFirstPopupFeature()
            }

            Scope(state: \.peerNudge, action: \.peerNudge) {
                PeerNudgeFeature()
            }

            Scope(state: \.supportScreen, action: \.supportScreen) {
                SupportScreenFeature()
            }

            Scope(state: \.questionSheet, action: \.questionSheet) {
                QuestionSheetFeature()
            }

            Scope(state: \.heartCostPopup, action: \.heartCostPopup) {
                HeartCostPopupFeature()
            }

            Scope(state: \.writeQuestion, action: \.writeQuestion) {
                WriteQuestionFeature()
            }
        }
    }
}
