import Foundation

/// MongleData → MongleFeatures 레이어 모두에서 사용 가능한 네트워크 에러 타입.
public enum APIError: Error, Equatable {
    /// 인터넷 연결 없음
    case offline
    /// 요청 시간 초과 (> 15 s)
    case timeout
    /// URL 구성 실패
    case invalidURL
    /// HTTPURLResponse 변환 실패
    case invalidResponse
    /// 네트워크 IO 오류 (URLError 등)
    case networkError(String)
    /// JSON 디코딩 실패
    case decodingError(String)
    /// 서버 측 4xx / 5xx 응답
    case serverError(statusCode: Int, message: String?)
    /// 인증 만료 / 토큰 없음 (401)
    case unauthorized
    /// 리소스 없음 (404)
    case notFound
    /// 기타
    case unknown

    // MARK: - User-facing message (Korean)

    public var localizedDescription: String {
        switch self {
        case .offline:
            return "인터넷에 연결되어 있지 않아요."
        case .timeout:
            return "서버 응답이 너무 오래 걸리고 있어요."
        case .invalidURL:
            return "잘못된 URL입니다."
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .decodingError:
            return "데이터를 읽는 중 오류가 발생했어요."
        case .serverError(let statusCode, let message):
            return "서버 오류 (\(statusCode)): \(message ?? "알 수 없는 오류")"
        case .unauthorized:
            return "인증이 필요합니다. 다시 로그인해 주세요."
        case .notFound:
            return "요청한 리소스를 찾을 수 없습니다."
        case .unknown:
            return "알 수 없는 오류가 발생했어요."
        }
    }

    // MARK: - Retry Policy

    /// 자동 재시도가 의미 있는 에러 (5xx, 타임아웃)
    public var isRetryable: Bool {
        switch self {
        case .timeout:
            return true
        case .serverError(let code, _):
            return code >= 500
        case .networkError:
            return true
        default:
            return false
        }
    }

    /// 로그인 화면으로 이동이 필요한 에러
    public var requiresLogin: Bool {
        self == .unauthorized
    }
}

// MARK: - Server Error Response Body

public struct ErrorResponse: Codable {
    public let message: String
    public let code: String?
}
