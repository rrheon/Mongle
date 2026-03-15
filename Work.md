# Mongle 작업 현황

## 작업 위치

| 플랫폼 | 경로 |
|--------|------|
| iOS | `/Users/yong/Desktop/FamTree/MongleFeatures` |
| Android | `/Users/yong/Mongle-Android` |
| Server | `/Users/yong/Desktop/FamTreeServer` |
| UI 디자인 | `MongleUI.pen` |

---

## ✅ 완료된 작업

### Android

- [x] 네트워크 레이어 구축 (Retrofit 2.11 + OkHttp 4.12 + Moshi 1.15)
- [x] `NetworkModule` (Hilt) — BASE_URL `http://10.0.2.2:3000/`
- [x] `MongleApiService` — socialLogin / emailLogin / emailSignup Retrofit 인터페이스
- [x] `ApiAuthRepository` — MockAuthRepository 대체, 토큰 SharedPreferences 저장
- [x] `SocialLoginHelper` — Kakao 코루틴 래퍼 + Google Sign-In Intent 헬퍼
- [x] `LoginScreen` — 실제 Kakao / Google 로그인 흐름 연동
- [x] `LoginViewModel` — `setError()` 메서드 추가

---

### iOS — 인프라

- [x] **NetworkMonitor** — NWPathMonitor 기반 오프라인 실시간 감지 (`MongleData`)
- [x] **APIError** public화 — `.offline` / `.timeout` 케이스 추가, `isRetryable` / `requiresLogin` 프로퍼티
- [x] **APIClient 개선** — URLSession 15초 타임아웃, 오프라인 즉시 차단, URLError→APIError 자동 변환, 지수 백오프 자동 재시도 (5xx·타임아웃 최대 2회)
- [x] **AppError** — 앱 전체 통합 에러 타입 (`MongleFeatures/Error/AppError.swift`)
  - `userMessage` (한국어), `isRetryable`, `requiresLogin`, SF Symbol `icon`
  - `AppError.from(_ error: Error)` — APIError / URLError / Domain 에러 자동 변환
- [x] **ErrorHandler** TCA `@Dependency(\.errorHandler)` — DEBUG 로깅 내장, `Effect.mapToAppError()` 헬퍼
- [x] **MongleErrorView** 재사용 UI 컴포넌트
  - `MongleErrorBanner`: 에러 종류별 색상 상단 배너 + 재시도 버튼
  - `MongleErrorFullscreen`: 첫 로딩 실패용 전체화면 에러 뷰
  - `.mongleErrorBanner()` View modifier (`AppError?` / `String?` 오버로드)
- [x] **Repository 팩토리** 추가 (`makeAnswerRepository()`, `makeUserRepository()`, `makeDailyQuestionRepository()`)
- [x] **AppDependencies** — `answerRepository`, `userRepository`, `dailyQuestionRepository` TCA 의존성 등록
- [x] **Question 도메인** — `dailyQuestionId: String?` 필드 추가 (서버 DailyQuestion PK 전파)
- [x] **QuestionMapper** — `DailyQuestionResponseDTO.id` → `Question.dailyQuestionId` 매핑
- [x] **데이터 레이어 서버 API 동기화**
  - `AnswerDTO` — 서버 camelCase 구조로 재작성 (`user: UserDTO` 중첩, `questionId`, `imageUrl`)
  - `FamilyAnswersResponseDTO` 추가 (`answers`, `totalCount`, `myAnswer`)
  - `DailyQuestionResponseDTO` 필드 추가 (`hasMyAnswer`, `familyAnswerCount`, `familyId`, `isSkipped`, `skippedAt`)
  - `AnswerEndpoint` — 실제 경로로 수정 (`/answers/family/{id}`, `/answers/my/{id}`, `POST /answers {questionId, content}`)
  - `QuestionEndpoint.skip` 추가 (`POST /questions/skip`)
  - `FamilyEndpoint.leave` 추가 (`DELETE /families/leave`), `removeMember` 대체
  - `AnswerMapper` — 새 DTO 구조 매핑 (`user.id` → `userId`, `questionId` → `dailyQuestionId`)
  - `AnswerRepository` — 새 엔드포인트 사용, `getByDailyQuestion` → `getFamilyAnswers` 내부 사용
  - `FamilyRepository.removeMember` → `DELETE /families/leave` 사용
  - `QuestionRepository.skipTodayQuestion()` 구현

---

### iOS — 온보딩

- [x] UserDefaults로 온보딩 완료 상태 저장 (`mongle.hasSeenOnboarding`)
- [x] 다시 보지 않기 → 로그인 화면 이동
- [x] 시작 버튼 → 로그인 화면 이동

---

### iOS — 로그인

- [x] Kakao / Google / Apple 소셜 로그인 연동 (`SocialLoginProvider`)
- [x] JWT 토큰 Keychain 저장 (`KeychainTokenStorage`)
- [x] 로그인 성공 → `authRepository.socialLogin()` → 토큰 저장 → 그룹 선택 화면 이동
- [x] 둘러보기 → 게스트 홈 화면 이동 (mock 데이터)

---

### iOS — 그룹 선택

- [x] 새 공간 만들기 → `familyRepository.create()` API 연동 → 초대코드 발급
- [x] 초대코드로 참여 → `familyRepository.joinFamily(inviteCode:)` API 연동
- [x] `GroupSelectFeature` delegate 패턴으로 `RootFeature`에서 API 처리
- [x] `isLoading`, `errorMessage` 상태 관리

---

### iOS — Home 화면

- [x] **하트 버튼** → 팝오버 형식 변경 (`HeartCalloutView`) — 재촉하기/질문다시받기/나만의질문 비용 표시
- [x] **몽글 캐릭터 동적화** — `familyMembers` + `memberAnswerStatus` 기반으로 실제 멤버 표시
- [x] **hasAnsweredToday 실제 API** — `answerRepository.getByDailyQuestion()` → `memberAnswerStatus` 딕셔너리 생성
- [x] `MongleSceneView` — `members: [(name, color, hasAnswered)]` 파라미터 추가 (정적 하드코딩 제거)

---

### iOS — History 화면

- [x] `HistoryFeature.State` — `familyId: UUID?`, `familyMembers: [User]` 추가
- [x] `dailyQuestionRepository.getHistoryByFamily()` → `answerRepository.getByDailyQuestion()` → `questionRepository.getByOrder()` 실제 API 연동
- [x] 멤버 이름 → `familyMembers` 배열로 `answer.userId` 매핑
- [x] 캐시 적용 — `historyItems.isEmpty` guard로 이미 로드한 데이터 재요청 방지
- [x] `familyId` nil일 경우 mock 데이터 fallback
- [x] `AppError` 통합 에러 시스템 적용 + `MongleErrorBanner` 연결

---

### iOS — 프로필 설정

- [x] **프로필 편집 (MongleCardEdit)** — `userRepository.update()` 실제 API 연동 (저장 완료)
  - ⚠️ `ProfileEditFeature.onAppear` 사용자 초기 로딩은 여전히 Task.sleep mock (`state.user == nil`일 때만 타는 분기, RootFeature에서 주입 시 무관)
- [x] **알림 설정** — UserDefaults로 각 알림 항목 개별 관리 (`notification.r1` ~ `r6`)
- [x] **그룹 관리**
  - [x] 그룹 나가기 → 확인 alert → `familyRepository.removeMember(userId:familyId:)` API 연동
  - [x] 초대코드 복사 → `UIPasteboard.general.string` 클립보드 저장
  - [x] `SupportScreenFeature` — `familyId`, `currentUserId` 상태 추가 (ProfileEditFeature에서 주입)
- [x] **계정 관리**
  - [x] 로그아웃 → `authRepository.logout()` → 토큰 삭제 → 로그인 화면 이동
  - [x] 계정탈퇴 → 확인 팝업 → `authRepository.deleteAccount()` → 로그인 화면 이동
  - [x] `@Dependency(\.authRepository)` 실제 의존성 주입

---

## 🔲 남은 작업

### iOS — 우선순위 높음

#### Home 화면

- [x] **질문 답변 제출** — `QuestionDetailFeature` 실제 API 연동 완료
  - `answerRepository.create()` / `answerRepository.update()` 연동
  - 제출 후 `hasAnsweredToday = true`, `memberAnswerStatus[currentUser.id] = true` 반영
  - `familyMembers` 전달 → 가족 답변 이름 매핑
- [x] **답변 수정하기** — 이미 답변한 경우 버튼 "수정하기"로 표시, `answerRepository.update()` 연동 완료
- [x] **나만의 질문 작성하기**
  - 서버: `POST /questions/custom` (하트 3개 차감, 하루 1회 제한, Question.isCustom 플래그)
  - iOS: `WriteQuestionFeature` 실제 API 연동, 성공 시 todayQuestion/hearts/memberAnswerStatus 업데이트
- [x] **질문 다시 받기**
  - 서버: `POST /questions/skip`에 하트 차감(-1) + 잔액 부족 시 에러 추가
  - iOS: `HeartCostPopup` 확인 → `questionRepository.skipTodayQuestion()` 실제 호출
  - iOS: 성공 시 `todayQuestion` 교체, `hearts` -1, `memberAnswerStatus` 초기화
  - 그룹 내 하루 1회 제한 서버에서 처리 (`isSkipped` 체크)
- [x] **재촉하기 (Nudge)**
  - 서버: `POST /nudge` (하트 1개 차감, 같은 가족 구성원 확인)
  - iOS: `PeerNudgeFeature` 실제 API 연동, 성공 시 hearts 업데이트
  - ⚠️ 푸시 알림 전송은 APNs/FCM 인프라 구축 후 별도 구현 필요

#### 프로필 설정

- [x] **그룹 관리 — 방장 멤버 내보내기**
  - `isCurrentUserOwner` 기반 내보내기 버튼 표시 (방장만 보임)
  - `familyRepository.kickMember(memberId:)` → `DELETE /families/members/{memberId}` 연동
  - `familyCreatedById` ProfileEditFeature → RootFeature에서 주입
- [x] **기분 히스토리 실제 데이터 연동**
  - 서버: `POST /moods` (upsert), `GET /moods?days=N` 엔드포인트 추가 (MoodRecord 모델)
  - iOS: `MoodRepositoryProtocol` + `MoodRepository` + `MoodEndpoint` + TCA dependency 등록
  - `SupportScreenFeature.onAppear` → `moodRepository.getRecentMoods(days: 14)` 실제 호출
  - `Domain.MoodRecord` 도입, mood ID(영문) ↔ 한국어 레이블 변환은 View에서 처리

#### 알림 화면

- [x] `NotificationFeature` 실제 API 연동
  - 서버: `Notification` Prisma 모델 추가, `GET /notifications`, `PATCH /notifications/:id/read`, `PATCH /notifications/read-all` 구현
  - iOS: `NotificationRepositoryProtocol` + `NotificationRepository` + `NotificationEndpoint` + TCA dependency 등록
  - `NotificationFeature.onAppear`/`refresh` → 실제 API, `markAsRead`/`markAllAsRead` → 낙관적 업데이트 + 서버 동기화

---

### iOS — 우선순위 중간

#### 에러 처리 시스템 나머지 Feature 적용

AppError 시스템 모든 Feature 적용 완료:

- [x] `HomeFeature` — `appError: AppError?` 추가, `MongleErrorBanner` 연결
- [x] `LoginFeature` — `appError: AppError?` 추가, `setAppError` 연동
- [x] `GroupSelectFeature` — `appError: AppError?` 추가
- [x] `QuestionDetailFeature` — `appError: AppError?` 추가
- [x] `AccountManagementFeature` — `appError: AppError?` 추가
- [x] `ProfileEditFeature` — `appError: AppError?` 추가
- [x] **`Root+Reducer`** — `loadDataResponse(.failure)` 시 AppError 변환, `.unauthorized` → 자동 로그인 화면 이동

#### Home 화면 — 둘러보기 게스트 제한

- [x] 탭바 제외 버튼 터치 시 로그인 요청 팝업 → 로그인 버튼 / 취소
  - `HomeFeature.State.isGuest` (currentUser == nil 기반) + `showGuestLoginPrompt`
  - 제한 대상: `questionTapped`, `heartsTapped`, `answerRequiredTapped`, `peerNudgeTapped`
  - 로그인 버튼 → `delegate(.requestLogin)` → MainTab → Root → 로그인 화면 이동

---

### iOS — 우선순위 낮음

- [x] **스트릭(Streak) 표시** — 연속 답변 일수 계산 로직 및 서버 연동
  - 서버: `GET /users/me/streak` — Answer 기록 기반 연속 답변 일수 계산 (오늘/어제부터 역산)
  - iOS: `UserRepositoryInterface.getMyStreak()`, `UserEndpoint.getMyStreak`
  - `HomeFeature.State.streakDays` 추가, `RootData.streakDays` 포함, `HomeTopBarState`에 실제 값 전달
- [x] **하트 잔액 실시간 반영** — `User.hearts` 도메인 모델 추가, UserDTO/UserMapper 반영, Root+Reducer에서 `currentUser.hearts`로 초기화
- [x] **푸시 알림 권한 요청** — 최초 로그인 후 `.authenticated` 상태 진입 시 1회 요청
  - `UserDefaults("mongle.didRequestPushPermission")` 으로 중복 요청 방지
  - `UNUserNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound])`
- [x] **토큰 자동 갱신 (Token Refresh)** — 완료
  - 서버: `jwt.ts` access 1h / refresh 30d, `POST /auth/refresh` 엔드포인트 추가
  - iOS: `APIClient` 401 → `attemptTokenRefresh()` → 재시도, `TokenRefreshCoordinator` actor로 동시 갱신 방지

---

### Android — 남은 작업

- [ ] Home 화면 (그룹명, 오늘의 질문, 몽글 캐릭터, 가족 멤버 연동)
- [ ] History 화면 (기록 목록 API 연동)
- [ ] Profile 화면 (프로필 편집, 그룹 관리, 계정 관리)
- [ ] 알림 화면
- [ ] 전체 UI iOS 디자인과 일치시키기

---

### 서버 확인 필요 사항

- [x] **History N+1 문제 해결**
  - 서버: `GET /questions` 응답에 `answers: HistoryAnswerSummary[]` 포함, 단일 Prisma 쿼리로 최적화
  - iOS: `HistoryFeature`가 `questionRepository.getHistory(page:limit:)` 단일 호출로 전환 (120+ 요청 → 1 요청)
  - iOS: `DailyQuestionHistoryResponse`, `HistoryQuestion` 도메인 모델 추가
- [x] `HomeFeature.familyAnswerCount` 실제 연결 — `Question` 도메인에 필드 추가, `Root+Reducer` 초기화 시 반영
- [x] 기분(Mood) 기록 API — `POST /moods` (upsert), `GET /moods?days=N` 완료
- [x] 나만의 질문 등록 API — `POST /questions/custom`, 하트 -3, isCustom 플래그, 하루 1회 제한 완료
- [x] 질문 다시 받기 API — `POST /questions/skip` 하트 차감 포함 완료
- [x] 재촉하기 API — `POST /nudge` 하트 차감 완료 (푸시 알림은 APNs/FCM 인프라 필요)
- [x] 알림 목록 / 읽음 처리 API 엔드포인트 — 완료
- [x] Token refresh 엔드포인트 (`POST /auth/refresh`) — 구현 완료 (stateless JWT rotation)

---

## 에러 처리 시스템 사용법

새로운 Feature에 통합 에러 처리 적용하는 패턴:

```swift
// 1. Feature에 의존성 주입
@Dependency(\.errorHandler) var errorHandler

// 2. State에 appError 추가
public var appError: AppError?

// 3. Action에 setAppError 추가
case setAppError(AppError?)

// 4. catch 블록에서 사용
} catch {
    await send(.setAppError(errorHandler(error, context: "FeatureName.action")))
}

// 5. Reducer에서 처리
case .setAppError(let error):
    state.appError = error
    state.isLoading = false
    // 로그인 필요 시 자동 처리
    if error?.requiresLogin == true {
        return .send(.delegate(.requestLogin))
    }
    return .none

// 6. View에서 배너 표시
.mongleErrorBanner(
    error: store.appError,
    onDismiss: { store.send(.setAppError(nil)) },
    onRetry: store.appError?.isRetryable == true ? { store.send(.refresh) } : nil
)
```
