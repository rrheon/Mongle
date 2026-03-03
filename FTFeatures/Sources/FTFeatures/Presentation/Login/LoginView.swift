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
    @State private var googleProvider = GoogleLoginProvider()

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [FTColor.primaryLight.opacity(0.3), FTColor.surface, FTColor.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: FTSpacing.xl) {
                Spacer()

                // Logo Section
                VStack(spacing: FTSpacing.lg) {
                    ZStack {
                        Circle()
                            .fill(FTColor.primaryLight)
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1.05 : 1.0)

                        FTLogo(size: .large, type: .MongleImg)
                    }
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                    VStack(spacing: FTSpacing.xs) {
                        Text("Mongle")
                            .font(FTFont.heading1())
                            .foregroundColor(FTColor.textPrimary)

                        Text("가족과 함께 추억을 쌓아보세요")
                            .font(FTFont.body1())
                            .foregroundColor(FTColor.textSecondary)
                    }
                }

                Spacer()

                // Error Banner
                if let errorMessage = store.errorMessage {
                    FTErrorBanner(message: errorMessage) {
                        store.send(.dismissError)
                    }
                    .padding(.horizontal, FTSpacing.lg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Social Login Section
                VStack(spacing: FTSpacing.lg) {
                    HStack(spacing: FTSpacing.md) {
                        Rectangle()
                            .fill(FTColor.divider)
                            .frame(height: 1)
                        Text("간편 로그인")
                            .font(FTFont.caption())
                            .foregroundColor(FTColor.textHint)
                        Rectangle()
                            .fill(FTColor.divider)
                            .frame(height: 1)
                    }

                    HStack(spacing: FTSpacing.md) {
                        SocialLoginCircleButton(
                            icon: "kakao_icon",
                            backgroundColor: FTColor.kakao,
                            label: "카카오"
                        ) {
                            store.send(.socialLoginTapped(.kakao))
                            Task { @MainActor in
                                do {
                                    let credential = try await kakaoProvider.authenticate()
                                    store.send(.socialCredentialReceived(credential))
                                } catch {
                                    store.send(.socialLoginFailed(error.localizedDescription))
                                }
                            }
                        }

                        SocialLoginCircleButton(
                            icon: "naver_icon",
                            backgroundColor: FTColor.naver,
                            label: "네이버"
                        ) {
                            // TODO: NaverLoginProvider 구현 후 연결
                        }

                        // Google 로그인 - GoogleLoginProvider 연결
                        SocialLoginCircleButton(
                            icon: "google_icon",
                            backgroundColor: FTColor.surface,
                            label: "구글"
                        ) {
                            store.send(.socialLoginTapped(.google))
                            Task { @MainActor in
                                do {
                                    let credential = try await googleProvider.authenticate()
                                    store.send(.socialCredentialReceived(credential))
                                } catch {
                                    store.send(.socialLoginFailed(error.localizedDescription))
                                }
                            }
                        }

                        // Apple 로그인 - AppleLoginProvider 연결
                        SocialLoginCircleButton(
                            systemIcon: "apple.logo",
                            backgroundColor: FTColor.apple,
                            iconColor: FTColor.appleText,
                            label: "Apple"
                        ) {
                            store.send(.socialLoginTapped(.apple))
                            Task { @MainActor in
                                do {
                                    let credential = try await appleProvider.authenticate()
                                    store.send(.socialCredentialReceived(credential))
                                } catch {
                                    let nsError = error as NSError
                                    // 사용자가 직접 취소한 경우(1001)는 에러 표시 안 함
                                    guard nsError.domain != ASAuthorizationError.errorDomain
                                            || nsError.code != ASAuthorizationError.canceled.rawValue
                                    else { return }
                                    store.send(.socialLoginFailed(error.localizedDescription))
                                }
                            }
                        }
                    }
                    .disabled(store.isLoading)
                    .opacity(store.isLoading ? 0.5 : 1.0)
                }

                // Primary Actions
                VStack(spacing: FTSpacing.md) {
                    FTButton("이메일로 로그인", style: .primary) {
                        store.send(.emailLoginTapped)
                    }

                    FTButton("회원가입", style: .secondary) {
                        store.send(.emailSignupTapped)
                    }
                }
                .padding(.horizontal, FTSpacing.lg)
                .disabled(store.isLoading)

                // Guest mode
                Button {
                    // Guest mode
                } label: {
                    Text("둘러보기")
                        .font(FTFont.body2())
                        .foregroundColor(FTColor.textSecondary)
                        .underline()
                }
                .padding(.top, FTSpacing.sm)

                Spacer()
                    .frame(height: FTSpacing.lg)
            }
            .padding(.horizontal, FTSpacing.lg)

            // Loading Overlay
            if store.isLoading {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()

                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.4)
                    .tint(FTColor.primary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.isLoading)
        .animation(.easeInOut(duration: 0.2), value: store.errorMessage)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Social Login Circle Button

private struct SocialLoginCircleButton: View {
    var icon: String? = nil
    var systemIcon: String? = nil
    let backgroundColor: Color
    var iconColor: Color = .white
    let label: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: FTSpacing.xs) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 56, height: 56)
                        .shadow(color: backgroundColor.opacity(0.3), radius: 8, x: 0, y: 4)

                    if let icon = icon {
                        Image(icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    } else if let systemIcon = systemIcon {
                        Image(systemName: systemIcon)
                            .font(.system(size: 24))
                            .foregroundColor(iconColor)
                    }
                }
            }
            .buttonStyle(ScaleButtonStyle())

            Text(label)
                .font(FTFont.caption())
                .foregroundColor(FTColor.textSecondary)
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: FTSpacing.lg) {
            ZStack {
                Circle()
                    .fill(FTColor.primaryLight)
                    .frame(width: 140, height: 140)

                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(FTColor.primary)
            }

            VStack(spacing: FTSpacing.sm) {
                Text(title)
                    .font(FTFont.heading2())
                    .foregroundColor(FTColor.textPrimary)

                Text(description)
                    .font(FTFont.body1())
                    .foregroundColor(FTColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(FTSpacing.xl)
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
