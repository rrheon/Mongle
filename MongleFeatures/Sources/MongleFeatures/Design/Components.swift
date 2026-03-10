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
                    colors: [Color(hex: "6BBF93"), Color(hex: "7BC8A0")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color(hex: "6BBF93").opacity(0.2), radius: 12, x: 0, y: 4)
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
            .shadow(color: Color(hex: "D4A090").opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }
}

/// component/Button/Ghost — no background, gray text
public struct MongleButtonGhost: View {
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
                        .foregroundColor(MongleColor.textSecondary)
                }
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MongleColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
    }
}

/// component/Button/SmallPill — compact gradient pill
public struct MongleButtonSmallPill: View {
    let label: String
    var action: () -> Void

    public init(_ label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(MongleFont.captionBold())
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 32)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "6BBF93"), Color(hex: "7BC8A0")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
        }
    }
}

/// component/Button/SmallOutline — compact outline pill
public struct MongleButtonSmallOutline: View {
    let label: String
    var action: () -> Void

    public init(_ label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MongleColor.textSecondary)
                .padding(.horizontal, 16)
                .frame(height: 32)
                .background(Color.white.opacity(0.8))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(MongleColor.border, lineWidth: 1))
        }
    }
}

/// component/Button/CTA — large full-width gradient pill with icon
public struct MongleButtonCTA: View {
    let label: String
    var icon: String? = "book.fill"
    var action: () -> Void

    public init(_ label: String, icon: String? = "book.fill", action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                Text(label)
                    .font(MongleFont.button())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color(hex: "6BBF93"), Color(hex: "7BC8A0")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color(hex: "6BBF93").opacity(0.25), radius: 16, x: 0, y: 6)
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
        .shadow(color: Color(hex: "D4A090").opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

/// component/Input/TextArea — multi-line text area
public struct MongleInputTextArea: View {
    let placeholder: String
    @Binding var text: String

    public init(placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textHint)
                    .padding(16)
            }
            TextEditor(text: $text)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(12)
        }
        .frame(minHeight: 120)
        .background(Color.white)
        .cornerRadius(MongleRadius.medium)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.medium).stroke(MongleColor.border, lineWidth: 1))
        .shadow(color: Color(hex: "D4A090").opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Badges

/// component/Badge/Level — peach pill "Lv.N Name"
public struct MongleBadgeLevel: View {
    let level: Int
    let name: String

    public init(level: Int, name: String) {
        self.level = level
        self.name = name
    }

    public var body: some View {
        HStack(spacing: 4) {
            Text("Lv.\(level)")
                .font(MongleFont.captionBold())
                .foregroundColor(Color(hex: "F5978E"))
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "F5978E"))
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(Color(hex: "FFE5D9"))
        .clipShape(Capsule())
    }
}

/// component/Badge/Streak — gradient pill "🔥 N Days Streak"
public struct MongleBadgeStreak: View {
    let days: Int

    public init(days: Int) {
        self.days = days
    }

    public var body: some View {
        HStack(spacing: 6) {
            Text("🔥")
                .font(.system(size: 14))
            Text("\(days) Days")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
            Text("Streak")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(
            LinearGradient(
                colors: [Color(hex: "F5978E"), Color(hex: "F7B4A0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
        .shadow(color: Color(hex: "F5978E").opacity(0.2), radius: 8, x: 0, y: 2)
    }
}

/// component/Badge/Answered — green pill "✓ 답변하기"
public struct MongleBadgeAnswered: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
            Text("답변 완료")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(
            LinearGradient(
                colors: [Color(hex: "6BBF93"), Color(hex: "7BC8A0")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(Capsule())
    }
}

/// component/Badge/Pending — gray outline pill "미답변"
public struct MongleBadgePending: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 10))
                .foregroundColor(MongleColor.textHint)
            Text("미답변")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MongleColor.textHint)
        }
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(Color.white.opacity(0.8))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(MongleColor.border, lineWidth: 1))
    }
}

/// component/NotificationDot — red circle indicator
public struct MongleNotificationDot: View {
    public init() {}

    public var body: some View {
        Circle()
            .fill(MongleColor.notificationDot)
            .frame(width: 10, height: 10)
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
                        .fill(Color(hex: "1A1A1A"))
                        .frame(width: eyeSize, height: eyeSize)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    Circle()
                        .fill(Color(hex: "1A1A1A"))
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
}

// MARK: - XP Bar

/// component/XPBar — level badge + "current/total XP" + progress track
public struct MongleXPBar: View {
    let level: Int
    let levelName: String
    let current: Int
    let total: Int

    public init(level: Int, levelName: String, current: Int, total: Int) {
        self.level = level
        self.levelName = levelName
        self.current = current
        self.total = total
    }

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return min(CGFloat(current) / CGFloat(total), 1.0)
    }

    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                MongleBadgeLevel(level: level, name: levelName)
                Spacer()
                Text("\(current) / \(total) XP")
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "C2E8D4"))
                        .frame(height: 8)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "5BAF85"), Color(hex: "7BC8A0")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Cards

/// component/Card/Question — glass card with emoji, label, question text
public struct MongleCardQuestion: View {
    let question: String
    var emoji: String = "🌿"
    var label: String = "Today's Question"
    var onTap: (() -> Void)? = nil

    public init(question: String, emoji: String = "🌿", label: String = "Today's Question", onTap: (() -> Void)? = nil) {
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
                        .foregroundColor(Color(hex: "5BAF85"))
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
            .shadow(color: Color(hex: "D4A090").opacity(0.12), radius: 16, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

// MARK: component/Card/Glass — generic glass container card

public struct MongleCardGlass<Content: View>: View {
    let title: String
    var description: String? = nil
    @ViewBuilder let content: Content

    public init(title: String, description: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MongleColor.textPrimary)
                    .kerning(-0.2)
                if let description {
                    Text(description)
                        .font(MongleFont.body2())
                        .foregroundColor(MongleColor.textSecondary)
                        .lineSpacing(4)
                }
            }
            content
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .cornerRadius(MongleRadius.xl)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: Color(hex: "D4A090").opacity(0.12), radius: 20, x: 0, y: 4)
    }
}
// MARK: MongleCardGroup

public struct MongleCardGroup: View {
    let groupName: String
    let memberColors: [Color]
    var streakDays: Int? = nil
    var onTap: (() -> Void)? = nil

    public init(
        groupName: String,
        memberColors: [Color],
        streakDays: Int? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.groupName = groupName
        self.memberColors = memberColors
        self.streakDays = streakDays
        self.onTap = onTap
    }

    public var body: some View {
        Button { onTap?() } label: {
            VStack(alignment: .leading, spacing: 12) {
                Text(groupName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MongleColor.textPrimary)

                HStack {
                    HStack(spacing: -10) {
                        ForEach(memberColors.indices, id: \.self) { i in
                            MongleMonggle(color: memberColors[i], size: 36)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2).frame(width: 36, height: 36))
                                .zIndex(Double(memberColors.count - i))
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MongleColor.textHint)
                }

                if let streakDays {
                    Text("\(streakDays)일 연속")
                        .font(MongleFont.captionBold())
                        .foregroundColor(MongleColor.primary)
                        .padding(.horizontal, MongleSpacing.sm)
                        .padding(.vertical, 3)
                        .background(MongleColor.primaryLight)
                        .clipShape(Capsule())
                }
            }
            .padding(20)
            .background(MongleColor.cardGlass)
            .cornerRadius(MongleRadius.xl)
            .overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(MongleColor.border, lineWidth: 1))
            .shadow(color: Color(hex: "D4A090").opacity(0.12), radius: 20, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

/// component/Card/Emotion — compact emotion history card
public struct MongleCardEmotion: View {
    let date: String
    let mood: String
    var gradientColors: [Color] = [Color(hex: "F7B4A0"), Color(hex: "C2E8D4")]

    public init(date: String, mood: String, gradientColors: [Color] = [Color(hex: "F7B4A0"), Color(hex: "C2E8D4")]) {
        self.date = date
        self.mood = mood
        self.gradientColors = gradientColors
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: gradientColors,
                        center: .center,
                        startRadius: 0,
                        endRadius: 24
                    )
                )
                .frame(width: 48, height: 48)
                .blur(radius: 6)

            VStack(spacing: 2) {
                Text(date)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MongleColor.textPrimary)
                Text(mood)
                    .font(.system(size: 11))
                    .foregroundColor(MongleColor.textSecondary)
            }
        }
        .padding(16)
        .frame(width: 160)
        .background(.ultraThinMaterial)
        .cornerRadius(MongleRadius.xl)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: Color(hex: "D4A090").opacity(0.12), radius: 16, x: 0, y: 4)
    }
}

// MARK: - Settings List Item

/// component/ListItem/Settings — icon + title/desc + chevron
public struct MongleListItemSettings: View {
    public enum Trailing {
        case chevron
        case toggle(Binding<Bool>)
        case none
    }

    let iconName: String
    let iconColor: Color
    let iconBg: Color
    let title: String
    var description: String? = nil
    var trailing: Trailing = .chevron
    var action: (() -> Void)? = nil

    public init(
        iconName: String,
        iconColor: Color,
        iconBg: Color,
        title: String,
        description: String? = nil,
        trailing: Trailing = .chevron,
        action: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.iconBg = iconBg
        self.title = title
        self.description = description
        self.trailing = trailing
        self.action = action
    }

    public var body: some View {
        Button { action?() } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: MongleRadius.medium)
                        .fill(iconBg)
                        .frame(width: 36, height: 36)
                    Image(systemName: iconName)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MongleColor.textPrimary)
                    if let description {
                        Text(description)
                            .font(MongleFont.caption())
                            .foregroundColor(MongleColor.textHint)
                    }
                }

                Spacer()

                switch trailing {
                case .chevron:
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18))
                        .foregroundColor(MongleColor.textHint)
                case .toggle(let binding):
                    Toggle("", isOn: binding)
                        .tint(MongleColor.primary)
                        .labelsHidden()
                case .none:
                    EmptyView()
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(MongleRadius.large)
        }
        .buttonStyle(.plain)
        .disabled(action == nil && { if case .toggle = trailing { return false }; return true }())
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
        MoodOption(id: "happy",   emoji: "😊", label: "행복",  color: MongleColor.moodHappy),
        MoodOption(id: "calm",    emoji: "😌", label: "평온",  color: MongleColor.moodCalm),
        MoodOption(id: "loved",   emoji: "🥰", label: "사랑",  color: MongleColor.moodLoved),
        MoodOption(id: "sad",     emoji: "😢", label: "우울",  color: MongleColor.moodSad),
        MoodOption(id: "tired",   emoji: "😴", label: "지침",  color: MongleColor.moodTired),
    ]
}

/// component/MoodSelector — glass card with row of mood balls
public struct MongleMoodSelector: View {
    let moods: [MoodOption]
    @Binding var selected: MoodOption?

    public init(moods: [MoodOption] = MoodOption.defaults, selected: Binding<MoodOption?>) {
        self.moods = moods
        self._selected = selected
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("오늘의 기분은?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MongleColor.textPrimary)
                Text("기분에 따라 몽글의 색이 변해요")
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }

            HStack {
                ForEach(moods) { mood in
                    Spacer()
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(mood.color)
                                .frame(width: 44, height: 44)
                                .shadow(color: mood.color.opacity(0.33), radius: 10, x: 0, y: 3)

                            if selected == mood {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2.5)
                                    .frame(width: 44, height: 44)
                            }
                        }

                        Text(mood.emoji)
                            .font(.system(size: 14))
                        Text(mood.label)
                            .font(.system(size: 10, weight: selected == mood ? .semibold : .medium))
                            .foregroundColor(selected == mood ? MongleColor.textPrimary : MongleColor.textSecondary)
                    }
                    .frame(width: 56)
                    .onTapGesture { selected = mood }
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(MongleRadius.xl)
        .overlay(RoundedRectangle(cornerRadius: MongleRadius.xl).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: Color(hex: "D4A090").opacity(0.12), radius: 16, x: 0, y: 4)
    }
}

// MARK: - Header/Home

/// component/Header/Home — streak badge | family name | bell+dot
public struct MongleHeaderHome: View {
    let familyName: String
    let streakDays: Int
    var hasNotification: Bool = false
    var onBellTapped: (() -> Void)? = nil

    public init(familyName: String, streakDays: Int, hasNotification: Bool = false, onBellTapped: (() -> Void)? = nil) {
        self.familyName = familyName
        self.streakDays = streakDays
        self.hasNotification = hasNotification
        self.onBellTapped = onBellTapped
    }

    public var body: some View {
        HStack {
            MongleBadgeStreak(days: streakDays)

            Spacer()

            Text(familyName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(MongleColor.textPrimary)

            Spacer()

            Button { onBellTapped?() } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 24))
                        .foregroundColor(MongleColor.textPrimary)
                        .frame(width: 24, height: 24)

                    if hasNotification {
                        MongleNotificationDot()
                            .offset(x: 4, y: -4)
                    }
                }
                .frame(width: 28, height: 28)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
    }
}

// MARK: - Answer Sheet

/// component/Sheet/Answer — bottom sheet with question + textarea + CTA
public struct MongleSheetAnswer: View {
    let question: String
    @Binding var answerText: String
    var onSubmit: () -> Void

    public init(question: String, answerText: Binding<String>, onSubmit: @escaping () -> Void) {
        self.question = question
        self._answerText = answerText
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Handle bar
            RoundedRectangle(cornerRadius: 100)
                .fill(Color(hex: "E0E0E0"))
                .frame(width: 40, height: 4)

            // Question
            VStack(alignment: .leading, spacing: 8) {
                Text("🌿 Today's Question")
                    .font(MongleFont.captionBold())
                    .foregroundColor(Color(hex: "5BAF85"))

                Text(question)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MongleColor.textPrimary)
                    .kerning(-0.2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Input
            MongleInputTextArea(
                placeholder: "오늘의 감정을 자유롭게 적어보세요.\n어떤 이야기든 좋아요.",
                text: $answerText
            )
            .frame(height: 140)

            // Submit
            MongleButtonCTA("마음 남기기", icon: "heart.fill", action: onSubmit)
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .shadow(color: Color(hex: "1A1A1A").opacity(0.1), radius: 20, x: 0, y: -4)
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

// MARK: - Error Banner

public struct MongleErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    public init(message: String, onDismiss: @escaping () -> Void) {
        self.message = message
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: MongleSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textPrimary)
                .lineLimit(2)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MongleColor.textSecondary)
            }
        }
        .padding(MongleSpacing.md)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(MongleRadius.medium)
    }
}

// MARK: - Helpers

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Previews

#Preview("Buttons") {
    ScrollView {
        VStack(spacing: 16) {
            MongleButtonPrimary("시작하기", icon: "plus", action: {})
            MongleButtonSecondary("답변하기", action: {})
            MongleButtonGhost("더보기", icon: "chevron.right", action: {})
            HStack {
                MongleButtonSmallPill("답변하기", action: {})
                MongleButtonSmallOutline("미답변", action: {})
            }
            MongleButtonCTA("오늘의 감정 보기", action: {})
        }
        .padding()
    }
    .background(Color(hex: "F5F4F1"))
}

#Preview("Badges") {
    VStack(spacing: 16) {
        MongleBadgeStreak(days: 5)
        MongleBadgeLevel(level: 3, name: "Cozy Forest")
        HStack(spacing: 8) {
            MongleBadgeAnswered()
            MongleBadgePending()
            MongleNotificationDot()
        }
    }
    .padding()
    .background(Color(hex: "F5F4F1"))
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
    .background(Color(hex: "F5F4F1"))
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
            HStack {
                MongleCardEmotion(date: "3월 4일", mood: "따뜻한 하루")
                MongleCardEmotion(date: "3월 3일", mood: "설레는 하루")
            }
        }
        .padding()
    }
    .background(Color(hex: "F5F4F1"))
}

#Preview("MoodSelector") {
    struct PreviewWrapper: View {
        @State var selected: MoodOption? = MoodOption.defaults[2]
        var body: some View {
            MongleMoodSelector(selected: $selected)
                .padding()
        }
    }
    return PreviewWrapper()
        .background(Color(hex: "F5F4F1"))
}

#Preview("Header") {
    MongleHeaderHome(familyName: "Kim Family", streakDays: 5, hasNotification: true)
        .background(Color(hex: "F5F4F1"))
}
