import Foundation

protocol APIClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func request(_ endpoint: APIEndpoint) async throws
}

// MARK: - Token Refresh Actor (동시 갱신 방지)

/// 동시에 여러 401이 발생해도 refresh를 한 번만 실행하도록 직렬화하는 actor.
private actor TokenRefreshCoordinator {
    private var isRefreshing = false
    private var refreshResult: Result<String, Error>?

    /// 리프레시가 진행 중이면 완료를 기다린 뒤 결과 반환. 아니면 직접 실행.
    func refresh(using block: () async throws -> String) async throws -> String {
        // 이미 갱신 완료 결과가 있으면 바로 반환 (같은 세션 내 재사용)
        if let result = refreshResult {
            refreshResult = nil
            return try result.get()
        }
        if isRefreshing {
            // 이미 갱신 중: 짧게 대기 후 결과 확인 (폴링 대신 sleep)
            while isRefreshing {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            if let result = refreshResult {
                refreshResult = nil
                return try result.get()
            }
            throw APIError.unauthorized
        }
        isRefreshing = true
        do {
            let newToken = try await block()
            refreshResult = .success(newToken)
            isRefreshing = false
            return newToken
        } catch {
            refreshResult = .failure(error)
            isRefreshing = false
            throw error
        }
    }
}

// MARK: - APIClient

final class APIClient: APIClientProtocol, @unchecked Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let tokenStorage: TokenStorageProtocol
    private let networkMonitor: NetworkMonitor
    private let maxRetryCount: Int
    private let refreshCoordinator = TokenRefreshCoordinator()

    // MARK: - Init

    init(
        tokenStorage: TokenStorageProtocol = KeychainTokenStorage(),
        networkMonitor: NetworkMonitor = .shared,
        maxRetryCount: Int = 2
    ) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15     // 요청 하나당 최대 15초
        config.timeoutIntervalForResource = 60    // 전체 리소스 로딩 60초
        self.session = URLSession(configuration: config)
        self.tokenStorage = tokenStorage
        self.networkMonitor = networkMonitor
        self.maxRetryCount = maxRetryCount

        self.decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateString)"
            )
        }
    }

    // MARK: - Request with Response

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        try checkConnectivity()
        return try await withRetry(label: "\(type(of: endpoint))") {
            var urlRequest = try endpoint.buildURLRequest()
            self.attachAuthToken(to: &urlRequest)
            let (data, response) = try await self.perform(urlRequest)

            // 401 → 리프레시 토큰으로 갱신 후 1회 재시도
            if response.statusCode == 401 {
                let newToken = try await self.attemptTokenRefresh()
                var retryRequest = try endpoint.buildURLRequest()
                retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                let (retryData, retryResponse) = try await self.perform(retryRequest)
                try self.validateResponse(retryResponse, data: retryData)
                do {
                    return try self.decoder.decode(T.self, from: retryData)
                } catch {
                    throw APIError.decodingError(error.localizedDescription)
                }
            }

            try self.validateResponse(response, data: data)
            do {
                return try self.decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error.localizedDescription)
            }
        }
    }

    // MARK: - Request without Response

    func request(_ endpoint: APIEndpoint) async throws {
        try checkConnectivity()
        try await withRetry(label: "\(type(of: endpoint))") {
            var urlRequest = try endpoint.buildURLRequest()
            self.attachAuthToken(to: &urlRequest)
            let (data, response) = try await self.perform(urlRequest)

            if response.statusCode == 401 {
                let newToken = try await self.attemptTokenRefresh()
                var retryRequest = try endpoint.buildURLRequest()
                retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                let (retryData, retryResponse) = try await self.perform(retryRequest)
                try self.validateResponse(retryResponse, data: retryData)
                return
            }

            try self.validateResponse(response, data: data)
        }
    }

    // MARK: - Private: Connectivity

    private func checkConnectivity() throws {
        guard networkMonitor.isConnected else {
            throw APIError.offline
        }
    }

    // MARK: - Private: Perform (URLError → APIError 변환)

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            return (data, httpResponse)
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        }
    }

    // MARK: - Private: URLError → APIError 매핑

    private func mapURLError(_ urlError: URLError) -> APIError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .offline
        case .timedOut:
            return .timeout
        case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return .networkError("서버에 연결할 수 없습니다.")
        default:
            return .networkError(urlError.localizedDescription)
        }
    }

    // MARK: - Private: Response Validation

    private func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            let errorMessage = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.serverError(
                statusCode: response.statusCode,
                message: errorMessage?.message
            )
        }
    }

    // MARK: - Private: Token

    private func attachAuthToken(to request: inout URLRequest) {
        if let token = tokenStorage.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    // MARK: - Private: Token Refresh

    /// 리프레시 토큰으로 새 액세스 토큰 발급. 실패 시 `.unauthorized` throw.
    private func attemptTokenRefresh() async throws -> String {
        return try await refreshCoordinator.refresh {
            guard let refreshToken = self.tokenStorage.getRefreshToken() else {
                throw APIError.unauthorized
            }
            let endpoint = AuthEndpoint.refreshToken(refreshToken: refreshToken)
            var urlRequest = try endpoint.buildURLRequest()
            // refresh 요청은 토큰 없이 보냄 (만료 토큰 첨부 금지)
            urlRequest.setValue(nil, forHTTPHeaderField: "Authorization")

            let (data, response) = try await self.perform(urlRequest)
            guard response.statusCode == 200 else {
                // refresh 자체가 401 → 완전한 로그인 필요
                throw APIError.unauthorized
            }
            let refreshResponse = try self.decoder.decode(RefreshTokenResponseDTO.self, from: data)
            try self.tokenStorage.saveToken(refreshResponse.token)
            if let newRefreshToken = refreshResponse.refreshToken {
                try self.tokenStorage.saveRefreshToken(newRefreshToken)
            }
            return refreshResponse.token
        }
    }

    // MARK: - Private: Retry Logic

    /// `isRetryable` 에러에 한해 최대 `maxRetryCount`회 재시도.
    /// 백오프 간격: 0.5s → 1.0s (지수적 증가)
    @discardableResult
    private func withRetry<T>(
        label: String,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error = APIError.unknown
        for attempt in 0...maxRetryCount {
            do {
                return try await operation()
            } catch let apiError as APIError where apiError.isRetryable && attempt < maxRetryCount {
                lastError = apiError
                let backoffNanos = UInt64(500_000_000) * UInt64(pow(2.0, Double(attempt))) // 0.5s, 1.0s
                try? await Task.sleep(nanoseconds: backoffNanos)
            } catch {
                throw error
            }
        }
        throw lastError
    }
}

// MARK: - Mock Client for Testing

final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    var mockResponse: Any?
    var mockError: Error?

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        if let error = mockError { throw error }
        guard let response = mockResponse as? T else {
            throw APIError.decodingError("Mock response type mismatch")
        }
        return response
    }

    func request(_ endpoint: APIEndpoint) async throws {
        if let error = mockError { throw error }
    }
}
