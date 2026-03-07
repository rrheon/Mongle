//
//  MongleCard.swift
//  Mongle
//
//  Created by Claude on 2025-01-07.
//

import SwiftUI

// MARK: - Card Container
struct MongleCard<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var cornerRadius: CGFloat
    var hasShadow: Bool
    var backgroundColor: Color

    @Environment(\.colorScheme) var colorScheme

    init(
        padding: CGFloat = MongleSpacing.lg,
        cornerRadius: CGFloat = MongleRadius.xl,
        hasShadow: Bool = true,
        backgroundColor: Color = MongleColor.cardBackground,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.hasShadow = hasShadow
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: hasShadow ? shadowColor : .clear,
                radius: hasShadow ? 12 : 0,
                x: 0,
                y: hasShadow ? 4 : 0
            )
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.3)
            : Color.black.opacity(0.06)
    }
}

// MARK: - Question Card (마인드브릿지 스타일 질문 카드)
struct MongleQuestionCard: View {
    let category: String
    let question: String
    var hasAnswered: Bool = false
    var familyAnswerCount: Int = 0
    var totalFamilyMembers: Int = 0
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: MongleSpacing.md) {
                // Top Row - Category & Status
                HStack {
                    // Category Tag
                    HStack(spacing: MongleSpacing.xxs) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 12))
                        Text(category)
                            .font(MongleFont.captionBold())
                    }
                    .foregroundColor(MongleColor.primary)
                    .padding(.horizontal, MongleSpacing.sm)
                    .padding(.vertical, MongleSpacing.xxs)
                    .background(MongleColor.primaryLight)
                    .cornerRadius(MongleRadius.full)

                    Spacer()

                    // Answer Status
                    if hasAnswered {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("답변 완료")
                                .font(MongleFont.captionBold())
                        }
                        .foregroundColor(MongleColor.success)
                    }
                }

                // Question Text
                Text(question)
                    .font(MongleFont.heading3())
                    .foregroundColor(MongleColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Bottom Row - Family Progress & Arrow
                HStack {
                    if totalFamilyMembers > 0 {
                        HStack(spacing: MongleSpacing.xxs) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12))
                            Text("\(familyAnswerCount)/\(totalFamilyMembers)명 답변")
                                .font(MongleFont.caption())
                        }
                        .foregroundColor(MongleColor.textSecondary)
                    }

                    Spacer()

                    if !hasAnswered {
                        HStack(spacing: MongleSpacing.xxs) {
                            Text("답변하기")
                                .font(MongleFont.captionBold())
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(MongleColor.primary)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(MongleColor.textHint)
                    }
                }
            }
            .padding(MongleSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: MongleRadius.xl)
                    .fill(hasAnswered ? MongleColor.cardBackgroundHighlight : MongleColor.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.xl)
                    .stroke(hasAnswered ? MongleColor.primary.opacity(0.3) : .clear, lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.06),
                radius: 12,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var categoryIcon: String {
        switch category {
        case "일상": return "sun.max.fill"
        case "추억": return "photo.fill"
        case "가치관": return "heart.fill"
        case "미래": return "sparkles"
        case "감사": return "hands.clap.fill"
        default: return "bubble.leMongle.fill"
        }
    }
}

// MARK: - Stat Card (통계 표시 카드)
struct MongleStatCard: View {
    let icon: String
    let value: String
    let label: String
    var iconColor: Color = MongleColor.primary

    var body: some View {
        VStack(spacing: MongleSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)

            Text(value)
                .font(MongleFont.heading2())
                .foregroundColor(MongleColor.textPrimary)

            Text(label)
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MongleSpacing.md)
        .background(MongleColor.cardBackground)
        .cornerRadius(MongleRadius.large)
    }
}

// MARK: - Member Avatar
struct MongleMemberAvatar: View {
    let name: String
    var size: CGFloat = 48
    var showName: Bool = true
    var backgroundColor: Color = MongleColor.primaryLight
    var textColor: Color = MongleColor.primaryDark

    var body: some View {
        VStack(spacing: MongleSpacing.xxs) {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                        .foregroundColor(textColor)
                )

            if showName {
                Text(name)
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Empty State View
struct MongleEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: MongleSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(MongleColor.primaryLight)

            VStack(spacing: MongleSpacing.sm) {
                Text(title)
                    .font(MongleFont.heading3())
                    .foregroundColor(MongleColor.textPrimary)

                Text(message)
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                MongleButton(actionTitle, style: .primary, size: .medium) {
                    action()
                }
                .frame(width: 200)
            }
        }
        .padding(MongleSpacing.xl)
    }
}

// MARK: - Toast View
struct MongleToast: View {
    let message: String
    var icon: String = "checkmark.circle.fill"
    var iconColor: Color = MongleColor.success

    var body: some View {
        HStack(spacing: MongleSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(iconColor)

            Text(message)
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textPrimary)
        }
        .padding(.horizontal, MongleSpacing.lg)
        .padding(.vertical, MongleSpacing.md)
        .background(MongleColor.cardBackground)
        .cornerRadius(MongleRadius.full)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Error Banner
struct MongleErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
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

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Section Header
struct MongleSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MongleFont.body1Bold())
                    .foregroundColor(MongleColor.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(MongleFont.caption())
                        .foregroundColor(MongleColor.textSecondary)
                }
            }

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: MongleSpacing.xxs) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(MongleFont.captionBold())
                    .foregroundColor(MongleColor.primary)
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Cards") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Question Card")
                .font(MongleFont.heading3())

            MongleQuestionCard(
                category: "일상",
                question: "오늘 가장 기억에 남는 순간은 무엇인가요?",
                hasAnswered: false,
                familyAnswerCount: 2,
                totalFamilyMembers: 4
            ) {}

            MongleQuestionCard(
                category: "감사",
                question: "최근에 가족에게 감사했던 일이 있나요?",
                hasAnswered: true,
                familyAnswerCount: 4,
                totalFamilyMembers: 4
            ) {}

            Text("Stat Cards")
                .font(MongleFont.heading3())

            HStack(spacing: MongleSpacing.md) {
                MongleStatCard(icon: "bubble.leMongle.and.bubble.right.fill", value: "42", label: "총 답변")
                MongleStatCard(icon: "flame.fill", value: "7일", label: "연속 참여", iconColor: .orange)
            }

            Text("Member Avatars")
                .font(MongleFont.heading3())

            HStack(spacing: MongleSpacing.sm) {
                MongleMemberAvatar(name: "아빠")
                MongleMemberAvatar(name: "엄마")
                MongleMemberAvatar(name: "나")
            }

            Text("Empty State")
                .font(MongleFont.heading3())

            MongleEmptyState(
                icon: "person.3",
                title: "아직 가족이 없어요",
                message: "새 가족을 만들거나\n초대 코드로 참여해보세요",
                actionTitle: "가족 만들기"
            ) {}

            Text("Toast & Banner")
                .font(MongleFont.heading3())

            MongleToast(message: "초대 코드가 복사되었습니다")

            MongleErrorBanner(message: "네트워크 오류가 발생했습니다") {}

            Text("Section Header")
                .font(MongleFont.heading3())

            MongleSectionHeader(
                title: "가족 구성원",
                subtitle: "4명",
                actionTitle: "전체보기"
            ) {}
        }
        .padding()
    }
    .background(MongleColor.surface)
}
