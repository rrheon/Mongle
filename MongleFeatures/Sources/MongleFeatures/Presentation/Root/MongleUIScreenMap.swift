import Foundation

public enum MongleUIScreen: String, CaseIterable, Sendable {
    case login = "01 · Login"
    case groupSelect = "02 · Group Select"
    case home = "03 · Home"
    case answer = "04 · Answer"
    case history = "05 · History"
    case settings = "06 · Settings"
    case peerAnswerSelfAnswered = "07 · Peer Answer View (Self Answered)"
    case popupAnswerFirst = "08 · Popup - Answer First"
    case peerNotAnsweredNudge = "09 · Peer Not Answered (Nudge)"
    case heartsSystem = "10 · Hearts System"
    case createGroupStep1 = "11 · Create Group Step1"
    case createGroupStep2Invite = "12 · Create Group Step2 (Invite)"
    case notificationCenter = "13 · Notification Center"
    case historyCalendar = "14 · History Calendar"
    case notificationSettings = "15 · Notification Settings"
    case groupManagement = "16 · Group Management"
    case moodHistory = "17 · Mood History"
    case onboardingWelcome = "OB1 · Onboarding - Welcome"
    case onboardingGroup = "OB2 · Onboarding - Group"
    case onboardingQuestion = "OB3 · Onboarding - Question"
}
