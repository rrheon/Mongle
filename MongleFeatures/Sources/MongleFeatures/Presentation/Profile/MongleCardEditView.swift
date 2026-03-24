//
//  MongleCardEditView.swift
//  Mongle
//

import SwiftUI
import ComposableArchitecture
import Domain

public struct MongleCardEditView: View {
    @Bindable var store: StoreOf<MongleCardEditFeature>

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
        .alert("변경 실패", isPresented: Binding(
            get: { store.saveError != nil },
            set: { if !$0 { store.send(.dismissSaveError) } }
        )) {
            Button("확인", role: .cancel) { store.send(.dismissSaveError) }
        } message: {
            Text(store.saveError?.userMessage ?? "")
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
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(MongleScaleButtonStyle())

            Spacer()

            Text("프로필 편집")
                .font(MongleFont.heading3())
                .foregroundColor(MongleColor.textPrimary)

            Spacer()

            Button {
                store.send(.saveTapped)
            } label: {
                Text("저장")
                    .font(MongleFont.body1Bold())
                    .foregroundColor(store.isValid ? MongleColor.primarySoft : MongleColor.textHint)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(MongleScaleButtonStyle())
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
            monggleForMood
                .animation(.spring(response: 0.3), value: store.selectedMoodId)

            Text("기분을 바꾸면 색이 변해요")
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textHint)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var monggleForMood: some View {
        switch store.selectedMoodId {
        case "happy":   MongleMonggle.yellow(size: 80)
        case "calm":    MongleMonggle.green(size: 80)
        case "loved":   MongleMonggle.pink(size: 80)
        case "sad":     MongleMonggle.blue(size: 80)
        case "tired":   MongleMonggle.orange(size: 80)
        default:        MongleMonggle.pink(size: 80)
        }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("이름")
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)

            MongleInputText(
                placeholder: "이름 입력",
                text: $store.editedName.sending(\.nameChanged),
                icon: "person.fill"
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
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)

            let moodBinding = Binding<MoodOption?>(
                get: { MoodOption.defaults.first { $0.id == store.selectedMoodId } },
                set: { if let newId = $0?.id { store.send(.moodSelected(newId)) } }
            )
            MongleMoodSelector(selected: moodBinding)
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
