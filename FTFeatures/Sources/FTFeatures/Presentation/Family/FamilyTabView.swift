//
//  FamilyTabView.swift
//  FamTree
//
//  Created by Claude on 2025-01-06.
//

import SwiftUI
import ComposableArchitecture
import Domain

struct FamilyTabView: View {
    @Bindable var store: StoreOf<FamilyFeature>
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [FTColor.surface, FTColor.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if store.isLoading && store.family == nil {
                    FamilyLoadingView()
                } else if store.hasFamily {
                    FamilyMainContent(store: store)
                } else {
                    FamilyOnboardingView(
                        onCreateTapped: { store.send(.createFamilyTapped) },
                        onJoinTapped: { store.send(.joinFamilyTapped) }
                    )
                }

                // Toast
                if store.showInviteCodeCopied {
                    VStack {
                        Spacer()
                        FTToast(message: "초대 코드가 복사되었습니다")
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, FTSpacing.xxl)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showInviteCodeCopied)
                }
            }
            .navigationTitle("가족")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

// MARK: - Family Loading View
private struct FamilyLoadingView: View {
    @State private var scale: CGFloat = 0.9

    var body: some View {
        VStack(spacing: FTSpacing.lg) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(FTColor.primary)
                .scaleEffect(scale)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: scale
                )

            Text("가족 정보를 불러오는 중...")
                .font(FTFont.body1())
                .foregroundColor(FTColor.textSecondary)
        }
        .onAppear {
            scale = 1.1
        }
    }
}

// MARK: - Family Main Content
private struct FamilyMainContent: View {
    @Bindable var store: StoreOf<FamilyFeature>

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: FTSpacing.lg) {
                // Family Hero Card
                FamilyHeroCard(
                    familyName: store.family?.name ?? "",
                    memberCount: store.members.count,
                    createdAt: store.family?.createdAt ?? .now
                )
                .padding(.horizontal, FTSpacing.lg)
                .padding(.top, FTSpacing.sm)

                // Hedgehog Grid
                FamilyHedgehogGridSection(
                    members: store.members,
                    onCopyTapped: { store.send(.copyInviteCodeTapped) }
                )
                .padding(.horizontal, FTSpacing.lg)

                // Invite Section
                InviteCodeCard(
                    inviteCode: store.inviteCode,
                    onCopyTapped: { store.send(.copyInviteCodeTapped) }
                )
                .padding(.horizontal, FTSpacing.lg)

                // Members List
                FamilyMembersList(
                    members: store.members,
                    currentUserId: store.currentUser?.id
                )
                .padding(.horizontal, FTSpacing.lg)

                // Error
                if let errorMessage = store.errorMessage {
                    FTErrorBanner(message: errorMessage) {
                        store.send(.dismissErrorTapped)
                    }
                    .padding(.horizontal, FTSpacing.lg)
                }

                // Leave Button
                if !store.isCreator {
                    Button {
                        store.send(.leaveFamilyTapped)
                    } label: {
                        HStack(spacing: FTSpacing.xs) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("가족 떠나기")
                        }
                        .font(FTFont.body2())
                        .foregroundColor(FTColor.error)
                    }
                    .padding(.top, FTSpacing.lg)
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

// MARK: - Family Hero Card
private struct FamilyHeroCard: View {
    let familyName: String
    let memberCount: Int
    let createdAt: Date

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            VStack(spacing: FTSpacing.lg) {
                // Family Icon
                ZStack {
                    Circle()
                        .fill(FTColor.primaryLight)
                        .frame(width: 88, height: 88)

                    Image(systemName: "house.fill")
                        .font(.system(size: 40))
                        .foregroundColor(FTColor.primary)
                }

                // Family Name
                Text(familyName)
                    .font(FTFont.heading2())
                    .foregroundColor(FTColor.textPrimary)

                // Stats
                HStack(spacing: FTSpacing.xl) {
                    FamilyStatBubble(
                        icon: "person.2.fill",
                        value: "\(memberCount)명",
                        label: "구성원"
                    )

                    Rectangle()
                        .fill(FTColor.divider)
                        .frame(width: 1, height: 40)

                    FamilyStatBubble(
                        icon: "calendar",
                        value: formattedDate,
                        label: "시작일"
                    )

                    Rectangle()
                        .fill(FTColor.divider)
                        .frame(width: 1, height: 40)

                    FamilyStatBubble(
                        icon: "heart.fill",
                        value: "\(daysSinceCreation)일",
                        label: "함께한 날"
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        return formatter.string(from: createdAt)
    }

    private var daysSinceCreation: Int {
        let days = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        return max(1, days)
    }
}

// MARK: - Family Stat Bubble
private struct FamilyStatBubble: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: FTSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(FTColor.primary)

            Text(value)
                .font(FTFont.body1Bold())
                .foregroundColor(FTColor.textPrimary)

            Text(label)
                .font(FTFont.caption())
                .foregroundColor(FTColor.textSecondary)
        }
    }
}

// MARK: - Invite Code Card
private struct InviteCodeCard: View {
    let inviteCode: String
    let onCopyTapped: () -> Void

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            VStack(alignment: .leading, spacing: FTSpacing.md) {
                FTSectionHeader(
                    title: "초대 코드",
                    subtitle: "가족을 초대해보세요"
                )

                HStack {
                    // Code Display
                    HStack(spacing: FTSpacing.xs) {
                        Image(systemName: "key.fill")
                            .foregroundColor(FTColor.primary)
                        Text(inviteCode)
                            .font(FTFont.heading3())
                            .foregroundColor(FTColor.primary)
                            .tracking(3)
                    }
                    .padding(.horizontal, FTSpacing.md)
                    .padding(.vertical, FTSpacing.sm)
                    .background(FTColor.primaryLight)
                    .cornerRadius(FTRadius.medium)

                    Spacer()

                    // Copy Button
                    Button(action: onCopyTapped) {
                        HStack(spacing: FTSpacing.xs) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 14))
                            Text("복사")
                                .font(FTFont.buttonSmall())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, FTSpacing.md)
                        .padding(.vertical, FTSpacing.sm)
                        .background(FTColor.primary)
                        .cornerRadius(FTRadius.medium)
                    }
                }

                Text("초대 코드를 공유하면 가족이 참여할 수 있어요")
                    .font(FTFont.caption())
                    .foregroundColor(FTColor.textHint)
            }
        }
    }
}

// MARK: - Family Members List
private struct FamilyMembersList: View {
    let members: [User]
    let currentUserId: UUID?

    var body: some View {
        FTCard(cornerRadius: FTRadius.xl) {
            VStack(alignment: .leading, spacing: FTSpacing.md) {
                HStack {
                    Text("가족 구성원")
                        .font(FTFont.body1Bold())
                        .foregroundColor(FTColor.textPrimary)

                    Text("\(members.count)")
                        .font(FTFont.captionBold())
                        .foregroundColor(.white)
                        .padding(.horizontal, FTSpacing.sm)
                        .padding(.vertical, FTSpacing.xxs)
                        .background(FTColor.primary)
                        .cornerRadius(FTRadius.full)

                    Spacer()
                }

                VStack(spacing: FTSpacing.xs) {
                    ForEach(members) { member in
                        FamilyMemberRow(
                            member: member,
                            isCurrentUser: member.id == currentUserId
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Family Member Row
private struct FamilyMemberRow: View {
    let member: User
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: FTSpacing.md) {
            // Avatar
            FTMemberAvatar(
                name: member.name,
                size: 52,
                showName: false
            )

            // Info
            VStack(alignment: .leading, spacing: FTSpacing.xxs) {
                HStack(spacing: FTSpacing.xs) {
                    Text(member.name)
                        .font(FTFont.body1Bold())
                        .foregroundColor(FTColor.textPrimary)

                    if isCurrentUser {
                        Text("나")
                            .font(FTFont.captionBold())
                            .foregroundColor(.white)
                            .padding(.horizontal, FTSpacing.xs)
                            .padding(.vertical, 2)
                            .background(FTColor.primary)
                            .cornerRadius(FTRadius.full)
                    }
                }

                HStack(spacing: FTSpacing.xxs) {
                    Image(systemName: roleIcon)
                        .font(.system(size: 12))
                    Text(member.role.rawValue)
                        .font(FTFont.caption())
                }
                .foregroundColor(FTColor.textSecondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(FTColor.textHint)
        }
        .padding(FTSpacing.sm)
        .background(FTColor.surface)
        .cornerRadius(FTRadius.medium)
    }

    private var roleIcon: String {
        switch member.role {
        case .father: return "figure.stand"
        case .mother: return "figure.stand.dress"
        case .son: return "figure.and.child.holdinghands"
        case .daughter: return "figure.and.child.holdinghands"
        case .other: return "person.fill"
        }
    }
}

// MARK: - Family Hedgehog Grid Section
private struct FamilyHedgehogGridSection: View {
    let members: [User]
    let onCopyTapped: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: FTSpacing.md),
        GridItem(.flexible(), spacing: FTSpacing.md)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: FTSpacing.md) {
            FTSectionHeader(
                title: "우리 가족 고슴도치",
                subtitle: "\(members.count)마리"
            )

            LazyVGrid(columns: columns, spacing: FTSpacing.md) {
                ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                    FamilyHedgehogCard(member: member, animationDelay: Double(index) * 0.3)
                }

                FamilyInviteCard(onTapped: onCopyTapped)
            }
        }
    }
}

// MARK: - Family Hedgehog Card
private struct FamilyHedgehogCard: View {
    let member: User
    let animationDelay: Double

    @State private var floatOffset: CGFloat = 0
    @State private var isPressed: Bool = false

    var body: some View {
        HedgehogView(
            name: member.name,
            color: roleColor(for: member.role),
            hasAnswered: false,
            hasCurrentUserAnswered: false,
            onViewAnswer: {},
            onAnswerQuestion: {}
        )
        .padding(.vertical, FTSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: FTRadius.xl)
                .fill(FTColor.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .offset(y: floatOffset)
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.8)
                .delay(animationDelay)
                .repeatForever(autoreverses: true)
            ) {
                floatOffset = -5
            }
        }
        .onTapGesture {
            isPressed = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                isPressed = false
            }
        }
    }

    private func roleColor(for role: FamilyRole) -> Color {
        switch role {
        case .father: return FTColor.primary
        case .mother: return Color.pink
        case .son: return Color.blue.opacity(0.8)
        case .daughter: return Color.purple.opacity(0.8)
        case .other: return FTColor.textSecondary
        }
    }
}

// MARK: - Family Invite Card
private struct FamilyInviteCard: View {
    let onTapped: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: onTapped) {
            VStack(spacing: FTSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(FTColor.primaryLight)
                        .frame(width: 48, height: 48)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(FTColor.primary)
                }
                .padding(.top, FTSpacing.md)

                Text("초대하기")
                    .font(FTFont.body1())
                    .foregroundColor(FTColor.textSecondary)
            }
            .padding(.vertical, FTSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: FTRadius.xl)
                    .fill(FTColor.surface.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: FTRadius.xl)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                            )
                            .foregroundColor(FTColor.divider)
                    )
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Family Onboarding View
private struct FamilyOnboardingView: View {
    let onCreateTapped: () -> Void
    let onJoinTapped: () -> Void

    var body: some View {
        VStack(spacing: FTSpacing.xl) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(FTColor.primaryLight)
                    .frame(width: 140, height: 140)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 56))
                    .foregroundColor(FTColor.primary)
            }

            VStack(spacing: FTSpacing.sm) {
                Text("가족과 함께 시작해요")
                    .font(FTFont.heading2())
                    .foregroundColor(FTColor.textPrimary)

                Text("가족 그룹을 만들고\n매일 서로의 이야기를 나눠보세요")
                    .font(FTFont.body1())
                    .foregroundColor(FTColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(spacing: FTSpacing.md) {
                FTButton("새 가족 만들기", style: .primary, icon: "sf.plus") {
                    onCreateTapped()
                }

                FTButton("초대 코드로 참여", style: .secondary, icon: "sf.person.badge.key") {
                    onJoinTapped()
                }
            }
            .padding(.horizontal, FTSpacing.xl)
            .padding(.top, FTSpacing.md)

            Spacer()
        }
        .padding(FTSpacing.lg)
    }
}

// MARK: - Previews
#Preview("Family Tab - With Family") {
    FamilyTabView(
        store: Store(initialState: FamilyFeature.State(
            family: Family(
                id: UUID(),
                name: "우리 가족",
                memberIds: [UUID(), UUID(), UUID()],
                createdBy: UUID(),
                createdAt: .now,
                inviteCode: "ABC12345",
                treeProgressId: UUID()
            ),
            members: [
                User(id: UUID(), email: "dad@example.com", name: "아빠", profileImageURL: nil, role: .father, createdAt: .now),
                User(id: UUID(), email: "mom@example.com", name: "엄마", profileImageURL: nil, role: .mother, createdAt: .now),
                User(id: UUID(), email: "me@example.com", name: "나", profileImageURL: nil, role: .son, createdAt: .now)
            ],
            currentUser: User(id: UUID(), email: "me@example.com", name: "나", profileImageURL: nil, role: .son, createdAt: .now)
        )) {
            FamilyFeature()
        }
    )
}

#Preview("Family Tab - No Family") {
    FamilyTabView(
        store: Store(initialState: FamilyFeature.State()) {
            FamilyFeature()
        }
    )
}

#Preview("Family Tab - Loading") {
    FamilyTabView(
        store: Store(initialState: FamilyFeature.State(isLoading: true)) {
            FamilyFeature()
        }
    )
}
