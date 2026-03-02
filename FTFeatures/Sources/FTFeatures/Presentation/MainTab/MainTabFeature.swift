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
        public var tree: TreeFeature.State
        public var family: FamilyFeature.State
        public var settings: SettingsFeature.State

        public enum Tab: Hashable, Sendable {
            case home
            case tree
            case family
            case settings
        }

        public init(
            selectedTab: Tab = .home,
            home: HomeFeature.State = HomeFeature.State(),
            tree: TreeFeature.State = TreeFeature.State(),
            family: FamilyFeature.State = FamilyFeature.State(),
            settings: SettingsFeature.State = SettingsFeature.State()
        ) {
            self.selectedTab = selectedTab
            self.home = home
            self.tree = tree
            self.family = family
            self.settings = settings
        }
    }

    public enum Action: Sendable, Equatable {
        case selectTab(State.Tab)
        case home(HomeFeature.Action)
        case tree(TreeFeature.Action)
        case family(FamilyFeature.Action)
        case settings(SettingsFeature.Action)
        case logout

        // MARK: - Delegate Actions (RootFeature에서 처리)
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case navigateToQuestionDetail(Question)
            case navigateToCreateFamily
            case navigateToJoinFamily
            case requestRefresh
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }

        Scope(state: \.tree, action: \.tree) {
            TreeFeature()
        }

        Scope(state: \.family, action: \.family) {
            FamilyFeature()
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

            case .home(.delegate(.navigateToCreateFamily)):
                return .send(.delegate(.navigateToCreateFamily))

            case .home(.delegate(.navigateToJoinFamily)):
                return .send(.delegate(.navigateToJoinFamily))

            case .home(.delegate(.requestRefresh)):
                return .send(.delegate(.requestRefresh))

            case .home:
                return .none

            case .tree:
                return .none

            // MARK: - Family Delegate Actions
            case .family(.delegate(.navigateToCreateFamily)):
                return .send(.delegate(.navigateToCreateFamily))

            case .family(.delegate(.navigateToJoinFamily)):
                return .send(.delegate(.navigateToJoinFamily))

            case .family(.delegate(.leftFamily)):
                // 가족을 떠난 후 홈으로 이동하고 데이터 새로고침
                state.selectedTab = .home
                return .send(.delegate(.requestRefresh))

            case .family:
                return .none

            // MARK: - Settings Delegate Actions
            case .settings(.delegate(.logout)):
                return .send(.logout)

            case .settings(.delegate(.accountDeleted)):
                // 회원탈퇴 후 로그아웃과 동일하게 처리 (RootFeature에서 미인증 상태로 전환)
                return .send(.logout)

            case .settings(.delegate(.openURL)):
                // URL 열기는 RootFeature에서 처리하거나 여기서 직접 처리
                return .none

            case .settings:
                return .none

            case .logout:
                // 로그아웃은 상위로 전달 (RootFeature에서 처리)
                return .none

            case .delegate:
                // 상위 Feature에서 처리
                return .none
            }
        }
    }
}
