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
        public var search = SearchHistoryFeature.State()
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
        public var showCustomQuestionExistsToast = false

        // MARK: Answer Heart Popup
        public var showAnswerHeartPopup = false

        // MARK: Current User Mood Override (답변 시 선택한 mood)
        public var currentUserMoodId: String? = nil

        // MARK: Preview Mood (프로필 편집 중 색상 미리보기)
        public var previewMoodId: String? = nil

        public enum Tab: Hashable {
            case home
            case history
            case search
            case notification
            case settings
        }

        public init(
            selectedTab: Tab = .home,
            home: HomeFeature.State = HomeFeature.State(),
            history: HistoryFeature.State = HistoryFeature.State(),
            search: SearchHistoryFeature.State = SearchHistoryFeature.State(),
            notification: NotificationFeature.State = NotificationFeature.State(),
            profile: ProfileEditFeature.State = ProfileEditFeature.State()
        ) {
            self.selectedTab = selectedTab
            self.home = home
            self.history = history
            self.search = search
            self.notification = notification
            self.profile = profile
        }
    }
}
