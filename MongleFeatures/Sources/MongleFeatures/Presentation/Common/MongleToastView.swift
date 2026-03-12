import SwiftUI

// MARK: - Toast View (공용)
// 03-C · Home (Refresh Toast)
// 03-B-1 · Home (Write Toast)

public enum ToastType {
    case refreshQuestion   // 질문 다시받기 완료
    case writeQuestion     // 나만의 질문 작성 완료

    var icon: String {
        switch self {
        case .refreshQuestion: return "arrow.clockwise.circle.fill"
        case .writeQuestion: return "pencil.circle.fill"
        }
    }

    var message: String {
        switch self {
        case .refreshQuestion: return "새로운 질문을 받았어요! 🎉"
        case .writeQuestion: return "나만의 질문을 등록했어요! ✏️"
        }
    }

    var iconColor: Color {
        switch self {
        case .refreshQuestion: return MongleColor.secondary
        case .writeQuestion: return MongleColor.accentOrange
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
