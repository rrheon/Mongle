//
//  CreateFamilyView.swift
//  FamTree
//
//  Created by Claude on 2025-01-06.
//

import SwiftUI
import ComposableArchitecture
import Domain

struct CreateFamilyView: View {
    @Bindable var store: StoreOf<CreateFamilyFeature>
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                FTColor.surface
                    .ignoresSafeArea()

                if store.step == .invite, let family = store.createdFamily {
                    FamilyInviteSuccessView(family: family) {
                        store.send(.doneTapped)
                    }
                } else {
                    createFormView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if store.step == .form {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("취소") {
                            store.send(.cancelTapped)
                        }
                        .foregroundColor(FTColor.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Form View
    private var createFormView: some View {
        ScrollView {
            VStack(spacing: FTSpacing.xl) {
                // Header
                VStack(spacing: FTSpacing.sm) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(FTColor.primary)

                    Text("새 가족 만들기")
                        .font(FTFont.heading2())
                        .foregroundColor(FTColor.textPrimary)

                    Text("가족 이름을 정하고\n나의 역할을 선택해주세요")
                        .font(FTFont.body2())
                        .foregroundColor(FTColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, FTSpacing.xl)

                // Form
                VStack(spacing: FTSpacing.lg) {
                    // Family Name Input
                    VStack(alignment: .leading, spacing: FTSpacing.xs) {
                        Text("가족 이름")
                            .font(FTFont.body2())
                            .foregroundColor(FTColor.textSecondary)

                        TextField(
                            "예: 우리 가족, 행복한 우리집",
                            text: Binding(
                                get: { store.familyName },
                                set: { store.send(.familyNameChanged($0)) }
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

                    // Role Selection
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
                }
                .padding(.horizontal, FTSpacing.lg)

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

                // Create Button
                FTButton(
                    "가족 만들기",
                    style: .primary,
                    isLoading: store.isLoading
                ) {
                    isFocused = false
                    store.send(.createButtonTapped)
                }
                .disabled(!store.isValid || store.isLoading)
                .opacity(store.isValid ? 1 : 0.6)
                .padding(.horizontal, FTSpacing.lg)
            }
        }
    }
}

// MARK: - Family Invite Success View
struct FamilyInviteSuccessView: View {
    let family: Family
    let onDone: () -> Void

    @State private var showShareSheet = false
    @State private var codeScale: CGFloat = 0.8
    @State private var codeOpacity: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: FTSpacing.xl) {
                // Success Icon
                VStack(spacing: FTSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(FTColor.primaryLight)
                            .frame(width: 110, height: 110)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 58))
                            .foregroundColor(FTColor.success)
                    }

                    Text("가족이 만들어졌어요!")
                        .font(FTFont.heading2())
                        .foregroundColor(FTColor.textPrimary)

                    Text(family.name)
                        .font(FTFont.body1())
                        .foregroundColor(FTColor.textSecondary)
                }
                .padding(.top, FTSpacing.xxl)

                // Invite Code
                VStack(spacing: FTSpacing.sm) {
                    Text("초대 코드")
                        .font(FTFont.body2())
                        .foregroundColor(FTColor.textSecondary)

                    Text(family.inviteCode)
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .tracking(8)
                        .foregroundColor(FTColor.primary)
                        .padding(.horizontal, FTSpacing.xl)
                        .padding(.vertical, FTSpacing.md)
                        .background(FTColor.primaryLight)
                        .cornerRadius(FTRadius.large)
                        .scaleEffect(codeScale)
                        .opacity(codeOpacity)

                    Text("이 코드를 공유해 가족을 초대할 수 있어요")
                        .font(FTFont.caption())
                        .foregroundColor(FTColor.textHint)
                }

                // Invite Section
                VStack(spacing: FTSpacing.md) {
                    Text("사람들을 초대해보세요")
                        .font(FTFont.body1Bold())
                        .foregroundColor(FTColor.textPrimary)

                    // Share Button
                    Button {
                        showShareSheet = true
                    } label: {
                        HStack(spacing: FTSpacing.xs) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("초대 링크 공유하기")
                                .font(FTFont.button())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FTSpacing.md)
                        .background(FTColor.primary)
                        .cornerRadius(FTRadius.medium)
                    }
                    .padding(.horizontal, FTSpacing.lg)

                    // Info Tips
                    VStack(spacing: FTSpacing.xs) {
                        InviteTipRow(icon: "message.fill", text: "카카오톡, 메시지로 코드를 보내보세요")
                        InviteTipRow(icon: "link", text: "링크를 통해 앱으로 바로 접근할 수 있어요")
                    }
                    .padding(.horizontal, FTSpacing.lg)
                }

                // Done Button
                FTButton("시작하기", style: .secondary) {
                    onDone()
                }
                .padding(.horizontal, FTSpacing.lg)
                .padding(.bottom, FTSpacing.xxl)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [
                "가족 앱 FamTree에 참여해요! 🌳\n초대 코드: \(family.inviteCode)"
            ])
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.2)) {
                codeScale = 1.0
                codeOpacity = 1.0
            }
        }
    }
}

// MARK: - Invite Tip Row
private struct InviteTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: FTSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(FTColor.primary)
                .frame(width: 20)

            Text(text)
                .font(FTFont.caption())
                .foregroundColor(FTColor.textHint)

            Spacer()
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Role Selection Button
struct RoleSelectionButton: View {
    let role: FamilyRole
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: FTSpacing.xs) {
                Image(systemName: iconName)
                    .font(.system(size: 24))

                Text(role.rawValue)
                    .font(FTFont.body2())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, FTSpacing.md)
            .background(isSelected ? FTColor.primaryLight : FTColor.background)
            .foregroundColor(isSelected ? FTColor.primaryDark : FTColor.textSecondary)
            .cornerRadius(FTRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: FTRadius.medium)
                    .stroke(isSelected ? FTColor.primary : FTColor.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var iconName: String {
        switch role {
        case .father: return "figure.stand"
        case .mother: return "figure.stand.dress"
        case .son: return "figure.child"
        case .daughter: return "figure.child.and.lock.fill"
        case .other: return "person.fill"
        }
    }
}

// MARK: - FamilyRole Extension for allCases
extension FamilyRole: CaseIterable {
    public static var allCases: [FamilyRole] {
        [.father, .mother, .son, .daughter, .other]
    }
}

// MARK: - Previews
#Preview("Create Family") {
    CreateFamilyView(
        store: Store(initialState: CreateFamilyFeature.State()) {
            CreateFamilyFeature()
        }
    )
}

#Preview("Invite Success") {
    FamilyInviteSuccessView(
        family: Family(
            id: UUID(),
            name: "행복한 우리집",
            memberIds: [UUID()],
            createdBy: UUID(),
            createdAt: .now,
            inviteCode: "ABC12345",
            treeProgressId: UUID()
        ),
        onDone: {}
    )
}
