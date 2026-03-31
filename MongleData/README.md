
# 📦 Data Layer Architecture

본 프로젝트의 Data 레이어는 Clean Architecture를 기반으로 설계되었으며,
데이터 접근 책임을 명확히 분리하고 Domain 레이어와의 의존성을 최소화하는 것을 목표로 합니다.

---

## 📁 Data Layer Structure

```text
Data/
├── DataSources/          # 실제 데이터 접근 계층
│   ├── Local/            # 로컬 저장소 (UserDefaults 등)
│   └── Remote/           # 네트워크 통신 (API)
├── DTOs/                 # Data Transfer Objects
├── Mappers/              # DTO ↔ Domain 변환
└── Repositories/         # Repository 구현체
```

---

## 1️⃣ DataSources

### 역할

* 실제 데이터의 **조회 / 저장**을 담당
* 네트워크, 로컬 저장소 등 **외부 시스템과 직접 통신**

---

### 🔹 Remote (원격 데이터 소스)

| 파일                     | 역할                                  |
| ---------------------- | ----------------------------------- |
| `APIClient.swift`      | URLSession 기반 HTTP 요청 처리            |
| `APIEndpoint.swift`    | API Endpoint 정의 (URL, Method, Body) |
| `APIError.swift`       | API 관련 에러 타입 정의                     |
| `UserAPIService.swift` | 사용자 관련 API 호출                       |
| `AuthAPIService.swift` | 인증 관련 API 호출                        |

---

### 🔹 Local (로컬 데이터 소스)

| 파일                          | 역할                  |
| --------------------------- | ------------------- |
| `UserDefaultsManager.swift` | UserDefaults 제네릭 래퍼 |
| `UserLocalDataSource.swift` | User 로컬 캐싱          |
| `AuthLocalDataSource.swift` | 토큰 및 로그인 상태 저장      |

---

## 2️⃣ DTOs (Data Transfer Objects)

### 역할

* API 요청/응답을 위한 데이터 구조
* **JSON ↔ Swift 변환** 책임
* 서버 스펙에 맞춘 타입 사용 (String 기반)

```swift
// 예시: UserDTO
struct UserDTO: Codable {
    let id: String
    let email: String
    let name: String
    let profileImageURL: String?
    let role: String
    let createdAt: String
}
```

### 주요 DTO 목록

| DTO                | 용도           |
| ------------------ | ----------    |
| `UserDTO`          | 사용자 정보      |
| `FamilyDTO`        | 가족 그룹 정보    |
| `MemberDTO`        | 가족 멤버 정보    |
| `QuestionDTO`      | 질문 템플릿      |
| `DailyQuestionDTO` | 오늘의 질문      |
| `AnswerDTO`        | 답변           |
| `TreeProgressDTO`  | 나무 성장 상태    |
| `AuthDTO`          | 로그인 / 회원가입  |

---

## 3️⃣ Mappers

### 역할

* **DTO ↔ Domain Entity 변환**
* 타입 안정성 확보
* API 스펙 변경으로부터 Domain 보호

```swift
struct UserMapper {
    static func toDomain(_ dto: UserDTO) -> User {
        User(
            id: UUID(uuidString: dto.id) ?? UUID(),
            email: dto.email,
            name: dto.name,
            profileImageURL: dto.profileImageURL,
            role: FamilyRole(rawValue: dto.role) ?? .other,
            createdAt: ISO8601DateFormatter().date(from: dto.createdAt) ?? Date()
        )
    }
}
```

### Mapper가 필요한 이유

* **Domain**

  * `UUID`, `Date`, `Enum` 등 타입 안전한 구조
* **API / DTO**

  * `String` 기반 (JSON 호환)
* Mapper를 통해 두 레이어 간 책임을 명확히 분리

---

## 4️⃣ Repositories

### 역할

* Domain 레이어에 정의된 **Repository Protocol 구현**
* DataSource와 Mapper를 조합하여 Domain에 필요한 데이터 제공

---

### 🔹 Domain Protocol

```swift
protocol AuthRepositoryProtocol {
    func signIn(email: String, password: String) async throws -> User
}
```

---

### 🔹 Data Layer Implementation

```swift
final class AuthRepository: AuthRepositoryProtocol {
    private let apiClient: APIClientProtocol

    func signIn(email: String, password: String) async throws -> User {
        let request = LoginRequestDTO(email: email, password: password)
        let response: LoginResponseDTO = try await apiClient.request(.login(request))
        return UserMapper.toDomain(response.user)
    }
}
```

---

### Repository 목록

| Repository                | 담당 기능           |
| ------------------------- | --------------- |
| `AuthRepository`          | 로그인 / 회원가입 / 토큰 |
| `UserRepository`          | 사용자 조회 / 수정     |
| `FamilyRepository`        | 가족 생성 / 멤버 관리   |
| `QuestionRepository`      | 질문 조회           |
| `DailyQuestionRepository` | 오늘의 질문          |
| `AnswerRepository`        | 답변 생성 / 조회      |
| `TreeRepository`          | 나무 성장 추적        |

---

## 🔄 Data Flow

```text
Presentation
(HomeFeature → Repository Protocol)
        ↓
Domain
(Repository Protocol / Entity)
        ↓
Data
(Repository 구현 → Mapper → DTO → DataSource → API / Storage)
```

---

## ✅ 설계 포인트 요약

* Domain → Data **단방향 의존성**
* API 스펙 변경이 Domain에 영향을 주지 않도록 보호
* 테스트 및 유지보수에 용이한 구조
* 역할과 책임이 명확한 레이어 분리

