# 작업 보고서 - Android iOS 동기화 (2026-03-24)

## 작업 배경

iOS에서 이미 구현된 기능들을 Android에도 맞추는 작업:
- 하트 수 표시 (TopBar)
- 가족 멤버 탭 → 재촉하기 화면
- 재촉하기 기능 (하트 소모, 광고 대체)
- Google AdMob 보상형 광고 통합
- `hearts`, `moodId` 필드 도메인 모델 반영

---

## 구현 내용

### 1. 도메인/데이터 레이어 정리

#### `domain/model/User.kt`
- `hearts: Int = 0` 필드 추가
- `moodId: String? = null` 필드 추가

#### `data/remote/MongleApiService.kt`
- `ApiUserResponse`에 `moodId: String? = null` 추가
- 이미 추가되어 있던 `NudgeResponse`, `AdHeartRewardRequest`, `AdHeartRewardResponse`, `SkipQuestionResponse` 확인
- `grantAdHearts`, `sendNudge` 엔드포인트 확인

#### `data/remote/ApiUserRepository.kt`
- `toDomain()` 맵퍼에 `hearts = hearts`, `moodId = moodId` 반영
- `grantAdHearts(amount: Int): Int` 메서드 추가

#### `data/remote/ApiFamilyRepository.kt`
- `toDomain()` 맵퍼에 `hearts = hearts`, `moodId = moodId` 반영

#### `data/remote/ApiAuthRepository.kt`
- `toDomain()` 맵퍼에 `hearts = hearts`, `moodId = moodId` 반영

#### `data/remote/ApiQuestionRepository.kt`
- `skipTodayQuestion(): Question` 메서드 추가 (`POST questions/skip`)
- `createCustomQuestion(content: String): Question` 메서드 추가 (`POST questions/custom`)

---

### 2. 재촉하기(Nudge) 기능

#### `domain/repository/NudgeRepository.kt` (신규)
```kotlin
interface NudgeRepository {
    suspend fun sendNudge(targetUserId: String): Int
}
```

#### `data/remote/ApiNudgeRepository.kt` (신규)
- `sendNudge(targetUserId)` → `POST nudge/{targetUserId}` → `heartsRemaining` 반환

#### `di/AppModule.kt`
- `ApiNudgeRepository → NudgeRepository` 바인딩 추가

---

### 3. AdMob 통합

#### `gradle/libs.versions.toml`
- `googleMobileAds = "23.3.0"` 버전 추가
- `google-mobile-ads` 라이브러리 항목 추가

#### `app/build.gradle.kts`
- `implementation(libs.google.mobile.ads)` 추가

#### `AndroidManifest.xml`
- AdMob App ID 메타데이터 추가:
  ```xml
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-4718464707406824~8995741193" />
  ```

#### `util/AdManager.kt` (신규)
- `@Singleton` Hilt 컴포넌트
- `initialize()`: `MobileAds.initialize()` + 보상형 광고 프리로드
- `setActivity(activity)`: 광고 표시를 위한 Activity 참조 설정
- `showRewardedAd(onRewarded, onFailed)`: 보상형 광고 표시, 완료 시 콜백 호출
- 광고 단위: `ca-app-pub-4718464707406824/9365243021`

#### `MongleApplication.kt`
- `AdManager` Inject 추가
- `onCreate`에서 `adManager.initialize()` 호출

#### `MainActivity.kt`
- `AdManager` Inject 추가
- `onCreate`, `onResume`에서 `adManager.setActivity(this)` 호출
- `onDestroy`에서 `adManager.setActivity(null)` 호출
- `MongleNavHost`에 `adManager` 전달

---

### 4. 홈 화면 업데이트

#### `ui/home/HomeViewModel.kt`
- `HomeEvent.NavigateToNudge(targetUser: User)` 이벤트 추가
- `onMemberTapped(member)`: 본인 제외 다른 멤버 탭 시 `NavigateToNudge` 이벤트 발행
- `updateHearts(hearts)`: 하트 수 업데이트 메서드 추가

#### `ui/home/HomeScreen.kt`
- `HomeTopBar`에 `hearts: Int` 파라미터 추가 → 하트 아이콘 + 숫자 표시 (iOS 동일 방식)
- `MongleSceneSection`에 `currentUserId`, `onMemberTapped` 파라미터 추가
- 본인 아닌 멤버 탭 시 `onMemberTapped` 호출
- `onNavigateToNudge` 콜백 파라미터 추가

---

### 5. 재촉하기 화면

#### `ui/nudge/PeerNudgeViewModel.kt` (신규)
**State:**
- `targetUserId`, `targetUserName`: 대상 유저 정보
- `hearts`: 현재 보유 하트
- `isLoading`, `isSent`, `isWatchingAd`: 상태 플래그
- `hasEnoughHearts`: `hearts >= 1` 계산 속성

**Actions:**
- `initialize(targetUserId, targetUserName, hearts)`: 초기화
- `sendNudge()`: 직접 재촉 전송 (하트 1개 소모)
- `watchAdForNudge(adManager)`: 광고 시청 → 서버에 하트 1개 지급 → 재촉 전송
- `dismissError()`: 오류 메시지 해제

#### `ui/nudge/PeerNudgeScreen.kt` (신규)
iOS `PeerNudgeView`와 동일한 UX:
- 대상 멤버 캐릭터 + 이름 표시
- 하트 1개 비용 안내 배지
- **하트 충분**: "재촉하기 💌" 버튼 (MonglePrimary 색상)
- **하트 부족**: "하트가 부족해요." 메시지 + "광고 보고 재촉하기 💚" 버튼
- **광고 시청 중**: ProgressView 표시, 버튼 비활성화
- **전송 완료**: "✅ 재촉 메시지를 보냈어요!" 메시지
- TopBar 우측에 현재 하트 수 표시

---

### 6. 네비게이션 업데이트

#### `ui/navigation/MongleNavHost.kt`
- `showNudgeTarget: User?` 상태 변수 추가
- `PeerNudgeScreen` 화면 분기 추가
- `adManager: AdManager?` 파라미터 추가

#### `ui/main/MainTabScreen.kt`
- `onNavigateToNudge: (User) -> Unit` 파라미터 추가
- `HomeScreen`에 `onNavigateToNudge` 전달

---

## 수정된 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `domain/model/User.kt` | `hearts`, `moodId` 필드 추가 |
| `data/remote/MongleApiService.kt` | `ApiUserResponse.moodId` 추가 |
| `data/remote/ApiUserRepository.kt` | `toDomain()` 업데이트, `grantAdHearts()` 추가 |
| `data/remote/ApiFamilyRepository.kt` | `toDomain()` 업데이트 |
| `data/remote/ApiAuthRepository.kt` | `toDomain()` 업데이트 |
| `data/remote/ApiQuestionRepository.kt` | `skipTodayQuestion()`, `createCustomQuestion()` 추가 |
| `domain/repository/NudgeRepository.kt` | 신규 인터페이스 |
| `data/remote/ApiNudgeRepository.kt` | 신규 구현체 |
| `di/AppModule.kt` | `NudgeRepository` 바인딩 추가 |
| `gradle/libs.versions.toml` | Google Mobile Ads 버전/라이브러리 추가 |
| `app/build.gradle.kts` | `google.mobile.ads` 의존성 추가 |
| `AndroidManifest.xml` | AdMob App ID 메타데이터 추가 |
| `util/AdManager.kt` | 신규 AdMob 유틸리티 |
| `MongleApplication.kt` | AdMob 초기화 추가 |
| `MainActivity.kt` | AdManager Activity 참조 관리 추가 |
| `ui/home/HomeViewModel.kt` | `NavigateToNudge` 이벤트, `onMemberTapped()`, `updateHearts()` 추가 |
| `ui/home/HomeScreen.kt` | TopBar 하트 수 표시, 멤버 탭 지원, nudge 콜백 추가 |
| `ui/nudge/PeerNudgeViewModel.kt` | 신규 ViewModel |
| `ui/nudge/PeerNudgeScreen.kt` | 신규 화면 (iOS PeerNudgeView 대응) |
| `ui/navigation/MongleNavHost.kt` | Nudge 화면 라우팅 추가 |
| `ui/main/MainTabScreen.kt` | `onNavigateToNudge` 콜백 추가 |

---

## 미구현 항목 (다음 작업)

- **질문 넘기기 UI**: `QuestionDetailScreen`에 스킵 옵션 및 하트 비용 다이얼로그 미추가
- **직접 질문 작성하기 UI**: 하트 소모 확인 + 광고 대체 흐름 미추가
- **무드 픽커**: 홈 화면 현재 기분 선택 기능 미구현
- **SkipQuestion 광고 연동**: `ApiQuestionRepository.skipTodayQuestion()`은 구현됐으나 UI 연결 미완
