//
//  HomeView.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI
import ComposableArchitecture
import Domain

// MARK: - HomeView
struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    colors: [FTColor.surface, FTColor.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if store.isLoading && store.todayQuestion == nil {
                    HomeLoadingView()
                } else if !store.hasFamily {
                    NoFamilyView(
                        onCreateFamily: { store.send(.createFamilyTapped) },
                        onJoinFamily: { store.send(.joinFamilyTapped) }
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: FTSpacing.lg) {
                            // Header
                            HomeHeaderView(
                                userName: store.currentUser?.name ?? "사용자",
                                familyName: store.family?.name
                            )

                            // Error Banner
                            if let errorMessage = store.errorMessage {
                                FTErrorBanner(message: errorMessage) {
                                    store.send(.dismissError)
                                }
                                .padding(.horizontal, FTSpacing.lg)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // 고슴도치 정원 (가족 멤버들이 돌아다님)
                            if !store.familyMembers.isEmpty {
                                VStack(alignment: .leading, spacing: FTSpacing.sm) {
                                    FTSectionHeader(
                                        title: "우리 가족 고슴도치",
                                        subtitle: "\(store.familyMembers.count)마리"
                                    )
                                    .padding(.horizontal, FTSpacing.lg)

                                    GeometryReader { geometry in
                                        HedgehogGardenView(
                                            members: store.familyMembers,
                                            memberAnswerStatus: store.memberAnswerStatus,
                                            hasActiveQuestion: store.todayQuestion != nil,
                                            gardenSize: CGSize(
                                                width: 350,
                                                height: 280
                                            )
                                        )
                                        .padding(.horizontal, FTSpacing.lg)
                                    }
                                    .frame(height: 280)
                                }
                            }

                            // Today's Question Card (마인드브릿지 스타일)
                            VStack(alignment: .leading, spacing: FTSpacing.sm) {
                                FTSectionHeader(
                                    title: "오늘의 질문",
                                    subtitle: formattedDate
                                )
                                .padding(.horizontal, FTSpacing.lg)

                                if let question = store.todayQuestion {
                                    FTQuestionCard(
                                        category: question.category.rawValue,
                                        question: question.content,
                                        hasAnswered: store.hasAnsweredToday,
                                        familyAnswerCount: store.familyAnswerCount,
                                        totalFamilyMembers: store.familyMembers.count
                                    ) {
                                        store.send(.questionTapped)
                                    }
                                    .padding(.horizontal, FTSpacing.lg)
                                } else {
                                    NoQuestionCard()
                                        .padding(.horizontal, FTSpacing.lg)
                                }
                            }

                            // Quick Stats
                            QuickStatsSection(tree: store.familyTree)
                                .padding(.horizontal, FTSpacing.lg)

                            Spacer()
                                .frame(height: FTSpacing.xxl)
                        }
                        .padding(.top, FTSpacing.sm)
                    }
                    .refreshable {
                        store.send(.refreshData)
                        try? await Task.sleep(nanoseconds: 500_000_000)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: Date())
    }
}

// MARK: - Home Header View
struct HomeHeaderView: View {
    let userName: String
    let familyName: String?

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: FTSpacing.xxs) {
                if let familyName = familyName {
                    Text(familyName)
                        .font(FTFont.caption())
                        .foregroundColor(FTColor.primary)
                        .padding(.horizontal, FTSpacing.sm)
                        .padding(.vertical, FTSpacing.xxs)
                        .background(FTColor.primaryLight)
                        .cornerRadius(FTRadius.full)
                }

                HStack(spacing: FTSpacing.xxs) {
                    Text("안녕하세요,")
                        .font(FTFont.body1())
                        .foregroundColor(FTColor.textSecondary)
                    Text("\(userName)님")
                        .font(FTFont.heading3())
                        .foregroundColor(FTColor.textPrimary)
                }
            }

            Spacer()

            // Profile Avatar
            Circle()
                .fill(FTColor.primaryLight)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(userName.prefix(1)))
                        .font(FTFont.body1Bold())
                        .foregroundColor(FTColor.primaryDark)
                )
        }
        .padding(.horizontal, FTSpacing.lg)
        .padding(.top, FTSpacing.md)
    }
}

// MARK: - Home Loading View
struct HomeLoadingView: View {
    @State private var isAnimating = false
    @State private var bounce: CGFloat = 0

    var body: some View {
        VStack(spacing: FTSpacing.lg) {
            // Animated Hedgehog Loading
            ZStack {
                Circle()
                    .fill(FTColor.primaryLight.opacity(0.3))
                    .frame(width: 100, height: 100)

                // 간단한 고슴도치 아이콘
                VStack(spacing: 0) {
                    // 가시
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Capsule()
                                .fill(Color(hex: "8B7355"))
                                .frame(width: 6, height: 15)
                        }
                    }
                    .offset(y: 5)

                    // 몸통
                    Ellipse()
                        .fill(Color(hex: "D4A574"))
                        .frame(width: 50, height: 35)
                        .overlay(
                            // 얼굴
                            HStack(spacing: 8) {
                                Circle().fill(Color.black).frame(width: 5, height: 5)
                                Circle().fill(Color.black).frame(width: 5, height: 5)
                            }
                            .offset(x: 8, y: -2)
                        )
                }
                .offset(y: bounce)
            }
            .scaleEffect(isAnimating ? 1.05 : 0.95)
            .animation(
                .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                value: isAnimating
            )

            Text("고슴도치들을 불러오는 중...")
                .font(FTFont.body1())
                .foregroundColor(FTColor.textSecondary)
        }
        .onAppear {
            isAnimating = true
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                bounce = -5
            }
        }
    }
}

// MARK: - No Family View
struct NoFamilyView: View {
    let onCreateFamily: () -> Void
    let onJoinFamily: () -> Void

    @State private var hedgehogBounce: CGFloat = 0

    var body: some View {
        VStack(spacing: FTSpacing.xl) {
            Spacer()

            // 외로운 고슴도치 일러스트
            ZStack {
                Circle()
                    .fill(FTColor.primaryLight)
                    .frame(width: 140, height: 140)

                // 간단한 고슴도치
                VStack(spacing: 0) {
                    // 가시
                    HStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { _ in
                            Capsule()
                                .fill(Color(hex: "8B7355"))
                                .frame(width: 8, height: 20)
                        }
                    }
                    .offset(y: 8)

                    // 몸통
                    Ellipse()
                        .fill(Color(hex: "D4A574"))
                        .frame(width: 70, height: 50)
                        .overlay(
                            // 슬픈 얼굴
                            VStack(spacing: 4) {
                                HStack(spacing: 12) {
                                    Circle().fill(Color.black).frame(width: 8, height: 8)
                                    Circle().fill(Color.black).frame(width: 8, height: 8)
                                }
                                // 슬픈 입
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: 5))
                                    path.addQuadCurve(
                                        to: CGPoint(x: 15, y: 5),
                                        control: CGPoint(x: 7.5, y: 0)
                                    )
                                }
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 15, height: 8)
                            }
                            .offset(x: 10, y: -3)
                        )
                }
                .offset(y: hedgehogBounce)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    hedgehogBounce = -5
                }
            }

            VStack(spacing: FTSpacing.sm) {
                Text("고슴도치 친구들을 모아보세요")
                    .font(FTFont.heading2())
                    .foregroundColor(FTColor.textPrimary)

                Text("가족 그룹을 만들면\n각자의 고슴도치가 함께 살아요")
                    .font(FTFont.body1())
                    .foregroundColor(FTColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(spacing: FTSpacing.sm) {
                FTButton("새 가족 만들기", style: .primary, icon: "sf.plus") {
                    onCreateFamily()
                }

                FTButton("초대 코드로 참여", style: .secondary) {
                    onJoinFamily()
                }
            }
            .padding(.horizontal, FTSpacing.xl)
            .padding(.top, FTSpacing.md)

            Spacer()
        }
        .padding(FTSpacing.lg)
    }
}

// MARK: - No Question Card
struct NoQuestionCard: View {
    var body: some View {
        FTCard {
            VStack(spacing: FTSpacing.md) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 36))
                    .foregroundColor(FTColor.textHint)

                Text("오늘의 질문이 준비 중이에요")
                    .font(FTFont.body1())
                    .foregroundColor(FTColor.textSecondary)

                Text("내일 새로운 질문이 도착할 거예요!")
                    .font(FTFont.caption())
                    .foregroundColor(FTColor.textHint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FTSpacing.lg)
        }
    }
}

// MARK: - Quick Stats Section
struct QuickStatsSection: View {
    let tree: TreeProgress

    var body: some View {
        HStack(spacing: FTSpacing.md) {
            QuickStatItem(
                icon: "bubble.left.and.bubble.right.fill",
                value: "\(tree.totalAnswers)",
                label: "총 답변",
                color: FTColor.primary
            )

            QuickStatItem(
                icon: "flame.fill",
                value: "\(tree.consecutiveDays)일",
                label: "연속 참여",
                color: .orange
            )

            QuickStatItem(
                icon: "heart.fill",
                value: hedgehogMood(tree.stage),
                label: "고슴도치 기분",
                color: Color(hex: "D4A574")
            )
        }
    }

    private func hedgehogMood(_ stage: TreeStage) -> String {
        switch stage {
        case .seed: return "졸려요"
        case .sprout: return "기대돼요"
        case .sapling: return "신나요"
        case .youngTree: return "행복해요"
        case .matureTree: return "뿌듯해요"
        case .flowering: return "최고예요"
        case .bound: return "감동이에요"
        }
    }
}

struct QuickStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: FTSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(FTFont.body1Bold())
                .foregroundColor(FTColor.textPrimary)

            Text(label)
                .font(FTFont.caption())
                .foregroundColor(FTColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FTSpacing.md)
        .background(FTColor.cardBackground)
        .cornerRadius(FTRadius.large)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Tree Preview Card
struct TreePreviewCard: View {
    let tree: TreeProgress
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            VStack(spacing: FTSpacing.md) {
                HStack {
                    Text("우리 가족 나무")
                        .font(FTFont.body1Bold())
                        .foregroundColor(FTColor.textPrimary)

                    Spacer()

                    Text("Lv.\(tree.consecutiveDays)")
                        .font(FTFont.captionBold())
                        .foregroundColor(FTColor.primary)
                        .padding(.horizontal, FTSpacing.sm)
                        .padding(.vertical, FTSpacing.xxs)
                        .background(FTColor.primaryLight)
                        .cornerRadius(FTRadius.full)
                }

                HStack(spacing: FTSpacing.lg) {
                    // Animated Tree
                    AnimatedTreeView(stage: tree.stage, size: 100)

                    VStack(alignment: .leading, spacing: FTSpacing.sm) {
                        Text(treeStageName(tree.stage))
                            .font(FTFont.heading3())
                            .foregroundColor(FTColor.textPrimary)

                        // Progress Bar
                        VStack(alignment: .leading, spacing: FTSpacing.xxs) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: FTRadius.full)
                                        .fill(FTColor.primaryLight)
                                        .frame(height: 8)

                                    RoundedRectangle(cornerRadius: FTRadius.full)
                                        .fill(
                                            LinearGradient(
                                                colors: [FTColor.primary, FTColor.accent3],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * progressPercentage(tree.stage), height: 8)
                                }
                            }
                            .frame(height: 8)

                            Text(nextStageText(tree.stage))
                                .font(FTFont.caption())
                                .foregroundColor(FTColor.textHint)
                        }
                    }
                }
            }
        }
    }

    private func treeStageName(_ stage: TreeStage) -> String {
        switch stage {
        case .seed: return "씨앗"
        case .sprout: return "새싹"
        case .sapling: return "작은 나무"
        case .youngTree: return "청년 나무"
        case .matureTree: return "큰 나무"
        case .flowering: return "꽃 피는 나무"
        case .bound: return "열매 맺는 나무"
        }
    }

    private func progressPercentage(_ stage: TreeStage) -> CGFloat {
        switch stage {
        case .seed: return 0.1
        case .sprout: return 0.25
        case .sapling: return 0.4
        case .youngTree: return 0.6
        case .matureTree: return 0.8
        case .flowering: return 1.0
        case .bound: return 1.0
        }
    }

    private func nextStageText(_ stage: TreeStage) -> String {
        switch stage {
        case .seed: return "다음 단계까지 5개 답변"
        case .sprout: return "다음 단계까지 10개 답변"
        case .sapling: return "다음 단계까지 15개 답변"
        case .youngTree: return "다음 단계까지 20개 답변"
        case .matureTree: return "다음 단계까지 10개 답변"
        case .flowering, .bound: return "최고 단계 달성!"
        }
    }
}

// MARK: - Family Members Section
struct FamilyMembersSection: View {
    let members: [User]

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            VStack(alignment: .leading, spacing: FTSpacing.md) {
                FTSectionHeader(
                    title: "가족 구성원",
                    subtitle: "\(members.count)명"
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FTSpacing.md) {
                        ForEach(members) { member in
                            FTMemberAvatar(
                                name: member.name,
                                size: 52,
                                showName: true
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Home - With Hedgehogs") {
    let dadId = UUID()
    let momId = UUID()
    let meId = UUID()
    let sisId = UUID()

    return HomeView(
        store: Store(initialState: HomeFeature.State(
            todayQuestion: Question(
                id: UUID(),
                content: "오늘 가장 감사했던 순간은 언제인가요?",
                category: .gratitude,
                order: 1
            ),
            familyTree: TreeProgress(
                stage: .youngTree,
                totalAnswers: 42,
                consecutiveDays: 7
            ),
            family: MongleGroup(
                id: UUID(),
                name: "우리 가족",
                memberIds: [dadId, momId, meId, sisId],
                createdBy: dadId,
                createdAt: .now,
                inviteCode: "ABCD1234",
                treeProgressId: UUID()
            ),
            familyMembers: [
                User(id: dadId, email: "dad@example.com", name: "아빠", profileImageURL: nil, role: .father, createdAt: .now),
                User(id: momId, email: "mom@example.com", name: "엄마", profileImageURL: nil, role: .mother, createdAt: .now),
                User(id: meId, email: "me@example.com", name: "나", profileImageURL: nil, role: .son, createdAt: .now),
                User(id: sisId, email: "sis@example.com", name: "여동생", profileImageURL: nil, role: .daughter, createdAt: .now)
            ],
            currentUser: User(id: meId, email: "me@example.com", name: "홍길동", profileImageURL: nil, role: .son, createdAt: .now),
            hasAnsweredToday: false,
            memberAnswerStatus: [dadId: true, momId: true, meId: false, sisId: false]
        )) {
            HomeFeature()
        }
    )
}

#Preview("Home - All Answered") {
    let dadId = UUID()
    let momId = UUID()
    let meId = UUID()

    return HomeView(
        store: Store(initialState: HomeFeature.State(
            todayQuestion: Question(
                id: UUID(),
                content: "가족과 함께한 가장 행복한 여행은 어디였나요?",
                category: .memory,
                order: 1
            ),
            familyTree: TreeProgress(
                stage: .matureTree,
                totalAnswers: 65,
                consecutiveDays: 14
            ),
            family: MongleGroup(
                id: UUID(),
                name: "행복한 우리집",
                memberIds: [dadId, momId, meId],
                createdBy: dadId,
                createdAt: .now,
                inviteCode: "XYZ98765",
                treeProgressId: UUID()
            ),
            familyMembers: [
                User(id: dadId, email: "dad@example.com", name: "아빠", profileImageURL: nil, role: .father, createdAt: .now),
                User(id: momId, email: "mom@example.com", name: "엄마", profileImageURL: nil, role: .mother, createdAt: .now),
                User(id: meId, email: "me@example.com", name: "나", profileImageURL: nil, role: .son, createdAt: .now)
            ],
            currentUser: User(id: meId, email: "me@example.com", name: "철수", profileImageURL: nil, role: .son, createdAt: .now),
            hasAnsweredToday: true,
            memberAnswerStatus: [dadId: true, momId: true, meId: true]
        )) {
            HomeFeature()
        }
    )
}

#Preview("Home - No Family (Lonely Hedgehog)") {
    HomeView(
        store: Store(initialState: HomeFeature.State(
            currentUser: User(id: UUID(), email: "me@example.com", name: "새로운 사용자", profileImageURL: nil, role: .son, createdAt: .now)
        )) {
            HomeFeature()
        }
    )
}

#Preview("Home - Loading") {
    HomeView(
        store: Store(initialState: HomeFeature.State(
            isLoading: true
        )) {
            HomeFeature()
        }
    )
}
