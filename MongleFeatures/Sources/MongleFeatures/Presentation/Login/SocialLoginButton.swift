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

        var title: String {
            switch self {
            case .kakao:  return L10n.tr("login_kakao")
            case .apple:  return L10n.tr("login_apple")
            case .google: return L10n.tr("login_google")
            }
        }

        var font: Font {
            switch self {
            case .kakao: return .system(size: 16, weight: .semibold)
            default:     return MongleFont.button()
            }
        }

        // 카카오 공식 가이드: 12px / 그 외: MongleRadius.large(16)
        var cornerRadius: CGFloat {
            switch self {
            case .kakao: return MongleRadius.medium // 12px
            default:     return MongleRadius.large  // 16px
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
                    .font(provider.font)
                    .foregroundColor(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundColor)
            .cornerRadius(provider.cornerRadius)
            .overlay(borderOverlay)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch provider {
        case .kakao:
            KakaoLogoIcon(size: 20)

        case .apple:
            Image(systemName: "apple.logo")
                .font(.system(size: 18))
                .foregroundColor(foregroundColor)
        case .google:
            GoogleLogoIcon(size: 20)
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch provider {
        case .google, .apple:
            // Apple HIG variant 3: 흰 배경 + 검정 로고/텍스트 + 검정 테두리.
            // Google 브랜딩 가이드: 흰 배경 + 검정 테두리 허용.
            RoundedRectangle(cornerRadius: provider.cornerRadius)
                .stroke(Color.black.opacity(0.3), lineWidth: 1)
        default:
            EmptyView()
        }
    }

    private var backgroundColor: Color {
        switch provider {
        case .kakao:  return MongleColor.kakao
        case .apple:  return .white // HIG variant 3 (white background)
        case .google: return .white
        }
    }

    private var foregroundColor: Color {
        switch provider {
        case .kakao:  return Color.black.opacity(0.85)
        case .apple:  return .black // HIG variant 3 (black logo/text)
        case .google: return MongleColor.textPrimary
        }
    }
}


// MARK: - 카카오톡 로고 아이콘 (공식 SVG 기반, viewBox 0 0 32 32)

private struct KakaoLogoIcon: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 32.0

            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * s, y: y * s)
            }

            var path = Path()
            // M16 4
            path.move(to: pt(16, 4))
            // C9.373 4 4 8.283 4 13.565
            path.addCurve(to: pt(4, 13.565),
                          control1: pt(9.373, 4),
                          control2: pt(4, 8.283))
            // c0 3.327 2.152 6.255 5.378 7.957  (relative → 4,13.565 기준)
            path.addCurve(to: pt(9.378, 21.522),
                          control1: pt(4, 16.892),
                          control2: pt(6.152, 19.820))
            // l-1.077 3.93  (relative → 9.378,21.522 기준)
            path.addLine(to: pt(8.301, 25.452))
            // c-.114 .417 .37 .766 .73 .518  (relative → 8.301,25.452 기준)
            path.addCurve(to: pt(9.031, 25.970),
                          control1: pt(8.187, 25.869),
                          control2: pt(8.671, 26.218))
            // l4.475 -3.05  (relative → 9.031,25.970 기준)
            path.addLine(to: pt(13.506, 22.920))
            // c1.157 .173 2.366 .266 3.606 .266  (relative → 13.506,22.920 기준)
            path.addCurve(to: pt(17.112, 23.186),
                          control1: pt(14.663, 23.093),
                          control2: pt(15.872, 23.186))
            // c6.627 0 12 -4.283 12 -9.565  (relative → 17.112,23.186 기준)
            path.addCurve(to: pt(29.112, 13.621),
                          control1: pt(23.739, 23.186),
                          control2: pt(29.112, 18.903))
            // C28 8.283 22.627 4 16 4  (absolute)
            path.addCurve(to: pt(16, 4),
                          control1: pt(28, 8.283),
                          control2: pt(22.627, 4))
            path.closeSubpath()

            context.fill(path, with: .color(.black))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Google 로고 아이콘 (공식 SVG 기반 인라인 구현)

private struct GoogleLogoIcon: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 48.0

            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * s, y: y * s)
            }

            // Red — top arc (#EA4335)
            var red = Path()
            red.move(to: pt(24, 9.5))
            red.addCurve(to: pt(33.21, 13.1),  control1: pt(27.54, 9.5),   control2: pt(30.71, 10.72))
            red.addLine(to: pt(40.06, 6.25))
            red.addCurve(to: pt(24, 0),         control1: pt(35.9, 2.38),   control2: pt(30.47, 0))
            red.addCurve(to: pt(2.56, 13.22),   control1: pt(14.62, 0),     control2: pt(6.51, 5.38))
            red.addLine(to: pt(10.54, 19.41))
            red.addCurve(to: pt(24, 9.5),       control1: pt(12.43, 13.72), control2: pt(17.74, 9.5))
            red.closeSubpath()
            context.fill(red, with: .color(MongleColor.googleRed))

            // Blue — right arc (#4285F4)
            var blue = Path()
            blue.move(to: pt(46.98, 24.55))
            blue.addCurve(to: pt(46.6, 20),     control1: pt(46.98, 22.98), control2: pt(46.83, 21.46))
            blue.addLine(to: pt(24, 20))
            blue.addLine(to: pt(24, 29.02))
            blue.addLine(to: pt(36.94, 29.02))
            blue.addCurve(to: pt(32.16, 36.2),  control1: pt(36.36, 31.98), control2: pt(34.68, 34.5))
            blue.addLine(to: pt(39.89, 42.2))
            blue.addCurve(to: pt(46.98, 24.55), control1: pt(44.4, 38.02),  control2: pt(46.98, 31.84))
            blue.closeSubpath()
            context.fill(blue, with: .color(MongleColor.googleBlue))

            // Yellow — left arc (#FBBC05)
            var yellow = Path()
            yellow.move(to: pt(10.53, 28.59))
            yellow.addCurve(to: pt(9.77, 24),    control1: pt(10.05, 27.14), control2: pt(9.77, 25.6))
            yellow.addCurve(to: pt(10.53, 19.41), control1: pt(9.77, 22.4),  control2: pt(10.04, 20.86))
            yellow.addLine(to: pt(2.55, 13.22))
            yellow.addCurve(to: pt(0, 24),        control1: pt(0.92, 16.46),  control2: pt(0, 20.12))
            yellow.addCurve(to: pt(2.56, 34.78),  control1: pt(0, 27.88),     control2: pt(0.92, 31.54))
            yellow.addLine(to: pt(10.53, 28.59))
            yellow.closeSubpath()
            context.fill(yellow, with: .color(MongleColor.googleYellow))

            // Green — bottom arc (#34A853)
            var green = Path()
            green.move(to: pt(24, 48))
            green.addCurve(to: pt(39.89, 42.19), control1: pt(30.48, 48),    control2: pt(35.93, 45.87))
            green.addLine(to: pt(32.16, 36.19))
            green.addCurve(to: pt(24, 38.49),    control1: pt(30.01, 37.64), control2: pt(27.24, 38.49))
            green.addCurve(to: pt(10.53, 28.58), control1: pt(17.74, 38.49), control2: pt(12.43, 34.27))
            green.addLine(to: pt(2.55, 34.77))
            green.addCurve(to: pt(24, 48),       control1: pt(6.51, 42.62),  control2: pt(14.62, 48))
            green.closeSubpath()
            context.fill(green, with: .color(MongleColor.googleGreen))
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 12) {
        SocialLoginButton(provider: .kakao)  {}
        SocialLoginButton(provider: .apple)  {}
        SocialLoginButton(provider: .google) {}
    }
    .padding()
}
