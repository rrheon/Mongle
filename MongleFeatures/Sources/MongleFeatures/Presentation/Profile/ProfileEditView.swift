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
                MongleColor.background.ignoresSafeArea()

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
                    .foregroundColor(MongleColor.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        store.send(.saveButtonTapped)
                    }
                    .font(MongleFont.body1Bold())
                    .foregroundColor(store.hasChanges && store.isValid ? MongleColor.primary : MongleColor.textHint)
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
            VStack(spacing: MongleSpacing.lg) {
                // 프로필 이미지
                profileImageSection

                // 이름 입력
                nameInputSection

                // 역할 선택
                roleSelectionSection

                // 이메일 (읽기 전용)
                emailSection
            }
            .padding(MongleSpacing.md)
        }
    }

    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: MongleSpacing.sm) {
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
                        .fill(MongleColor.primary)
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
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.primary)
        }
        .padding(.vertical, MongleSpacing.md)
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(MongleColor.primaryLight)
            .frame(width: 100, height: 100)
            .overlay(
                Text(store.editedName.prefix(1).uppercased())
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(MongleColor.primary)
            )
    }

    // MARK: - Name Input Section
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            Text("이름")
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)

            TextField("이름을 입력하세요", text: $store.editedName.sending(\.nameChanged))
                .font(MongleFont.body1())
                .padding(MongleSpacing.md)
                .background(MongleColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: MongleRadius.small)
                        .stroke(MongleColor.border, lineWidth: 1)
                )
        }
    }

    // MARK: - Role Selection Section
    private var roleSelectionSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            Text("가족 역할")
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)

            Button {
                store.send(.showRolePickerToggled)
            } label: {
                HStack {
                    Text(store.editedRole.rawValue)
                        .font(MongleFont.body1())
                        .foregroundColor(MongleColor.textPrimary)

                    Spacer()

                    Image(systemName: store.showRolePicker ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(MongleColor.textSecondary)
                }
                .padding(MongleSpacing.md)
                .background(MongleColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: MongleRadius.small)
                        .stroke(MongleColor.border, lineWidth: 1)
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
                                    .font(MongleFont.body1())
                                    .foregroundColor(MongleColor.textPrimary)

                                Spacer()

                                if store.editedRole == role {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(MongleColor.primary)
                                }
                            }
                            .padding(MongleSpacing.md)
                            .background(store.editedRole == role ? MongleColor.primaryLight : Color.clear)
                        }

                        if role != .other {
                            Divider()
                                .background(MongleColor.divider)
                        }
                    }
                }
                .background(MongleColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.small))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
    }

    // MARK: - Email Section
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            Text("이메일")
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)

            HStack {
                Text(store.user?.email ?? "")
                    .font(MongleFont.body1())
                    .foregroundColor(MongleColor.textHint)

                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(MongleColor.textHint)
            }
            .padding(MongleSpacing.md)
            .background(MongleColor.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.small))

            Text("이메일은 변경할 수 없습니다")
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textHint)
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: MongleSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)

            Text("프로필 불러오는 중...")
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textSecondary)
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
