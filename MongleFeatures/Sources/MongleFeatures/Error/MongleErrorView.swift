import SwiftUI

// MARK: - Error Banner

/// 화면 상단/하단에 표시하는 컴팩트 에러 배너.
///
/// ```swift
/// // 사용 예시 (View 안에서)
/// .overlay(alignment: .top) {
///     MongleErrorBanner(
///         error: store.errorMessage,
///         onDismiss: { store.send(.dismissError) },
///         onRetry: { store.send(.refreshData) }
///     )
/// }
/// ```
public struct MongleErrorBanner: View {
    let error: AppError?
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?

    public init(
        error: AppError?,
        onDismiss: @escaping () -> Void,
        onRetry: (() -> Void)? = nil
    ) {
        self.error = error
        self.onDismiss = onDismiss
        self.onRetry = onRetry
    }

    public var body: some View {
        if let error {
            HStack(spacing: MongleSpacing.sm) {
                Image(systemName: error.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(error.userMessage)
                    .font(MongleFont.caption())
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if error.isRetryable, let onRetry {
                    Button("재시도") { onRetry() }
                        .font(MongleFont.captionBold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }

                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, MongleSpacing.md)
            .padding(.vertical, MongleSpacing.sm + 2)
            .background(bannerColor(for: error).opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: MongleRadius.medium))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .padding(.horizontal, MongleSpacing.md)
            .padding(.bottom, MongleSpacing.sm)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: error)
        }
    }

    private func bannerColor(for error: AppError) -> Color {
        switch error {
        case .offline:      return Color(hex: "5B8EFF")   // 파랑 — 연결 문제
        case .timeout:      return Color(hex: "FF9800")   // 주황 — 느린 응답
        case .unauthorized: return Color(hex: "9C27B0")   // 보라 — 로그인 필요
        case .serverError:  return Color(hex: "F44336")   // 빨강 — 서버 오류
        default:            return Color(hex: "757575")   // 회색 — 기타
        }
    }
}

// MARK: - Full-screen Error State

/// 첫 로딩 실패 시 전체 화면을 대체하는 에러 뷰.
///
/// ```swift
/// if store.isLoading {
///     ProgressView()
/// } else if let error = store.errorState {
///     MongleErrorFullscreen(error: error) { store.send(.retry) }
/// } else {
///     // 정상 콘텐츠
/// }
/// ```
public struct MongleErrorFullscreen: View {
    let error: AppError
    let onRetry: (() -> Void)?

    public init(error: AppError, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: MongleSpacing.lg) {
            Spacer()

            // 아이콘
            Image(systemName: error.icon)
                .font(.system(size: 52))
                .foregroundColor(MongleColor.textHint)

            // 메시지
            Text(error.userMessage)
                .font(MongleFont.body1())
                .foregroundColor(MongleColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MongleSpacing.xl)

            // 재시도 버튼
            if error.isRetryable, let onRetry {
                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("다시 시도")
                    }
                    .font(MongleFont.body2Bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, MongleSpacing.lg)
                    .padding(.vertical, MongleSpacing.sm + 2)
                    .background(MongleColor.primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MongleColor.background)
    }
}

// MARK: - View Modifier

private struct MongleErrorBannerModifier: ViewModifier {
    let error: AppError?
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                MongleErrorBanner(error: error, onDismiss: onDismiss, onRetry: onRetry)
            }
    }
}

public extension View {
    /// AppError 기반 배너를 뷰 상단에 오버레이한다.
    func mongleErrorBanner(
        error: AppError?,
        onDismiss: @escaping () -> Void,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        modifier(MongleErrorBannerModifier(error: error, onDismiss: onDismiss, onRetry: onRetry))
    }
}

// MARK: - String-based Backward-compatible Banner

private struct MongleStringErrorBannerModifier: ViewModifier {
    let message: String?
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                let error: AppError? = message.map { .unknown($0) }
                MongleErrorBanner(error: error, onDismiss: onDismiss, onRetry: onRetry)
            }
    }
}

public extension View {
    /// 기존 `errorMessage: String?` 패턴과 하위 호환되는 배너.
    func mongleErrorBanner(
        message: String?,
        onDismiss: @escaping () -> Void,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        modifier(MongleStringErrorBannerModifier(message: message, onDismiss: onDismiss, onRetry: onRetry))
    }
}
