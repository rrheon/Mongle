import SwiftUI

// MARK: - Eye Expression

/// 몽글 캐릭터의 눈 표정. 평소에는 neutral, 기절 시 fainted, 탭 시 mood별 고유 표정으로 전환.
/// `MongleMonggle.eyeView`에서 7개 레이어를 항상 렌더하고 opacity로만 전환한다
/// (구조 diff 회피 — `DizzyWobbleModifier` 주석 참조).
public enum EyeExpression: String, CaseIterable, Equatable {
    case neutral  // 기본: 흰 테두리 검은 원
    case fainted  // 기절: xmark
    case happy    // 웃는 눈 (반달 아치)
    case calm     // 작은 점 (반쯤 감김)
    case loved    // 하트
    case sad      // 처진 호 + 작은 눈물
    case tired    // 가로 일자선

    /// mood 문자열 → 탭 시 표정 매핑.
    public static func forMood(_ moodId: String?) -> EyeExpression {
        switch moodId {
        case "happy":  return .happy
        case "calm":   return .calm
        case "loved":  return .loved
        case "sad":    return .sad
        case "tired":  return .tired
        default:       return .happy
        }
    }
}
