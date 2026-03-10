import Foundation
import ComposableArchitecture

@Reducer
public struct OnboardingFeature {
    @ObservableState
    public struct State: Equatable {
        public struct Page: Equatable, Sendable, Identifiable {
            public var id: Int { index }
            public let index: Int
            public let eyebrow: String
            public let title: String
            public let description: String
            public let iconName: String
            public let accentHex: String
            public let backgroundHex: String

            public init(
                index: Int,
                eyebrow: String,
                title: String,
                description: String,
                iconName: String,
                accentHex: String,
                backgroundHex: String
            ) {
                self.index = index
                self.eyebrow = eyebrow
                self.title = title
                self.description = description
                self.iconName = iconName
                self.accentHex = accentHex
                self.backgroundHex = backgroundHex
            }
        }

        public var currentIndex: Int = 0
        public var pages: [Page]

        public var currentPage: Page {
            pages[currentIndex]
        }

        public var isLastPage: Bool {
            currentIndex == pages.count - 1
        }

        public init(
            currentIndex: Int = 0,
            pages: [Page] = [
                .init(
                    index: 0,
                    eyebrow: "환영해요 🌿",
                    title: "가족, 친구와 매일 마음을 나누는\n감정 공간을 시작해요",
                    description: "질문 하나로 서로의 하루를 듣고,\n작은 감정을 오래 남길 수 있어요.",
                    iconName: "heart.text.square.fill",
                    accentHex: "F5978E",
                    backgroundHex: "FFF1F0"
                ),
                .init(
                    index: 1,
                    eyebrow: "함께 만들기",
                    title: "가족, 친구, 커플 등\n함께하고 싶은 사람들을 초대해요",
                    description: "그룹을 만들고 초대 코드로 연결하면\n우리만의 감정 공간이 열려요.",
                    iconName: "person.3.fill",
                    accentHex: "66BB6A",
                    backgroundHex: "EAF7EE"
                ),
                .init(
                    index: 2,
                    eyebrow: "매일 함께",
                    title: "매일 새로운 질문에 답하고\n서로의 마음을 더 알아가요",
                    description: "몽글이 건네는 질문에 답하면서\n하루의 감정과 관계의 온도를 쌓아보세요.",
                    iconName: "sparkles",
                    accentHex: "FF9800",
                    backgroundHex: "FFF1DE"
                )
            ]
        ) {
            self.currentIndex = currentIndex
            self.pages = pages
        }
    }

    public enum Action: Sendable, Equatable {
        case pageChanged(Int)
        case nextTapped
        case skipTapped
        case getStartedTapped
        case delegate(Delegate)

        public enum Delegate: Sendable, Equatable {
            case finished
        }
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .pageChanged(let index):
                guard state.pages.indices.contains(index) else { return .none }
                state.currentIndex = index
                return .none

            case .nextTapped:
                guard !state.isLastPage else {
                    return .send(.delegate(.finished))
                }
                state.currentIndex += 1
                return .none

            case .skipTapped, .getStartedTapped:
                return .send(.delegate(.finished))

            case .delegate:
                return .none
            }
        }
    }
}
