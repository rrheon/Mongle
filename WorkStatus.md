# FamTree 작업 현황

> 마지막 업데이트: 2026-03-01 (Keychain 교체 + loginProviderType 연결)

---

## 프로젝트 구조

```
FamTree/
├── Domain/                  # 순수 도메인 레이어 (Entity, Repository Protocol)
├── FTData/                  # 데이터 레이어 (API, DTO, Repository 구현)
├── FTFeatures/              # 프레젠테이션 레이어 (TCA Feature + View)
└── FamTree/                 # 앱 진입점 (FamTreeApp.swift)
```

**의존성 방향:** `FTFeatures` → `FTData` → `Domain`

**핵심 기술 스택**
- Swift + SwiftUI
- TCA (The Composable Architecture) 1.9.0+
- SPM 멀티 모듈
- iOS 17+ / macOS 14+

---

## 완료된 작업

### 1. 가족 탭 UI — 고슴도치 그리드
**파일:** `FTFeatures/.../Family/FamilyTabView.swift`

- `FamilyHedgehogGridSection`: 2열 `LazyVGrid`로 가족 구성원 목록 표시
- `FamilyHedgehogCard`: `HedgehogView`(컬러 원 캐릭터)를 역할별 색상으로 표시
- `FamilyInviteCard`: 점선 테두리 "초대하기" 카드 (그리드 마지막 칸)
- 카드마다 `animationDelay`를 달리해 순차 부유(float) 애니메이션 적용

---

### 2. 소셜 로그인 — OCP 기반 아키텍처

**설계 원칙:** 새로운 제공자 추가 시 기존 코드 수정 불필요. Credential 타입 + Provider 클래스만 추가.

#### Domain
**`SocialLoginCredential.swift`**
```swift
public enum SocialProviderType: String { case apple, kakao, naver, google }

public protocol SocialLoginCredential: Sendable {
    var providerType: SocialProviderType { get }
    var fields: [String: String] { get }
}
```

**`AuthRepositoryProtocol.swift`**
```swift
func socialLogin(with credential: any SocialLoginCredential) async throws -> User
func deleteAccount() async throws
```

#### FTData — Credential 구현체

| 파일 | 제공자 | 서버 전송 필드 |
|------|--------|--------------|
| `AppleLoginCredential.swift` | Apple | `identity_token`, `authorization_code`, `name?`, `email?` |
| `KakaoLoginCredential.swift` | Kakao | `access_token`, `name?`, `email?` |
| `GoogleLoginCredential.swift` | Google | `id_token`, `name?`, `email?` |

**API 엔드포인트** (`APIEndpoint.swift`)
```
POST   /auth/social    — 소셜 로그인 (provider + fields)
DELETE /auth/account   — 계정 삭제
```

#### FTFeatures — Provider 구현체
**`SocialLoginProvider.swift`**

| 클래스 | `authenticate()` | `revokeClientAccess()` |
|--------|---------|---------|
| `AppleLoginProvider` | `ASAuthorizationController` + `CheckedContinuation` | no-op (서버에서 revoke) |
| `KakaoLoginProvider` | `loginWithKakaoTalk` → `loginWithKakaoAccount` 폴백 | `UserApi.shared.unlink()` |
| `GoogleLoginProvider` | `GIDSignIn.sharedInstance.signIn(withPresenting:)` | `GIDSignIn.sharedInstance.disconnect()` |

**`revokeClientSocialAccess(for:)`**: `@MainActor` 헬퍼 — SettingsFeature가 제공자별 클라이언트 연결 해제를 호출하는 단일 진입점

**SDK 의존성 (FTFeatures/Package.swift)**
```swift
.package(url: "https://github.com/kakao/kakao-ios-sdk",    from: "2.22.0")
.package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
```

**`LoginView.swift`**: Apple / Kakao / Google 버튼 연결 완료 (Naver 미연결)

**`LoginFeature.swift`**: ⚠️ `socialCredentialReceived` Mock 구현 중 (API 연동 대기)

---

### 3. 회원탈퇴

**탈퇴 처리 흐름:**
```
탈퇴 버튼 탭
  → [클라이언트] revokeClientSocialAccess(for: providerType)
      - Apple : no-op
      - Kakao : UserApi.shared.unlink()
      - Google: GIDSignIn.sharedInstance.disconnect()
  → [서버] DELETE /auth/account
      - Apple : 서버가 저장된 refresh_token으로 Apple revoke API 호출
      - Kakao/Google: 이미 unlink/disconnect 완료 → 계정 삭제만 처리
  → 로컬 토큰 삭제
  → delegate(.accountDeleted) → MainTabFeature.logout → RootFeature 미인증 상태
```

**변경 파일:**

| 파일 | 변경 내용 |
|------|---------|
| `AuthRepositoryProtocol.swift` | `deleteAccount()` + `accountDeletionFailed` 에러 |
| `APIEndpoint.swift` | `AuthEndpoint.deleteAccount` (`DELETE /auth/account`) |
| `AuthRepository.swift` | `deleteAccount()` 구현 (토큰 삭제 포함) |
| `SocialLoginProvider.swift` | 각 Provider `revokeClientAccess()` + 헬퍼 함수 |
| `SettingsFeature.swift` | `loginProviderType`, `showDeleteAccountConfirmation`, 삭제 액션/로직 |
| `SettingsTabView.swift` | 회원탈퇴 버튼 + 2단계 확인 Alert |
| `MainTabFeature.swift` | `settings(.delegate(.accountDeleted))` → `.logout` 전파 |

**⚠️ 현재 Mock 상태:** `SettingsFeature.deleteAccountConfirmed`에서 실제 API 호출 대신 800ms 지연 후 성공 처리. FastAPI 연동 시 교체 필요.

---

## 미완료 / TODO

### 🔴 필수 — 앱 실행에 필요

#### 앱 설정 (Xcode + Info.plist)

- 설정한 키, 파일을 참고하여 작업할 것.
- gitignore가 있다면 해당 파일은 깃허브에 올라가지 않도록 할 것 (없으면 생성)

**Apple Sign In**
- [ ] Xcode → Signing & Capabilities → **Sign in with Apple** capability 추가
  - Apple developer account 필요 추후에 작업

**Kakao 로그인**
- [x] 카카오 개발자 콘솔에서 iOS 앱 등록 → **Native App Key** 발급
  - Native App Key : 73b4d3e9a62701280ec877fe441949b3
- [x] `Info.plist`에 URL Scheme 추가: `kakao73b4d3e9a62701280ec877fe441949b3`
- [x] `FamTreeApp.swift` SDK 초기화 및 URL 핸들링 (`KakaoSDK.initSDK` + `AuthController.handleOpenUrl`)
- [x] `Package.swift` `package:` 파라미터 확인 — `"kakao-ios-sdk"` 확인 완료

**Google 로그인**
- [x] Google Cloud Console에서 iOS OAuth 2.0 클라이언트 ID 발급
  - `credentials.plist`에서 CLIENT_ID 확인 완료
- [ ] `GoogleService-Info.plist` 다운로드 → 프로젝트 추가 (credentials.plist로 대체 사용 중)
- [x] `Info.plist`에 `REVERSED_CLIENT_ID` URL Scheme 추가
- [x] `FamTreeApp.swift`에 URL 핸들링 (`GIDSignIn.sharedInstance.handle(url)`)
- [ ] `google_icon` 이미지 에셋 추가

**기타**
- [x] `.gitignore` 루트 생성 — `credentials.plist`, `GoogleService-Info.plist` 등 민감 파일 제외
- [x] `Info.plist` 수동 생성 + `pbxproj` `GENERATE_INFOPLIST_FILE = NO` 전환

---

### 🟡 중요 — 기능 완성에 필요

#### 백엔드 연동 (Node.js/Express — /Users/yong/Desktop/FamTreeServer)

> ⚠️ 서버는 FastAPI가 아닌 **Node.js/Express + Prisma + PostgreSQL** 구조입니다.
> 인증은 AWS Cognito 기반이나, 소셜 로그인을 위해 커스텀 JWT 레이어를 추가했습니다.

**인증 엔드포인트 (신규 추가 완료)**
- [x] `POST /auth/social` — Apple/Kakao/Google 토큰 검증 후 커스텀 JWT 발급
  - Apple: `identity_token` → JWKS 검증 → user upsert
  - Kakao: `access_token` → Kakao API 조회 → user upsert
  - Google: `id_token` → JWKS 검증 → user upsert
- [x] `DELETE /auth/account` — 계정 삭제 (JWT 인증 필요)
- [x] 커스텀 JWT 지원: `src/utils/jwt.ts` + `src/middleware/auth.ts` 업데이트

**Mock 제거 (완료)**
- [x] `LoginFeature.socialCredentialReceived` → `authRepository.socialLogin(with:)` 실제 호출
- [x] `SettingsFeature.deleteAccountConfirmed` → `authRepository.deleteAccount()` 실제 호출
- [x] `RootFeature.refreshHomeData` → 실제 API 호출 (families/my, questions/today, tree/progress)
- [x] `RootFeature.onAppear` → `authRepository.getCurrentUser()` 실제 인증 상태 확인
- [x] `APIEndpoint.baseURL` → `http://localhost:3000`

**iOS 구조 변경 (완료)**
- [x] `AppDependencies.swift` — TCA `@Dependency` 등록 (auth/family/question/tree)
- [x] `FTData.swift` — 공개 팩토리 함수 (`makeAuthRepository()` 등)
- [x] `UserDTO` — 서버 camelCase 형식으로 CodingKeys 업데이트
- [x] `FamilyResponseDTO`, `TreeProgressResponseDTO`, `DailyQuestionResponseDTO` — 신규 DTO
- [x] Mapper에 서버 응답 형식 변환 메서드 추가
- [x] `HomeEndpoint` — `GET /families/my`, `GET /questions/today`, `GET /tree/progress`
- [x] `MongleRepositoryInterface.getMyFamily()` / `QuestionRepositoryInterface.getTodayQuestion()` / `TreeRepositoryInterface.getMyTreeProgress()` 추가

#### loginProviderType 연결
- [x] `LoginFeature.delegate(.loggedIn(user, providerType?))` — delegate에 `SocialProviderType?` 추가
  - `LoginFeature.State.lastUsedProviderType` 저장 → `.loginResponse(.success)` 시 delegate에 포함
  - `RootFeature.State.loginProviderType` 저장
  - `loadDataResponse` 에서 `SettingsFeature.State(loginProviderType:)` 주입
  - `checkAuthResponse` → `refreshHomeData` 트리거로 수정 (로그인 후 MainTab 생성 보장)

#### 토큰 보안 강화
- [x] `AuthRepository.TokenStorage` — `UserDefaults` → `KeychainTokenStorage` 교체 완료
  - `Security` 프레임워크 사용, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` 접근 정책
  - 서비스: `com.mongle.auth`

---

### 🟢 향후 작업

#### 네이버 로그인
- [ ] `FTData/Credentials/NaverLoginCredential.swift` 생성
- [ ] `SocialLoginProvider.swift`에 `NaverLoginProvider` + `revokeClientAccess()` 추가
- [ ] `FTFeatures/Package.swift`에 네이버 SDK 의존성 추가
- [ ] `LoginView.swift` 네이버 버튼 연결 (현재 빈 TODO)

#### 푸시 알림 (FCM)
- [ ] Firebase SDK 추가 (푸시 전용)
- [ ] `UNUserNotificationCenter` 권한 요청
- [ ] FCM 토큰 서버 등록 로직
- [ ] `NotificationFeature.swift` / `NotificationView.swift` 실제 데이터 연동

#### 이메일 로그인 / 회원가입
- [ ] `LoginFeature.emailLoginTapped`, `emailSignupTapped` 액션에 네비게이션 추가
- [ ] `EmailLoginView.swift` Feature 연동 완성

---

## 파일별 상태 요약

### Domain
| 파일 | 상태 |
|------|------|
| `SocialLoginCredential.swift` | ✅ 완료 |
| `AuthRepositoryProtocol.swift` | ✅ 완료 (`socialLogin` + `deleteAccount` 포함) |
| `User.swift`, `FamilyGroup.swift` 등 | ✅ 완료 |

### FTData
| 파일 | 상태 |
|------|------|
| `AppleLoginCredential.swift` | ✅ 완료 |
| `KakaoLoginCredential.swift` | ✅ 완료 |
| `GoogleLoginCredential.swift` | ✅ 완료 |
| `AuthRepository.swift` | ✅ 완료 (`socialLogin` + `deleteAccount` 구현, API 연동 대기) |
| `APIEndpoint.swift` | ✅ 완료 (`/auth/social` + `/auth/account`, baseURL 교체 대기) |
| `APIClient.swift` | ✅ 완료 |

### FTFeatures
| 파일 | 상태 |
|------|------|
| `SocialLoginProvider.swift` | ✅ Apple·Kakao·Google 로그인 + 회원탈퇴 완료 |
| `LoginFeature.swift` | ⚠️ Mock 구현 (API 연동 대기) |
| `LoginView.swift` | ✅ Apple·Kakao·Google 버튼 연결 완료 (Naver 미연결) |
| `SettingsFeature.swift` | ✅ 로그아웃 + 회원탈퇴 완료 (Mock, loginProviderType 연결 대기) |
| `SettingsTabView.swift` | ✅ 로그아웃 + 회원탈퇴 UI 완료 |
| `MainTabFeature.swift` | ✅ accountDeleted 전파 추가 완료 |
| `RootFeature.swift` | ⚠️ Mock 데이터 사용 중 |
| `FamilyTabView.swift` | ✅ 고슴도치 그리드 완료 |
| `HomeFeature.swift` / `HomeView.swift` | ✅ 완료 |
| `NotificationFeature.swift` / `NotificationView.swift` | ⚠️ 파일 존재, FCM 미연동 |
| `FamTreeApp.swift` | ⚠️ Kakao·Google URL 핸들링 미추가 |

---

## 다음 작업 우선순위

1. ✅ **`FamTreeApp.swift`** — `AppLifecycleSupport.swift`의 `SocialSDK`로 이미 완료
2. **Xcode Capability** — Sign in with Apple 추가 (Apple 개발자 계정 필요)
3. ✅ **Keychain 토큰 저장** — `KeychainTokenStorage` 구현 완료
4. **FastAPI 백엔드** — `/auth/social`, `/auth/account` 엔드포인트 구현
5. ✅ **loginProviderType 연결** — Login → Root → Settings 경로 완료
6. **Mock 제거** — FastAPI 연동 후: `LoginFeature.socialCredentialReceived`, `SettingsFeature.deleteAccountConfirmed`, `RootFeature.refreshHomeData`, `RootFeature.onAppear`
