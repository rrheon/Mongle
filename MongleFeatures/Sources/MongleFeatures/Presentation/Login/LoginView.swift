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

          Text("몽글")
            .font(MongleFont.heading1())
            
          Text("오늘의 마음은 어떤 색인가요?")
            .font(MongleFont.body1())
            .foregroundStyle(MongleColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: geo.size.height * 0.55)

        Spacer()

        // 버튼 영역 - 하단 고정
        VStack(spacing: MongleSpacing.xs) {
          socialButtonGroup

          if let errorMessage = store.errorMessage {
            MongleErrorBanner(message: errorMessage) {
              store.send(.dismissError)
            }
          }
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
    .animation(.easeInOut(duration: 0.2), value: store.isLoading)
    .animation(.easeInOut(duration: 0.2), value: store.errorMessage)
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
      
      Button {
        print("둘러보기")
      } label: {
        Text("둘러보기")
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
