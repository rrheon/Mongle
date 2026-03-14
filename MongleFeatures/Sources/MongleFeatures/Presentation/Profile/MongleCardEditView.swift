//
//  MongleCardEditView.swift
//  Mongle
//

import SwiftUI
import ComposableArchitecture
import Domain

public struct MongleCardEditView: View {
    @Bindable var store: StoreOf<MongleCardEditFeature>
    @State private var selectedMood: MoodOption? = MoodOption.defaults.first(where: { $0.id == "loved" })

    public init(store: StoreOf<MongleCardEditFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            scrollContent
        }
        .background(MongleColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: selectedMood) { _, newMood in
            if let id = newMood?.id {
                store.send(.moodSelected(id))
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                store.send(.backTapped)
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(MongleColor.textPrimary)
            }

            Spacer()

            Text("프로필 편집")
                .font(.custom("Outfit", size: 18).weight(.semibold))
                .foregroundColor(MongleColor.textPrimary)

            Spacer()

            Button {
                store.send(.saveTapped)
            } label: {
                Text("저장")
                    .font(.custom("Outfit", size: 15).weight(.bold))
                    .foregroundColor(store.isValid ? MongleColor.primarySoft : MongleColor.textHint)
            }
            .disabled(!store.isValid || store.isSaving)
        }
        .frame(height: 56)
        .padding(.top, MongleSpacing.sm)
        .padding(.horizontal, MongleSpacing.md)
        .background(Color.white.ignoresSafeArea(edges: .top))
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                avatarSection
                nameSection
                moodSection
                Spacer(minLength: 0)
            }
            .padding(.top, 28)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [avatarStartColor, avatarEndColor],
                            center: .init(x: 0.35, y: 0.35),
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: avatarEndColor.opacity(0.27), radius: 12, x: 0, y: 4)

                // Left eye
                Circle()
                    .fill(MongleColor.textPrimary)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5).frame(width: 15, height: 15))
                    .offset(x: -10, y: 2)

                // Right eye
                Circle()
                    .fill(MongleColor.textPrimary)
                    .frame(width: 13, height: 13)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5).frame(width: 15, height: 15))
                    .offset(x: 10, y: 2)
            }

            Text("기분을 바꾸면 색이 변해요")
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textHint)
        }
        .frame(maxWidth: .infinity)
    }

    private var avatarStartColor: Color {
        switch store.selectedMoodId {
        case "happy":   return MongleColor.moodHappyLight
        case "calm":    return MongleColor.moodCalmLight
        case "loved":   return MongleColor.moodLovedLight
        case "sad":     return MongleColor.moodSadLight
        case "tired":   return MongleColor.moodTiredLight
        default:        return MongleColor.moodLovedLight
        }
    }

    private var avatarEndColor: Color {
        switch store.selectedMoodId {
        case "happy":   return MongleColor.moodHappy
        case "calm":    return MongleColor.moodCalm
        case "loved":   return MongleColor.moodLoved
        case "sad":     return MongleColor.moodSad
        case "tired":   return MongleColor.moodTired
        default:        return MongleColor.moodLoved
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이름")
                .font(.custom("Outfit", size: 14).weight(.semibold))
                .foregroundColor(MongleColor.textPrimary)

            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MongleColor.primary)

                TextField("이름 입력", text: $store.editedName.sending(\.nameChanged))
                    .font(.custom("Outfit", size: 16).weight(.medium))
                    .foregroundColor(MongleColor.textPrimary)
            }
            .frame(height: 52)
            .padding(.horizontal, MongleSpacing.md)
            .background(MongleColor.cardBackgroundSolid)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.medium)
                    .stroke(MongleColor.moodCalm, lineWidth: 1.5)
            )

            Text("다른 멤버에게 보여지는 이름이에요")
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textHint)
        }
    }

    // MARK: - Mood Section

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘의 기분")
                .font(.custom("Outfit", size: 14).weight(.semibold))
                .foregroundColor(MongleColor.textPrimary)

            MongleMoodSelector(selected: $selectedMood)
        }
    }
}

// MARK: - Preview

#Preview {
    MongleCardEditView(
        store: Store(initialState: MongleCardEditFeature.State(
            user: User(
                id: UUID(),
                email: "test@mongle.app",
                name: "Mom",
                profileImageURL: nil,
                role: .mother,
                createdAt: Date()
            )
        )) {
            MongleCardEditFeature()
        }
    )
}
