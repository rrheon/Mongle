//
//  BadgesFeature.swift
//  MongleFeatures
//
//  Created for Mongle v2 — UI-2 (PRD §4)
//

import Foundation
import ComposableArchitecture
import Domain

@Reducer
public struct BadgesFeature {

    public enum Category: String, Equatable, Sendable, Codable {
        case streak = "STREAK"
        case answerCount = "ANSWER_COUNT"
    }

    /// PRD §4 GET /users/me/badges 응답 1건 (획득 사실).
    public struct Award: Equatable, Identifiable, Sendable {
        public let code: String
        public let awardedAt: Date
        public var seenAt: Date?
        public var id: String { code }

        public init(code: String, awardedAt: Date, seenAt: Date? = nil) {
            self.code = code
            self.awardedAt = awardedAt
            self.seenAt = seenAt
        }
    }

    /// 배지 정의 (서버 `definitions` 또는 클라이언트 폴백).
    public struct Definition: Equatable, Identifiable, Sendable {
        public let code: String
        public let category: Category
        public let iconKey: String
        public var id: String { code }

        public init(code: String, category: Category, iconKey: String) {
            self.code = code
            self.category = category
            self.iconKey = iconKey
        }

        /// PRD §4.5 — 이름/조건은 클라이언트 Localizable.
        public var localizedName: String { L10n.tr("\(iconKey)_name") }
        public var localizedCondition: String { L10n.tr("\(iconKey)_condition") }
    }

    @ObservableState
    public struct State: Equatable {
        public var awards: [Award] = []
        public var definitions: [Definition] = []
        public var isLoading: Bool = false
        public var errorMessage: String?
        /// 미확인 획득 배지(seenAt==null) 큐 — 첫 항목을 팝업으로 표시 후 dismiss 시 다음으로 진행.
        /// PRD §4: badgeEarnedNotify 토글과 무관하게 항상 인앱 표시.
        public var pendingPopupCodes: [String] = []
        public var currentPopupCode: String? { pendingPopupCodes.first }
        public var currentPopupDefinition: Definition? {
            guard let code = currentPopupCode else { return nil }
            return definitions.first(where: { $0.code == code })
        }

        public init() {}

        public var earnedCodes: Set<String> { Set(awards.map(\.code)) }

        public var earnedDefinitions: [Definition] {
            definitions.filter { earnedCodes.contains($0.code) }
        }

        public var lockedDefinitions: [Definition] {
            definitions.filter { !earnedCodes.contains($0.code) }
        }

        public func awardedAt(for code: String) -> Date? {
            awards.first(where: { $0.code == code })?.awardedAt
        }
    }

    public enum Action: Sendable, Equatable {
        case onAppear
        case closeTapped
        case badgesLoaded(BadgeList)
        case loadFailed(String)
        case markSeenCompleted([String])
        case popupDismissed
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case close
        }
    }

    @Dependency(\.userRepository) var userRepository

    public init() {}

    /// PRD §4.2 초기 6개 배지 — Localizable 키와 일치하는 iconKey.
    public static let defaultDefinitions: [Definition] = [
        .init(code: "STREAK_3",   category: .streak,      iconKey: "badge_streak_3"),
        .init(code: "STREAK_7",   category: .streak,      iconKey: "badge_streak_7"),
        .init(code: "STREAK_30",  category: .streak,      iconKey: "badge_streak_30"),
        .init(code: "STREAK_100", category: .streak,      iconKey: "badge_streak_100"),
        .init(code: "ANSWERS_10", category: .answerCount, iconKey: "badge_answers_10"),
        .init(code: "ANSWERS_50", category: .answerCount, iconKey: "badge_answers_50")
    ]

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let list = try await userRepository.getBadges()
                        await send(.badgesLoaded(list))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }

            case .badgesLoaded(let list):
                state.isLoading = false
                // 서버 정의를 우선 사용하되, 비어있으면 클라이언트 폴백 카탈로그.
                let serverDefs = list.definitions.map(Self.toDefinition)
                state.definitions = serverDefs.isEmpty ? Self.defaultDefinitions : serverDefs
                state.awards = list.badges.map { .init(code: $0.code, awardedAt: $0.awardedAt, seenAt: $0.seenAt) }
                let unseen = list.badges.filter { $0.seenAt == nil }.map(\.code)
                state.pendingPopupCodes = unseen
                guard !unseen.isEmpty else { return .none }
                return .run { send in
                    try? await userRepository.markBadgesSeen(codes: unseen)
                    await send(.markSeenCompleted(unseen))
                }

            case .loadFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                // 폴백: 카탈로그만 노출 (획득 0개).
                if state.definitions.isEmpty {
                    state.definitions = Self.defaultDefinitions
                }
                return .none

            case .markSeenCompleted(let codes):
                let now = Date()
                let codeSet = Set(codes)
                state.awards = state.awards.map { award in
                    guard codeSet.contains(award.code), award.seenAt == nil else { return award }
                    var updated = award
                    updated.seenAt = now
                    return updated
                }
                return .none

            case .popupDismissed:
                if !state.pendingPopupCodes.isEmpty {
                    state.pendingPopupCodes.removeFirst()
                }
                return .none

            case .closeTapped:
                return .send(.delegate(.close))

            case .delegate:
                return .none
            }
        }
    }

    /// Domain BadgeDefinition → Feature.Definition 매핑.
    private static func toDefinition(_ d: BadgeDefinition) -> Definition {
        let cat: Category = (d.category == .answerCount) ? .answerCount : .streak
        return Definition(code: d.code, category: cat, iconKey: d.iconKey)
    }
}
