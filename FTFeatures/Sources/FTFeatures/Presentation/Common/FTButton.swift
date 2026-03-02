//
//  FTButton.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI

struct FTButton: View {
    enum Style {
        case primary
        case secondary
        case tertiary  // 텍스트만 있는 버튼
        case kakao
        case naver
        case google
        case apple
    }

    enum Size {
        case large   // 52pt
        case medium  // 44pt
        case small   // 36pt
    }

    let title: String
    let style: Style
    let size: Size
    let isLoading: Bool
    let icon: String?
    let action: () -> Void

    init(
        _ title: String,
        style: Style = .primary,
        size: Size = .large,
        isLoading: Bool = false,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: FTSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if let iconName = icon ?? socialIconName {
                        if iconName.hasPrefix("sf.") {
                            Image(systemName: String(iconName.dropFirst(3)))
                                .font(.system(size: iconSize))
                        } else {
                            Image(iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: iconSize, height: iconSize)
                        }
                    }
                    Text(title)
                        .font(buttonFont)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: hasBorder ? 1.5 : 0)
            )
            .shadow(
                color: hasShadow ? shadowColor : .clear,
                radius: hasShadow ? 8 : 0,
                x: 0,
                y: hasShadow ? 3 : 0
            )
        }
        .disabled(isLoading)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLoading)
    }

    // MARK: - Size Properties
    private var buttonHeight: CGFloat {
        switch size {
        case .large: return 52
        case .medium: return 44
        case .small: return 36
        }
    }

    private var buttonFont: Font {
        switch size {
        case .large: return FTFont.button()
        case .medium: return FTFont.button()
        case .small: return FTFont.buttonSmall()
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .large: return 20
        case .medium: return 18
        case .small: return 16
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .large: return FTRadius.large
        case .medium: return FTRadius.medium
        case .small: return FTRadius.small
        }
    }

    // MARK: - Style Properties
    private var backgroundColor: Color {
        switch style {
        case .primary: return FTColor.primary
        case .secondary: return FTColor.primaryLight
        case .tertiary: return .clear
        case .kakao: return FTColor.kakao
        case .naver: return FTColor.naver
        case .google: return FTColor.background
        case .apple: return FTColor.apple
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return FTColor.primary
        case .tertiary: return FTColor.primary
        case .kakao: return FTColor.kakaoText
        case .naver: return FTColor.naverText
        case .google: return FTColor.textPrimary
        case .apple: return FTColor.appleText
        }
    }

    private var borderColor: Color {
        switch style {
        case .google: return FTColor.border
        case .secondary: return FTColor.primary.opacity(0.3)
        default: return .clear
        }
    }

    private var hasBorder: Bool {
        style == .google || style == .secondary
    }

    private var hasShadow: Bool {
        style == .primary
    }

    private var shadowColor: Color {
        FTColor.primary.opacity(0.25)
    }

    private var socialIconName: String? {
        switch style {
        case .kakao: return "kakao_icon"
        case .naver: return "naver_icon"
        case .google: return "google_icon"
        case .apple: return "sf.apple.logo"
        default: return nil
        }
    }
}

// MARK: - Pill Button (작은 태그형 버튼)
struct FTPillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FTFont.captionBold())
                .foregroundColor(isSelected ? .white : FTColor.primary)
                .padding(.horizontal, FTSpacing.md)
                .padding(.vertical, FTSpacing.xs)
                .background(isSelected ? FTColor.primary : FTColor.primaryLight)
                .cornerRadius(FTRadius.full)
        }
    }
}

// MARK: - Icon Button (원형 아이콘 버튼)
struct FTIconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    init(icon: String, size: CGFloat = 44, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundColor(FTColor.textSecondary)
                .frame(width: size, height: size)
                .background(FTColor.surface)
                .clipShape(Circle())
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            Text("Primary Buttons")
                .font(FTFont.heading3())

            FTButton("회원가입", style: .primary) {}
            FTButton("중간 크기", style: .primary, size: .medium) {}
            FTButton("작은 버튼", style: .primary, size: .small) {}

            Text("Secondary Buttons")
                .font(FTFont.heading3())

            FTButton("둘러보기", style: .secondary) {}

            Text("Tertiary Buttons")
                .font(FTFont.heading3())

            FTButton("건너뛰기", style: .tertiary) {}

            Text("Social Buttons")
                .font(FTFont.heading3())

            FTButton("카카오로 시작하기", style: .kakao) {}
            FTButton("네이버로 시작하기", style: .naver) {}
            FTButton("Google로 시작하기", style: .google) {}
            FTButton("Apple로 시작하기", style: .apple) {}

            Text("Pill Buttons")
                .font(FTFont.heading3())

            HStack {
                FTPillButton(title: "전체", isSelected: true) {}
                FTPillButton(title: "일상", isSelected: false) {}
                FTPillButton(title: "추억", isSelected: false) {}
            }

            Text("Icon Buttons")
                .font(FTFont.heading3())

            HStack {
                FTIconButton(icon: "bell") {}
                FTIconButton(icon: "gearshape") {}
                FTIconButton(icon: "person") {}
            }
        }
        .padding()
    }
}
