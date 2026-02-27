//
//  JoinFamilyView.swift
//  FamTree
//
//  Created by Claude on 2025-01-06.
//

import SwiftUI
import ComposableArchitecture
import Domain

struct JoinFamilyView: View {
    @Bindable var store: StoreOf<JoinFamilyFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.surface
                    .ignoresSafeArea()

                if store.step == .profile {
                    ProfileCreationView(store: store)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    searchView
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: store.step)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if store.step == .profile {
                        Button {
                            store.send(.backToSearch)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("뒤로")
                            }
                            .foregroundColor(FTColor.textSecondary)
                        }
                    } else {
                        Button("취소") {
                            store.send(.cancelTapped)
                        }
                        .foregroundColor(FTColor.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Search View
    private var searchView: some View {
        ScrollView {
            VStack(spacing: FTSpacing.xl) {
                // Header
                VStack(spacing: FTSpacing.sm) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(FTColor.primary)

                    Text("가족 참여하기")
                        .font(FTFont.heading2())
                        .foregroundColor(FTColor.textPrimary)

                    Text("초대 코드를 입력하여\n가족에 참여해보세요")
                        .font(FTFont.body2())
                        .foregroundColor(FTColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, FTSpacing.xl)

                // Form
                VStack(spacing: FTSpacing.lg) {
                    // Invite Code Input
                    VStack(alignment: .leading, spacing: FTSpacing.xs) {
                        Text("초대 코드")
                            .font(FTFont.body2())
                            .foregroundColor(FTColor.textSecondary)

                        HStack(spacing: FTSpacing.sm) {
                            TextField(
                                "ABCD1234",
                                text: Binding(
                                    get: { store.inviteCode },
                                    set: { store.send(.inviteCodeChanged($0)) }
                                )
                            )
                            .font(FTFont.heading3())
                            .textCase(.uppercase)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .padding(FTSpacing.md)
                            .background(FTColor.background)
                            .cornerRadius(FTRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: FTRadius.medium)
                                    .stroke(FTColor.border, lineWidth: 1)
                            )

                            Button {
                                store.send(.searchButtonTapped)
                            } label: {
                                if store.isSearching {
                                    ProgressView()
                                        .frame(width: 52, height: 52)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 20, weight: .semibold))
                                        .frame(width: 52, height: 52)
                                }
                            }
                            .background(store.isValidCode ? FTColor.primary : FTColor.textHint)
                            .foregroundColor(.white)
                            .cornerRadius(FTRadius.medium)
                            .disabled(!store.isValidCode || store.isSearching)
                        }
                    }

                    // Found Family Card
                    if let family = store.foundFamily {
                        FoundFamilyCard(family: family)
                            .transition(.opacity.combined(with: .scale))
                    }

                    // Role Selection (only show when family is found)
                    if store.foundFamily != nil {
                        VStack(alignment: .leading, spacing: FTSpacing.xs) {
                            Text("나의 역할")
                                .font(FTFont.body2())
                                .foregroundColor(FTColor.textSecondary)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: FTSpacing.sm) {
                                ForEach(FamilyRole.allCases, id: \.self) { role in
                                    RoleSelectionButton(
                                        role: role,
                                        isSelected: store.selectedRole == role
                                    ) {
                                        store.send(.roleSelected(role))
                                    }
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, FTSpacing.lg)
                .animation(.easeInOut(duration: 0.3), value: store.foundFamily != nil)

                // Error Message
                if let errorMessage = store.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(FTColor.error)
                        Text(errorMessage)
                            .font(FTFont.body2())
                            .foregroundColor(FTColor.error)
                    }
                    .padding(FTSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(FTColor.error.opacity(0.1))
                    .cornerRadius(FTRadius.medium)
                    .padding(.horizontal, FTSpacing.lg)
                }

                Spacer()
                    .frame(height: FTSpacing.xl)

                // Join Button
                if store.foundFamily != nil {
                    FTButton(
                        "다음 단계로",
                        style: .primary,
                        isLoading: store.isLoading
                    ) {
                        store.send(.joinButtonTapped)
                    }
                    .disabled(!store.canJoin)
                    .padding(.horizontal, FTSpacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
    }
}

// MARK: - Profile Creation View
struct ProfileCreationView: View {
    @Bindable var store: StoreOf<JoinFamilyFeature>
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: FTSpacing.xl) {
                // Header
                VStack(spacing: FTSpacing.md) {
                    // 캐릭터 아이콘 (선택된 색상 반영)
                    ZStack {
                        Circle()
                            .fill(avatarColor.opacity(0.2))
                            .frame(width: 110, height: 110)

                        Image(systemName: "person.fill")
                            .font(.system(size: 52))
                            .foregroundColor(avatarColor)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: store.selectedMoodColor)

                    Text("프로필을 만들어보세요")
                        .font(FTFont.heading2())
                        .foregroundColor(FTColor.textPrimary)

                    Text("가족 내에서 사용할\n이름과 색상을 선택해요")
                        .font(FTFont.body2())
                        .foregroundColor(FTColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, FTSpacing.xl)

                // 이름 입력
                VStack(alignment: .leading, spacing: FTSpacing.xs) {
                    Text("이름")
                        .font(FTFont.body2())
                        .foregroundColor(FTColor.textSecondary)

                    TextField(
                        "이름을 입력해주세요",
                        text: Binding(
                            get: { store.profileName },
                            set: { store.send(.profileNameChanged($0)) }
                        )
                    )
                    .font(FTFont.body1())
                    .padding(FTSpacing.md)
                    .background(FTColor.background)
                    .cornerRadius(FTRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: FTRadius.medium)
                            .stroke(FTColor.border, lineWidth: 1)
                    )
                    .focused($isFocused)
                }
                .padding(.horizontal, FTSpacing.lg)

                // 기분 색상 선택 (선택사항)
                VStack(alignment: .leading, spacing: FTSpacing.sm) {
                    HStack(spacing: FTSpacing.xs) {
                        Text("기분 색상 선택")
                            .font(FTFont.body2())
                            .foregroundColor(FTColor.textSecondary)

                        Text("선택사항")
                            .font(FTFont.caption())
                            .foregroundColor(FTColor.textHint)
                            .padding(.horizontal, FTSpacing.xs)
                            .padding(.vertical, 2)
                            .background(FTColor.surface)
                            .cornerRadius(FTRadius.full)
                    }
                    .padding(.horizontal, FTSpacing.lg)

                    Text("지금 기분을 색상으로 표현해보세요 (미선택 시 기본 색상)")
                        .font(FTFont.caption())
                        .foregroundColor(FTColor.textHint)
                        .padding(.horizontal, FTSpacing.lg)

                    // Color grid
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 4),
                        spacing: FTSpacing.md
                    ) {
                        ForEach(MoodColor.allCases, id: \.self) { mood in
                            MoodColorButton(
                                mood: mood,
                                isSelected: store.selectedMoodColor == mood
                            ) {
                                let newValue: MoodColor? = (store.selectedMoodColor == mood) ? nil : mood
                                store.send(.moodColorSelected(newValue))
                            }
                        }
                    }
                    .padding(.horizontal, FTSpacing.lg)
                }

                // Error Message
                if let errorMessage = store.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(FTColor.error)
                        Text(errorMessage)
                            .font(FTFont.body2())
                            .foregroundColor(FTColor.error)
                    }
                    .padding(FTSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(FTColor.error.opacity(0.1))
                    .cornerRadius(FTRadius.medium)
                    .padding(.horizontal, FTSpacing.lg)
                }

                // 확인 버튼
                FTButton(
                    "프로필 완성하기",
                    style: .primary,
                    isLoading: store.isLoading
                ) {
                    isFocused = false
                    store.send(.confirmProfileTapped)
                }
                .disabled(!store.canConfirmProfile)
                .opacity(store.canConfirmProfile ? 1 : 0.6)
                .padding(.horizontal, FTSpacing.lg)
                .padding(.bottom, FTSpacing.xxl)
            }
        }
    }

    private var avatarColor: Color {
        if let mood = store.selectedMoodColor {
            return Color(hex: mood.hexString)
        }
        return FTColor.primary
    }
}

// MARK: - Mood Color Button
struct MoodColorButton: View {
    let mood: MoodColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FTSpacing.xxs) {
                Circle()
                    .fill(Color(hex: mood.hexString))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color(hex: mood.hexString) : Color.clear, lineWidth: 3)
                            .padding(-4)
                    )
                    .shadow(
                        color: isSelected ? Color(hex: mood.hexString).opacity(0.4) : Color.clear,
                        radius: 6, x: 0, y: 3
                    )
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                Text(mood.label)
                    .font(FTFont.caption())
                    .foregroundColor(isSelected ? Color(hex: mood.hexString) : FTColor.textSecondary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Found Family Card
struct FoundFamilyCard: View {
    let family: Family

    var body: some View {
        VStack(spacing: FTSpacing.md) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(FTColor.success)

                Text("가족을 찾았습니다!")
                    .font(FTFont.body1())
                    .fontWeight(.semibold)
                    .foregroundColor(FTColor.textPrimary)

                Spacer()
            }

            HStack {
                VStack(alignment: .leading, spacing: FTSpacing.xxs) {
                    Text(family.name)
                        .font(FTFont.heading3())
                        .foregroundColor(FTColor.textPrimary)

                    Text("구성원 \(family.memberIds.count)명")
                        .font(FTFont.caption())
                        .foregroundColor(FTColor.textSecondary)
                }

                Spacer()

                Image(systemName: "house.fill")
                    .font(.system(size: 40))
                    .foregroundColor(FTColor.primaryLight)
            }
        }
        .padding(FTSpacing.lg)
        .background(FTColor.success.opacity(0.1))
        .cornerRadius(FTRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: FTRadius.large)
                .stroke(FTColor.success.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Previews
#Preview("Join Family - Empty") {
    JoinFamilyView(
        store: Store(initialState: JoinFamilyFeature.State()) {
            JoinFamilyFeature()
        }
    )
}

#Preview("Join Family - Found") {
    JoinFamilyView(
        store: Store(initialState: JoinFamilyFeature.State(
            inviteCode: "TESTCODE",
            foundFamily: Family(
                id: UUID(),
                name: "행복한 가족",
                memberIds: [UUID(), UUID(), UUID()],
                createdBy: UUID(),
                createdAt: .now,
                inviteCode: "TESTCODE",
                treeProgressId: UUID()
            )
        )) {
            JoinFamilyFeature()
        }
    )
}

#Preview("Profile Creation") {
    let state = JoinFamilyFeature.State(
        inviteCode: "TESTCODE",
        foundFamily: Family(
            id: UUID(),
            name: "행복한 가족",
            memberIds: [UUID(), UUID()],
            createdBy: UUID(),
            createdAt: .now,
            inviteCode: "TESTCODE",
            treeProgressId: UUID()
        )
    )
    ProfileCreationView(
        store: Store(initialState: {
            var s = state
            s.step = .profile
            return s
        }()) {
            JoinFamilyFeature()
        }
    )
}
