//
//  Components.swift
//  Mongle
//
//  Created from pencil-new.pen design system
//

import SwiftUI

// MARK: - Buttons

/// component/Button/Primary — gradient pill, white text+icon
public struct MongleButtonPrimary: View {
    let label: String
    var icon: String? = nil
    var action: () -> Void

    public init(_ label: String, icon: String? = nil, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                Text(label)
                    .font(MongleFont.button())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                LinearGradient(
                    colors: [MongleColor.primaryGradientStart, MongleColor.primaryGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: MongleColor.primaryGradientStart.opacity(0.2), radius: 12, x: 0, y: 4)
        }
    }
}

/// component/Button/Secondary — glass pill, green text+icon
public struct MongleButtonSecondary: View {
    let label: String
    var icon: String? = nil
    var action: () -> Void

    public init(_ label: String, icon: String? = nil, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(MongleColor.primary)
                }
                Text(label)
                    .font(MongleFont.button())
                    .foregroundColor(MongleColor.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white.opacity(0.8))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(MongleColor.primary, lineWidth: 1.5))
            .shadow(color: MongleColor.shadowBase.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Inputs

/// component/Input/Text — single-line text field with icon
public struct MongleInputText: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = "magnifyingglass"

    public init(placeholder: String, text: Binding<String>, icon: String = "magnifyingglass") {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(MongleColor.textHint)
            TextField(placeholder, text: $text)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textPrimary)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color.white)
        .cornerRadius(MongleRadius.medium)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.medium).stroke(MongleColor.border, lineWidth: 1))
        .shadow(color: MongleColor.shadowBase.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Monggle Character

/// component/Monggle — colored ball with two white-outlined eyes + optional name
public struct MongleMonggle: View {
    let color: Color
    var name: String? = nil
    var size: CGFloat = 56

    public init(color: Color, name: String? = nil, size: CGFloat = 56) {
        self.color = color
        self.name = name
        self.size = size
    }

    private var eyeSize: CGFloat { size * 0.18 }
    private var eyeOffset: CGFloat { size * 0.04 }

    public var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .shadow(color: color.opacity(0.3), radius: size * 0.2, x: 0, y: size * 0.07)

                HStack(spacing: eyeSize * 0.6) {
                    Circle()
                        .fill(MongleColor.textPrimary)
                        .frame(width: eyeSize, height: eyeSize)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    Circle()
                        .fill(MongleColor.textPrimary)
                        .frame(width: eyeSize, height: eyeSize)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                }
                .offset(y: eyeOffset)
            }

            if let name {
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(MongleColor.textPrimary)
            }
        }
        .frame(width: name != nil ? 72 : size)
    }
}

// Convenience initializers for each Monggle color
public extension MongleMonggle {
    static func green(name: String? = nil, size: CGFloat = 56) -> MongleMonggle {
        MongleMonggle(color: MongleColor.monggleGreen, name: name, size: size)
    }
    static func yellow(name: String? = nil, size: CGFloat = 56) -> MongleMonggle {
        MongleMonggle(color: MongleColor.monggleYellow, name: name, size: size)
    }
    static func blue(name: String? = nil, size: CGFloat = 56) -> MongleMonggle {
        MongleMonggle(color: MongleColor.monggleBlue, name: name, size: size)
    }
    static func pink(name: String? = nil, size: CGFloat = 56) -> MongleMonggle {
        MongleMonggle(color: MongleColor.mongglePink, name: name, size: size)
    }
    static func orange(name: String? = nil, size: CGFloat = 56) -> MongleMonggle {
        MongleMonggle(color: MongleColor.monggleOrange, name: name, size: size)
    }
    // MG-150 — mood 색 단일 매핑 진실은 V2Palette.mood.
    static func forMood(_ moodId: String?, size: CGFloat = 56) -> MongleMonggle {
        MongleMonggle(color: V2Palette.mood(moodId), size: size)
    }
}


// MARK: - Cards

/// component/Card/Question — glass card with emoji, label, question text
public struct MongleCardQuestion: View {
    let question: String
    var emoji: String = "🌿"
    var label: String = L10n.tr("home_today_question")
    var onTap: (() -> Void)? = nil

    public init(question: String, emoji: String = "🌿", label: String = L10n.tr("home_today_question"), onTap: (() -> Void)? = nil) {
        self.question = question
        self.emoji = emoji
        self.label = label
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(emoji)
                        .font(.system(size: 16))
                    Text(label)
                        .font(MongleFont.captionBold())
                        .foregroundColor(MongleColor.primaryMuted)
                }

                HStack(alignment: .center) {
                    Text(question)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MongleColor.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16))
                        .foregroundColor(MongleColor.textHint)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(MongleRadius.xl)
            .overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(Color.white.opacity(0.2), lineWidth: 1))
            .shadow(color: MongleColor.shadowBase.opacity(0.12), radius: 16, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

// MARK: MongleCardGroup

public struct MongleCardGroup: View {
    let groupName: String
    let memberColors: [Color]
    var onTap: (() -> Void)? = nil

    public init(
        groupName: String,
        memberColors: [Color],
        onTap: (() -> Void)? = nil
    ) {
        self.groupName = groupName
        self.memberColors = memberColors
        self.onTap = onTap
    }

    public var body: some View {
        Button { onTap?() } label: {
          VStack(alignment: .leading, spacing: 10) {
            HStack {
              VStack(alignment: .leading, spacing: 12) {
                Text(groupName)
                  .font(.system(size: 18, weight: .semibold))
                  .foregroundColor(MongleColor.textPrimary)
                
                HStack(spacing: -10) {
                  ForEach(memberColors.indices, id: \.self) { i in
                    MongleMonggle(color: memberColors[i], size: 36)
                      .overlay(Circle().stroke(Color.white, lineWidth: 2).frame(width: 36, height: 36))
                      .zIndex(Double(memberColors.count - i))
                  }
                }
                
              }
              
              Spacer()
              
              Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(MongleColor.textHint)
              
            }
            
          }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .frame(height: 130)

            .background(MongleColor.cardGlass)
            .cornerRadius(MongleRadius.xl)
            .overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(MongleColor.border, lineWidth: 1))
            .shadow(color: MongleColor.shadowBase.opacity(0.12), radius: 20, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mood Selector

public struct MoodOption: Identifiable, Equatable {
    public let id: String
    public let emoji: String
    public let label: String
    public let color: Color

    public init(id: String, emoji: String, label: String, color: Color) {
        self.id = id
        self.emoji = emoji
        self.label = label
        self.color = color
    }

    public static let defaults: [MoodOption] = [
        MoodOption(id: "calm",    emoji: "😌", label: L10n.tr("mood_calm"),    color: MongleColor.monggleGreen),
        MoodOption(id: "happy",   emoji: "😊", label: L10n.tr("mood_happy"),   color: MongleColor.monggleYellow),
        MoodOption(id: "loved",   emoji: "🥰", label: L10n.tr("mood_loved"),   color: MongleColor.mongglePink),
        MoodOption(id: "sad",     emoji: "😢", label: L10n.tr("mood_sad"),     color: MongleColor.monggleBlue),
        MoodOption(id: "tired",   emoji: "😴", label: L10n.tr("mood_tired"),   color: MongleColor.monggleOrange),
    ]

    /// moodId → defaults 인덱스 역매핑 캐시.
    /// 호출지마다 `defaults.firstIndex(where:)` linear scan 을 O(1) lookup 으로 대체.
    public static let indexById: [String: Int] = Dictionary(
        uniqueKeysWithValues: defaults.enumerated().map { ($1.id, $0) }
    )

    /// moodId → Color 매핑 캐시. 화면 내 정의된 5-way switch (PeerNudgeView,
    /// MainTab+Reducer, MainTabView, NotificationView 등) 를 단일 진입점으로 통합.
    public static let colorById: [String: Color] = Dictionary(
        uniqueKeysWithValues: defaults.map { ($0.id, $0.color) }
    )

    /// moodId 가 nil 이거나 매핑이 없을 때 사용되는 fallback. 기존 화면들이
    /// monggleYellow / mongglePink 으로 분기되어 일관성이 깨져있던 것을 통일.
    public static let defaultColor: Color = MongleColor.mongglePink

    /// 단일 진입점 — 모든 moodId → Color 변환은 이 함수를 사용.
    public static func color(for moodId: String?) -> Color {
        guard let moodId, let color = colorById[moodId] else { return defaultColor }
        return color
    }
}

// MARK: - Panel Modifier

extension View {
    public func monglePanel(
        background: Color = MongleColor.cardGlass,
        cornerRadius: CGFloat = MongleRadius.xl,
        borderColor: Color = MongleColor.borderCard,
        shadowOpacity: CGFloat = 0.12
    ) -> some View {
        self
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: MongleColor.shadowWarm.opacity(shadowOpacity), radius: 20, x: 0, y: 4)
    }
}

// MARK: - Button Styles

public struct MongleScaleButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct MongleRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.black.opacity(0.05) : Color.clear)
    }
}


// MARK: - Previews

#Preview("Buttons") {
    ScrollView {
        VStack(spacing: 16) {
            MongleButtonPrimary("시작하기", icon: "plus", action: {})
            MongleButtonSecondary("답변하기", action: {})
        }
        .padding()
    }
    .background(MongleColor.bgNeutral)
}

#Preview("Monggle") {
    HStack(spacing: 8) {
        MongleMonggle.green(name: "Mom")
        MongleMonggle.yellow(name: "Lily")
        MongleMonggle.blue(name: "Ben")
        MongleMonggle.pink(name: "Alex")
        MongleMonggle.orange(name: "Dad")
    }
    .padding()
    .background(MongleColor.bgNeutral)
}

#Preview("Cards") {
    ScrollView {
        VStack(spacing: 16) {
            MongleCardQuestion(
                question: "오늘 당신을 웃게 한 건 무엇인가요?",
                onTap: {}
            )
            MongleCardGroup(
                groupName: "Kim Family",
                memberColors: [MongleColor.monggleGreen, MongleColor.monggleYellow, MongleColor.monggleBlue, MongleColor.mongglePink, MongleColor.monggleOrange]
            )
        }
        .padding()
    }
    .background(MongleColor.bgNeutral)
}


// MARK: - Mongle Character Movement Model

public struct MongleCharacter: Identifiable {
    public let id = UUID()
    public let name: String
    public var color: Color
    public var hasAnswered: Bool
    public var hasSkipped: Bool
    public var position: CGPoint
    public var targetPosition: CGPoint
    public var overlapCounter: Int = 0  // 충돌 지속 프레임 수
    public var stepCount: Int = 0       // 이동 누적 스텝 수 (hop 위상 계산용)
    public var restFramesLeft: Int = 0  // 휴식 남은 프레임 수 (> 0 이면 정지)
    /// 캐릭터 hop 오프셋 캐시. body 호출마다 sin/abs 를 반복 계산하던 것을
    /// step() 1회 갱신으로 옮겨 ZStack 재평가 비용을 낮춘다.
    public var hopY: CGFloat = 0

    public init(name: String, color: Color, hasAnswered: Bool, hasSkipped: Bool = false, position: CGPoint, targetPosition: CGPoint) {
        self.name = name
        self.color = color
        self.hasAnswered = hasAnswered
        self.hasSkipped = hasSkipped
        self.position = position
        self.targetPosition = targetPosition
    }
}

// MARK: - Mongle Interactive View (상태 배지 + 캐릭터)

public struct MongleView: View {
    public let name: String
    public let color: Color
    public let hasAnswered: Bool
    /// 해당 멤버가 오늘 질문을 패스했는지 (다른 가족에게도 "질문 넘김" 뱃지가 보이도록 사용)
    public let hasSkipped: Bool
    public let hasCurrentUserAnswered: Bool
    public let hasCurrentUserSkipped: Bool
    public let isCurrentUser: Bool
    public let onViewAnswer: () -> Void
    public let onNudge: () -> Void
    public let onSelfTap: () -> Void

    public let onAnswerFirstToView: (String) -> Void
    public let onAnswerFirstToNudge: (String) -> Void

    public init(name: String, color: Color, hasAnswered: Bool,
                hasSkipped: Bool = false,
                hasCurrentUserAnswered: Bool,
                hasCurrentUserSkipped: Bool = false,
                isCurrentUser: Bool = false,
                onViewAnswer: @escaping () -> Void,
                onNudge: @escaping () -> Void,
                onSelfTap: @escaping () -> Void = {},
                onAnswerFirstToView: @escaping (String) -> Void = { _ in },
                onAnswerFirstToNudge: @escaping (String) -> Void = { _ in }) {
        self.name = name
        self.color = color
        self.hasAnswered = hasAnswered
        self.hasSkipped = hasSkipped
        self.hasCurrentUserAnswered = hasCurrentUserAnswered
        self.hasCurrentUserSkipped = hasCurrentUserSkipped
        self.isCurrentUser = isCurrentUser
        self.onViewAnswer = onViewAnswer
        self.onNudge = onNudge
        self.onSelfTap = onSelfTap
        self.onAnswerFirstToView = onAnswerFirstToView
        self.onAnswerFirstToNudge = onAnswerFirstToNudge
    }

    private func handleTap() {
      // 나의 캐릭터를 탭한 경우
      if isCurrentUser {
          onSelfTap()
          return
      }

      // 패스했거나 답변한 경우 → 상대 답변 볼 수 있음
      let canView = hasCurrentUserAnswered || hasCurrentUserSkipped

      // 상대가 "패스" 한 경우 — 재촉/답변보기 모두 해당 없음 (가족 간 강요 방지)
      if hasSkipped {
          return
      }

      // 상대의 답변여부, 내가 볼 수 있는지
      switch (hasAnswered, canView) {
      case (true, true):
          onViewAnswer() // 상대 답변 완료 + 내가 볼 수 있음 -> 답변 보기

      case (true, false):
          onAnswerFirstToView(name)  // 상대만 완료 -> 내가 먼저 써야 함 (팝업)

      case (false, true):
          onNudge()  // 내가 볼 수 있음 + 상대 미답변 -> 재촉하기

      case (false, false):
          onAnswerFirstToNudge(name) // 둘 다 미완료 -> 내가 먼저 써야 재촉 가능 (팝업)
      }
    }

    public var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 4) {
                statusBadge
                // MG-120 — 본인 캐릭터는 이름 옆에 "(나)" suffix 를 붙여 status badge 색상에
                // 더해 즉시 식별 가능하게 한다.
                let displayName = isCurrentUser ? "\(name) \(L10n.tr("home_member_me_suffix"))" : name
                // MG-150 — V2 톤(둥근 몸체 + 흰테 눈 + dropshadow + 본인 ring) 을 인라인으로
                // 그린다. V2Mongle 컨테이너를 직접 쓰면 내부 절대 offset 때문에 frame 강제
                // 축소 시 본체가 frame 위쪽을 가득 채워 상단 statusBadge 와 겹친다.
                // 정확한 70x70 frame 안에 본체를 center 정렬해 layout 을 안정시킨다.
                v2CharacterBody
                Text(displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(MongleColor.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    /// 캐릭터 본체 + 눈 + (본인일 때) ring. 컨테이너 70x70 (ring 포함).
    private var v2CharacterBody: some View {
        let bodySize: CGFloat = 56
        let eyeSize: CGFloat = bodySize * 0.18
        // 기존 MongleMonggle 의 눈 위치(body 중심 + size*0.04 만큼 아래) 그대로.
        let eyeOffset: CGFloat = bodySize * 0.04
        return ZStack {
            if isCurrentUser {
                Circle()
                    .strokeBorder(V2Palette.mint, lineWidth: 2)
                    .frame(width: bodySize + 14, height: bodySize + 14)
            }
            Circle()
                .fill(color)
                .frame(width: bodySize, height: bodySize)
                .overlay(Circle().strokeBorder(V2Palette.inkSoft, lineWidth: 1.5))
                .shadow(color: Color.black.opacity(0.32), radius: 7, x: 0, y: 4)

            HStack(spacing: eyeSize * 0.6) {
                eye(size: eyeSize)
                eye(size: eyeSize)
            }
            .offset(y: eyeOffset)
        }
        .frame(width: bodySize + 14, height: bodySize + 14)
    }

    private func eye(size: CGFloat) -> some View {
        Circle()
            .fill(V2Palette.ink)
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
    }

    @ViewBuilder
    private var statusBadge: some View {
        if isCurrentUser {
            let icon: String = hasAnswered ? "checkmark.circle.fill" : (hasCurrentUserSkipped ? "arrow.right.circle.fill" : "pencil.circle")
            let label: String = hasAnswered ? L10n.tr("home_answer_complete") : (hasCurrentUserSkipped ? L10n.tr("home_skipped_label") : L10n.tr("home_answer_btn"))
            let bgColor: Color = hasAnswered ? MongleColor.primary.opacity(0.85) : (hasCurrentUserSkipped ? Color.purple.opacity(0.7) : MongleColor.accentOrange.opacity(0.85))
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(label)
                    .font(.caption2.bold())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bgColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
        } else {
            // 상대방 뱃지: 답변함 / 패스함 / 미답변 3가지 상태 구분
            let style = peerBadgeStyle
            HStack(spacing: 4) {
                Image(systemName: style.icon)
                    .font(.system(size: 10, weight: .bold))
                Text(style.label)
                    .font(.caption2.bold())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(style.bgColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
    }

    private var peerBadgeStyle: (icon: String, label: String, bgColor: Color) {
        if hasAnswered {
            return ("checkmark.circle.fill", L10n.tr("home_answer_complete"), Color.green.opacity(0.85))
        } else if hasSkipped {
            return ("arrow.right.circle.fill", L10n.tr("home_skipped_label"), Color.purple.opacity(0.7))
        } else {
            return ("clock", L10n.tr("nudge_send"), Color.gray.opacity(0.4))
        }
    }
}

// MARK: - Mongle Member (Home / Scene 멤버 모델)

/// Home 화면 캐릭터 노드의 단일 모델.
///
/// 이전에는 `(name: String, color: Color, hasAnswered: Bool, hasSkipped: Bool)` tuple 배열로
/// 주고받았으나, 이는 (1) Equatable 자동 합성이 안 되어 SwiftUI 의 view diff 에서 비효율,
/// (2) Identifiable 미준수로 ForEach 의 id 추출 클로저가 element 마다 호출,
/// (3) 신규 필드 추가 시 명명 충돌·초기화 누락 위험이 있었다.
///
/// 명명된 struct 로 끌어올려 SwiftUI / TCA 양쪽 모두 1급 시민으로 다룰 수 있게 한다.
public struct MongleMember: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let color: Color
    public let hasAnswered: Bool
    public let hasSkipped: Bool

    public init(id: UUID, name: String, color: Color, hasAnswered: Bool, hasSkipped: Bool) {
        self.id = id
        self.name = name
        self.color = color
        self.hasAnswered = hasAnswered
        self.hasSkipped = hasSkipped
    }
}

// MARK: - Mongle Scene (구역 내 이동 + 충돌 감지)

public struct MongleSceneView: View {
    public var hasCurrentUserAnswered: Bool = false
    public var hasCurrentUserSkipped: Bool = false
    public var members: [MongleMember]
    public var currentUserName: String?
    public var onViewAnswer: (String) -> Void = { _ in }
    public var onNudge: (String) -> Void = { _ in }
    public var onSelfTap: () -> Void = {}
    public var onAnswerFirstToView: (String) -> Void = { _ in }
    public var onAnswerFirstToNudge: (String) -> Void = { _ in }

    private let stepSize: CGFloat = 2.0
    /// 0.16s = 6.25Hz. 이전 0.12s(8.3Hz) 대비 부하 약 25% 감소하면서 시각적 자연스러움 유지.
    private let interval: TimeInterval = 0.16
    private let collisionRadius: CGFloat = 76
    private let targetThreshold: CGFloat = 12
    private let wallPadding: CGFloat = 50
    private let overlapLimit: Int = 10

    @State private var mongles: [MongleCharacter] = []
    @State private var timer: Timer?
    /// scenePhase 가 .active 가 아니면 Timer 를 invalidate 하여 백그라운드 CPU 점유를 막는다.
    /// NavigationStack push 등으로 onDisappear 가 즉시 fire 되지 않는 케이스에서도 유효.
    @Environment(\.scenePhase) private var scenePhase

    private static let defaultMemberData: [MongleMember] = [
        MongleMember(id: UUID(), name: "Dad",  color: .orange, hasAnswered: true,  hasSkipped: false),
        MongleMember(id: UUID(), name: "Mom",  color: .green,  hasAnswered: false, hasSkipped: false),
        MongleMember(id: UUID(), name: "Lily", color: .yellow, hasAnswered: true,  hasSkipped: false),
        MongleMember(id: UUID(), name: "Ben",  color: .blue,   hasAnswered: false, hasSkipped: false),
        MongleMember(id: UUID(), name: "Alex", color: .pink,   hasAnswered: true,  hasSkipped: false)
    ]

    public init(hasCurrentUserAnswered: Bool = false,
                hasCurrentUserSkipped: Bool = false,
                members: [MongleMember] = [],
                currentUserName: String? = nil,
                onViewAnswer: @escaping (String) -> Void = { _ in },
                onNudge: @escaping (String) -> Void = { _ in },
                onSelfTap: @escaping () -> Void = {},
                onAnswerFirstToView: @escaping (String) -> Void = { _ in },
                onAnswerFirstToNudge: @escaping (String) -> Void = { _ in }) {
        self.hasCurrentUserAnswered = hasCurrentUserAnswered
        self.hasCurrentUserSkipped = hasCurrentUserSkipped
        self.members = members
        self.currentUserName = currentUserName
        self.onViewAnswer = onViewAnswer
        self.onNudge = onNudge
        self.onSelfTap = onSelfTap
        self.onAnswerFirstToView = onAnswerFirstToView
        self.onAnswerFirstToNudge = onAnswerFirstToNudge
    }

    private var effectiveMembers: [MongleMember] {
        // 빈 배열이면 폴백, 아니면 입력 배열 그대로 사용 (재할당 0회)
        members.isEmpty ? Self.defaultMemberData : members
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(mongles) { h in
                    // hopY 는 step() 시점에 캐시됨 (body 재평가 시 sin/abs 반복 호출 제거)
                    MongleView(
                        name: h.name,
                        color: h.color,
                        hasAnswered: h.hasAnswered,
                        hasSkipped: h.hasSkipped,
                        hasCurrentUserAnswered: hasCurrentUserAnswered,
                        hasCurrentUserSkipped: hasCurrentUserSkipped,
                        isCurrentUser: currentUserName != nil && h.name == currentUserName,
                        onViewAnswer: { onViewAnswer(h.name) },
                        onNudge: { onNudge(h.name) },
                        onSelfTap: onSelfTap,
                        onAnswerFirstToView: onAnswerFirstToView,
                        onAnswerFirstToNudge: onAnswerFirstToNudge
                    )
                    .position(CGPoint(x: h.position.x, y: h.position.y + h.hopY))
                    .animation(.linear(duration: interval), value: h.stepCount)
                }
            }
            .onAppear {
                if geo.size.width > 0, geo.size.height > 0 {
                    if mongles.isEmpty { initMongles(size: geo.size) }
                    startTimer(size: geo.size)
                }
            }
            .onChange(of: geo.size) { _, newSize in
                guard newSize.width > 0, newSize.height > 0 else { return }
                if mongles.isEmpty { initMongles(size: newSize) }
                if timer == nil { startTimer(size: newSize) }
            }
            .onChange(of: scenePhase) { _, newPhase in
                // 백그라운드/비활성 진입 시 Timer 정지, 복귀 시 재시작
                if newPhase == .active {
                    if geo.size.width > 0, geo.size.height > 0, timer == nil {
                        startTimer(size: geo.size)
                    }
                } else {
                    timer?.invalidate()
                    timer = nil
                }
            }
            // 멤버 배열 변화 1개의 onChange 로 통합 (이전: name/hasAnswered/hasSkipped/color
            // 4중 onChange + 매 평가마다 members.map 임시배열 4개 생성).
            // 핸들러 안에서는 [String: MongleMember] dict 인덱스로 O(1) 매치하여
            // 이전의 nested O(N²) linear search 제거.
            .onChange(of: members) { oldMembers, newMembers in
                guard geo.size.width > 0, geo.size.height > 0 else { return }

                // 이름 집합이 바뀌면 시뮬레이션 자체를 재초기화 (가족 구성원 변경)
                let oldNames = Set(oldMembers.map { $0.name })
                let newNames = Set(newMembers.map { $0.name })
                if oldNames != newNames {
                    initMongles(size: geo.size)
                    return
                }

                // 동일 멤버라면 상태(answer/skip/color) 만 업데이트
                let lookup = Dictionary(uniqueKeysWithValues: newMembers.map { ($0.name, $0) })
                for i in mongles.indices {
                    guard let member = lookup[mongles[i].name] else { continue }
                    if mongles[i].hasAnswered != member.hasAnswered {
                        mongles[i].hasAnswered = member.hasAnswered
                    }
                    if mongles[i].hasSkipped != member.hasSkipped {
                        mongles[i].hasSkipped = member.hasSkipped
                    }
                    if mongles[i].color != member.color {
                        mongles[i].color = member.color
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func initMongles(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        var placed: [CGPoint] = []
        mongles = effectiveMembers.map { member in
            var pos = randomPos(size: size)
            for _ in 0..<30 {
                let overlaps = placed.contains { hypot(pos.x - $0.x, pos.y - $0.y) < collisionRadius }
                if !overlaps { break }
                pos = randomPos(size: size)
            }
            placed.append(pos)
            return MongleCharacter(
                name: member.name,
                color: member.color,
                hasAnswered: member.hasAnswered,
                hasSkipped: member.hasSkipped,
                position: pos,
                targetPosition: randomPos(size: size)
            )
        }
    }

    private func randomPos(size: CGSize) -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: wallPadding...(size.width - wallPadding)),
            y: CGFloat.random(in: wallPadding...(size.height - wallPadding))
        )
    }

    private func startTimer(size: CGSize) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            step(size: size)
        }
    }

    private func step(size: CGSize) {
        for i in mongles.indices {
            if mongles[i].restFramesLeft > 0 {
                mongles[i].restFramesLeft -= 1
                if mongles[i].restFramesLeft == 0 {
                    mongles[i].targetPosition = randomPos(size: size)
                }
                continue
            }

            var pos = mongles[i].position
            let target = mongles[i].targetPosition
            let dx = target.x - pos.x
            let dy = target.y - pos.y
            let dist = hypot(dx, dy)

            if dist < targetThreshold {
                if Bool.random() {
                    mongles[i].restFramesLeft = Int.random(in: 10...50)
                } else {
                    mongles[i].targetPosition = randomPos(size: size)
                }
                continue
            }

            pos.x += (dx / dist) * stepSize
            pos.y += (dy / dist) * stepSize

            if pos.x < wallPadding || pos.x > size.width - wallPadding ||
                pos.y < wallPadding || pos.y > size.height - wallPadding {
                pos.x = min(max(pos.x, wallPadding), size.width - wallPadding)
                pos.y = min(max(pos.y, wallPadding), size.height - wallPadding)
                mongles[i].targetPosition = randomPos(size: size)
            }

            let collides = mongles.indices.contains { j in
                guard j != i else { return false }
                return hypot(pos.x - mongles[j].position.x,
                             pos.y - mongles[j].position.y) < collisionRadius
            }
            if collides {
                mongles[i].overlapCounter += 1
                if mongles[i].overlapCounter >= overlapLimit {
                    mongles[i].targetPosition = randomPos(size: size)
                    mongles[i].overlapCounter = 0
                }
                continue
            }

            mongles[i].overlapCounter = 0
            mongles[i].stepCount += 1
            mongles[i].position = pos
            // hopY 캐싱: body 재평가마다 sin/abs 반복 호출하던 것을 step 시점으로 이동
            mongles[i].hopY = -abs(sin(CGFloat(mongles[i].stepCount) * .pi / 5.0)) * 12
        }
    }
}
