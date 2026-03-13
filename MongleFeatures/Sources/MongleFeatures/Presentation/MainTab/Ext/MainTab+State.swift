//
//  File.swift
//  MongleFeatures
//
//  Created by 최용헌 on 3/12/26.
//

import ComposableArchitecture
import Domain

extension MainTabFeature {

    @ObservableState
    public struct State: Equatable {

        // MARK: Tab
        public var selectedTab: Tab = .home

        // MARK: Push Navigation
        public var path = StackState<Path.State>()

        // MARK: Child Features
        public var home = HomeFeature.State()
        public var history = HistoryFeature.State()
        public var notification = NotificationFeature.State()
        public var profile = ProfileEditFeature.State()

        // MARK: Modals
        @Presents public var modal: Modal.State?

        // MARK: Toast
        public var showRefreshToast = false
        public var showWriteToast = false
        public var showNudgeToast = false
        public var showEditAnswerToast = false
        public var showAnswerSubmittedToast = false

        public enum Tab: Hashable {
            case home
            case history
            case notification
            case settings
        }

        public init(
            selectedTab: Tab = .home,
            home: HomeFeature.State = HomeFeature.State(),
            history: HistoryFeature.State = HistoryFeature.State(),
            notification: NotificationFeature.State = NotificationFeature.State(),
            profile: ProfileEditFeature.State = ProfileEditFeature.State()
        ) {
            self.selectedTab = selectedTab
            self.home = home
            self.history = history
            self.notification = notification
            self.profile = profile
        }
    }
}
