//
//  DesignSystem.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI

// MARK: - Colors

public enum FTColor {
    // Primary Colors - 기존 그린 유지
    public static let primary = Color(light: "4CAF50", dark: "66D267")
    public static let primaryLight = Color(light: "E8F5E9", dark: "2E4A30")
    public static let primaryDark = Color(light: "388E3C", dark: "4CAF50")
    public static let primarySoft = Color(light: "C8E6C9", dark: "3D5C3F")

    // Social Login Colors
    public static let kakao = Color(hex: "FEE500")
    public static let kakaoText = Color(hex: "000000")
    public static let naver = Color(hex: "03C75A")
    public static let naverText = Color(hex: "FFFFFF")
    public static let apple = Color(light: "000000", dark: "FFFFFF")
    public static let appleText = Color(light: "FFFFFF", dark: "000000")

    // Background Colors - 더 부드러운 톤
    public static let background = Color(light: "FFFFFF", dark: "121212")
    public static let surface = Color(light: "F5F7F5", dark: "1E1E1E")
    public static let surfaceElevated = Color(light: "FFFFFF", dark: "252525")

    // Card Background - 마인드브릿지 스타일 부드러운 카드
    public static let cardBackground = Color(light: "FFFFFF", dark: "1E1E1E")
    public static let cardBackgroundHighlight = Color(light: "F0FAF0", dark: "243324")

    // Border & Divider
    public static let border = Color(light: "E8ECE8", dark: "2E2E2E")
    public static let divider = Color(light: "EEEEEE", dark: "2E2E2E")

    // Text Colors
    public static let textPrimary = Color(light: "1A1A1A", dark: "FFFFFF")
    public static let textSecondary = Color(light: "666666", dark: "BDBDBD")
    public static let textHint = Color(light: "9E9E9E", dark: "757575")
    public static let textOnPrimary = Color(hex: "FFFFFF")

    // Status Colors
    public static let error = Color(light: "F44336", dark: "EF5350")
    public static let warning = Color(light: "FFC107", dark: "FFCA28")
    public static let success = Color(light: "4CAF50", dark: "66BB6A")
    public static let info = Color(light: "2196F3", dark: "42A5F5")

    // Accent Colors for variety (가족별 색상 등에 활용)
    public static let accent1 = Color(light: "81C784", dark: "81C784") // 연녹색
    public static let accent2 = Color(light: "A5D6A7", dark: "A5D6A7") // 더 연한 녹색
    public static let accent3 = Color(light: "66BB6A", dark: "66BB6A") // 밝은 녹색
}

// MARK: - Typography
public enum FTFont {
    public static func heading1() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    public static func heading2() -> Font {
        .system(size: 24, weight: .bold, design: .rounded)
    }

    public static func heading3() -> Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }

    public static func body1() -> Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }

    public static func body1Bold() -> Font {
        .system(size: 16, weight: .semibold, design: .rounded)
    }

    public static func body2() -> Font {
        .system(size: 14, weight: .regular, design: .rounded)
    }

    public static func caption() -> Font {
        .system(size: 12, weight: .regular, design: .rounded)
    }

    public static func captionBold() -> Font {
        .system(size: 12, weight: .semibold, design: .rounded)
    }

    public static func button() -> Font {
        .system(size: 16, weight: .semibold, design: .rounded)
    }

    public static func buttonSmall() -> Font {
        .system(size: 14, weight: .semibold, design: .rounded)
    }
}

// MARK: - Spacing
public enum FTSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}

// MARK: - Corner Radius - 더 둥글게 (마인드브릿지 스타일)
public enum FTRadius {
    public static let xs: CGFloat = 8
    public static let small: CGFloat = 12
    public static let medium: CGFloat = 16
    public static let large: CGFloat = 20
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let full: CGFloat = 9999
}

// MARK: - Shadow Styles
public enum FTShadow {
    public static func soft(scheme: ColorScheme = .light) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        let shadowColor = scheme == .dark
            ? Color.black.opacity(0.3)
            : Color.black.opacity(0.06)
        return (shadowColor, 12, 0, 4)
    }

    public static func medium(scheme: ColorScheme = .light) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        let shadowColor = scheme == .dark
            ? Color.black.opacity(0.4)
            : Color.black.opacity(0.1)
        return (shadowColor, 16, 0, 6)
    }

    public static func elevated(scheme: ColorScheme = .light) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        let shadowColor = scheme == .dark
            ? Color.black.opacity(0.5)
            : Color.black.opacity(0.15)
        return (shadowColor, 20, 0, 8)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
  
  /// Light Mode와 Dark Mode를 모두 지원하는 Color 초기화
  init(light: String, dark: String) {
      self.init(UIColor { traitCollection in
          traitCollection.userInterfaceStyle == .dark
              ? UIColor(Color(hex: dark))
              : UIColor(Color(hex: light))
      })
  }
}
