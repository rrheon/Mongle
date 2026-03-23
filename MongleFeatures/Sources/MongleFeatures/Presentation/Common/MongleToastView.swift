import SwiftUI

// MARK: - Toast View (공용)
// 03-C · Home (Refresh Toast)
// 03-B-1 · Home (Write Toast)

public enum ToastType {
    // MARK: Success
    case refreshQuestion   // 질문 다시받기 완료
    case writeQuestion     // 나만의 질문 작성 완료
    case nudge             // 재촉하기 완료
    case editAnswer        // 답변수정하기 완료
    case answerSubmitted   // 답변 작성 완료
    case groupLeft         // 그룹 나가기 완료
    // MARK: Error
    case alreadyMember     // 이미 속해있는 그룹
    case invalidInviteCode // 유효하지 않은 초대코드
    case appError(AppError) // 앱 공통 오류

    var icon: String {
        switch self {
        case .refreshQuestion:  return "arrow.clockwise.circle.fill"
        case .writeQuestion:    return "pencil.circle.fill"
        case .nudge:            return "heart.fill"
        case .editAnswer:       return "checkmark.circle.fill"
        case .answerSubmitted:  return "paperplane.fill"
        case .groupLeft:        return "checkmark.circle.fill"
        case .alreadyMember:    return "person.crop.circle.badge.exclamationmark.fill"
        case .invalidInviteCode: return "key.slash.fill"
        case .appError(let e):  return e.icon
        }
    }

    var message: String {
        switch self {
        case .refreshQuestion:  return "질문을 넘겼어요. 다른 가족 답변을 확인해보세요! 👀"
        case .writeQuestion:    return "나만의 질문을 등록했어요! ✏️"
        case .nudge:            return "재촉 메시지를 보냈어요! 💌"
        case .editAnswer:       return "답변을 수정했어요! ✅"
        case .answerSubmitted:  return "마음을 남겼어요! 🌿"
        case .groupLeft:        return "그룹에서 나왔어요"
        case .alreadyMember:    return "이미 속해있는 그룹이에요"
        case .invalidInviteCode: return "초대코드를 다시 확인해주세요"
        case .appError(let e):  return e.toastMessage
        }
    }

    var iconColor: Color {
        switch self {
        case .refreshQuestion:  return MongleColor.secondary
        case .writeQuestion:    return MongleColor.accentOrange
        case .nudge:            return MongleColor.heartRed
        case .editAnswer:       return MongleColor.primary
        case .answerSubmitted:  return MongleColor.primary
        case .groupLeft:        return MongleColor.primary
        case .alreadyMember:    return MongleColor.error
        case .invalidInviteCode: return MongleColor.error
        case .appError:         return MongleColor.error
        }
    }
}

public struct MongleToastView: View {
    let type: ToastType

    public init(type: ToastType) {
        self.type = type
    }

    public var body: some View {
        HStack(spacing: MongleSpacing.sm) {
            Image(systemName: type.icon)
                .font(.system(size: 18))
                .foregroundColor(type.iconColor)
            Text(type.message)
                .font(MongleFont.body2Bold())
                .foregroundColor(MongleColor.textPrimary)
        }
        .padding(.vertical, MongleSpacing.sm)
        .padding(.horizontal, MongleSpacing.md)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, MongleSpacing.md)
    }
}
