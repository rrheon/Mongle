//import SwiftUI
//import ComposableArchitecture
//import Domain
//
//private enum PreviewFixtures {
//    static let familyID = UUID()
//    static let mom = User(
//        id: UUID(),
//        email: "mom@example.com",
//        name: "Mom",
//        profileImageURL: nil,
//        role: .mother,
//        createdAt: .now
//    )
//    static let lily = User(
//        id: UUID(),
//        email: "lily@example.com",
//        name: "Lily",
//        profileImageURL: nil,
//        role: .daughter,
//        createdAt: .now
//    )
//    static let ben = User(
//        id: UUID(),
//        email: "ben@example.com",
//        name: "Ben",
//        profileImageURL: nil,
//        role: .son,
//        createdAt: .now
//    )
//    static let dad = User(
//        id: UUID(),
//        email: "dad@example.com",
//        name: "Dad",
//        profileImageURL: nil,
//        role: .father,
//        createdAt: .now
//    )
//    static let family = MongleGroup(
//        id: familyID,
//        name: "Kim Family",
//        memberIds: [mom.id, lily.id, ben.id, dad.id],
//        createdBy: mom.id,
//        createdAt: .now,
//        inviteCode: "MONG-4729"
//    )
//    static let todayQuestion = Question(
//        id: UUID(),
//        content: "오늘 당신을 웃게 한 건 무엇인가요?",
//        category: .daily,
//        order: 1
//    )
//
//    static let notifications: [Domain.Notification] = [
//        .init(
//            id: UUID(),
//            userId: mom.id,
//            type: .memberAnswered,
//            title: "Lily가 오늘의 질문에 답변했어요",
//            body: "Lily의 생각을 확인하고 하트를 보내보세요.",
//            isRead: false,
//            createdAt: .now
//        ),
//        .init(
//            id: UUID(),
//            userId: mom.id,
//            type: .answerRequest,
//            title: "Dad가 Mom에게 재촉 알림을 보냈어요",
//            body: "Mom이 아직 답변하지 않았어요. 하트 1개가 사용됐어요.",
//            isRead: false,
//            createdAt: .now.addingTimeInterval(-3600)
//        ),
//        .init(
//            id: UUID(),
//            userId: mom.id,
//            type: .badgeEarned,
//            title: "Mom이 하트 5개를 선물했어요 🎁",
//            body: "하트 시스템에서 새 행동을 열어볼 수 있어요.",
//            isRead: true,
//            createdAt: .now.addingTimeInterval(-7200)
//        )
//    ]
//
//    static let familyAnswers: [QuestionDetailFeature.State.FamilyAnswer] = [
//        .init(
//            user: lily,
//            answer: Answer(
//                id: UUID(),
//                dailyQuestionId: todayQuestion.id,
//                userId: lily.id,
//                content: "아침에 고양이가 제 발 위에서 잠든 것을 발견했어요. 너무 귀여워서 한동안 꼼짝도 못했지 뭐예요 🐱",
//                imageURL: nil,
//                createdAt: .now.addingTimeInterval(-1200)
//            )
//        ),
//        .init(
//            user: mom,
//            answer: Answer(
//                id: UUID(),
//                dailyQuestionId: todayQuestion.id,
//                userId: mom.id,
//                content: "오늘 오랜만에 가족이랑 같이 밥 먹었는데 진짜 행복했어요 😊",
//                imageURL: nil,
//                createdAt: .now.addingTimeInterval(-3200)
//            )
//        )
//    ]
//
//    static func homeState(guest: Bool = false) -> HomeFeature.State {
//        HomeFeature.State(
//            todayQuestion: todayQuestion,
//            family: family,
//            familyMembers: [mom, lily, ben, dad],
//            currentUser: guest ? nil : mom,
//            isLoading: false,
//            isRefreshing: false,
//            errorMessage: nil,
//            hasAnsweredToday: !guest,
//            familyAnswerCount: 3,
//            memberAnswerStatus: [
//                lily.id: true,
//                ben.id: false,
//                dad.id: false
//            ]
//        )
//    }
//
//    static func mainTabState(guest: Bool = false) -> MainTabFeature.State {
//        MainTabFeature.State(
//            isGuestMode: guest,
//            home: homeState(guest: guest),
//            history: HistoryFeature.State(),
//            notification: NotificationFeature.State(notifications: notifications),
//            profile: ProfileEditFeature.State(user: guest ? nil : mom)
//        )
//    }
//}
//
//#Preview("Login") {
//    LoginView(
//        store: Store(initialState: LoginFeature.State()) {
//            LoginFeature()
//        }
//    )
//}
//
//
//
//
//#Preview("Question Detail") {
//    QuestionDetailView(
//        store: Store(initialState: QuestionDetailFeature.State(
//            question: PreviewFixtures.todayQuestion,
//            currentUser: PreviewFixtures.mom,
//            familyAnswers: PreviewFixtures.familyAnswers
//        )) {
//            QuestionDetailFeature()
//        }
//    )
//}
//
//#Preview("Peer Answer") {
//    PeerAnswerView(
//        store: Store(initialState: PeerAnswerFeature.State(
//            memberName: "Lily",
//            monggleColor: MongleColor.monggleYellow,
//            questionText: PreviewFixtures.todayQuestion.content,
//            peerAnswer: "아침에 고양이가 제 발 위에서 잠든 것을 발견했어요. 너무 귀여워서 한동안 꼼짝도 못했지 뭐예요 🐱",
//            myAnswer: "아이들이 아침에 처음으로 같이 요리해줬어요. 계란이 좀 타긴 했지만 정말 행복했어요 😊",
//            peerAnswerTime: "오늘 오전 9:23",
//            myAnswerTime: "오늘 오전 8:41"
//        )) {
//            PeerAnswerFeature()
//        }
//    )
//}
//
//#Preview("Peer Nudge") {
//    PeerNudgeView(
//        store: Store(initialState: PeerNudgeFeature.State(
//            memberName: "Ben",
//            questionText: PreviewFixtures.todayQuestion.content
//        )) {
//            PeerNudgeFeature()
//        }
//    )
//}
//
//#Preview("Answer First Popup") {
//    AnswerFirstPopupView(
//        store: Store(initialState: AnswerFirstPopupFeature.State(memberName: "Lily")) {
//            AnswerFirstPopupFeature()
//        }
//    )
//}
//
//#Preview("History") {
//    HistoryView(
//        store: Store(initialState: HistoryFeature.State()) {
//            HistoryFeature()
//        }
//    )
//}
//
//#Preview("Notification") {
//    NotificationView(
//        store: Store(initialState: NotificationFeature.State(notifications: PreviewFixtures.notifications)) {
//            NotificationFeature()
//        }
//    )
//}
//
//#Preview("Profile") {
//    ProfileEditView(
//        store: Store(initialState: ProfileEditFeature.State(user: PreviewFixtures.mom)) {
//            ProfileEditFeature()
//        }
//    )
//}
//
//
//
//#Preview("Main Tab") {
//    MainTabView(
//        store: Store(initialState: PreviewFixtures.mainTabState()) {
//            MainTabFeature()
//        }
//    )
//}
//
//#Preview("Main Tab Guest") {
//    MainTabView(
//        store: Store(initialState: PreviewFixtures.mainTabState(guest: true)) {
//            MainTabFeature()
//        }
//    )
//}
//
//#Preview("Root Guest") {
//    RootView(
//        store: Store(initialState: RootFeature.State(
//            appState: .guestBrowsing,
//            hasSeenOnboarding: true,
//            mainTab: PreviewFixtures.mainTabState(guest: true)
//        )) {
//            RootFeature()
//        }
//    )
//}
//
//#Preview("Support Hearts") {
//    SupportScreenView(
//        store: Store(initialState: SupportScreenFeature.State(screen: .heartsSystem)) {
//            SupportScreenFeature()
//        }
//    )
//}
//
//#Preview("Support Calendar") {
//    SupportScreenView(
//        store: Store(initialState: SupportScreenFeature.State(screen: .historyCalendar)) {
//            SupportScreenFeature()
//        }
//    )
//}
//
//#Preview("Support Notification Settings") {
//    SupportScreenView(
//        store: Store(initialState: SupportScreenFeature.State(screen: .notificationSettings)) {
//            SupportScreenFeature()
//        }
//    )
//}
//
//#Preview("Support Group") {
//    SupportScreenView(
//        store: Store(initialState: SupportScreenFeature.State(screen: .groupManagement)) {
//            SupportScreenFeature()
//        }
//    )
//}
//
//#Preview("Support Mood History") {
//    SupportScreenView(
//        store: Store(initialState: SupportScreenFeature.State(screen: .moodHistory)) {
//            SupportScreenFeature()
//        }
//    )
//}
