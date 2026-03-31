//
//  APIEndpoint.swift
//  Mongle
//
//  Created on 2025-12-08.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

protocol APIEndpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

extension APIEndpoint {
    var baseURL: String {
        return "https://1cq1kfgvf1.execute-api.ap-northeast-2.amazonaws.com"
    }

    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }

    var queryItems: [URLQueryItem]? {
        return nil
    }

    var body: Data? {
        return nil
    }

    func buildURLRequest() throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

// MARK: - Auth Endpoints

enum AuthEndpoint: APIEndpoint {
    case login(email: String, password: String)
    case signup(name: String, email: String, password: String, role: String)
    /// 소셜 로그인 단일 엔드포인트.
    /// provider: "apple" | "kakao" | "naver" | "google"
    /// fields: 제공자별 페이로드 (SocialLoginCredential.fields)
    case socialLogin(provider: String, fields: [String: String])
    case logout
    /// 계정 완전 삭제 (서버에서 Apple token revoke 포함 처리)
    case deleteAccount
    case getCurrentUser
    case refreshToken(refreshToken: String)

    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .signup:
            return "/auth/signup"
        case .socialLogin:
            return "/auth/social"
        case .logout:
            return "/auth/logout"
        case .deleteAccount:
            return "/auth/account"
        case .getCurrentUser:
            return "/users/me"
        case .refreshToken:
            return "/auth/refresh"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .signup, .socialLogin, .logout, .refreshToken:
            return .post
        case .deleteAccount:
            return .delete
        case .getCurrentUser:
            return .get
        }
    }

    var body: Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        switch self {
        case .login(let email, let password):
            let dto = LoginRequestDTO(email: email, password: password)
            return try? encoder.encode(dto)
        case .signup(let name, let email, let password, let role):
            let dto = SignupRequestDTO(email: email, name: name, password: password, role: role)
            return try? encoder.encode(dto)
        case .socialLogin(let provider, let fields):
            var body = fields
            body["provider"] = provider
            return try? JSONSerialization.data(withJSONObject: body)
        case .refreshToken(let refreshToken):
            let dto = RefreshTokenRequestDTO(refreshToken: refreshToken)
            return try? encoder.encode(dto)
        case .logout, .getCurrentUser, .deleteAccount:
            return nil
        }
    }
}

// MARK: - User Endpoints

// MARK: - Home Data Endpoints (서버 실제 경로 기준)

enum HomeEndpoint: APIEndpoint {
    case myFamily          // GET /families/my
    case todayQuestion     // GET /questions/today

    var path: String {
        switch self {
        case .myFamily:       return "/families/my"
        case .todayQuestion:  return "/questions/today"
        }
    }

    var method: HTTPMethod { .get }
}

// MARK: - User Endpoints

enum UserEndpoint: APIEndpoint {
    case fetchUser(userId: String)
    case updateUser(userId: String, data: UserDTO)
    case updateMe(name: String)
    case getMyStreak
    case registerDeviceToken(token: String)
    case adHeartReward(amount: Int)

    var path: String {
        switch self {
        case .fetchUser(let userId):
            return "/users/\(userId)"
        case .updateUser:
            return "/users/me"
        case .updateMe:
            return "/users/me"
        case .getMyStreak:
            return "/users/me/streak"
        case .registerDeviceToken:
            return "/users/me/device-token"
        case .adHeartReward:
            return "/users/me/hearts/ad-reward"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchUser, .getMyStreak:
            return .get
        case .updateUser, .updateMe:
            return .put
        case .registerDeviceToken:
            return .patch
        case .adHeartReward:
            return .post
        }
    }

    var body: Data? {
        switch self {
        case .registerDeviceToken(let token):
            return try? JSONSerialization.data(withJSONObject: ["token": token])
        case .updateUser(_, let data):
            // UpdateUserRequest 허용 필드만 전송 (TSOA noImplicitAdditionalProperties: throw-on-extras)
            var params: [String: Any] = ["name": data.name, "role": data.role]
            if let moodId = data.moodId { params["moodId"] = moodId }
            if let profileImageUrl = data.profileImageUrl { params["profileImageUrl"] = profileImageUrl }
            return try? JSONSerialization.data(withJSONObject: params)
        case .updateMe(let name):
            return try? JSONEncoder().encode(["name": name])
        case .adHeartReward(let amount):
            return try? JSONSerialization.data(withJSONObject: ["amount": amount])
        default:
            return nil
        }
    }
}

// MARK: - Family Endpoints

enum FamilyEndpoint: APIEndpoint {
    case create(name: String, nickname: String?, colorId: String?)
    case get(familyId: String)
    case update(familyId: String, data: FamilyDTO)
    case delete(familyId: String)
    case findByInviteCode(inviteCode: String)
    case getFamiliesByUserId(userId: String)
    case addMember(familyId: String, userId: String, role: String)
    /// DELETE /families/leave — JWT 토큰의 유저를 가족에서 제거
    case leave
    /// DELETE /families/members/{memberId} — 방장이 특정 멤버를 내보내기
    case kickMember(memberId: String)
    case getMembers(familyId: String)
    case join(inviteCode: String, nickname: String?, colorId: String?)
    /// GET /families/all — 내 모든 가족 목록
    case getAll
    /// POST /families/{familyId}/select — 활성 가족 전환
    case selectFamily(familyId: String)
    /// PATCH /families/transfer-creator — 방장 위임
    case transferCreator(newCreatorId: String)

    var path: String {
        switch self {
        case .create:
            return "/families"
        case .get(let familyId), .update(let familyId, _), .delete(let familyId):
            return "/families/\(familyId)"
        case .findByInviteCode:
            return "/families/by-invite-code"
        case .getFamiliesByUserId:
            return "/families/by-user"
        case .addMember(let familyId, _, _):
            return "/families/\(familyId)/members"
        case .leave:
            return "/families/leave"
        case .kickMember(let memberId):
            return "/families/members/\(memberId)"
        case .getMembers(let familyId):
            return "/families/\(familyId)/members"
        case .join:
            return "/families/join"
        case .getAll:
            return "/families/all"
        case .selectFamily(let familyId):
            return "/families/\(familyId)/select"
        case .transferCreator:
            return "/families/transfer-creator"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create, .addMember, .join, .selectFamily:
            return .post
        case .get, .findByInviteCode, .getFamiliesByUserId, .getMembers, .getAll:
            return .get
        case .update:
            return .put
        case .delete, .leave, .kickMember:
            return .delete
        case .transferCreator:
            return .patch
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .findByInviteCode(let inviteCode):
            return [URLQueryItem(name: "code", value: inviteCode)]
        case .getFamiliesByUserId(let userId):
            return [URLQueryItem(name: "user_id", value: userId)]
        default:
            return nil
        }
    }

    var body: Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        switch self {
        case .create(let name, let nickname, let colorId):
            var params: [String: Any] = ["name": name, "creatorRole": "OTHER"]
            if let nickname { params["nickname"] = nickname }
            if let colorId { params["colorId"] = colorId }
            return try? JSONSerialization.data(withJSONObject: params)
        case .update(_, let data):
            return try? encoder.encode(data)
        case .addMember(_, let userId, let role):
            let params = [
                "user_id": userId,
                "role": role
            ]
            return try? encoder.encode(params)
        case .join(let inviteCode, let nickname, let colorId):
            var params: [String: Any] = ["inviteCode": inviteCode, "role": "OTHER"]
            if let nickname { params["nickname"] = nickname }
            if let colorId { params["colorId"] = colorId }
            return try? JSONSerialization.data(withJSONObject: params)
        case .transferCreator(let newCreatorId):
            return try? JSONSerialization.data(withJSONObject: ["newCreatorId": newCreatorId])
        default:
            return nil
        }
    }
}

// MARK: - Question Endpoints

enum QuestionEndpoint: APIEndpoint {
    case getByOrder(order: Int)
    case getByCategory(category: String)
    case getAll
    /// POST /questions/skip — 오늘 질문 건너뛰기 (하트 1개 차감), 새 질문 반환
    case skip
    /// GET /questions?page=&limit= — 가족 질문 히스토리 (답변 포함)
    case getHistory(page: Int, limit: Int)
    /// POST /questions/custom — 나만의 질문 작성 (하트 3개 차감)
    case createCustom(content: String)

    var path: String {
        switch self {
        case .getByOrder:
            return "/questions/by-order"
        case .getByCategory:
            return "/questions/by-category"
        case .getAll, .getHistory:
            return "/questions"
        case .skip:
            return "/questions/skip"
        case .createCustom:
            return "/questions/custom"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .skip, .createCustom:
            return .post
        default:
            return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getByOrder(let order):
            return [URLQueryItem(name: "order", value: "\(order)")]
        case .getByCategory(let category):
            return [URLQueryItem(name: "category", value: category)]
        case .getHistory(let page, let limit):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        default:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case .createCustom(let content):
            return try? JSONSerialization.data(withJSONObject: ["content": content])
        default:
            return nil
        }
    }
}

// MARK: - Daily Question Endpoints

enum DailyQuestionEndpoint: APIEndpoint {
    case create(familyId: String, questionId: String, questionOrder: Int, date: String)
    case get(id: String)
    case getByFamilyAndDate(familyId: String, date: String)
    case getHistoryByFamily(familyId: String, limit: Int?)
    case update(id: String, isCompleted: Bool, answerIds: [String])

    var path: String {
        switch self {
        case .create:
            return "/daily-questions"
        case .get(let id):
            return "/daily-questions/\(id)"
        case .getByFamilyAndDate:
            return "/daily-questions/by-family-date"
        case .getHistoryByFamily:
            return "/daily-questions/history"
        case .update(let id, _, _):
            return "/daily-questions/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        case .get, .getByFamilyAndDate, .getHistoryByFamily:
            return .get
        case .update:
            return .put
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getByFamilyAndDate(let familyId, let date):
            return [
                URLQueryItem(name: "family_id", value: familyId),
                URLQueryItem(name: "date", value: date)
            ]
        case .getHistoryByFamily(let familyId, let limit):
            var items = [URLQueryItem(name: "family_id", value: familyId)]
            if let limit = limit {
                items.append(URLQueryItem(name: "limit", value: "\(limit)"))
            }
            return items
        default:
            return nil
        }
    }

    var body: Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        switch self {
        case .create(let familyId, let questionId, let questionOrder, let date):
            let params: [String: Any] = [
                "family_id": familyId,
                "question_id": questionId,
                "question_order": questionOrder,
                "date": date
            ]
            return try? JSONSerialization.data(withJSONObject: params)
        case .update(_, let isCompleted, let answerIds):
            let params: [String: Any] = [
                "is_completed": isCompleted,
                "answer_ids": answerIds
            ]
            return try? JSONSerialization.data(withJSONObject: params)
        default:
            return nil
        }
    }
}

// MARK: - Nudge Endpoints

enum NudgeEndpoint: APIEndpoint {
    /// POST /nudge — 재촉하기 (하트 1개 차감)
    case send(targetUserId: String)

    var path: String { "/nudge" }
    var method: HTTPMethod { .post }

    var body: Data? {
        switch self {
        case .send(let targetUserId):
            return try? JSONSerialization.data(withJSONObject: ["targetUserId": targetUserId])
        }
    }
}

// MARK: - Answer Endpoints

enum AnswerEndpoint: APIEndpoint {
    case create(questionId: String, content: String, imageUrl: String?, moodId: String?)
    case get(id: String)
    /// GET /answers/family/{questionId} — 가족 전체 답변 + myAnswer
    case getFamilyAnswers(questionId: String)
    /// GET /answers/my/{questionId} — 내 답변
    case getMyAnswer(questionId: String)
    case update(id: String, content: String, imageUrl: String?, moodId: String?)

    var path: String {
        switch self {
        case .create:
            return "/answers"
        case .get(let id):
            return "/answers/\(id)"
        case .getFamilyAnswers(let questionId):
            return "/answers/family/\(questionId)"
        case .getMyAnswer(let questionId):
            return "/answers/my/\(questionId)"
        case .update(let id, _, _, _):
            return "/answers/\(id.lowercased())"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        case .get, .getFamilyAnswers, .getMyAnswer:
            return .get
        case .update:
            return .put
        }
    }

    var body: Data? {
        switch self {
        case .create(let questionId, let content, let imageUrl, let moodId):
            var params: [String: Any] = [
                "questionId": questionId,
                "content": content
            ]
            if let imageUrl = imageUrl {
                params["imageUrl"] = imageUrl
            }
            if let moodId = moodId {
                params["moodId"] = moodId
            }
            return try? JSONSerialization.data(withJSONObject: params)
        case .update(_, let content, let imageUrl, let moodId):
            var params: [String: Any] = ["content": content]
            if let imageUrl = imageUrl {
                params["imageUrl"] = imageUrl
            }
            if let moodId = moodId {
                params["moodId"] = moodId
            }
            return try? JSONSerialization.data(withJSONObject: params)
        default:
            return nil
        }
    }
}

// MARK: - Mood Endpoints

enum MoodEndpoint: APIEndpoint {
    /// POST /moods — 기분 기록 저장 (upsert, 하루 1회)
    case save(mood: String, note: String?, date: String?)
    /// GET /moods?days=N — 최근 N일 기분 목록
    case getRecent(days: Int)

    var path: String { "/moods" }

    var method: HTTPMethod {
        switch self {
        case .save: return .post
        case .getRecent: return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getRecent(let days):
            return [URLQueryItem(name: "days", value: "\(days)")]
        default:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case .save(let mood, let note, let date):
            var params: [String: Any] = ["mood": mood]
            if let note { params["note"] = note }
            if let date { params["date"] = date }
            return try? JSONSerialization.data(withJSONObject: params)
        default:
            return nil
        }
    }
}

// MARK: - Notification Endpoints

enum NotificationEndpoint: APIEndpoint {
    /// GET /notifications?limit=N
    case getAll(limit: Int)
    /// PATCH /notifications/{id}/read
    case markAsRead(id: String)
    /// PATCH /notifications/read-all
    case markAllAsRead
    /// DELETE /notifications/{id}
    case delete(id: String)
    /// DELETE /notifications
    case deleteAll

    var path: String {
        switch self {
        case .getAll: return "/notifications"
        case .markAsRead(let id): return "/notifications/\(id)/read"
        case .markAllAsRead: return "/notifications/read-all"
        case .delete(let id): return "/notifications/\(id)"
        case .deleteAll: return "/notifications"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getAll: return .get
        case .markAsRead, .markAllAsRead: return .patch
        case .delete, .deleteAll: return .delete
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getAll(let limit):
            return [URLQueryItem(name: "limit", value: "\(limit)")]
        default:
            return nil
        }
    }
}
