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
        HStack {
            Button {
                store.send(.closeTapped)
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MongleColor.textPrimary)
                    .frame(width: 24, height: 24)
            }
            Spacer()
            Text("나만의 질문 작성하기")
                .font(MongleFont.heading3())
                .foregroundColor(MongleColor.textPrimary)
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, MongleSpacing.md)
        .frame(height: 56)
        .background(Color.white)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            Text("가족에게 묻고 싶은 질문을 작성해요")
                .font(MongleFont.body1Bold())
                .foregroundColor(MongleColor.textPrimary)
            Text("작성한 질문은 오늘의 질문으로 등록돼요.\n가족 모두가 답변할 수 있어요 🌿")
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textSecondary)
                .lineSpacing(3)
        }
    }

    // MARK: - Text Editor

    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: MongleSpacing.sm) {
            Text("질문")
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textHint)

            ZStack(alignment: .topLeading) {
                if store.questionText.isEmpty {
                    Text("예) 오늘 하루 가장 기억에 남는 순간은 무엇인가요?")
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
                Text("\(store.questionText.count) 자")
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        VStack(spacing: 0) {
            Divider()
            MongleButtonPrimary(store.isSubmitting ? "등록 중..." : "질문 등록하기") {
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
