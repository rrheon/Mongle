//
//  LoginView.swift
//  Mongle
//
//  Created by 최용헌 on 12/12/25.
//

import SwiftUI
import AuthenticationServices
import ComposableArchitecture

// MARK: - Login View

struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>

    @State private var isAnimating = false
    @State private var appleProvider = AppleLoginProvider()
    @State private var kakaoProvider = KakaoLoginProvider()

    var body: some View {
        ZStack {
            // Background
            Color(hex: "F5F4F1")
                .ignoresSafeArea()

            VStack(spacing: MongleSpacing.xl) {
                Spacer()

              // Logo Section
              VStack(spacing: MongleSpacing.xs) {
                  MongleLogo(size: .large, type: .MongleLogo)
                    .animation(
                      .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                      value: isAnimating
                    )
                  
                  Text("몽글")
                    .font(MongleFont.heading1())
                    .foregroundColor(MongleColor.textPrimary)
                  
                  Text("오늘의 마음은 어떤 색인가요?")
                    .font(MongleFont.body1())
                    .foregroundColor(MongleColor.textSecondary)
                }

                Spacer()

                // Error Banner
                if let errorMessage = store.errorMessage {
                    MongleErrorBanner(message: errorMessage) {
                        store.send(.dismissError)
                    }
                    .padding(.horizontal, MongleSpacing.lg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Login Buttons
                VStack(spacing: MongleSpacing.md) {
                    SocialLoginButton(provider: .kakao) {
                        performSocialLogin(type: .kakao) { try await kakaoProvider.authenticate() }
                    }
                    SocialLoginButton(provider: .apple) {
                        performSocialLogin(type: .apple, ignoreCancellation: true) { try await appleProvider.authenticate() }
                    }
                }
                .padding(.horizontal, MongleSpacing.lg)
                .disabled(store.isLoading)
                .opacity(store.isLoading ? 0.5 : 1.0)

                // Guest mode
                Button {
                    // Guest mode
                } label: {
                    Text("둘러보기")
                        .font(MongleFont.body2())
                        .foregroundColor(MongleColor.textSecondary)
                        .underline()
                }
                .padding(.top, MongleSpacing.xs)

                Spacer()
                    .frame(height: MongleSpacing.lg)
            }
            .padding(.horizontal, MongleSpacing.lg)

            // Loading Overlay
            if store.isLoading {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.4)
                    .tint(MongleColor.primary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.isLoading)
        .animation(.easeInOut(duration: 0.2), value: store.errorMessage)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Private Helpers

private extension LoginView {
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

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: MongleSpacing.lg) {
            ZStack {
                Circle()
                    .fill(MongleColor.primaryLight)
                    .frame(width: 140, height: 140)

                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(MongleColor.primary)
            }

            VStack(spacing: MongleSpacing.sm) {
                Text(title)
                    .font(MongleFont.heading2())
                    .foregroundColor(MongleColor.textPrimary)

                Text(description)
                    .font(MongleFont.body1())
                    .foregroundColor(MongleColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(MongleSpacing.xl)
    }
}

#Preview("Login") {
    LoginView(
        store: Store(initialState: LoginFeature.State()) {
            LoginFeature()
        }
    )
}

#Preview("Login - Loading") {
    LoginView(
        store: Store(initialState: LoginFeature.State(isLoading: true)) {
            LoginFeature()
        }
    )
}

#Preview("Login - Error") {
    LoginView(
        store: Store(initialState: LoginFeature.State(errorMessage: "Apple 로그인에 실패했습니다.")) {
            LoginFeature()
        }
    )
}

#Preview("Onboarding Page") {
    OnboardingPageView(
        icon: "leaf.fill",
        title: "가족 나무를 키워요",
        description: "매일 질문에 답하면\n가족 나무가 성장해요"
    )
}
