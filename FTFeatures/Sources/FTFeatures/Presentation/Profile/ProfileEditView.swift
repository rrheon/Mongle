//
//  ProfileEditView.swift
//  Mongle
//
//  Created by Claude on 1/9/26.
//

import SwiftUI
import ComposableArchitecture
import Domain

public struct ProfileEditView: View {
    @Bindable var store: StoreOf<ProfileEditFeature>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<ProfileEditFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                FTColor.background.ignoresSafeArea()

                if store.isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        store.send(.cancelButtonTapped)
                    }
                    .foregroundColor(FTColor.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        store.send(.saveButtonTapped)
                    }
                    .font(FTFont.body1Bold())
                    .foregroundColor(store.hasChanges && store.isValid ? FTColor.primary : FTColor.textHint)
                    .disabled(!store.hasChanges || !store.isValid || store.isSaving)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }

    // MARK: - Content View
    private var contentView: some View {
        ScrollView {
            VStack(spacing: FTSpacing.lg) {
                // 프로필 이미지
                profileImageSection

                // 이름 입력
                nameInputSection

                // 역할 선택
                roleSelectionSection

                // 이메일 (읽기 전용)
                emailSection
            }
            .padding(FTSpacing.md)
        }
    }

    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: FTSpacing.sm) {
            Button {
                store.send(.profileImageTapped)
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    // 프로필 이미지
                    if let urlString = store.profileImageURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            profilePlaceholder
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else {
                        profilePlaceholder
                    }

                    // 편집 아이콘
                    Circle()
                        .fill(FTColor.primary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                        .offset(x: 4, y: 4)
                }
            }

            Text("사진 변경")
                .font(FTFont.caption())
                .foregroundColor(FTColor.primary)
        }
        .padding(.vertical, FTSpacing.md)
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(FTColor.primaryLight)
            .frame(width: 100, height: 100)
            .overlay(
                Text(store.editedName.prefix(1).uppercased())
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(FTColor.primary)
            )
    }

    // MARK: - Name Input Section
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: FTSpacing.xs) {
            Text("이름")
                .font(FTFont.captionBold())
                .foregroundColor(FTColor.textSecondary)

            TextField("이름을 입력하세요", text: $store.editedName.sending(\.nameChanged))
                .font(FTFont.body1())
                .padding(FTSpacing.md)
                .background(FTColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FTRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: FTRadius.small)
                        .stroke(FTColor.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Role Selection Section
    private var roleSelectionSection: some View {
        VStack(alignment: .leading, spacing: FTSpacing.xs) {
            Text("가족 역할")
                .font(FTFont.captionBold())
                .foregroundColor(FTColor.textSecondary)

            Button {
                store.send(.showRolePickerToggled)
            } label: {
                HStack {
                    Text(store.editedRole.rawValue)
                        .font(FTFont.body1())
                        .foregroundColor(FTColor.textPrimary)

                    Spacer()

                    Image(systemName: store.showRolePicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(FTColor.textSecondary)
                }
                .padding(FTSpacing.md)
                .background(FTColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FTRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: FTRadius.small)
                        .stroke(FTColor.border, lineWidth: 1)
                )
            }

            // 역할 선택 옵션
            if store.showRolePicker {
                VStack(spacing: 0) {
                    ForEach([FamilyRole.father, .mother, .son, .daughter, .other], id: \.self) { role in
                        Button {
                            store.send(.roleChanged(role))
                        } label: {
                            HStack {
                                Text(role.rawValue)
                                    .font(FTFont.body1())
                                    .foregroundColor(FTColor.textPrimary)

                                Spacer()

                                if store.editedRole == role {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(FTColor.primary)
                                }
                            }
                            .padding(FTSpacing.md)
                            .background(store.editedRole == role ? FTColor.primaryLight : Color.clear)
                        }

                        if role != .other {
                            Divider()
                                .background(FTColor.divider)
                        }
                    }
                }
                .background(FTColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: FTRadius.small))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }

    // MARK: - Email Section
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: FTSpacing.xs) {
            Text("이메일")
                .font(FTFont.captionBold())
                .foregroundColor(FTColor.textSecondary)

            HStack {
                Text(store.user?.email ?? "")
                    .font(FTFont.body1())
                    .foregroundColor(FTColor.textHint)

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(FTColor.textHint)
            }
            .padding(FTSpacing.md)
            .background(FTColor.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: FTRadius.small))

            Text("이메일은 변경할 수 없습니다")
                .font(FTFont.caption())
                .foregroundColor(FTColor.textHint)
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: FTSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("프로필 불러오는 중...")
                .font(FTFont.body2())
                .foregroundColor(FTColor.textSecondary)
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileEditView(
        store: Store(initialState: ProfileEditFeature.State()) {
            ProfileEditFeature()
        }
    )
}
