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
        .overlay {
            if let error = store.saveError {
                MonglePopupView(
                    icon: .init(
                        systemName: "exclamationmark.circle.fill",
                        foregroundColor: MongleColor.error,
                        backgroundColor: MongleColor.bgErrorSoft
                    ),
                    title: L10n.tr("settings_change_failed"),
                    description: error.userMessage,
                    primaryLabel: L10n.tr("common_confirm"),
                    onPrimary: { store.send(.dismissSaveError) }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: store.saveError != nil)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        MongleNavigationHeader(title: L10n.tr("settings_profile_edit")) {
            MongleBackButton { store.send(.backTapped) }
        } right: {
            Button { store.send(.saveTapped) } label: {
                Text(L10n.tr("common_save"))
                    .font(MongleFont.body1Bold())
                    .foregroundColor(store.isValid ? MongleColor.primarySoft : MongleColor.textHint)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(MongleScaleButtonStyle())
            .disabled(!store.isValid || store.isSaving)
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                avatarSection
                nameSection
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
            MongleMonggle.forMood(store.selectedMoodId, size: 80)
                .animation(.spring(response: 0.3), value: store.selectedMoodId)

            Text(L10n.tr("settings_mood_hint"))
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textHint)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr("settings_name_label"))
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)

            MongleInputText(
                placeholder: L10n.tr("settings_name_placeholder"),
                text: $store.editedName.sending(\.nameChanged),
                icon: "person.fill"
            )

            Text(L10n.tr("settings_name_hint"))
                .font(MongleFont.caption())
                .foregroundColor(MongleColor.textHint)
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
