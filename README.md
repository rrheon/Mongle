# 몽글 (Mongle) — iOS

> 가족이 매일 하나의 질문에 함께 답하며 서로를 더 깊이 알아가는 가족 소통 앱

---

## 앱 개요

**몽글**은 매일 하나의 질문을 가족 구성원 모두에게 제시하고, 각자의 답변을 통해 서로의 일상과 생각을 공유하는 가족 커뮤니케이션 앱입니다.

- 매일 새 질문 제공 (일상, 추억, 가치관, 미래, 감사 카테고리)
- 가족 구성원의 답변을 한눈에 확인
- 하트 시스템: 나만의 질문 작성, 질문 다시받기, 재촉하기 기능
- 연속 답변 스트릭(Streak) 트래킹

---

## 기술 스택

| 분류 | 기술 |
|------|------|
| 언어 | Swift 5.10 |
| UI | SwiftUI |
| 아키텍처 | TCA (The Composable Architecture) |
| 비동기 | Swift Concurrency (async/await) |
| 의존성 주입 | TCA `@Dependency` |
| 패키지 관리 | Swift Package Manager |
| 소셜 로그인 | Kakao SDK, Google Sign-In, Apple Sign-In |
| 네트워크 | URLSession (커스텀 APIClient, 지수 백오프 재시도) |
| 보안 | Keychain (토큰 저장) |
| 광고 | Google Mobile Ads + UMP (GDPR/CCPA 동의 수집) |
| 최소 iOS | iOS 17.0 |

---

## 프로젝트 구조

프로젝트는 **3개의 Swift Package + 1개의 Xcode 앱 타깃**으로 구성됩니다.

```
FamTree/
├── Mongle.xcodeproj          # Xcode 프로젝트
├── Mongle/                   # 앱 타깃 진입점
│   ├── MongleApp.swift       # @main, RootFeature 마운트
│   └── Info.plist
│
├── Domain/                   # Swift Package — 비즈니스 규칙
│   └── Sources/Domain/
│       ├── Entities/         # 도메인 엔티티 (외부 프레임워크 미의존)
│       │   ├── User.swift          # 사용자 + FamilyRole
│       │   ├── Question.swift      # 질문 + HistoryQuestion
│       │   ├── Answer.swift        # 답변
│       │   ├── FamilyGroup.swift   # 가족 그룹
│       │   ├── DailyQuestion.swift # 오늘의 질문 인스턴스
│       │   └── Notification.swift  # 알림
│       └── Repositories/     # Repository Protocol 정의
│           ├── AuthRepositoryProtocol.swift
│           ├── UserRepositoryProtocol.swift
│           ├── FamilyRepositoryProtocol.swift
│           ├── QuestionRepositoryProtocol.swift
│           ├── AnswerRepositoryProtocol.swift
│           ├── NudgeRepositoryProtocol.swift
│           ├── MoodRepositoryProtocol.swift
│           └── NotificationRepositoryProtocol.swift
│
├── MongleData/               # Swift Package — 데이터 레이어 (git submodule)
│   └── Sources/MongleData/
│       ├── DataSources/
│       │   ├── Remote/API/   # APIClient, APIEndpoint, APIError, NetworkMonitor
│       │   └── Local/        # Keychain 토큰 저장, UserDefaults
│       ├── DTOs/             # 서버 JSON ↔ Swift 변환 구조체
│       ├── Mappers/          # DTO → Domain Entity 변환
│       ├── Repositories/     # Repository Protocol 구현체
│       └── Credentials/      # 소셜 로그인 Credential (Kakao/Google/Apple)
│
└── MongleFeatures/           # Swift Package — Presentation 레이어 (TCA)
    └── Sources/MongleFeatures/
        ├── Presentation/
        │   ├── Root/         # RootFeature: 앱 전체 상태 (인증·데이터 로드)
        │   ├── MainTab/      # MainTabFeature: 탭바 + 코디네이터
        │   ├── Onboarding/   # 온보딩 화면
        │   ├── Login/        # LoginFeature: 이메일·소셜 로그인
        │   ├── Group/        # GroupSelectFeature: 그룹 생성·참여
        │   ├── Home/         # HomeFeature: 오늘의 질문 카드, 가족 현황, 하트 팝업
        │   ├── History/      # HistoryFeature: 월별 달력 + 과거 질문 카드
        │   ├── Question/     # QuestionDetailFeature, WriteQuestionFeature
        │   ├── Peer/         # PeerNudgeFeature: 재촉하기, PeerAnswerFeature
        │   ├── Notification/ # NotificationFeature: 알림 목록·읽음 처리
        │   ├── Profile/      # ProfileEditFeature, AccountManagementFeature
        │   ├── Settings/     # SettingsFeature
        │   └── Support/      # SupportScreenFeature: 그룹 관리, 기분 히스토리
        ├── Design/           # 디자인 시스템 (색상, 폰트, 공통 컴포넌트)
        └── Error/            # AppError, ErrorHandler, MongleErrorView
```

---

## 아키텍처

### 레이어 구조

```
Presentation (MongleFeatures)
    ↓ @Dependency (TCA)
Domain (Interface만 의존)
    ↑ implements
Data (MongleData)
```

### TCA 패턴

각 화면은 `Feature = State + Action + Reducer + View` 구조로 구성됩니다.

```swift
// State — 불변 UI 상태
struct HomeFeature: Reducer {
    @ObservableState
    struct State: Equatable {
        var todayQuestion: Question?
        var streakDays: Int = 0
        var appError: AppError?
        ...
    }

    // Action — 사용자 이벤트 + 내부 이펙트
    enum Action {
        case onAppear
        case questionTapped
        case loadDataResponse(Result<RootData, Error>)
        case delegate(Delegate)
        ...
    }

    // Reducer — 상태 변이 + 이펙트 반환
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let data = try await questionRepository.getTodayQuestion()
                    await send(.loadDataResponse(.success(data)))
                }
            ...
            }
        }
    }
}
```

### Delegate 패턴 (화면 간 통신)

자식 Feature는 부모에게 이벤트를 `delegate`로 전달합니다. 실제 네비게이션 처리는 `MainTabFeature`와 `RootFeature`에서 담당합니다.

```swift
enum Action {
    case delegate(Delegate)
    enum Delegate {
        case navigateToQuestionDetail(Question)
        case requestLogin
    }
}
```

### 에러 처리 시스템

모든 Feature에 통합 에러 처리가 적용되어 있습니다.

```swift
// catch 블록
} catch {
    await send(.setAppError(errorHandler(error, context: "HomeFeature.onAppear")))
}

// View에서 배너 표시
.mongleErrorBanner(
    error: store.appError,
    onDismiss: { store.send(.setAppError(nil)) },
    onRetry: store.appError?.isRetryable == true ? { store.send(.refresh) } : nil
)
```

---

## 주요 기능 구현 상태

| 화면 | 기능 | 상태 |
|------|------|------|
| 온보딩 | 슬라이드 + 다시보지않기 | ✅ |
| 로그인 | 카카오 / 구글 / 애플 소셜 로그인 | ✅ |
| 그룹 선택 | 새 그룹 생성, 초대코드 참여 | ✅ |
| 홈 | 오늘의 질문, 가족 캐릭터 현황, 스트릭, 하트 팝업 | ✅ |
| 질문 상세 | 답변 제출·수정, 가족 답변 목록 | ✅ |
| 나만의 질문 | 하트 3개 차감, 하루 1회 제한 | ✅ |
| 질문 다시받기 | 하트 1개 차감 | ✅ |
| 재촉하기 | 하트 1개 차감, 푸시 알림 (APNs 인프라 필요) | ✅ |
| 히스토리 | 월별 달력, 과거 질문·답변 조회 | ✅ |
| 알림 | 알림 목록, 읽음·전체읽음 처리 | ✅ |
| 프로필 편집 | 이름·역할 변경 | ✅ |
| 그룹 관리 | 초대코드 복사, 멤버 내보내기(방장) | ✅ |
| 계정 관리 | 로그아웃, 회원탈퇴 | ✅ |
| 기분 히스토리 | 최근 14일 기분 기록 | ✅ |
| 게스트 모드 | 로그인 없이 홈 둘러보기 | ✅ |
| 토큰 자동 갱신 | 401 → refresh → 재시도, 동시 갱신 방지 | ✅ |
| 오프라인 감지 | NWPathMonitor 기반 즉시 차단 | ✅ |
| 푸시 알림 권한 | 최초 로그인 시 1회 요청 | ✅ |
| 광고 (AdMob) | 리워드/배너 광고, UMP(GDPR/CCPA) 동의 폼, ATT 프롬프트 | ✅ |
| 약관/개인정보 | Notion 호스팅 페이지를 기기 언어(ko/en/ja) 로 자동 선택 | ✅ |
| 다국어 지원 | ko / en / ja 리소스 번들 | ✅ |

---

## 시작하기

### 사전 요건

- Xcode 15.4 이상
- iOS 17.0 시뮬레이터 또는 실기기
- Swift Package Manager (자동 의존성 해결)

### 소셜 로그인 설정

**카카오 로그인**

1. [Kakao Developers](https://developers.kakao.com)에서 앱 등록
2. `Info.plist`의 `kakao{NATIVE_APP_KEY}` URL Scheme 교체
3. `MongleData/Credentials/KakaoLoginCredential.swift` 확인

**구글 로그인**

1. Firebase Console에서 iOS 앱 등록 후 `GoogleService-Info.plist` 발급
2. `app/` 디렉토리에 추가 (`.gitignore`에 포함되어 있어 커밋되지 않음)

**Apple 로그인**

- Xcode Signing & Capabilities에서 "Sign in with Apple" 추가

### 빌드

Xcode에서 `Mongle.xcodeproj`를 열고 시뮬레이터 또는 실기기로 빌드합니다.
SPM 패키지는 첫 빌드 시 자동으로 다운로드됩니다.

---

## 의존성

| 패키지 | 용도 |
|--------|------|
| [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) | TCA 프레임워크 |
| [kakao-ios-sdk](https://github.com/kakao/kakao-ios-sdk) | 카카오 소셜 로그인 |
| [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) | 구글 소셜 로그인 |
| [swift-package-manager-google-mobile-ads](https://github.com/googleads/swift-package-manager-google-mobile-ads) | AdMob 배너/리워드 광고 |
| [swift-package-manager-google-user-messaging-platform](https://github.com/googleads/swift-package-manager-google-user-messaging-platform) | UMP (GDPR/CCPA 동의 수집 CMP) |

---

## 관련 저장소

| 저장소 | 설명 |
|--------|------|
| `MongleData` | 데이터 레이어 Swift Package (git submodule) |
| `Mongle-Android` | Android 포팅 버전 |
| `MongleServer` | Node.js + Prisma 백엔드 서버 |
