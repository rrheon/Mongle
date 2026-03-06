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
    @ObservableState
    public struct State: Equatable {
        public var selectedTab: Tab = .home
        public var home: HomeFeature.State
        public var history: HistoryFeature.State
        public var settings: SettingsFeature.State

        public enum Tab: Hashable, Sendable {
            case home
            case history
            case settings
        }

        public init(
            selectedTab: Tab = .home,
            home: HomeFeature.State = HomeFeature.State(),
            history: HistoryFeature.State = HistoryFeature.State(),
            settings: SettingsFeature.State = SettingsFeature.State()
        ) {
            self.selectedTab = selectedTab
            self.home = home
            self.history = history
            self.settings = settings
        }
    }

    public enum Action: Sendable, Equatable {
        case selectTab(State.Tab)
        case home(HomeFeature.Action)
        case history(HistoryFeature.Action)
        case settings(SettingsFeature.Action)
        case logout

        // MARK: - Delegate Actions (RootFeature에서 처리)
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case navigateToQuestionDetail(Question)
            case requestRefresh
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }

        Scope(state: \.history, action: \.history) {
            HistoryFeature()
        }

        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Reduce { state, action in
            switch action {
            case .selectTab(let tab):
                state.selectedTab = tab
                return .none

            // MARK: - Home Delegate Actions
            case .home(.delegate(.navigateToQuestionDetail(let question))):
                return .send(.delegate(.navigateToQuestionDetail(question)))

            case .home(.delegate(.requestRefresh)):
                return .send(.delegate(.requestRefresh))

            case .home:
                return .none

            case .history:
                return .none

            // MARK: - Settings Delegate Actions
            case .settings(.delegate(.logout)):
                return .send(.logout)

            case .settings(.delegate(.accountDeleted)):
                return .send(.logout)

            case .settings(.delegate(.openURL)):
                return .none

            case .settings:
                return .none

            case .logout:
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
