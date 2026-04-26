//
//  EmailLoginView.swift
//  MongleFeatures
//
//  이메일/비밀번호 로그인 입력 화면. EmailSignupView 의 inputFormView 와 동일한
//  디자인 언어(라벨+텍스트필드+에러 라벨+Primary 버튼)를 재사용한다.
//

import SwiftUI
import ComposableArchitecture

struct EmailLoginView: View {
    @Bindable var store: StoreOf<EmailLoginFeature>
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case email, password }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: MongleSpacing.lg) {
                    VStack(alignment: .leading, spacing: MongleSpacing.xs) {
                        Text(L10n.tr("email_auth_login_title"))
                            .font(MongleFont.heading1())
                            .foregroundStyle(MongleColor.textPrimary)
                        Text(L10n.tr("email_auth_login_subtitle"))
                            .font(MongleFont.body2())
                            .foregroundStyle(MongleColor.textSecondary)
                    }
                    .padding(.top, MongleSpacing.md)

                    labeledField(
                        label: L10n.tr("email_auth_email_label"),
                        icon: "envelope",
                        text: $store.email,
                        placeholder: L10n.tr("email_auth_email_placeholder"),
                        keyboardType: .emailAddress,
                        isSecure: false,
                        field: .email,
                        error: store.emailError
                    )

                    labeledField(
                        label: L10n.tr("email_auth_password_label"),
                        icon: "lock",
                        text: $store.password,
                        placeholder: L10n.tr("email_auth_password_placeholder"),
                        keyboardType: .default,
                        isSecure: true,
                        field: .password,
                        error: store.passwordError
                    )
                }
                .padding(.horizontal, MongleSpacing.xl)
                .padding(.bottom, MongleSpacing.xl)
            }

            Button {
                focusedField = nil
                store.send(.submitTapped)
            } label: {
                HStack {
                    if store.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(L10n.tr("email_auth_login_submit"))
                            .font(MongleFont.body1Bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MongleSpacing.md)
                .foregroundStyle(.white)
                .background(store.canSubmit ? MongleColor.primary : MongleColor.border)
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            }
            .disabled(!store.canSubmit)
            .padding(.horizontal, MongleSpacing.xl)
            .padding(.bottom, MongleSpacing.xl)
        }
        .background(MongleColor.background)
        .alert(
            "",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.send(.dismissError) } }
            ),
            actions: {
                Button(L10n.tr("common_confirm")) { store.send(.dismissError) }
            },
            message: { Text(store.errorMessage ?? "") }
        )
        .overlay {
            if store.showInvalidCredentialsAlert {
                MonglePopupView(
                    icon: .init(
                        systemName: "exclamationmark.lock.fill",
                        foregroundColor: MongleColor.error,
                        backgroundColor: MongleColor.bgErrorLight
                    ),
                    title: L10n.tr("email_login_invalid_title"),
                    description: L10n.tr("email_login_invalid_desc"),
                    primaryLabel: L10n.tr("common_confirm"),
                    onPrimary: { store.send(.dismissInvalidCredentialsAlert) }
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: store.showInvalidCredentialsAlert)
            }
        }
    }

    // MARK: - Helpers

    private var topBar: some View {
        HStack {
            Button {
                store.send(.backTapped)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MongleColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
        }
        .padding(.horizontal, MongleSpacing.sm)
        .padding(.top, MongleSpacing.xs)
    }

    @ViewBuilder
    private func labeledField(
        label: String,
        icon: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType,
        isSecure: Bool,
        field: Field,
        error: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: MongleSpacing.xs) {
            Text(label)
                .font(MongleFont.captionBold())
                .foregroundColor(MongleColor.textSecondary)

            HStack(spacing: MongleSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(MongleColor.textHint)
                Group {
                    if isSecure {
                        SecureField(
                            "",
                            text: text,
                            prompt: Text(placeholder).foregroundColor(MongleColor.textHint)
                        )
                    } else {
                        TextField(
                            "",
                            text: text,
                            prompt: Text(placeholder).foregroundColor(MongleColor.textHint)
                        )
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    }
                }
                .font(MongleFont.body2())
                .foregroundColor(MongleColor.textPrimary)
                .focused($focusedField, equals: field)
            }
            .padding(MongleSpacing.md)
            .background(Color.white)
            .cornerRadius(MongleRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: MongleRadius.large)
                    .stroke(
                        error != nil ? MongleColor.error
                        : focusedField == field ? MongleColor.primary
                        : MongleColor.border,
                        lineWidth: focusedField == field ? 1.5 : 1
                    )
            )

            if let error {
                Text(error)
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.error)
            }
        }
    }
}
