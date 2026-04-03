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
    // Primary / Brand
    public static let primary = Color(light: "4CAF50", dark: "7BC8A0")
    public static let primaryLight = Color(light: "A5D6A7", dark: "C2E8D4")
    public static let primaryDark = Color(light: "388E3C", dark: "5BAF85")
    public static let primarySoft = Color(light: "43A047", dark: "6BBF93")

    // Primary gradient (button, badge gradients)
    public static let primaryGradientStart = Color(hex: "6BBF93")
    public static let primaryGradientEnd = Color(hex: "7BC8A0")
    public static let primaryXLight = Color(hex: "C2E8D4")
    public static let primaryMuted = Color(hex: "5BAF85")
    public static let primaryDeep = Color(hex: "2E7D32")

    // Secondary / warm accent
    public static let secondary = Color(light: "FF7043", dark: "F5978E")

    // Social Login
    public static let kakao = Color(hex: "FEE500")
    public static let naver = Color(hex: "03C75A")
    public static let naverText = Color(hex: "FFFFFF")
    public static let apple = Color(light: "000000", dark: "FFFFFF")
    public static let appleText = Color(light: "FFFFFF", dark: "000000")
    public static let googleBorder = Color(hex: "747775")
    public static let googleRed = Color(hex: "EA4335")
    public static let googleBlue = Color(hex: "4285F4")
    public static let googleYellow = Color(hex: "FBBC05")
    public static let googleGreen = Color(hex: "34A853")

    // Background
    public static let background = Color(light: "F8FAF8", dark: "F8FAF8")
    public static let surface = Color(light: "FDF8F5", dark: "FDF8F5")
    public static let bgNeutral = Color(hex: "F5F4F1")
    public static let bgCreamy = Color(hex: "FFFCF8")
    public static let bgWarm = Color(hex: "FFF0E6")
    public static let bgNeutralWarm = Color(hex: "F3EFEA")
    public static let bgInfoLight = Color(hex: "E8F2FD")
    public static let bgSuccessLight = Color(hex: "E8F6EA")
    public static let bgWarmLight = Color(hex: "FFF1E2")
    public static let bgMintLight = Color(hex: "EAF7EE")
    public static let bgErrorLight = Color(hex: "FCEEEF")
    public static let bgDanger = Color(hex: "FDE8E8")
    public static let bgErrorSoft = Color(hex: "FDEBEC")
    public static let bgYellowSoft = Color(hex: "FFF1DE")
    public static let bgPeach = Color(hex: "FFE5D9")

    // App background gradient
    public static let gradientBgStart = Color(hex: "FFF8F0")
    public static let gradientBgMid = Color(hex: "FFF2EB")
    public static let gradientBgEnd = Color(hex: "EFF8F1")

    // Card
    public static let cardBackground = Color.white.opacity(0.8)
    public static let cardBackgroundSolid = Color.white
    public static let cardGlass = Color.white.opacity(0.6)

    // Border / Divider
    public static let border = Color(hex: "E0E0E0")
    public static let borderCard = Color.white.opacity(0.2)
    public static let borderWarm = Color(hex: "EEE3D8")
    public static let divider = Color(hex: "E0E0E0")

    // Text
    public static let textPrimary = Color(hex: "1A1A1A")
    public static let textSecondary = Color(hex: "6D6D6D")
    public static let textHint = Color(hex: "757575")

    // Status
    public static let error = Color(hex: "F44336")
    public static let warning = Color(hex: "FF9800")
    public static let success = Color(light: "4CAF50", dark: "66BB6A")
    public static let info = Color(hex: "42A5F5")
    public static let notificationDot = Color(hex: "F44336")

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

    // Heart / like
    public static let heartRed = Color(hex: "FF6B6B")
    public static let heartRedLight = Color(hex: "FFE5E5")
    public static let heartPink = Color(hex: "FF7C85")
    public static let heartPinkLight = Color(hex: "FF9393")
    public static let heartPastel = Color(hex: "FFB3B8")
    public static let heartPastelLight = Color(hex: "FFD8D8")

    // Accent
    public static let accentOrange = Color(hex: "FF9800")
    public static let accentPeach = Color(hex: "F7B4A0")
    public static let accentYellowLight = Color(hex: "FFE082")
    public static let coralLight = Color(hex: "FF8A80")

    // UI extras
    public static let brown = Color(hex: "5D4037")
    public static let pageIndicatorInactive = Color(hex: "E7DED5")

    // Calendar
    public static let calendarSunday = Color(hex: "1565C0")

    // Shadow
    public static let shadowColor = Color(light: "1A1A1A14", dark: "D4A09014")
    public static let shadowWarm = Color(hex: "D4A09020")
    public static let shadowBase = Color(hex: "D4A090")
}


// MARK: - Font

public enum MongleFont {
    private static func suit(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .heavy:    return .custom("SUIT-ExtraBold", size: size)
        case .bold:     return .custom("SUIT-Bold", size: size)
        case .semibold: return .custom("SUIT-SemiBold", size: size)
        case .medium:   return .custom("SUIT-Medium", size: size)
        default:        return .custom("SUIT-Regular", size: size)
        }
    }

    public static func heading1() -> Font { suit(28, weight: .heavy) }
    public static func heading2() -> Font { suit(22, weight: .semibold) }
    public static func heading3() -> Font { suit(18, weight: .semibold) }
    public static func body1() -> Font { suit(15, weight: .medium) }
    public static func body1Bold() -> Font { suit(15, weight: .semibold) }
    public static func body2() -> Font { suit(14) }
    public static func body2Bold() -> Font { suit(14, weight: .semibold) }
    public static func caption() -> Font { suit(12) }
    public static func captionBold() -> Font { suit(12, weight: .semibold) }
    public static func button() -> Font { suit(16, weight: .semibold) }
    public static func buttonSmall() -> Font { suit(14, weight: .semibold) }
    public static func label() -> Font { suit(11) }

    /// SPM 번들에서 SUIT 폰트를 시스템에 등록합니다. 앱 시작 시 한 번 호출하세요.
    public static func registerFonts() {
        let names = ["SUIT-Regular", "SUIT-Medium", "SUIT-SemiBold", "SUIT-Bold", "SUIT-ExtraBold"]
        for name in names {
            guard let url = Bundle.module.url(forResource: name, withExtension: "otf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
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
        (MongleColor.shadowColor, 8, 0, 2)
    }

    public static func medium(scheme: ColorScheme = .light) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (MongleColor.shadowColor, 12, 0, 4)
    }

    public static func elevated(scheme: ColorScheme = .light) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (MongleColor.shadowWarm, 20, 0, 4)
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
