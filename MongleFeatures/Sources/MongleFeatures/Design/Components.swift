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
                        colors: [MongleColor.primaryGradientStart, MongleColor.primaryGradientEnd],
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
                    colors: [MongleColor.primaryGradientStart, MongleColor.primaryGradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: MongleColor.primaryGradientStart.opacity(0.25), radius: 16, x: 0, y: 6)
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
        .shadow(color: MongleColor.shadowBase.opacity(0.08), radius: 6, x: 0, y: 2)
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
                .foregroundColor(MongleColor.moodLoved)
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MongleColor.moodLoved)
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(MongleColor.bgPeach)
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
                colors: [MongleColor.moodLoved, MongleColor.accentPeach],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
        .shadow(color: MongleColor.moodLoved.opacity(0.2), radius: 8, x: 0, y: 2)
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
            Text(L10n.tr("home_answer_complete"))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(
            LinearGradient(
                colors: [MongleColor.primaryGradientStart, MongleColor.primaryGradientEnd],
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
    static func forMood(_ moodId: String?, size: CGFloat = 56) -> MongleMonggle {
        switch moodId {
        case "happy":  return MongleMonggle(color: MongleColor.monggleYellow, size: size)
        case "calm":   return MongleMonggle(color: MongleColor.monggleGreen, size: size)
        case "loved":  return MongleMonggle(color: MongleColor.mongglePink, size: size)
        case "sad":    return MongleMonggle(color: MongleColor.monggleBlue, size: size)
        case "tired":  return MongleMonggle(color: MongleColor.monggleOrange, size: size)
        default:       return MongleMonggle(color: MongleColor.mongglePink, size: size)
        }
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
                        .fill(MongleColor.primaryXLight)
                        .frame(height: 8)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [MongleColor.primaryMuted, MongleColor.primaryGradientEnd],
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
        .shadow(color: MongleColor.shadowBase.opacity(0.12), radius: 20, x: 0, y: 4)
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

/// component/Card/Emotion — compact emotion history card
public struct MongleCardEmotion: View {
    let date: String
    let mood: String
    var gradientColors: [Color] = [MongleColor.accentPeach, MongleColor.primaryXLight]

    public init(date: String, mood: String, gradientColors: [Color] = [MongleColor.accentPeach, MongleColor.primaryXLight]) {
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
        .shadow(color: MongleColor.shadowBase.opacity(0.12), radius: 16, x: 0, y: 4)
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
        MoodOption(id: "calm",    emoji: "😌", label: L10n.tr("mood_calm"),    color: MongleColor.monggleGreen),
        MoodOption(id: "happy",   emoji: "😊", label: L10n.tr("mood_happy"),   color: MongleColor.monggleYellow),
        MoodOption(id: "loved",   emoji: "🥰", label: L10n.tr("mood_loved"),   color: MongleColor.mongglePink),
        MoodOption(id: "sad",     emoji: "😢", label: L10n.tr("mood_sad"),     color: MongleColor.monggleBlue),
        MoodOption(id: "tired",   emoji: "😴", label: L10n.tr("mood_tired"),   color: MongleColor.monggleOrange),
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
                        MongleMonggle.forMood(mood.id, size: 44)
                            .scaleEffect(selected == mood ? 1.18 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: selected)

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
        .shadow(color: MongleColor.shadowBase.opacity(0.12), radius: 16, x: 0, y: 4)
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
                .fill(MongleColor.border)
                .frame(width: 40, height: 4)

            // Question
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Question")
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.primaryMuted)

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
            MongleButtonCTA("답변 남기기", icon: "heart.fill", action: onSubmit)
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .background(Color.white)
        .clipShape(
            .rect(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24
            )
        )
        .shadow(color: MongleColor.textPrimary.opacity(0.1), radius: 20, x: 0, y: -4)
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
            MongleButtonGhost("더보기", icon: "chevron.right", action: {})
            HStack {
                MongleButtonSmallPill("답변하기", action: {})
                MongleButtonSmallOutline("미답변", action: {})
            }
            MongleButtonCTA("오늘의 감정 보기", action: {})
        }
        .padding()
    }
    .background(MongleColor.bgNeutral)
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
            HStack {
                MongleCardEmotion(date: "3월 4일", mood: "따뜻한 하루")
                MongleCardEmotion(date: "3월 3일", mood: "설레는 하루")
            }
        }
        .padding()
    }
    .background(MongleColor.bgNeutral)
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
        .background(MongleColor.bgNeutral)
}

#Preview("Header") {
    MongleHeaderHome(familyName: "Kim Family", streakDays: 5, hasNotification: true)
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
    public var isDragging: Bool = false // 드래그 중 여부 (true이면 자동 이동 skip)

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

    // 찌부(squish) + 흔들기(wiggle) 인터랙션 상태
    @State private var isPressed: Bool = false

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
        VStack(spacing: 4) {
            statusBadge
            MongleMonggle(color: color, name: name)
        }
        // 찌부 효과: 꾹 누르면 납작해짐
        .scaleEffect(
            x: isPressed ? 1.15 : 1.0,
            y: isPressed ? 0.7 : 1.0,
            anchor: .bottom
        )
        // 흔들기 효과: 누르는 동안 좌우 회전 반복
        .rotationEffect(.degrees(isPressed ? 5 : 0))
        // 찌부 y 오프셋
        .offset(y: isPressed ? 8 : 0)
        .animation(
            isPressed
                ? .easeInOut(duration: 0.12).repeatForever(autoreverses: true)
                : .spring(response: 0.4, dampingFraction: 0.4),
            value: isPressed
        )
        .accessibilityAddTraits(.isButton)
        .onTapGesture { handleTap() }
        .onLongPressGesture(minimumDuration: 0.15, pressing: { pressing in
            if pressing {
                isPressed = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else {
                isPressed = false
            }
        }, perform: {})
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

// MARK: - Mongle Scene (구역 내 이동 + 충돌 감지)

public struct MongleSceneView: View {
    public var hasCurrentUserAnswered: Bool = false
    public var hasCurrentUserSkipped: Bool = false
    public var members: [(name: String, color: Color, hasAnswered: Bool, hasSkipped: Bool)]
    public var currentUserName: String?
    public var onViewAnswer: (String) -> Void = { _ in }
    public var onNudge: (String) -> Void = { _ in }
    public var onSelfTap: () -> Void = {}
    public var onAnswerFirstToView: (String) -> Void = { _ in }
    public var onAnswerFirstToNudge: (String) -> Void = { _ in }

    private let stepSize: CGFloat = 2.0
    private let interval: TimeInterval = 0.12
    private let collisionRadius: CGFloat = 76
    private let targetThreshold: CGFloat = 12
    private let wallPadding: CGFloat = 50
    private let overlapLimit: Int = 10

    @State private var mongles: [MongleCharacter] = []
    @State private var timer: Timer?

    private static let defaultMemberData: [(String, Color, Bool, Bool)] = [
        ("Dad", .orange, true, false),
        ("Mom", .green, false, false),
        ("Lily", .yellow, true, false),
        ("Ben", .blue, false, false),
        ("Alex", .pink, true, false)
    ]

    public init(hasCurrentUserAnswered: Bool = false,
                hasCurrentUserSkipped: Bool = false,
                members: [(name: String, color: Color, hasAnswered: Bool, hasSkipped: Bool)] = [],
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

    private var effectiveMembers: [(String, Color, Bool, Bool)] {
        members.isEmpty ? Self.defaultMemberData : members.map { ($0.name, $0.color, $0.hasAnswered, $0.hasSkipped) }
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(mongles) { h in
                    let hopY = h.isDragging ? 0 : -abs(sin(CGFloat(h.stepCount) * .pi / 5.0)) * 12
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
                    // 드래그 중: 살짝 키우기 + 그림자 강화
                    .scaleEffect(h.isDragging ? 1.1 : 1.0)
                    .shadow(color: h.isDragging ? Color.black.opacity(0.25) : Color.clear,
                            radius: h.isDragging ? 12 : 0, x: 0, y: 6)
                    .position(CGPoint(x: h.position.x, y: h.position.y + hopY))
                    .animation(.linear(duration: interval), value: h.stepCount)
                    .gesture(
                        LongPressGesture(minimumDuration: 0.3)
                            .sequenced(before: DragGesture())
                            .onChanged { value in
                                guard let idx = mongles.firstIndex(where: { $0.id == h.id }) else { return }
                                switch value {
                                case .first(true):
                                    // LongPress 인식됨, 드래그 시작 대기
                                    if !mongles[idx].isDragging {
                                        mongles[idx].isDragging = true
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                case .second(true, let drag):
                                    // 드래그 진행 중
                                    if let drag = drag {
                                        let newX = min(max(drag.location.x, wallPadding), geo.size.width - wallPadding)
                                        let newY = min(max(drag.location.y, wallPadding), geo.size.height - wallPadding)
                                        mongles[idx].position = CGPoint(x: newX, y: newY)
                                    }
                                default:
                                    break
                                }
                            }
                            .onEnded { _ in
                                guard let idx = mongles.firstIndex(where: { $0.id == h.id }) else { return }
                                // 착지: bounce 애니메이션 + 자동 이동 재개
                                mongles[idx].isDragging = false
                                mongles[idx].targetPosition = randomPos(size: geo.size)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.5), value: h.isDragging)
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
            .onChange(of: members.map { $0.name }) { _, _ in
                guard geo.size.width > 0, geo.size.height > 0 else { return }
                initMongles(size: geo.size)
            }
            .onChange(of: members.map { $0.hasAnswered }) { _, _ in
                for i in mongles.indices {
                    if let member = members.first(where: { $0.name == mongles[i].name }) {
                        mongles[i].hasAnswered = member.hasAnswered
                    }
                }
            }
            .onChange(of: members.map { $0.hasSkipped }) { _, _ in
                for i in mongles.indices {
                    if let member = members.first(where: { $0.name == mongles[i].name }) {
                        mongles[i].hasSkipped = member.hasSkipped
                    }
                }
            }
            .onChange(of: members.map { $0.color }) { _, _ in
                for i in mongles.indices {
                    if let member = members.first(where: { $0.name == mongles[i].name }) {
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
        mongles = effectiveMembers.map { name, color, hasAnswered, hasSkipped in
            var pos = randomPos(size: size)
            for _ in 0..<30 {
                let overlaps = placed.contains { hypot(pos.x - $0.x, pos.y - $0.y) < collisionRadius }
                if !overlaps { break }
                pos = randomPos(size: size)
            }
            placed.append(pos)
            return MongleCharacter(
                name: name,
                color: color,
                hasAnswered: hasAnswered,
                hasSkipped: hasSkipped,
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
            // 드래그 중인 캐릭터는 자동 이동 skip
            if mongles[i].isDragging { continue }

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
        }
    }
}
