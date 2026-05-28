//
//  V2Palette.swift
//  Mongle — v2 design handoff (Home + Shop)
//
//  Exact palette from the claude.ai/design "몽글 v2" prototype.
//  Type uses the app's existing MongleFont (SUIT); this enum only fixes the
//  prototype's color values so the showcase stays visually faithful.
//

import SwiftUI

enum V2Palette {
    // Surfaces / neutrals
    static let cream = Color(hex: "FFF8F0")
    static let cream2 = Color(hex: "FFE8D6")
    static let cream3 = Color(hex: "F5DEC8")
    static let paperWhite = Color.white
    static let ink = Color(hex: "1A1A1A")
    static let inkSoft = Color(hex: "1A1A1A").opacity(0.6)
    static let dark = Color(hex: "15120F")
    static let dark2 = Color(hex: "221C16")
    static let muted = Color(hex: "8B6F7A")
    static let mutedSoft = Color(hex: "5D4E5A")
    static let hairline = Color(hex: "EFE6DD")

    // Family character colors
    static let dad = Color(hex: "F7B68A")
    static let mom = Color(hex: "A8DFBC")
    static let lily = Color(hex: "FFE082")
    static let ben = Color(hex: "B3D9F2")
    static let alex = Color(hex: "F7B4D9")
    static var family: [Color] { [dad, mom, lily, ben, alex] }

    /// MG-150 — mood → 캐릭터 색 단일 매핑 진실. Home / 답변 표시 / 알림 / 그룹 화면 등
    /// 모든 호출처가 이 함수를 참조해 mood 색이 어긋나지 않게 한다.
    static func mood(_ moodId: String?) -> Color {
        switch moodId {
        case "happy":  return ben    // 활기 — blue
        case "calm":   return mom    // 차분 — mint
        case "loved":  return lily   // 따뜻 — yellow
        case "sad":    return dad    // 가라앉음 — peach
        case "tired":  return alex   // 노곤 — pink
        default:       return alex
        }
    }

    // Accents
    static let mint = Color(hex: "A8DFBC")
    static let mintInk = Color(hex: "1F6B41")
    static let coral = Color(hex: "F7B4A0")
    static let heartPink = Color(hex: "F06292")
    static let streak = Color(hex: "FFC078")
    static let notif = Color(hex: "E57373")
    static let star = Color(hex: "F9A825")
    static let blueSat = Color(hex: "90CAF9")
    static let pinkSoft = Color(hex: "F8BBD0")
    static let brownEar = Color(hex: "A1887F")
    static let purple = Color(hex: "B39DDB")
}

/// The prototype's logical artboard size (iPhone 14). v2 screens are laid out
/// against this coordinate space so the design maps ~1:1 on a 393pt-wide device.
enum V2Canvas {
    static let width: CGFloat = 393
    static let height: CGFloat = 852
}

/// SUIT (the app font) at arbitrary point sizes — the prototype uses many custom
/// sizes that don't map onto MongleFont's fixed scale.
enum V2Font {
    static func suit(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .black, .heavy:    return .custom("SUIT-ExtraBold", size: size)
        case .bold:             return .custom("SUIT-Bold", size: size)
        case .semibold:         return .custom("SUIT-SemiBold", size: size)
        case .medium:           return .custom("SUIT-Medium", size: size)
        default:                return .custom("SUIT-Regular", size: size)
        }
    }
}
