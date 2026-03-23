import Foundation
import MongleData
import Domain

// MARK: - AppError

/// 앱 전체에서 사용하는 통합 에러 타입.
///
/// 네트워크 레이어(APIError), 도메인 레이어(AuthError, MongleError 등)에서 발생한 모든 에러를
/// 이 타입으로 변환해 Feature 레이어에서 일관되게 처리한다.
public enum AppError: Error, Equatable, Sendable {

    // MARK: - Cases

    /// 인터넷 연결 없음
    case offline
    /// 요청 시간 초과
    case timeout
    /// 로그인 만료 / 인증 필요
    case unauthorized
    /// 요청한 리소스를 찾을 수 없음
    case notFound
    /// 서버 오류 (5xx)
    case serverError(statusCode: Int)
    /// 일반 네트워크 IO 오류
    case network(String)
    /// JSON 디코딩 실패
    case decoding
    /// 도메인 비즈니스 에러 (이미 한국어 메시지 포함)
    case domain(String)
    /// 분류되지 않은 기타 에러
    case unknown(String)

    // MARK: - User-facing Properties

    /// 토스트에 표시할 짧은 한 줄 메시지
    public var toastMessage: String {
        switch self {
        case .offline:              return "인터넷 연결을 확인해주세요"
        case .timeout:              return "서버 응답이 오래 걸리고 있어요"
        case .unauthorized:         return "로그인이 필요해요"
        case .notFound:             return "요청한 데이터를 찾을 수 없어요"
        case .serverError(let code): return "서버 오류가 발생했어요 (\(code))"
        case .network:              return "네트워크 오류가 발생했어요"
        case .decoding:             return "데이터를 읽는 중 오류가 발생했어요"
        case .domain(let msg):      return msg
        case .unknown(let msg):     return msg.isEmpty ? "알 수 없는 오류가 발생했어요" : msg
        }
    }

    /// 사용자에게 표시할 한국어 메시지
    public var userMessage: String {
        switch self {
        case .offline:
            return "인터넷에 연결되어 있지 않아요.\n연결 상태를 확인한 후 다시 시도해 주세요."
        case .timeout:
            return "서버 응답이 너무 오래 걸리고 있어요.\n잠시 후 다시 시도해 주세요."
        case .unauthorized:
            return "로그인이 필요해요."
        case .notFound:
            return "요청한 데이터를 찾을 수 없어요."
        case .serverError(let code):
            return "서버에 문제가 발생했어요 (\(code)).\n잠시 후 다시 시도해 주세요."
        case .network(let msg):
            return "네트워크 오류가 발생했어요.\n\(msg)"
        case .decoding:
            return "데이터를 읽는 중 오류가 발생했어요."
        case .domain(let msg):
            return msg
        case .unknown(let msg):
            return msg.isEmpty ? "알 수 없는 오류가 발생했어요." : msg
        }
    }

    /// 재시도 버튼을 표시해야 하는 에러
    public var isRetryable: Bool {
        switch self {
        case .offline, .timeout, .serverError, .network:
            return true
        default:
            return false
        }
    }

    /// 로그인 화면으로 이동이 필요한 에러
    public var requiresLogin: Bool {
        self == .unauthorized
    }

    /// SF Symbol 이름
    public var icon: String {
        switch self {
        case .offline:          return "wifi.slash"
        case .timeout:          return "clock.badge.exclamationmark"
        case .unauthorized:     return "lock.fill"
        case .notFound:         return "magnifyingglass"
        case .serverError:      return "exclamationmark.triangle.fill"
        case .network:          return "antenna.radiowaves.left.and.right.slash"
        case .decoding:         return "doc.badge.ellipsis"
        case .domain, .unknown: return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - Error Conversion

public extension AppError {

    /// 임의의 `Error`를 `AppError`로 변환한다.
    /// APIError → AppError 직접 매핑, 그 외는 localizedDescription 기반.
    static func from(_ error: Error) -> AppError {

        // APIError (MongleData 공개 타입)
        if let apiError = error as? APIError {
            return fromAPIError(apiError)
        }

        // URLError (APIClient 바깥에서 직접 던져지는 경우 대비)
        if let urlError = error as? URLError {
            return fromURLError(urlError)
        }

        // Domain 에러 — 이미 한국어 메시지를 포함하므로 .domain으로 래핑
        if error is AuthError || error is MongleError || error is AnswerError
            || error is QuestionError || error is DailyQuestionError || error is UserError {
            return .domain(error.localizedDescription)
        }

        return .unknown(error.localizedDescription)
    }

    // MARK: Private helpers

    private static func fromAPIError(_ e: APIError) -> AppError {
        switch e {
        case .offline:              return .offline
        case .timeout:              return .timeout
        case .unauthorized:         return .unauthorized
        case .notFound:             return .notFound
        case .serverError(let code, let message):
            if code < 500, let msg = message, !msg.isEmpty {
                return .domain(msg)
            }
            return .serverError(statusCode: code)
        case .networkError(let msg):  return .network(msg)
        case .decodingError:        return .decoding
        case .invalidURL, .invalidResponse, .unknown:
            return .unknown(e.localizedDescription)
        }
    }

    private static func fromURLError(_ e: URLError) -> AppError {
        switch e.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .offline
        case .timedOut:
            return .timeout
        default:
            return .network(e.localizedDescription)
        }
    }
}
