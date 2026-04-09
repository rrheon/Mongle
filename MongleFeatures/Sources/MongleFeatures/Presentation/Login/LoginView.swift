//
//  LoginView.swift
//  Mongle
//
//  Created by 최용헌 on 12/12/25.
//

import SwiftUI
import AuthenticationServices
import ComposableArchitecture

struct LoginView: View {
  @Bindable var store: StoreOf<LoginFeature>
  
  @State private var appleProvider = AppleLoginProvider()
  @State private var kakaoProvider = KakaoLoginProvider()
  @State private var googleProvider = GoogleLoginProvider()
  
  var body: some View {
    GeometryReader { geo in
      VStack(spacing: 0) {
        // 로고 영역 - 상단 60% 차지
        VStack(spacing: MongleSpacing.md) {
          MongleLogo(size: .large, type: .MongleLogo)
            .padding(.top, MongleSpacing.xxl)

          Text(L10n.tr("login_title"))
            .font(MongleFont.heading1())
            .foregroundStyle(.black)

          Text(L10n.tr("login_subtitle"))
            .font(MongleFont.body1())
            .foregroundStyle(MongleColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: geo.size.height * 0.55)

        Spacer()

        // 버튼 영역 - 하단 고정
        VStack(spacing: MongleSpacing.xs) {
          socialButtonGroup
        }
        .padding(.horizontal, MongleSpacing.xl)
        .padding(.bottom, MongleSpacing.xl)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .overlay {
      if store.isLoading {
        Color.black.opacity(0.15)
          .ignoresSafeArea()
        ProgressView()
          .progressViewStyle(.circular)
          .scaleEffect(1.4)
          .tint(MongleColor.primary)
      }
    }
    .background(MongleColor.background)
    .mongleErrorToast(
      error: store.appError,
      onDismiss: { store.send(.dismissError) }
    )
    .animation(.easeInOut(duration: 0.2), value: store.isLoading)
    .animation(.easeInOut(duration: 0.2), value: store.errorMessage)
    .sheet(isPresented: Binding(
      get: { store.showEmailChoiceSheet },
      set: { if !$0 { store.send(.emailChoiceSheetDismissed) } }
    )) {
      emailChoiceSheet
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(MongleColor.background)
    }
  }

  // MARK: - Email Login/Signup Choice Sheet

  private var emailChoiceSheet: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center) {
        Text(L10n.tr("login_email_sheet_title"))
          .font(MongleFont.body1Bold())
          .foregroundColor(MongleColor.textPrimary)

        Spacer(minLength: MongleSpacing.sm)

        Button {
          store.send(.emailChoiceSheetDismissed)
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(MongleColor.textSecondary)
            .frame(width: 32, height: 32)
            .background(MongleColor.bgNeutral)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, MongleSpacing.lg)
      .padding(.top, MongleSpacing.lg)
      .padding(.bottom, MongleSpacing.md)

      VStack(spacing: 0) {
        emailChoiceRow(
          icon: "person.crop.circle",
          title: L10n.tr("login_email_sheet_login"),
          subtitle: L10n.tr("login_email_sheet_login_desc")
        ) {
          store.send(.emailLoginOptionTapped)
        }

        Divider().padding(.leading, 60)

        emailChoiceRow(
          icon: "person.badge.plus",
          title: L10n.tr("login_email_sheet_signup"),
          subtitle: L10n.tr("login_email_sheet_signup_desc")
        ) {
          store.send(.emailSignupOptionTapped)
        }
      }
      .background(Color.white)
      .cornerRadius(MongleRadius.xl)
      .padding(.horizontal, MongleSpacing.md)
      .padding(.bottom, MongleSpacing.lg)
    }
    .frame(maxWidth: .infinity, alignment: .top)
    .background(MongleColor.background)
  }

  private func emailChoiceRow(
    icon: String,
    title: String,
    subtitle: String,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: MongleSpacing.md) {
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(MongleColor.primary)
          .frame(width: 44, height: 44)
          .background(MongleColor.primary.opacity(0.1))
          .clipShape(Circle())

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(MongleFont.body2Bold())
            .foregroundColor(MongleColor.textPrimary)
          Text(subtitle)
            .font(MongleFont.caption())
            .foregroundColor(MongleColor.textSecondary)
        }

        Spacer(minLength: 0)

        Image(systemName: "chevron.right")
          .font(.system(size: 14))
          .foregroundColor(MongleColor.textHint)
      }
      .padding(.horizontal, MongleSpacing.md)
      .padding(.vertical, MongleSpacing.md)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
  
  // MARK: SNS 로그인 버튼 그룹
  private var socialButtonGroup: some View {
    VStack(spacing: MongleSpacing.md) {
      SocialLoginButton(provider: .kakao) {
        performSocialLogin(type: .kakao) { try await kakaoProvider.authenticate() }
      }
      .disabled(store.isLoading)
      
      SocialLoginButton(provider: .google) {
        performSocialLogin(type: .google) { try await googleProvider.authenticate() }
      }
      .disabled(store.isLoading)
      
      SocialLoginButton(provider: .apple) {
        performSocialLogin(type: .apple, ignoreCancellation: true) { try await appleProvider.authenticate() }
      }
      .disabled(store.isLoading)

      // 이메일로 계속하기 — Apple 버튼 아래
      Button {
        store.send(.emailContinueTapped)
      } label: {
        HStack(spacing: MongleSpacing.sm) {
          Image(systemName: "envelope.fill")
            .font(.system(size: 18, weight: .semibold))
          Text(L10n.tr("login_email"))
            .font(MongleFont.body1Bold())
        }
        .foregroundStyle(Color.black)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color.white)
        .overlay(
          RoundedRectangle(cornerRadius: MongleRadius.large)
            .stroke(Color.black.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: MongleRadius.large))
      }
      .disabled(store.isLoading)

      Button {
        store.send(.browseTapped)
      } label: {
        Text(L10n.tr("login_browse"))
          .font(MongleFont.body2())
          .foregroundStyle(MongleColor.textHint)
      }
    }
    .opacity(store.isLoading ? 0.5 : 1.0)
  }
}


// MARK: LoginView Extension

private extension LoginView {
  func heroChip(_ title: String) -> some View {
    Text(title)
      .font(MongleFont.captionBold())
      .foregroundColor(MongleColor.primaryDark)
      .padding(.horizontal, MongleSpacing.sm)
      .padding(.vertical, MongleSpacing.xxs)
      .background(Color.white.opacity(0.88))
      .clipShape(Capsule())
  }
  
  func performSocialLogin(
    type: SocialProviderType,
    ignoreCancellation: Bool = false,
    authenticate: @escaping () async throws -> any SocialLoginCredential
  ) {
    store.send(.socialLoginTapped(type))
    Task { @MainActor in
      do {
        let credential = try await authenticate()
        store.send(.socialCredentialReceived(credential))
      } catch {
        if ignoreCancellation {
          let nsError = error as NSError
          guard nsError.domain != ASAuthorizationError.errorDomain
                  || nsError.code != ASAuthorizationError.canceled.rawValue
          else { return }
        }
        store.send(.socialLoginFailed(error.localizedDescription))
      }
    }
  }
}

#Preview("Login") {
  LoginView(
    store: Store(initialState: LoginFeature.State()) {
      LoginFeature()
    }
  )
}
