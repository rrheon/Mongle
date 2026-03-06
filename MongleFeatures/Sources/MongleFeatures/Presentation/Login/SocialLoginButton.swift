//
//  SocialLoginButton.swift
//  Mongle
//
//  Created by 최용헌 on 12/12/25.
//

import SwiftUI

struct SocialLoginButton: View {
    enum Provider {
        case kakao
        case apple
        case google
        case naver

        var title: String {
            switch self {
            case .kakao:  return "카카오로 시작하기"
            case .apple:  return "Apple로 시작하기"
            case .google: return "Google로 시작하기"
            case .naver:  return "네이버로 시작하기"
            }
        }

        var backgroundColor: Color {
            switch self {
            case .kakao:  return MongleColor.kakao
            case .apple:  return MongleColor.apple
            case .google: return .white
            case .naver:  return Color(hex: "03C75A")
            }
        }

        var foregroundColor: Color {
            switch self {
            case .kakao:  return Color(hex: "191919")
            case .apple:  return MongleColor.appleText
            case .google: return Color(hex: "191919")
            case .naver:  return .white
            }
        }

        @ViewBuilder
        var icon: some View {
            switch self {
            case .kakao:
                Image("kakao_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            case .apple:
                Image(systemName: "apple.logo")
                    .font(.system(size: 18))
            case .google:
                Image("google_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            case .naver:
                Image("naver_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
        }
    }

    let provider: Provider
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MongleSpacing.sm) {
                provider.icon
                Text(provider.title)
                    .font(MongleFont.button())
                    .foregroundColor(provider.foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(provider.backgroundColor)
            .cornerRadius(MongleRadius.large)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SocialLoginButton(provider: .kakao)  {}
        SocialLoginButton(provider: .apple)  {}
        SocialLoginButton(provider: .google) {}
        SocialLoginButton(provider: .naver)  {}
    }
    .padding()
}
