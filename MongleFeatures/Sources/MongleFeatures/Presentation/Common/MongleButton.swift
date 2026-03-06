//
//  MongleButton.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI

struct MongleButton: View {
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
            HStack(spacing: MongleSpacing.xs) {
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
        case .large: return MongleFont.button()
        case .medium: return MongleFont.button()
        case .small: return MongleFont.buttonSmall()
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
        case .large: return MongleRadius.large
        case .medium: return MongleRadius.medium
        case .small: return MongleRadius.small
        }
    }

    // MARK: - Style Properties
    private var backgroundColor: Color {
        switch style {
        case .primary: return MongleColor.primary
        case .secondary: return MongleColor.primaryLight
        case .tertiary: return .clear
        case .kakao: return MongleColor.kakao
        case .naver: return MongleColor.naver
        case .google: return MongleColor.background
        case .apple: return MongleColor.apple
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return MongleColor.primary
        case .tertiary: return MongleColor.primary
        case .kakao: return MongleColor.kakaoText
        case .naver: return MongleColor.naverText
        case .google: return MongleColor.textPrimary
        case .apple: return MongleColor.appleText
        }
    }

    private var borderColor: Color {
        switch style {
        case .google: return MongleColor.border
        case .secondary: return MongleColor.primary.opacity(0.3)
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
        MongleColor.primary.opacity(0.25)
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
struct MonglePillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MongleFont.captionBold())
                .foregroundColor(isSelected ? .white : MongleColor.primary)
                .padding(.horizontal, MongleSpacing.md)
                .padding(.vertical, MongleSpacing.xs)
                .background(isSelected ? MongleColor.primary : MongleColor.primaryLight)
                .cornerRadius(MongleRadius.full)
        }
    }
}

// MARK: - Icon Button (원형 아이콘 버튼)
struct MongleIconButton: View {
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
                .foregroundColor(MongleColor.textSecondary)
                .frame(width: size, height: size)
                .background(MongleColor.surface)
                .clipShape(Circle())
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            Text("Primary Buttons")
                .font(MongleFont.heading3())

            MongleButton("회원가입", style: .primary) {}
            MongleButton("중간 크기", style: .primary, size: .medium) {}
            MongleButton("작은 버튼", style: .primary, size: .small) {}

            Text("Secondary Buttons")
                .font(MongleFont.heading3())

            MongleButton("둘러보기", style: .secondary) {}

            Text("Tertiary Buttons")
                .font(MongleFont.heading3())

            MongleButton("건너뛰기", style: .tertiary) {}

            Text("Social Buttons")
                .font(MongleFont.heading3())

            MongleButton("카카오로 시작하기", style: .kakao) {}
            MongleButton("네이버로 시작하기", style: .naver) {}
            MongleButton("Google로 시작하기", style: .google) {}
            MongleButton("Apple로 시작하기", style: .apple) {}

            Text("Pill Buttons")
                .font(MongleFont.heading3())

            HStack {
                MonglePillButton(title: "전체", isSelected: true) {}
                MonglePillButton(title: "일상", isSelected: false) {}
                MonglePillButton(title: "추억", isSelected: false) {}
            }

            Text("Icon Buttons")
                .font(MongleFont.heading3())

            HStack {
                MongleIconButton(icon: "bell") {}
                MongleIconButton(icon: "gearshape") {}
                MongleIconButton(icon: "person") {}
            }
        }
        .padding()
    }
}
