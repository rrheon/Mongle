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
    /// 본체 윤곽선 색. 기본값 inkSoft 로 모든 몽글캐릭터가 동일한 얇은 테두리를 갖는다
    /// (배경과 본체 색이 비슷해도 형태가 묻히지 않게). 테두리를 빼려면 생성 후 nil 로 덮어쓴다.
    /// (public init 의 기본인자는 internal 인 V2Palette 를 참조할 수 없어 프로퍼티 기본값으로 둔다.)
    var borderColor: Color? = V2Palette.inkSoft
    /// 기절 상태(흔들기 감지). true면 eyeExpression 무시하고 .fainted(xmark)로 오버라이드.
    var isFainted: Bool = false
    /// 탭 등 인터랙션으로 전환되는 눈 표정 (mood 기반). 평소엔 .neutral.
    var eyeExpression: EyeExpression = .neutral

    public init(color: Color, name: String? = nil, size: CGFloat = 56,
                isFainted: Bool = false,
                eyeExpression: EyeExpression = .neutral) {
        self.color = color
        self.name = name
        self.size = size
        self.isFainted = isFainted
        self.eyeExpression = eyeExpression
    }

    private var eyeSize: CGFloat { size * 0.18 }
    private var eyeOffset: CGFloat { size * 0.04 }
    private var effectiveExpression: EyeExpression {
        isFainted ? .fainted : eyeExpression
    }

    public var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .overlay(borderColor.map { Circle().strokeBorder($0, lineWidth: 1.5) })
                    .shadow(color: color.opacity(0.3), radius: size * 0.2, x: 0, y: size * 0.07)

                HStack(spacing: eyeSize * 0.6) {
                    eyeView
                    eyeView
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

    /// 7개 표정 레이어를 항상 렌더하고 opacity로만 전환.
    /// (구조 diff 시 SwiftUI invalid sample 경고 회피 — DizzyWobbleModifier 주석 참조.)
    private var eyeView: some View {
        let expr = effectiveExpression
        return ZStack {
            // neutral: 흰 테두리 검은 원 (기본)
            Circle()
                .fill(MongleColor.textPrimary)
                .frame(width: eyeSize, height: eyeSize)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .opacity(expr == .neutral ? 1 : 0)
            // fainted: xmark
            Image(systemName: "xmark")
                .font(.system(size: eyeSize, weight: .heavy))
                .foregroundColor(MongleColor.textPrimary)
                .frame(width: eyeSize, height: eyeSize)
                .opacity(expr == .fainted ? 1 : 0)
            // happy: 웃는 눈 (위로 볼록 반달)
            happyEye
                .opacity(expr == .happy ? 1 : 0)
            // calm: 작은 점 (반쯤 감김)
            Circle()
                .fill(MongleColor.textPrimary)
                .frame(width: eyeSize * 0.5, height: eyeSize * 0.5)
                .opacity(expr == .calm ? 1 : 0)
            // loved: 하트
            Image(systemName: "heart.fill")
                .font(.system(size: eyeSize * 0.95, weight: .bold))
                .foregroundColor(MongleColor.mongglePink)
                .frame(width: eyeSize, height: eyeSize)
                .opacity(expr == .loved ? 1 : 0)
            // sad: 처진 호 + 작은 눈물 방울
            sadEye
                .opacity(expr == .sad ? 1 : 0)
            // tired: 가로 일자선
            Capsule()
                .fill(MongleColor.textPrimary)
                .frame(width: eyeSize, height: eyeSize * 0.25)
                .opacity(expr == .tired ? 1 : 0)
        }
        .frame(width: eyeSize, height: eyeSize)
        .animation(.easeInOut(duration: 0.18), value: expr)
    }

    /// happy: 위로 볼록한 반달 아치 (웃는 눈).
    private var happyEye: some View {
        let s = eyeSize
        return Canvas { ctx, canvasSize in
            let w = canvasSize.width, h = canvasSize.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.12, y: h * 0.62))
            p.addQuadCurve(
                to: CGPoint(x: w * 0.88, y: h * 0.62),
                control: CGPoint(x: w * 0.5, y: h * 0.05)
            )
            ctx.stroke(
                p,
                with: .color(MongleColor.textPrimary),
                style: StrokeStyle(lineWidth: s * 0.22, lineCap: .round)
            )
        }
        .frame(width: s, height: s)
    }

    /// sad: 아래로 볼록한 처진 호 + 작은 눈물 방울.
    private var sadEye: some View {
        let s = eyeSize
        return ZStack {
            Canvas { ctx, canvasSize in
                let w = canvasSize.width, h = canvasSize.height
                var p = Path()
                p.move(to: CGPoint(x: w * 0.12, y: h * 0.38))
                p.addQuadCurve(
                    to: CGPoint(x: w * 0.88, y: h * 0.38),
                    control: CGPoint(x: w * 0.5, y: h * 0.92)
                )
                ctx.stroke(
                    p,
                    with: .color(MongleColor.textPrimary),
                    style: StrokeStyle(lineWidth: s * 0.2, lineCap: .round)
                )
            }
            Circle()
                .fill(MongleColor.monggleBlue.opacity(0.85))
                .frame(width: s * 0.28, height: s * 0.28)
                .offset(y: s * 0.55)
        }
        .frame(width: s, height: s)
    }
}

// MARK: - Dizzy Overlay (헤롱헤롱: 머리 위 별 회전 + 본체 sway)

/// `TimelineView`로 매 프레임 sin 위상 계산 → repeatForever 의존 없이 안정적 회전.
struct DizzyOverlay: View {
    private let starCount = 3
    private let radius: CGFloat = 16

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let angle = (t * 200).truncatingRemainder(dividingBy: 360)
            ZStack {
                ForEach(0..<starCount, id: \.self) { i in
                    let baseAngle = Double(i) * (360.0 / Double(starCount))
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(MongleColor.accentOrange)
                        .offset(
                            x: radius * CGFloat(cos((baseAngle + angle) * .pi / 180)),
                            y: radius * 0.5 * CGFloat(sin((baseAngle + angle) * .pi / 180))
                        )
                }
            }
            .frame(width: radius * 2 + 12, height: radius + 12)
        }
    }
}

/// 캐릭터 본체를 좌우로 천천히 sway시키는 modifier (헤롱헤롱).
/// active 토글 시 TimelineView 분기로 구조 diff가 일어나면 invalid sample 경고를
/// 유발하므로 항상 TimelineView로 감싸고 active일 때만 회전 각도 적용.
struct DizzyWobbleModifier: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let angle = active ? sin(t * 4.5) * 12 : 0
            content
                .rotationEffect(.degrees(angle), anchor: .bottom)
        }
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

    // MG-140 — 답변/답변수정 mood 선택의 캐릭터 색이 Home/History/Search 와 동일한
    // V2Palette.mood() 단일 진실을 따르도록 통일.
    public static let defaults: [MoodOption] = [
        MoodOption(id: "calm",    emoji: "😌", label: L10n.tr("mood_calm"),    color: V2Palette.mood("calm")),
        MoodOption(id: "happy",   emoji: "😊", label: L10n.tr("mood_happy"),   color: V2Palette.mood("happy")),
        MoodOption(id: "loved",   emoji: "🥰", label: L10n.tr("mood_loved"),   color: V2Palette.mood("loved")),
        MoodOption(id: "sad",     emoji: "😢", label: L10n.tr("mood_sad"),     color: V2Palette.mood("sad")),
        MoodOption(id: "tired",   emoji: "😴", label: L10n.tr("mood_tired"),   color: V2Palette.mood("tired")),
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
    public static let defaultColor: Color = V2Palette.mood(nil)

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

public struct ShakeSample {
    public let t: Double
    public let x: CGFloat
}

public struct MongleCharacter: Identifiable {
    public let id = UUID()
    public let name: String
    public var color: Color
    public var moodId: String?           // 기분 식별자 (happy/calm/loved/sad/tired) — 탭 시 눈표정 매핑
    public var hasAnswered: Bool
    public var hasSkipped: Bool
    /// 머리/등/발밑 장식 id (상점). 본체와 함께 position/hop 으로 움직인다.
    public var headDecorationId: String?
    public var backDecorationId: String?
    public var feetDecorationId: String?
    public var position: CGPoint
    public var targetPosition: CGPoint
    public var overlapCounter: Int = 0  // 충돌 지속 프레임 수
    public var stepCount: Int = 0       // 이동 누적 스텝 수 (hop 위상 계산용)
    public var restFramesLeft: Int = 0  // 휴식 남은 프레임 수 (> 0 이면 정지)
    /// 캐릭터 hop 오프셋 캐시. body 호출마다 sin/abs 를 반복 계산하던 것을
    /// step() 1회 갱신으로 옮겨 ZStack 재평가 비용을 낮춘다.
    public var hopY: CGFloat = 0

    // MARK: 인터랙션 상태 (MG-15: 띠용 탭 + 드래그 + 흔들어 기절)
    public var isDragging: Bool = false  // 드래그 중 여부 (true이면 자동 이동 skip)
    public var shakeBuffer: [ShakeSample] = []  // 흔들기 감지용 x좌표 샘플 버퍼
    public var isFainted: Bool = false
    public var faintFramesLeft: Int = 0  // 기절 남은 프레임 수 (interval 기준)
    /// 탭 후 이동 정지 종료 시각 (시간 기반 — 프레임 드롭/re-render 에 영향받지 않게).
    public var actEndAt: Date? = nil
    public var interactionMood: String? = nil
    /// 마지막으로 movement가 진행된(또는 의도적으로 리셋된) 시각. Watchdog 정체 감지용.
    public var lastMovedAt: Date = Date()

    public var isActing: Bool {
        guard let endAt = actEndAt else { return false }
        return Date() < endAt
    }

    public init(name: String, color: Color, moodId: String? = nil, hasAnswered: Bool, hasSkipped: Bool = false, headDecorationId: String? = nil, backDecorationId: String? = nil, feetDecorationId: String? = nil, position: CGPoint, targetPosition: CGPoint) {
        self.name = name
        self.color = color
        self.moodId = moodId
        self.hasAnswered = hasAnswered
        self.hasSkipped = hasSkipped
        self.headDecorationId = headDecorationId
        self.backDecorationId = backDecorationId
        self.feetDecorationId = feetDecorationId
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
    /// 머리/등/발밑 슬롯 장식 id (상점). nil 이면 해당 슬롯 장식 없음.
    public let headDecorationId: String?
    public let backDecorationId: String?
    public let feetDecorationId: String?
    public let hasCurrentUserAnswered: Bool
    public let hasCurrentUserSkipped: Bool
    public let isCurrentUser: Bool
    public let onViewAnswer: () -> Void
    public let onNudge: () -> Void
    public let onSelfTap: () -> Void

    public let onAnswerFirstToView: (String) -> Void
    public let onAnswerFirstToNudge: (String) -> Void

    /// 흔들어 기절 중 여부. true면 띠용 탭/handleTap 무시 + DizzyOverlay 표시 + 본체 sway.
    public var isFainted: Bool = false
    /// 탭 액션 재생 중 여부. MongleSceneView 가 시간 기반으로 토글.
    public var isActing: Bool = false
    /// 탭 액션 중 적용할 눈 표정 (mood 기반). acting 아닐 땐 .neutral.
    public var eyeExpression: EyeExpression = .neutral
    /// 탭 순간 상위 Scene에 알려주는 콜백 (scene이 acting 상태로 전환).
    public var onTapInteract: () -> Void = {}

    // 찌부(squish) one-shot 인터랙션 상태 (짧은 탭 "띠용" 피드백)
    @State private var isPressed: Bool = false

    public init(name: String, color: Color, hasAnswered: Bool,
                hasSkipped: Bool = false,
                headDecorationId: String? = nil,
                backDecorationId: String? = nil,
                feetDecorationId: String? = nil,
                hasCurrentUserAnswered: Bool,
                hasCurrentUserSkipped: Bool = false,
                isCurrentUser: Bool = false,
                isFainted: Bool = false,
                isActing: Bool = false,
                eyeExpression: EyeExpression = .neutral,
                onViewAnswer: @escaping () -> Void,
                onNudge: @escaping () -> Void,
                onSelfTap: @escaping () -> Void = {},
                onAnswerFirstToView: @escaping (String) -> Void = { _ in },
                onAnswerFirstToNudge: @escaping (String) -> Void = { _ in },
                onTapInteract: @escaping () -> Void = {}) {
        self.name = name
        self.color = color
        self.hasAnswered = hasAnswered
        self.hasSkipped = hasSkipped
        self.headDecorationId = headDecorationId
        self.backDecorationId = backDecorationId
        self.feetDecorationId = feetDecorationId
        self.hasCurrentUserAnswered = hasCurrentUserAnswered
        self.hasCurrentUserSkipped = hasCurrentUserSkipped
        self.isCurrentUser = isCurrentUser
        self.isFainted = isFainted
        self.isActing = isActing
        self.eyeExpression = eyeExpression
        self.onViewAnswer = onViewAnswer
        self.onNudge = onNudge
        self.onSelfTap = onSelfTap
        self.onAnswerFirstToView = onAnswerFirstToView
        self.onAnswerFirstToNudge = onAnswerFirstToNudge
        self.onTapInteract = onTapInteract
    }

    /// 한 번 짧게 squish 후 복귀하는 "띠용" 액션
    private func playSquish() {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.45)) {
            isPressed = true
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.55)) {
                isPressed = false
            }
        }
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
        // MG-120 — 본인 캐릭터는 이름 옆에 "(나)" suffix 를 붙여 status badge 색상에
        // 더해 즉시 식별 가능하게 한다.
        let displayName = isCurrentUser ? "\(name) \(L10n.tr("home_member_me_suffix"))" : name
        VStack(spacing: 4) {
            statusBadge
            // MG-150 — V2 톤(둥근 몸체 + 흰테 눈 + dropshadow + 본인 ring) 을 인라인으로 그린다.
            // MG-15 — 흔들어 기절 시 본체 sway(DizzyWobble) + 머리 위 별(DizzyOverlay).
            ZStack {
                v2CharacterBody
                    .modifier(DizzyWobbleModifier(active: isFainted))
                if isFainted {
                    DizzyOverlay()
                        .offset(y: -40)
                }
            }
            Text(displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MongleColor.textPrimary)
        }
        // 찌부(띠용) 효과: 탭하면 잠깐 납작해짐
        .scaleEffect(
            x: isPressed ? 1.15 : 1.0,
            y: isPressed ? 0.7 : 1.0,
            anchor: .bottom
        )
        .offset(y: isPressed ? 8 : 0)
        .accessibilityAddTraits(.isButton)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isFainted else { return }
            playSquish()
            onTapInteract()
            handleTap()
        }
    }

    /// 캐릭터 본체 + 눈 + (본인일 때) ring. 컨테이너 70x70 (ring 포함).
    /// 본체/눈/그림자는 공지사항 화면과 동일하게 보이도록 `MongleMonggle` 을 그대로 사용한다
    /// (공지사항 캐릭터가 기준). 본인 식별용 mint ring 만 home 전용으로 덧그린다.
    private var v2CharacterBody: some View {
        let bodySize: CGFloat = 56
        let container: CGFloat = bodySize + 14   // 70 (본인 ring 포함 본체 footprint)
        // 장착 시에만 위/아래 여유를 둔다(미장착=컴팩트). 머리 장식이 상단 "답변" 배지와
        // 겹치지 않도록 headRoom 만큼 본체를 아래로 내려 배지와 분리한다.
        // aboveHead(후광)는 머리 위로 더 띄우므로 여유를 더 준다. hand(풍선)는 좌우로 나가지만
        // 위쪽 여유는 head 와 비슷하게.
        let headAnchor: DecorationAnchor? = headDecorationId.map { DecorationCatalog.placement(for: $0).anchor }
        let headRoom: CGFloat = headDecorationId == nil ? 0 : (headAnchor == .aboveHead ? 34 : 24)
        let feetRoom: CGFloat = feetDecorationId != nil ? 14 : 0
        return ZStack {
            // 등(back) 장식 — 본체 뒤에 먼저 그려 zIndex 가 본체보다 뒤. 본체보다 크게 그려
            // 실루엣 밖으로 삐져나와 보이게 한다(살짝 아래로 내려 날개=양옆, 망토=아래로).
            if let backDecorationId {
                DecorationCatalog.backView(for: backDecorationId, bodySize: bodySize)
                    .offset(y: bodySize * 0.12)
                    .allowsHitTesting(false)
            }
            if isCurrentUser {
                Circle()
                    .strokeBorder(V2Palette.mint, lineWidth: 2)
                    .frame(width: container, height: container)
            }
            MongleMonggle(color: color, size: bodySize, isFainted: isFainted, eyeExpression: eyeExpression)
            // 발밑(feet) 장식 — 본체 하단에 얹는다.
            if let feetDecorationId {
                DecorationCatalog.feetView(for: feetDecorationId)
                    .offset(y: bodySize * 0.5)
                    .allowsHitTesting(false)
            }
            // 머리계열(head/aboveHead/hand) 장식 — placement.anchor 로 위치 분기.
            // 같은 ZStack 이라 걷기/hop 시 함께 이동. id→뷰는 DecorationCatalog(headView) 공유.
            if let headDecorationId {
                let placement = DecorationCatalog.placement(for: headDecorationId)
                let base = homeHeadBaseline(placement.anchor, bodySize: bodySize)
                DecorationCatalog.headView(for: headDecorationId)
                    .scaleEffect(placement.scale)
                    .offset(x: base.width + placement.offset.width * bodySize,
                            y: base.height + placement.offset.height * bodySize)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: container, height: container)
        .padding(.top, headRoom)
        .padding(.bottom, feetRoom)
    }

    /// 앵커별 head 계열 baseline 오프셋 (home 좌표 기준, bodySize 비례).
    private func homeHeadBaseline(_ anchor: DecorationAnchor, bodySize: CGFloat) -> CGSize {
        switch anchor {
        case .onHead:    return CGSize(width: 0, height: -bodySize * 0.5)    // 현행
        case .aboveHead: return CGSize(width: 0, height: -bodySize * 0.56)   // 머리 위로 살짝 띄움(onHead -0.5 대비)
        case .hand:      return CGSize(width: bodySize * 0.58, height: -bodySize * 0.18) // 측면 손(위로 든 풍선)
        case .back, .feet: return CGSize(width: 0, height: -bodySize * 0.5)  // 안전 기본
        }
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
    /// 기분 식별자 (happy/calm/loved/sad/tired). 탭 시 눈표정 매핑에 사용 (MG-15).
    public let moodId: String?
    public let hasAnswered: Bool
    public let hasSkipped: Bool
    /// 머리/등/발밑 슬롯에 장착된 장식 id (상점). nil 이면 장식 없음. 현재는 본인 멤버만 주입한다.
    public let headDecorationId: String?
    public let backDecorationId: String?
    public let feetDecorationId: String?

    public init(id: UUID, name: String, color: Color, moodId: String? = nil, hasAnswered: Bool, hasSkipped: Bool, headDecorationId: String? = nil, backDecorationId: String? = nil, feetDecorationId: String? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.moodId = moodId
        self.hasAnswered = hasAnswered
        self.hasSkipped = hasSkipped
        self.headDecorationId = headDecorationId
        self.backDecorationId = backDecorationId
        self.feetDecorationId = feetDecorationId
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

    /// 바텀시트 dismiss 등 외부 이벤트로 이동 재개가 필요한 시점에 parent가 값을 변경.
    /// 이 값이 바뀌면 모든 캐릭터 state를 강제로 리셋해 이동을 재개한다 (MG-18).
    public var resumeSignal: Int = 0

    // 60fps tick으로 동작. 이전 0.16s + withAnimation linear 보간 방식이 ForEach 내
    // 다른 캐릭터 mutation과 같은 transaction에 묶여 드래그/흔들기 시 invalid sample
    // 경고를 유발했기 때문(MG-15). 각 프레임에서 position을 직접 갱신해 어떤 animation
    // transaction에도 의존하지 않는다.
    private let stepSize: CGFloat = 0.3
    private let interval: TimeInterval = 1.0 / 60.0
    private let collisionRadius: CGFloat = 76
    private let targetThreshold: CGFloat = 12
    private let wallPadding: CGFloat = 50
    // 60fps 환경에서 frame 단위 카운터 재조정 (이전 0.12s 환경의 ×7.2 ≈ 60)
    private let overlapLimit: Int = 60
    // 탭 후 이동 정지 시간
    private let tapActDuration: TimeInterval = 1.5
    // Watchdog: 이 시간 이상 움직임 없으면 강제 이동 재개
    private let stuckTimeout: TimeInterval = 2.0
    /// 드래그 좌표 기준 named coordinate space. 제스처를 .position 앞에 스코프해도
    /// drag.location 이 scene(GeometryReader) 좌표로 들어오게 한다.
    private static let sceneSpace = "mongleScene"

    @State private var mongles: [MongleCharacter] = []
    @State private var timer: Timer?
    /// scenePhase 가 .active 가 아니면 Timer 를 invalidate 하여 백그라운드 CPU 점유를 막는다.
    /// NavigationStack push 등으로 onDisappear 가 즉시 fire 되지 않는 케이스에서도 유효.
    @Environment(\.scenePhase) private var scenePhase
    /// 드래그 종료 시각. drag onEnded 직후 inner `.onTapGesture`가 동시 발동해
    /// acting(1.5초 정지)으로 진입하는 부작용을 막기 위한 가드. 이 window 내 tap은 무시.
    @State private var recentDragEndAt: [UUID: Date] = [:]
    private let dragTapIgnoreWindow: TimeInterval = 0.4

    // 게스트 "둘러보기" / 멤버 미로딩 시 폴백 데모 캐릭터.
    // 색은 기록(History) 화면의 색 매핑과 동일하게 맞춘다 — HistoryView 의
    // indexToMoodId = [calm, happy, loved, sad, tired] 순서를 그대로 따라 V2Palette.mood 로
    // 칠한다. moodId 도 같은 값으로 주어 탭 시 눈표정이 색과 일치하게 한다(MG-15).
    private static let defaultMemberData: [MongleMember] = [
        MongleMember(id: UUID(), name: "Dad",  color: V2Palette.mood("calm"),  moodId: "calm",  hasAnswered: true,  hasSkipped: false),
        MongleMember(id: UUID(), name: "Mom",  color: V2Palette.mood("happy"), moodId: "happy", hasAnswered: false, hasSkipped: false),
        MongleMember(id: UUID(), name: "Lily", color: V2Palette.mood("loved"), moodId: "loved", hasAnswered: true,  hasSkipped: false),
        MongleMember(id: UUID(), name: "Ben",  color: V2Palette.mood("sad"),   moodId: "sad",   hasAnswered: false, hasSkipped: false),
        MongleMember(id: UUID(), name: "Alex", color: V2Palette.mood("tired"), moodId: "tired", hasAnswered: true,  hasSkipped: false)
    ]

    public init(hasCurrentUserAnswered: Bool = false,
                hasCurrentUserSkipped: Bool = false,
                members: [MongleMember] = [],
                currentUserName: String? = nil,
                resumeSignal: Int = 0,
                onViewAnswer: @escaping (String) -> Void = { _ in },
                onNudge: @escaping (String) -> Void = { _ in },
                onSelfTap: @escaping () -> Void = {},
                onAnswerFirstToView: @escaping (String) -> Void = { _ in },
                onAnswerFirstToNudge: @escaping (String) -> Void = { _ in }) {
        self.hasCurrentUserAnswered = hasCurrentUserAnswered
        self.hasCurrentUserSkipped = hasCurrentUserSkipped
        self.members = members
        self.currentUserName = currentUserName
        self.resumeSignal = resumeSignal
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
                        headDecorationId: h.headDecorationId,
                        backDecorationId: h.backDecorationId,
                        feetDecorationId: h.feetDecorationId,
                        hasCurrentUserAnswered: hasCurrentUserAnswered,
                        hasCurrentUserSkipped: hasCurrentUserSkipped,
                        isCurrentUser: currentUserName != nil && h.name == currentUserName,
                        isFainted: h.isFainted,
                        isActing: h.isActing,
                        eyeExpression: h.isActing
                            ? EyeExpression.forMood(h.interactionMood ?? h.moodId)
                            : .neutral,
                        onViewAnswer: { onViewAnswer(h.name) },
                        onNudge: { onNudge(h.name) },
                        onSelfTap: onSelfTap,
                        onAnswerFirstToView: onAnswerFirstToView,
                        onAnswerFirstToNudge: onAnswerFirstToNudge,
                        onTapInteract: { triggerTap(id: h.id) }
                    )
                    .scaleEffect(h.isDragging ? 1.1 : 1.0)
                    .shadow(color: h.isDragging ? Color.black.opacity(0.25) : Color.clear,
                            radius: h.isDragging ? 12 : 0, x: 0, y: 6)
                    // 제스처를 .position 앞에 둬 히트영역을 "캐릭터 본체 크기"로 스코프한다.
                    // (.position 뒤에 붙이면 뷰가 부모 전체를 채워 제스처가 화면 전체를
                    //  잡아 다른 캐릭터/오버레이와 충돌 → 드래그가 엉뚱한 캐릭터로 가거나
                    //  안 먹는다.) 좌표는 named coordinateSpace 로 scene 기준 고정.
                    // simultaneousGesture로 두어 MongleView 내부 `.onTapGesture`가 짧은
                    // 탭에서도 반드시 발동되게 한다 (`.gesture`는 outer/inner 경합으로 흡수됨).
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.12)
                            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.sceneSpace)))
                            .onChanged { value in
                                guard let idx = mongles.firstIndex(where: { $0.id == h.id }) else { return }
                                if mongles[idx].isFainted { return }
                                switch value {
                                case .first(true):
                                    if !mongles[idx].isDragging {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                            mongles[idx].isDragging = true
                                        }
                                        mongles[idx].shakeBuffer.removeAll()
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                case .second(true, let drag):
                                    if let drag = drag {
                                        let newX = min(max(drag.location.x, wallPadding), geo.size.width - wallPadding)
                                        let newY = min(max(drag.location.y, wallPadding), geo.size.height - wallPadding)
                                        // 드래그 중 position 갱신은 어떤 애니메이션 컨텍스트에도
                                        // 휘말리지 않도록 명시적으로 disable.
                                        var t = Transaction()
                                        t.disablesAnimations = true
                                        withTransaction(t) {
                                            mongles[idx].position = CGPoint(x: newX, y: newY)
                                        }
                                        mongles[idx].lastMovedAt = Date()
                                        detectShake(idx: idx, sampleX: drag.location.x)
                                    }
                                default:
                                    break
                                }
                            }
                            .onEnded { _ in
                                guard let idx = mongles.firstIndex(where: { $0.id == h.id }) else { return }
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                    mongles[idx].isDragging = false
                                }
                                mongles[idx].shakeBuffer.removeAll()
                                // 직후 발동될 수 있는 tap gesture가 acting에 진입하지 않도록 기록.
                                recentDragEndAt[h.id] = Date()
                                if !mongles[idx].isFainted {
                                    // acting/rest 잔여 상태 정리 후 즉시 이동 재개.
                                    mongles[idx].actEndAt = nil
                                    mongles[idx].interactionMood = nil
                                    mongles[idx].restFramesLeft = 0
                                    mongles[idx].overlapCounter = 0
                                    mongles[idx].targetPosition = farRandomPos(
                                        from: mongles[idx].position, size: geo.size)
                                    mongles[idx].lastMovedAt = Date()
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                    )
                    // 60fps 직접 position 갱신 — withAnimation 보간 없이 부드럽다(MG-15).
                    .position(CGPoint(x: h.position.x, y: h.position.y + h.hopY))
                }
            }
            .coordinateSpace(.named(Self.sceneSpace))
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
            .onChange(of: resumeSignal) { _, _ in
                // 바텀시트 dismiss 등 외부 신호 수신. 모든 캐릭터 state를 강제 정상화해
                // 이동 재개 — 시트 present 중 timer/state가 꼬인 경우 복구(MG-18).
                guard geo.size.width > 0, geo.size.height > 0 else { return }
                let now = Date()
                for i in mongles.indices {
                    guard !mongles[i].isFainted else { continue }
                    mongles[i].actEndAt = nil
                    mongles[i].interactionMood = nil
                    mongles[i].restFramesLeft = 0
                    mongles[i].overlapCounter = 0
                    mongles[i].isDragging = false
                    mongles[i].targetPosition = farRandomPos(from: mongles[i].position, size: geo.size)
                    mongles[i].lastMovedAt = now
                }
                if timer == nil { startTimer(size: geo.size) }
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
                    if mongles[i].moodId != member.moodId {
                        mongles[i].moodId = member.moodId
                    }
                    if mongles[i].headDecorationId != member.headDecorationId {
                        mongles[i].headDecorationId = member.headDecorationId
                    }
                    if mongles[i].backDecorationId != member.backDecorationId {
                        mongles[i].backDecorationId = member.backDecorationId
                    }
                    if mongles[i].feetDecorationId != member.feetDecorationId {
                        mongles[i].feetDecorationId = member.feetDecorationId
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
                moodId: member.moodId,
                hasAnswered: member.hasAnswered,
                hasSkipped: member.hasSkipped,
                headDecorationId: member.headDecorationId,
                backDecorationId: member.backDecorationId,
                feetDecorationId: member.feetDecorationId,
                position: pos,
                targetPosition: randomPos(size: size)
            )
        }
    }

    /// 캐릭터 탭 시 1.5초 동안 이동을 정지하고 mood 기반 눈 표정을 재생.
    /// 연타 시엔 타이머를 리셋 (responsive feel).
    private func triggerTap(id: UUID) {
        guard let idx = mongles.firstIndex(where: { $0.id == id }) else { return }
        guard !mongles[idx].isFainted else { return }
        // 드래그 중에는 탭 이벤트 무시.
        guard !mongles[idx].isDragging else { return }
        // 드래그 직후(window 내)엔 동반 발동된 tap gesture를 무시해 acting 진입 방지.
        if let endedAt = recentDragEndAt[id],
           Date().timeIntervalSince(endedAt) < dragTapIgnoreWindow {
            return
        }
        let now = Date()
        mongles[idx].actEndAt = now.addingTimeInterval(tapActDuration)
        mongles[idx].interactionMood = mongles[idx].moodId
        mongles[idx].restFramesLeft = 0
        mongles[idx].overlapCounter = 0
        mongles[idx].shakeBuffer.removeAll()
        // 탭은 의도적 이벤트 — watchdog 기준점도 업데이트해 1.5초 정지를 정상으로 인정.
        mongles[idx].lastMovedAt = now
    }

    /// `current` 에서 최소 `collisionRadius * 1.5` 이상 떨어진 무작위 지점을 반환.
    /// acting 복귀 시 현재 위치와 가까운 target이 뽑혀 바로 rest로 빠지는 것을 방지.
    private func farRandomPos(from current: CGPoint, size: CGSize) -> CGPoint {
        let minDist = collisionRadius * 1.5
        for _ in 0..<20 {
            let candidate = randomPos(size: size)
            if hypot(candidate.x - current.x, candidate.y - current.y) >= minDist {
                return candidate
            }
        }
        return randomPos(size: size)
    }

    /// 위치 샘플 버퍼 기반 흔들기 감지 (MG-15).
    /// 일반 드래그(곡선 경로 포함)가 오인되지 않도록:
    /// - 드래그 시작 직후 0.25초 동안은 감지 skip (의도적 흔들기 진입 시간 확보)
    /// - 0.5초 윈도우에서 방향 반전 ≥4, 진폭 range ≥80pt 충족 시에만 기절
    private func detectShake(idx: Int, sampleX: CGFloat) {
        let now = Date().timeIntervalSince1970
        var buf = mongles[idx].shakeBuffer
        buf.append(ShakeSample(t: now, x: sampleX))
        buf = buf.filter { now - $0.t <= 0.5 }
        mongles[idx].shakeBuffer = buf

        guard buf.count >= 6 else { return }
        guard let firstT = buf.first?.t, now - firstT >= 0.25 else { return }

        var changes = 0
        var lastDir = 0
        for i in 1..<buf.count {
            let dx = buf[i].x - buf[i-1].x
            let dir = dx > 2.0 ? 1 : (dx < -2.0 ? -1 : 0)
            if dir != 0 && lastDir != 0 && dir != lastDir {
                changes += 1
            }
            if dir != 0 { lastDir = dir }
        }

        let xs = buf.map { $0.x }
        let range = (xs.max() ?? 0) - (xs.min() ?? 0)

        if changes >= 4 && range >= 80 {
            mongles[idx].isFainted = true
            mongles[idx].faintFramesLeft = Int(2.5 / interval)
            mongles[idx].isDragging = false
            mongles[idx].shakeBuffer.removeAll()
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
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
        // `.common` 모드로 runloop에 부착해 제스처/스크롤 등 tracking 모드 중에도
        // timer가 멈추지 않고 step()을 계속 호출하도록 한다(MG-15). `.default` 전용일 때
        // 탭/드래그 후 runloop가 tracking으로 전환되면 countdown이 정체돼 복귀가 지연됨.
        let t = Timer(timeInterval: interval, repeats: true) { _ in
            step(size: size)
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func step(size: CGSize) {
        let now = Date()
        for i in mongles.indices {
            // === Watchdog ===
            // 드래그/기절이 아닌데 stuckTimeout 이상 움직임이 없으면 어떤 상태에 갇혔든
            // 강제 리셋해 이동 재개. (acting의 1.5초 정지는 lastMovedAt을 탭 시점으로
            // 갱신하므로 2초 타임아웃에 걸리지 않음.)
            if !mongles[i].isFainted && !mongles[i].isDragging {
                if now.timeIntervalSince(mongles[i].lastMovedAt) > stuckTimeout {
                    mongles[i].actEndAt = nil
                    mongles[i].interactionMood = nil
                    mongles[i].restFramesLeft = 0
                    mongles[i].overlapCounter = 0
                    mongles[i].targetPosition = farRandomPos(from: mongles[i].position, size: size)
                    mongles[i].lastMovedAt = now
                    continue
                }
            }

            // 기절 중: 카운트다운만 진행 (hop 정지)
            if mongles[i].isFainted {
                mongles[i].hopY = 0
                mongles[i].faintFramesLeft -= 1
                if mongles[i].faintFramesLeft <= 0 {
                    mongles[i].isFainted = false
                    mongles[i].faintFramesLeft = 0
                    mongles[i].targetPosition = randomPos(size: size)
                    mongles[i].lastMovedAt = now
                }
                continue
            }
            // 탭 액션 재생 중(시간 기반): 위치·hop 고정.
            if mongles[i].isActing {
                mongles[i].hopY = 0
                continue
            }
            // 탭 액션이 방금 끝난 프레임: state 정리 + 이동 target 갱신 + 복귀.
            if mongles[i].actEndAt != nil {
                mongles[i].actEndAt = nil
                mongles[i].interactionMood = nil
                mongles[i].restFramesLeft = 0
                mongles[i].overlapCounter = 0
                mongles[i].isDragging = false
                mongles[i].targetPosition = farRandomPos(from: mongles[i].position, size: size)
                mongles[i].lastMovedAt = now
                continue
            }
            // 드래그 중: 자동 이동 skip (hop 정지)
            if mongles[i].isDragging {
                mongles[i].hopY = 0
                continue
            }

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
                    // 60fps 기준 휴식 프레임 수 (이전 0.16s 환경의 10~50 ×3.75 ≈ 60~360)
                    mongles[i].restFramesLeft = Int.random(in: 60...360)
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

            // 60fps + stepSize 0.3 환경에서 드래그 후 다른 캐릭터 옆에 떨어지면 모든
            // 방향이 collisionRadius 안이라 어떤 step도 거부되어 정지함.
            // → 충돌 영역 안이라도 "멀어지는 방향"은 허용. 가까워지는 진입만 거부.
            let collides = mongles.indices.contains { j in
                guard j != i else { return false }
                let oldDist = hypot(mongles[i].position.x - mongles[j].position.x,
                                    mongles[i].position.y - mongles[j].position.y)
                let newDist = hypot(pos.x - mongles[j].position.x,
                                    pos.y - mongles[j].position.y)
                return newDist < collisionRadius && newDist <= oldDist
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
            mongles[i].lastMovedAt = now
            // hopY 캐싱: body 재평가마다 sin/abs 반복 호출하던 것을 step 시점으로 이동.
            // 60fps tick 기준 hop 주기 ≈1.2s 유지: π / 36.
            mongles[i].hopY = -abs(sin(CGFloat(mongles[i].stepCount) * .pi / 36.0)) * 12
        }
    }
}
