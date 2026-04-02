import SwiftUI

// MARK: - Error Toast Modifier

private struct MongleErrorToastModifier: ViewModifier {
    let error: AppError?
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let error {
                    MongleToastView(type: .appError(error))
                        .padding(.bottom, MongleSpacing.lg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: error)
            .task(id: error) {
                guard error != nil else { return }
                try? await Task.sleep(for: .seconds(3))
                onDismiss()
            }
    }
}

public extension View {
    func mongleErrorToast(
        error: AppError?,
        onDismiss: @escaping () -> Void
    ) -> some View {
        modifier(MongleErrorToastModifier(error: error, onDismiss: onDismiss))
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

            Image(systemName: error.icon)
                .font(.system(size: 52))
                .foregroundColor(MongleColor.textHint)

            Text(error.userMessage)
                .font(MongleFont.body1())
                .foregroundColor(MongleColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MongleSpacing.xl)

            if error.isRetryable, let onRetry {
                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text(L10n.tr("common_retry"))
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
