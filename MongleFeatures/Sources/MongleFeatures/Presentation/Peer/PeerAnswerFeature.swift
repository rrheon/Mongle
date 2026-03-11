import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
public struct PeerAnswerFeature {
    @ObservableState
    public struct State: Equatable {
        public var memberName: String
        public var monggleColor: Color
        public var questionText: String
        public var peerAnswer: String
        public var myAnswer: String
        public var peerAnswerTime: String
        public var myAnswerTime: String

        public init(
            memberName: String,
            monggleColor: Color = MongleColor.monggleYellow,
            questionText: String,
            peerAnswer: String,
            myAnswer: String,
            peerAnswerTime: String = "오늘 오전 9:23",
            myAnswerTime: String = "오늘 오전 8:41"
        ) {
            self.memberName = memberName
            self.monggleColor = monggleColor
            self.questionText = questionText
            self.peerAnswer = peerAnswer
            self.myAnswer = myAnswer
            self.peerAnswerTime = peerAnswerTime
            self.myAnswerTime = myAnswerTime
        }
    }

    public enum Action: Sendable, Equatable {
        case closeTapped
        case reactTapped
        case commentTapped
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { _, action in
            switch action {
            case .closeTapped:
                return .send(.delegate(.close))
            case .reactTapped, .commentTapped, .delegate:
                return .none
            }
        }
    }
}
