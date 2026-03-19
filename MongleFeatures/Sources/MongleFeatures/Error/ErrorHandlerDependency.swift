import Foundation
import ComposableArchitecture

// MARK: - ErrorHandler Dependency

/// Feature에서 `@Dependency(\.errorHandler)`로 주입받아 사용하는 통합 에러 핸들러.
///
/// ```swift
/// @Dependency(\.errorHandler) var errorHandler
///
/// return .run { send in
///     do {
///         let data = try await repository.load()
///         await send(.dataLoaded(data))
///     } catch {
///         let appError = errorHandler.handle(error, "HomeFeature.load")
///         await send(.setError(appError))
///     }
/// }
/// ```
public struct ErrorHandler: Sendable {

    /// 임의의 Error를 AppError로 변환하고 내부적으로 로깅한다.
    /// - Parameters:
    ///   - error: 원본 에러
    ///   - context: 에러 발생 위치 (로그 식별용). 예: "HomeFeature.refreshData"
    /// - Returns: 변환된 AppError
    public var handle: @Sendable (Error, String) -> AppError

    public init(handle: @Sendable @escaping (Error, String) -> AppError) {
        self.handle = handle
    }

    /// 컨텍스트 없이 변환만 수행 (축약형)
    public func callAsFunction(_ error: Error, context: String = "") -> AppError {
        handle(error, context)
    }
}

// MARK: - DependencyKey

extension ErrorHandler: DependencyKey {

    public static let liveValue = ErrorHandler { error, context in
        let appError = AppError.from(error)

        #if DEBUG
        let tag = context.isEmpty ? "ErrorHandler" : context
        print("🔴 [\(tag)] \(appError) | raw: \(error)")
        #endif

        return appError
    }

    public static let testValue = ErrorHandler { error, _ in
        AppError.from(error)
    }
}

extension DependencyValues {
    public var errorHandler: ErrorHandler {
        get { self[ErrorHandler.self] }
        set { self[ErrorHandler.self] = newValue }
    }
}

