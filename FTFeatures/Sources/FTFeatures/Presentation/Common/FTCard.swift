//
//  FTCard.swift
//  Mongle
//
//  Created by Claude on 2025-01-07.
//

import SwiftUI

// MARK: - Card Container
struct FTCard<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var cornerRadius: CGFloat
    var hasShadow: Bool
    var backgroundColor: Color

    @Environment(\.colorScheme) var colorScheme

    init(
        padding: CGFloat = FTSpacing.lg,
        cornerRadius: CGFloat = FTRadius.xl,
        hasShadow: Bool = true,
        backgroundColor: Color = FTColor.cardBackground,
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
struct FTQuestionCard: View {
    let category: String
    let question: String
    var hasAnswered: Bool = false
    var familyAnswerCount: Int = 0
    var totalFamilyMembers: Int = 0
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: FTSpacing.md) {
                // Top Row - Category & Status
                HStack {
                    // Category Tag
                    HStack(spacing: FTSpacing.xxs) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 12))
                        Text(category)
                            .font(FTFont.captionBold())
                    }
                    .foregroundColor(FTColor.primary)
                    .padding(.horizontal, FTSpacing.sm)
                    .padding(.vertical, FTSpacing.xxs)
                    .background(FTColor.primaryLight)
                    .cornerRadius(FTRadius.full)

                    Spacer()

                    // Answer Status
                    if hasAnswered {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("답변 완료")
                                .font(FTFont.captionBold())
                        }
                        .foregroundColor(FTColor.success)
                    }
                }

                // Question Text
                Text(question)
                    .font(FTFont.heading3())
                    .foregroundColor(FTColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Bottom Row - Family Progress & Arrow
                HStack {
                    if totalFamilyMembers > 0 {
                        HStack(spacing: FTSpacing.xxs) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12))
                            Text("\(familyAnswerCount)/\(totalFamilyMembers)명 답변")
                                .font(FTFont.caption())
                        }
                        .foregroundColor(FTColor.textSecondary)
                    }

                    Spacer()

                    if !hasAnswered {
                        HStack(spacing: FTSpacing.xxs) {
                            Text("답변하기")
                                .font(FTFont.captionBold())
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(FTColor.primary)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(FTColor.textHint)
                    }
                }
            }
            .padding(FTSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: FTRadius.xl)
                    .fill(hasAnswered ? FTColor.cardBackgroundHighlight : FTColor.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FTRadius.xl)
                    .stroke(hasAnswered ? FTColor.primary.opacity(0.3) : .clear, lineWidth: 1)
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
        default: return "bubble.left.fill"
        }
    }
}

// MARK: - Stat Card (통계 표시 카드)
struct FTStatCard: View {
    let icon: String
    let value: String
    let label: String
    var iconColor: Color = FTColor.primary

    var body: some View {
        VStack(spacing: FTSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)

            Text(value)
                .font(FTFont.heading2())
                .foregroundColor(FTColor.textPrimary)

            Text(label)
                .font(FTFont.caption())
                .foregroundColor(FTColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(FTSpacing.md)
        .background(FTColor.cardBackground)
        .cornerRadius(FTRadius.large)
    }
}

// MARK: - Member Avatar
struct FTMemberAvatar: View {
    let name: String
    var size: CGFloat = 48
    var showName: Bool = true
    var backgroundColor: Color = FTColor.primaryLight
    var textColor: Color = FTColor.primaryDark

    var body: some View {
        VStack(spacing: FTSpacing.xxs) {
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
                    .font(FTFont.caption())
                    .foregroundColor(FTColor.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Empty State View
struct FTEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: FTSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(FTColor.primaryLight)

            VStack(spacing: FTSpacing.sm) {
                Text(title)
                    .font(FTFont.heading3())
                    .foregroundColor(FTColor.textPrimary)

                Text(message)
                    .font(FTFont.body2())
                    .foregroundColor(FTColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                FTButton(actionTitle, style: .primary, size: .medium) {
                    action()
                }
                .frame(width: 200)
            }
        }
        .padding(FTSpacing.xl)
    }
}

// MARK: - Toast View
struct FTToast: View {
    let message: String
    var icon: String = "checkmark.circle.fill"
    var iconColor: Color = FTColor.success

    var body: some View {
        HStack(spacing: FTSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(iconColor)

            Text(message)
                .font(FTFont.body2())
                .foregroundColor(FTColor.textPrimary)
        }
        .padding(.horizontal, FTSpacing.lg)
        .padding(.vertical, FTSpacing.md)
        .background(FTColor.cardBackground)
        .cornerRadius(FTRadius.full)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Error Banner
struct FTErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: FTSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(FTFont.body2())
                .foregroundColor(FTColor.textPrimary)
                .lineLimit(2)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FTColor.textSecondary)
            }
        }
        .padding(FTSpacing.md)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(FTRadius.medium)
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
struct FTSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FTFont.body1Bold())
                    .foregroundColor(FTColor.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(FTFont.caption())
                        .foregroundColor(FTColor.textSecondary)
                }
            }

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: FTSpacing.xxs) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(FTFont.captionBold())
                    .foregroundColor(FTColor.primary)
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
                .font(FTFont.heading3())

            FTQuestionCard(
                category: "일상",
                question: "오늘 가장 기억에 남는 순간은 무엇인가요?",
                hasAnswered: false,
                familyAnswerCount: 2,
                totalFamilyMembers: 4
            ) {}

            FTQuestionCard(
                category: "감사",
                question: "최근에 가족에게 감사했던 일이 있나요?",
                hasAnswered: true,
                familyAnswerCount: 4,
                totalFamilyMembers: 4
            ) {}

            Text("Stat Cards")
                .font(FTFont.heading3())

            HStack(spacing: FTSpacing.md) {
                FTStatCard(icon: "bubble.left.and.bubble.right.fill", value: "42", label: "총 답변")
                FTStatCard(icon: "flame.fill", value: "7일", label: "연속 참여", iconColor: .orange)
            }

            Text("Member Avatars")
                .font(FTFont.heading3())

            HStack(spacing: FTSpacing.sm) {
                FTMemberAvatar(name: "아빠")
                FTMemberAvatar(name: "엄마")
                FTMemberAvatar(name: "나")
            }

            Text("Empty State")
                .font(FTFont.heading3())

            FTEmptyState(
                icon: "person.3",
                title: "아직 가족이 없어요",
                message: "새 가족을 만들거나\n초대 코드로 참여해보세요",
                actionTitle: "가족 만들기"
            ) {}

            Text("Toast & Banner")
                .font(FTFont.heading3())

            FTToast(message: "초대 코드가 복사되었습니다")

            FTErrorBanner(message: "네트워크 오류가 발생했습니다") {}

            Text("Section Header")
                .font(FTFont.heading3())

            FTSectionHeader(
                title: "가족 구성원",
                subtitle: "4명",
                actionTitle: "전체보기"
            ) {}
        }
        .padding()
    }
    .background(FTColor.surface)
}
