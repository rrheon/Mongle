//
//  EmailSignupView.swift
//  MongleFeatures
//
//  이메일 회원가입 플로우 View. phase 에 따라 Consent / 입력폼 / 인증코드 화면을 전환한다.
//

import SwiftUI
import ComposableArchitecture

struct EmailSignupView: View {
    @Bindable var store: StoreOf<EmailSignupFeature>
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case email, password, code }

    var body: some View {
        Group {
            switch store.phase {
            case .consent:
                ConsentView(store: store.scope(state: \.consent, action: \.consent))

            case .inputForm:
                inputFormView

            case .verifyCode:
                verifyCodeView
            }
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
    }

    // MARK: - Input Form

    private var inputFormView: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: MongleSpacing.lg) {
                    VStack(alignment: .leading, spacing: MongleSpacing.xs) {
                        Text(L10n.tr("email_auth_signup_title"))
                            .font(MongleFont.heading1())
                            .foregroundStyle(MongleColor.textPrimary)
                        Text(L10n.tr("email_auth_signup_subtitle"))
                            .font(MongleFont.body2())
                            .foregroundStyle(MongleColor.textSecondary)
                    }
                    .padding(.top, MongleSpacing.md)

                    // 이메일
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

                    // 비밀번호
                    labeledField(
                        label: L10n.tr("email_auth_password_label"),
                        icon: "lock",
                        text: $store.password,
                        placeholder: L10n.tr("email_auth_password_placeholder"),
                        keyboardType: .default,
                        isSecure: true,
                        field: .password,
                        error: store.passwordError,
                        hint: L10n.tr("email_auth_password_hint")
                    )
                }
                .padding(.horizontal, MongleSpacing.xl)
                .padding(.bottom, MongleSpacing.xl)
            }

            // 제출 버튼
            Button {
                focusedField = nil
                store.send(.sendCodeTapped)
            } label: {
                HStack {
                    if store.isSendingCode {
                        ProgressView().tint(.white)
                    } else {
                        Text(L10n.tr("email_auth_send_code"))
                            .font(MongleFont.body1Bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MongleSpacing.md)
                .foregroundStyle(.white)
                .background(store.canProceedFromInput ? MongleColor.primary : MongleColor.border)
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            }
            .disabled(!store.canProceedFromInput)
            .padding(.horizontal, MongleSpacing.xl)
            .padding(.bottom, MongleSpacing.xl)
        }
    }

    // MARK: - Verify Code

    private var verifyCodeView: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: MongleSpacing.lg) {
                    VStack(alignment: .leading, spacing: MongleSpacing.xs) {
                        Text(L10n.tr("email_auth_verify_title"))
                            .font(MongleFont.heading1())
                            .foregroundStyle(MongleColor.textPrimary)
                        Text(String(format: L10n.tr("email_auth_verify_subtitle"), store.email))
                            .font(MongleFont.body2())
                            .foregroundStyle(MongleColor.textSecondary)
                    }
                    .padding(.top, MongleSpacing.md)

                    // 코드 입력
                    VStack(alignment: .leading, spacing: MongleSpacing.xs) {
                        Text(L10n.tr("email_auth_code_label"))
                            .font(MongleFont.captionBold())
                            .foregroundStyle(MongleColor.textSecondary)

                        HStack(spacing: MongleSpacing.sm) {
                            Image(systemName: "number")
                                .font(.system(size: 16))
                                .foregroundColor(MongleColor.textHint)
                            TextField(
                                "",
                                text: $store.code,
                                prompt: Text("000000").foregroundColor(MongleColor.textHint)
                            )
                            .font(MongleFont.body1())
                            .foregroundColor(MongleColor.textPrimary)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .focused($focusedField, equals: .code)
                        }
                        .padding(MongleSpacing.md)
                        .background(Color.white)
                        .cornerRadius(MongleRadius.large)
                        .overlay(
                            RoundedRectangle(cornerRadius: MongleRadius.large)
                                .stroke(
                                    store.codeError != nil ? MongleColor.error
                                    : focusedField == .code ? MongleColor.primary
                                    : MongleColor.border,
                                    lineWidth: focusedField == .code ? 1.5 : 1
                                )
                        )

                        if let error = store.codeError {
                            Text(error)
                                .font(MongleFont.caption())
                                .foregroundColor(MongleColor.error)
                        }
                    }

                    // 재전송 안내
                    HStack {
                        Spacer()
                        if store.resendCooldownSec > 0 {
                            Text(String(format: L10n.tr("email_auth_resend_cooldown"), store.resendCooldownSec))
                                .font(MongleFont.caption())
                                .foregroundStyle(MongleColor.textHint)
                        } else {
                            Button {
                                store.send(.resendCodeTapped)
                            } label: {
                                Text(L10n.tr("email_auth_resend"))
                                    .font(MongleFont.caption())
                                    .foregroundStyle(MongleColor.primary)
                                    .underline()
                            }
                        }
                    }
                }
                .padding(.horizontal, MongleSpacing.xl)
                .padding(.bottom, MongleSpacing.xl)
            }

            Button {
                focusedField = nil
                store.send(.verifyTapped)
            } label: {
                HStack {
                    if store.isVerifying {
                        ProgressView().tint(.white)
                    } else {
                        Text(L10n.tr("email_auth_verify_submit"))
                            .font(MongleFont.body1Bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MongleSpacing.md)
                .foregroundStyle(.white)
                .background(store.canSubmitCode ? MongleColor.primary : MongleColor.border)
                .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
            }
            .disabled(!store.canSubmitCode)
            .padding(.horizontal, MongleSpacing.xl)
            .padding(.bottom, MongleSpacing.xl)
        }
        .onAppear {
            focusedField = .code
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
        error: String?,
        hint: String? = nil
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
            } else if let hint {
                Text(hint)
                    .font(MongleFont.caption())
                    .foregroundColor(MongleColor.textHint)
            }
        }
    }
}
