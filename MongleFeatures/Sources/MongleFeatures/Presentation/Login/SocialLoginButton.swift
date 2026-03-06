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
    }

    let provider: Provider
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MongleSpacing.sm) {
                iconView
                Text(provider.title)
                    .font(MongleFont.button())
                    .foregroundColor(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundColor)
            .cornerRadius(MongleRadius.large)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch provider {
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

    private var backgroundColor: Color {
        switch provider {
        case .kakao:  return MongleColor.kakao
        case .apple:  return MongleColor.apple
        case .google: return .white
        case .naver:  return MongleColor.naver
        }
    }

    private var foregroundColor: Color {
        switch provider {
        case .kakao:  return MongleColor.kakaoText
        case .apple:  return MongleColor.appleText
        case .google: return MongleColor.textPrimary
        case .naver:  return MongleColor.naverText
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
