import SwiftUI
import ComposableArchitecture

// MARK: - 04-B · Write Question

public struct WriteQuestionView: View {
    @Bindable var store: StoreOf<WriteQuestionFeature>
    @FocusState private var isTextEditorFocused: Bool

    public init(store: StoreOf<WriteQuestionFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            navigationHeader
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MongleSpacing.lg) {
                    descriptionSection
                    textEditorSection
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, MongleSpacing.md)
                .padding(.top, MongleSpacing.lg)
                .padding(.bottom, MongleSpacing.xxl)
            }
            submitButton
        }
        .background(MongleColor.background)
        .onTapGesture {
            isTextEditorFocused = false
        }
        .mongleErrorToast(
            error: store.appError,
            onDismiss: { store.send(.setAppError(nil)) }
        )
    }

    // MARK: - Navigation Header

    private var navigationHeader: some View {
        MongleNavigationHeader(title: L10n.tr("write_title")) {
            MongleBackButton { store.send(.closeTapped) }
        } right: {
            EmptyView()
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            Text(L10n.tr("write_section_title"))
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)
            Text(L10n.tr("write_section_desc"))
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textSecondary)
                .lineSpacing(3)
        }
    }

    // MARK: - Text Editor

    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            Text(L10n.tr("write_field_label"))
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textHint)

            ZStack(alignment: .topLeading) {
                if store.questionText.isEmpty {
                    Text(L10n.tr("write_placeholder"))
                        .font(MongleFont.body2())
                        .foregroundColor(MongleColor.textHint)
                        .padding(.top, 12)
                        .padding(.leading, 5)
                }
                TextEditor(text: $store.questionText.sending(\.questionTextChanged))
                    .font(MongleFont.body2())
                    .foregroundColor(MongleColor.textPrimary)
                    .frame(minHeight: 120)
                    .focused($isTextEditorFocused)
                    .scrollContentBackground(.hidden)
            }
            .padding(MongleSpacing.sm)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.medium)
                    .stroke(
                        isTextEditorFocused ? MongleColor.primary : MongleColor.border,
                        lineWidth: isTextEditorFocused ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isTextEditorFocused)

            HStack {
                Spacer()
                Text(L10n.tr("write_char_count", store.questionText.count))
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        VStack(spacing: 0) {
            Divider()
            MongleButtonPrimary(store.isSubmitting ? L10n.tr("common_loading") : L10n.tr("write_submit")) {
                store.send(.submitTapped)
            }
            .opacity((store.canSubmit && !store.isSubmitting) ? 1 : 0.5)
            .disabled(!store.canSubmit || store.isSubmitting)
            .padding(.horizontal, MongleSpacing.md)
            .padding(.vertical, MongleSpacing.md)
        }
        .background(Color.white)
    }
}
