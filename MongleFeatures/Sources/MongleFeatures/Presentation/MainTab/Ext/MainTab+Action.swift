//
//  File.swift
//  MongleFeatures
//
//  Created by 최용헌 on 3/12/26.
//

import ComposableArchitecture
import Domain

extension MainTabFeature {

  @CasePathable
    public enum Action: Equatable {

        // MARK: Tab
        case selectTab(State.Tab)

        // MARK: Child Feature
        case home(HomeFeature.Action)
        case history(HistoryFeature.Action)
        case notification(NotificationFeature.Action)
        case profile(ProfileEditFeature.Action)

        // MARK: Navigation
        case path(StackAction<Path.State, Path.Action>)

        // MARK: Modal
        case modal(PresentationAction<Modal.Action>)

        // MARK: Toast
        case dismissRefreshToast
        case dismissWriteToast
        case dismissNudgeToast
        case dismissEditAnswerToast
        case dismissAnswerSubmittedToast

        // MARK: Auth
        case logout

        // MARK: Delegate
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case navigateToQuestionDetail(Question)
            case requestRefresh
            case requestLogin
        }
    }
}
