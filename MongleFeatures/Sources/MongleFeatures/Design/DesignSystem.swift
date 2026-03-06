//
//  DesignSystem.swift
//  Mongle
//
//  Created by 최용헌 on 12/11/25.
//

import SwiftUI
import UIKit

// MARK: - Colors

public enum MongleColor {
    // Primary (green-primary: #4CAF50 light / #7BC8A0 dark)
    public static let primary = Color(light: "4CAF50", dark: "7BC8A0")
    public static let primaryLight = Color(light: "E8F5E1", dark: "1E3A2A")
    public static let primaryDark = Color(light: "388E3C", dark: "5BAF85")
    public static let primarySoft = Color(light: "A5D6A7", dark: "C2E8D4")

    // XP / progress bar green
    public static let xpGreen = Color(light: "66BB6A", dark: "8DD4AE")

    // Social Login
    public static let kakao = Color(hex: "FEE500")
    public static let kakaoText = Color(hex: "191919")
    public static let naver = Color(hex: "03C75A")
    public static let naverText = Color(hex: "FFFFFF")
    public static let apple = Color(light: "000000", dark: "FFFFFF")
    public static let appleText = Color(light: "FFFFFF", dark: "000000")

    // Background (bg-secondary: #F5F4F1 / #FDF8F5)
    public static let background = Color(light: "FFF5F0", dark: "1A120D")
    public static let surface = Color(light: "F5F4F1", dark: "1E1A16")
    public static let surfaceWarm = Color(light: "FFF8F0", dark: "221A10")

    // Card
    public static let cardBackground = Color(light: "FFFFFF", dark: "1E1E1E")
    public static let cardBackgroundHighlight = Color(light: "E8F5E1", dark: "1E3A2A")
    public static let cardGlass = Color(hex: "FFFFFF").opacity(0.6)

    // Border
    public static let border = Color(hex: "E0E0E0")
    public static let borderCard = Color(hex: "FFFFFF").opacity(0.2)
    public static let divider = Color(light: "E0E0E0", dark: "2E2E2E")

    // Text (text-primary: #1A1A1A, text-secondary: #6D6D6D, text-tertiary: #9E9E9E)
    public static let textPrimary = Color(hex: "1A1A1A")
    public static let textSecondary = Color(hex: "6D6D6D")
    public static let textHint = Color(hex: "9E9E9E")
    public static let textOnPrimary = Color(hex: "FFFFFF")
    public static let textOnDark = Color(hex: "FFFFFF")

    // Status
    public static let error = Color(hex: "F44336")
    public static let warning = Color(hex: "FF9800")
    public static let success = Color(light: "4CAF50", dark: "66BB6A")
    public static let info = Color(hex: "42A5F5")
    public static let notificationDot = Color(hex: "F44336")

    // Gradient (bg-gradient-start → bg-gradient-end)
    public static let gradientStart = Color(hex: "F5A8A0")
    public static let gradientEnd = Color(hex: "A8DFBC")
    public static var gradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Monggle character colors
    public static let monggleGreen = Color(light: "66BB6A", dark: "8DD4AE")
    public static let monggleYellow = Color(hex: "FFD54F")
    public static let monggleBlue = Color(hex: "42A5F5")
    public static let mongglePink = Color(hex: "F06292")
    public static let monggleOrange = Color(hex: "FF9800")

    // Mood colors (fill + light background)
    public static let moodHappy = Color(hex: "FFD54F")
    public static let moodHappyLight = Color(hex: "FFF3C4")
    public static let moodLoved = Color(hex: "F5978E")
    public static let moodLovedLight = Color(hex: "FDDDD8")
    public static let moodCalm = Color(hex: "A8DFBC")
    public static let moodCalmLight = Color(hex: "D4F0E0")
    public static let moodSad = Color(hex: "90CAF9")
    public static let moodSadLight = Color(hex: "D4EAFC")
    public static let moodAngry = Color(hex: "EF9A9A")
    public static let moodAngryLight = Color(hex: "FDDEDE")
    public static let moodAnxious = Color(hex: "A5D6A7")
    public static let moodAnxiousLight = Color(hex: "D4EDDA")
    public static let moodExcited = Color(hex: "FF9800")
    public static let moodExcitedLight = Color(hex: "FFE0B2")
    public static let moodTired = Color(hex: "B39DDB")
    public static let moodTiredLight = Color(hex: "E0D6F0")

    // Streak
    public static let streakFire = Color(light: "FF6D00", dark: "F5978E")

    // Heart / like
    public static let heartRed = Color(hex: "FF6B6B")
    public static let heartRedLight = Color(hex: "FFE5E5")

    // Accent
    public static let accentBlue = Color(hex: "42A5F5")
    public static let accentCoral = Color(light: "FF7043", dark: "F5978E")
    public static let accentYellow = Color(hex: "FFD54F")
    public static let accentPurple = Color(hex: "AB47BC")
    public static let accentPink = Color(hex: "F06292")
    public static let accentOrange = Color(hex: "FF9800")
    public static let accentPeach = Color(hex: "F7B4A0")

    // Mint background
    public static let bgMint = Color(light: "D4EDDA", dark: "1A3325")
    public static let bgPeach = Color(hex: "FFE5D9")
}

// MARK: - Typography
// Design font: "Outfit" — falls back to .rounded system font if not bundled
public enum MongleFont {
    private static func outfit(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Use custom Outfit font if available, otherwise fall back to rounded system font
        if UIFont(name: "Outfit-Regular", size: size) != nil {
            switch weight {
            case .bold:       return .custom("Outfit-Bold", size: size)
            case .semibold:   return .custom("Outfit-SemiBold", size: size)
            case .medium:     return .custom("Outfit-Medium", size: size)
            default:          return .custom("Outfit-Regular", size: size)
            }
        }
        return .system(size: size, weight: weight, design: .rounded)
    }

    public static func heading1() -> Font { outfit(28, weight: .bold) }
    public static func heading2() -> Font { outfit(24, weight: .bold) }
    public static func heading3() -> Font { outfit(20, weight: .semibold) }
    public static func body1() -> Font { outfit(16) }
    public static func body1Bold() -> Font { outfit(16, weight: .semibold) }
    public static func body2() -> Font { outfit(14) }
    public static func body2Bold() -> Font { outfit(14, weight: .semibold) }
    public static func caption() -> Font { outfit(12) }
    public static func captionBold() -> Font { outfit(12, weight: .semibold) }
    public static func button() -> Font { outfit(16, weight: .semibold) }
    public static func buttonSmall() -> Font { outfit(14, weight: .semibold) }
    public static func label() -> Font { outfit(11) }
}

// MARK: - Spacing
// spacing-xs:4 / s:8 / m:12 / l:16 / xl:24 / xxl:32
public enum MongleSpacing {
    public static let xxs: CGFloat = 4   // spacing-xs
    public static let xs: CGFloat = 8    // spacing-s
    public static let sm: CGFloat = 12   // spacing-m
    public static let md: CGFloat = 16   // spacing-l
    public static let lg: CGFloat = 24   // spacing-xl
    public static let xl: CGFloat = 32   // spacing-xxl
    public static let xxl: CGFloat = 48  // extra
}

// MARK: - Corner Radius
// radius-xs:4 / s:8 / m:12 / l:16 / xl:20 / xxl:24 / pill:100
public enum MongleRadius {
    public static let xs: CGFloat = 4    // radius-xs
    public static let small: CGFloat = 8 // radius-s
    public static let medium: CGFloat = 12 // radius-m
    public static let large: CGFloat = 16  // radius-l
    public static let xl: CGFloat = 20    // radius-xl
    public static let xxl: CGFloat = 24   // radius-xxl
    public static let full: CGFloat = 100 // radius-pill
}

// MARK: - Shadow Styles
public enum MongleShadow {
    public static func soMongle(scheme: ColorScheme = .light) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
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
public extension Color {
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
  public init(light: String, dark: String) {
      self.init(UIColor { traitCollection in
          traitCollection.userInterfaceStyle == .dark
              ? UIColor(Color(hex: dark))
              : UIColor(Color(hex: light))
      })
  }
}
