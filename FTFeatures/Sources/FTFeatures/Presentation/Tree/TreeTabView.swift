//
//  TreeTabView.swift
//  Mongle
//
//  Created by Claude on 2025-01-06.
//

import SwiftUI
import ComposableArchitecture
import Domain

struct TreeTabView: View {
    @Bindable var store: StoreOf<TreeFeature>
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [FTColor.primaryLight.opacity(0.3), FTColor.surface],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                if store.isLoading && store.treeProgress == nil {
                    TreeLoadingView()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: FTSpacing.lg) {
                            // Tree Hero Section
                            TreeHeroSection(
                                stage: store.currentStage,
                                totalAnswers: store.totalAnswers,
                                consecutiveDays: store.consecutiveDays
                            )

                            // Progress Card
                            if !store.isMaxStage {
                                TreeProgressSection(
                                    progress: store.nextStageProgress,
                                    answersUntilNext: store.answersUntilNextStage,
                                    currentStage: store.currentStage
                                )
                                .padding(.horizontal, FTSpacing.lg)
                            } else {
                                MaxStageCard()
                                    .padding(.horizontal, FTSpacing.lg)
                            }

                            // Growth Journey
                            GrowthJourneySection(currentStage: store.currentStage)
                                .padding(.horizontal, FTSpacing.lg)

                            // Family Contributors
                            if !store.familyMembers.isEmpty {
                                FamilyContributorsCard(members: store.familyMembers)
                                    .padding(.horizontal, FTSpacing.lg)
                            }

                            // Error
                            if let errorMessage = store.errorMessage {
                                FTErrorBanner(message: errorMessage) {
                                    store.send(.dismissErrorTapped)
                                }
                                .padding(.horizontal, FTSpacing.lg)
                            }

                            Spacer()
                                .frame(height: FTSpacing.xxl)
                        }
                    }
                    .refreshable {
                        store.send(.refreshTapped)
                    }
                }
            }
            .navigationTitle("우리 가족 나무")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

// MARK: - Tree Loading View
private struct TreeLoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: FTSpacing.lg) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 48))
                .foregroundColor(FTColor.primary)
                .rotationEffect(.degrees(rotation))
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: rotation
                )

            Text("나무 정보를 불러오는 중...")
                .font(FTFont.body1())
                .foregroundColor(FTColor.textSecondary)
        }
        .onAppear {
            rotation = 15
        }
    }
}

// MARK: - Tree Hero Section
private struct TreeHeroSection: View {
    let stage: TreeStage
    let totalAnswers: Int
    let consecutiveDays: Int

    var body: some View {
        VStack(spacing: FTSpacing.lg) {
            // Animated Tree with glow effect
            ZStack {
                // Glow background
                Circle()
                    .fill(FTColor.primaryLight.opacity(0.5))
                    .frame(width: 180, height: 180)
                    .blur(radius: 30)

                AnimatedTreeView(stage: stage, size: 180)
            }
            .padding(.top, FTSpacing.lg)

            // Stage Name with badge
            VStack(spacing: FTSpacing.xs) {
                Text(stageName)
                    .font(FTFont.heading1())
                    .foregroundColor(FTColor.textPrimary)

                Text(stageDescription)
                    .font(FTFont.body2())
                    .foregroundColor(FTColor.textSecondary)
            }

            // Stats Row
            HStack(spacing: FTSpacing.xl) {
                TreeStatBubble(
                    icon: "bubble.left.and.bubble.right.fill",
                    value: "\(totalAnswers)",
                    label: "총 답변",
                    color: FTColor.primary
                )

                TreeStatBubble(
                    icon: "flame.fill",
                    value: "\(consecutiveDays)일",
                    label: "연속 참여",
                    color: .orange
                )
            }
            .padding(.horizontal, FTSpacing.xl)
            .padding(.bottom, FTSpacing.md)
        }
    }

    private var stageName: String {
        switch stage {
        case .seed: return "씨앗"
        case .sprout: return "새싹"
        case .sapling: return "어린 나무"
        case .youngTree: return "청년 나무"
        case .matureTree: return "큰 나무"
        case .flowering: return "꽃피는 나무"
        case .bound: return "열매 맺는 나무"
        }
    }

    private var stageDescription: String {
        switch stage {
        case .seed: return "작은 시작이 큰 나무가 되어요"
        case .sprout: return "새싹이 돋아나고 있어요"
        case .sapling: return "조금씩 자라고 있어요"
        case .youngTree: return "튼튼하게 성장 중이에요"
        case .matureTree: return "멋진 나무가 되었어요"
        case .flowering: return "아름다운 꽃이 피었어요"
        case .bound: return "열매가 맺히고 있어요"
        }
    }
}

// MARK: - Tree Stat Bubble
private struct TreeStatBubble: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: FTSpacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }

            Text(value)
                .font(FTFont.heading3())
                .foregroundColor(FTColor.textPrimary)

            Text(label)
                .font(FTFont.caption())
                .foregroundColor(FTColor.textSecondary)
        }
    }
}

// MARK: - Tree Progress Section
private struct TreeProgressSection: View {
    let progress: Double
    let answersUntilNext: Int
    let currentStage: TreeStage

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            VStack(alignment: .leading, spacing: FTSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: FTSpacing.xxs) {
                        Text("다음 단계까지")
                            .font(FTFont.body1Bold())
                            .foregroundColor(FTColor.textPrimary)

                        Text("\(answersUntilNext)개 답변이 더 필요해요")
                            .font(FTFont.caption())
                            .foregroundColor(FTColor.textSecondary)
                    }

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(FTFont.heading3())
                        .foregroundColor(FTColor.primary)
                }

                // Animated Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: FTRadius.full)
                            .fill(FTColor.primaryLight)
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: FTRadius.full)
                            .fill(
                                LinearGradient(
                                    colors: [FTColor.primary, FTColor.accent3],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 12)
                    }
                }
                .frame(height: 12)

                // Stage labels
                HStack {
                    HStack(spacing: FTSpacing.xxs) {
                        Image(systemName: stageIcon(currentStage))
                            .font(.system(size: 12))
                        Text(currentStageName)
                            .font(FTFont.caption())
                    }
                    .foregroundColor(FTColor.textSecondary)

                    Spacer()

                    HStack(spacing: FTSpacing.xxs) {
                        Text(nextStageName)
                            .font(FTFont.caption())
                        Image(systemName: stageIcon(nextStage))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(FTColor.primary)
                }
            }
        }
    }

    private var currentStageName: String {
        stageNameFor(currentStage)
    }

    private var nextStageName: String {
        stageNameFor(nextStage)
    }

    private var nextStage: TreeStage {
        TreeStage(rawValue: min(currentStage.rawValue + 1, 5)) ?? .flowering
    }

    private func stageNameFor(_ stage: TreeStage) -> String {
        switch stage {
        case .seed: return "씨앗"
        case .sprout: return "새싹"
        case .sapling: return "어린 나무"
        case .youngTree: return "청년 나무"
        case .matureTree: return "큰 나무"
        case .flowering: return "꽃피는 나무"
        case .bound: return "열매 나무"
        }
    }

    private func stageIcon(_ stage: TreeStage) -> String {
        switch stage {
        case .seed: return "circle.fill"
        case .sprout: return "leaf.fill"
        case .sapling: return "leaf.arrow.triangle.circlepath"
        case .youngTree: return "tree.fill"
        case .matureTree: return "tree.fill"
        case .flowering: return "sparkles"
        case .bound: return "star.fill"
        }
    }
}

// MARK: - Max Stage Card
private struct MaxStageCard: View {
    var body: some View {
        FTCard(cornerRadius: FTRadius.xl, backgroundColor: FTColor.cardBackgroundHighlight) {
            HStack(spacing: FTSpacing.md) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: FTSpacing.xxs) {
                    Text("최고 단계 달성!")
                        .font(FTFont.body1Bold())
                        .foregroundColor(FTColor.textPrimary)

                    Text("가족과 함께 멋진 나무를 키웠어요")
                        .font(FTFont.caption())
                        .foregroundColor(FTColor.textSecondary)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Growth Journey Section
private struct GrowthJourneySection: View {
    let currentStage: TreeStage

    private let stages: [(TreeStage, String, String, Int)] = [
        (.seed, "씨앗", "circle.fill", 0),
        (.sprout, "새싹", "leaf.fill", 5),
        (.sapling, "어린 나무", "leaf.arrow.triangle.circlepath", 15),
        (.youngTree, "청년 나무", "tree.fill", 30),
        (.matureTree, "큰 나무", "tree.fill", 60),
        (.flowering, "꽃피는 나무", "sparkles", 100)
    ]

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            VStack(alignment: .leading, spacing: FTSpacing.md) {
                FTSectionHeader(title: "성장 여정", subtitle: "나무가 자라는 과정")

                VStack(spacing: 0) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                        GrowthStageRow(
                            stage: stage.0,
                            name: stage.1,
                            icon: stage.2,
                            requiredAnswers: stage.3,
                            isCompleted: currentStage.rawValue > stage.0.rawValue,
                            isCurrent: currentStage == stage.0,
                            isLast: index == stages.count - 1
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Growth Stage Row
private struct GrowthStageRow: View {
    let stage: TreeStage
    let name: String
    let icon: String
    let requiredAnswers: Int
    let isCompleted: Bool
    let isCurrent: Bool
    let isLast: Bool

    var body: some View {
        HStack(spacing: FTSpacing.md) {
            // Timeline
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isCompleted || isCurrent ? FTColor.primary : FTColor.border)
                        .frame(width: 32, height: 32)

                    if isCurrent {
                        Circle()
                            .stroke(FTColor.primary.opacity(0.3), lineWidth: 4)
                            .frame(width: 40, height: 40)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(isCompleted || isCurrent ? .white : FTColor.textHint)
                }

                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? FTColor.primary : FTColor.border)
                        .frame(width: 2, height: 24)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: FTSpacing.xxs) {
                Text(name)
                    .font(isCurrent ? FTFont.body1Bold() : FTFont.body1())
                    .foregroundColor(isCurrent ? FTColor.primary : (isCompleted ? FTColor.textPrimary : FTColor.textHint))

                Text("\(requiredAnswers)개 답변")
                    .font(FTFont.caption())
                    .foregroundColor(FTColor.textSecondary)
            }

            Spacer()

            // Status
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(FTColor.success)
            } else if isCurrent {
                Text("현재")
                    .font(FTFont.captionBold())
                    .foregroundColor(.white)
                    .padding(.horizontal, FTSpacing.sm)
                    .padding(.vertical, FTSpacing.xxs)
                    .background(FTColor.primary)
                    .cornerRadius(FTRadius.full)
            }
        }
        .padding(.vertical, FTSpacing.xs)
    }
}

// MARK: - Family Contributors Card
private struct FamilyContributorsCard: View {
    let members: [User]

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            VStack(alignment: .leading, spacing: FTSpacing.md) {
                FTSectionHeader(
                    title: "함께 키우는 가족",
                    subtitle: "\(members.count)명이 참여 중"
                )

                // Overlapping avatars
                HStack(spacing: -FTSpacing.sm) {
                    ForEach(Array(members.prefix(5).enumerated()), id: \.offset) { index, member in
                        FTMemberAvatar(
                            name: member.name,
                            size: 48,
                            showName: false
                        )
                        .overlay(
                            Circle()
                                .stroke(FTColor.cardBackground, lineWidth: 3)
                        )
                        .zIndex(Double(5 - index))
                    }

                    if members.count > 5 {
                        ZStack {
                            Circle()
                                .fill(FTColor.textHint)
                                .frame(width: 48, height: 48)

                            Text("+\(members.count - 5)")
                                .font(FTFont.captionBold())
                                .foregroundColor(.white)
                        }
                        .overlay(
                            Circle()
                                .stroke(FTColor.cardBackground, lineWidth: 3)
                        )
                    }

                    Spacer()
                }

                Text("모두가 함께 가족 나무를 키우고 있어요!")
                    .font(FTFont.caption())
                    .foregroundColor(FTColor.textSecondary)
            }
        }
    }
}

// MARK: - Previews
#Preview("Tree Tab - Young Tree") {
    TreeTabView(
        store: Store(initialState: TreeFeature.State(
            treeProgress: TreeProgress(
                stage: .youngTree,
                totalAnswers: 35,
                consecutiveDays: 7
            ),
            familyMembers: [
                User(id: UUID(), email: "dad@example.com", name: "아빠", profileImageURL: nil, role: .father, createdAt: .now),
                User(id: UUID(), email: "mom@example.com", name: "엄마", profileImageURL: nil, role: .mother, createdAt: .now),
                User(id: UUID(), email: "me@example.com", name: "나", profileImageURL: nil, role: .son, createdAt: .now)
            ]
        )) {
            TreeFeature()
        }
    )
}

#Preview("Tree Tab - Seed") {
    TreeTabView(
        store: Store(initialState: TreeFeature.State(
            treeProgress: TreeProgress(
                stage: .seed,
                totalAnswers: 2,
                consecutiveDays: 1
            ),
            familyMembers: [
                User(id: UUID(), email: "me@example.com", name: "나", profileImageURL: nil, role: .son, createdAt: .now)
            ]
        )) {
            TreeFeature()
        }
    )
}

#Preview("Tree Tab - Loading") {
    TreeTabView(
        store: Store(initialState: TreeFeature.State(
            isLoading: true
        )) {
            TreeFeature()
        }
    )
}
