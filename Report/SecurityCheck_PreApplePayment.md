# iOS 알림·Apple 로그인·보안 점검 결과

> 점검일: 2026-04-07
> 대상: Apple Developer 결제 직전, iOS 앱 등록/빌드 준비
> 범위: `/Users/yong/Desktop/FamTree` (iOS), `/Users/yong/Desktop/MongleServer` (서버)

---

## 🔴 치명적 (결제 후 빌드/심사 전 반드시 수정)

### 1. Push Notifications Capability/Entitlement 누락
- 파일: `Mongle/Mongle.entitlements:1-5` — `<dict/>` 빈 상태
- 알림 코드(`Mongle/MongleApp.swift:22`, `MongleFeatures/Sources/MongleFeatures/Presentation/Root/Ext/Root+Reducer.swift:214` 등)가 `registerForRemoteNotifications()`를 호출하지만, `aps-environment` entitlement 없으면 **APNs 토큰이 절대 발급되지 않음** (실기기/시뮬레이터 공통)
- 조치: Xcode → Target → Signing & Capabilities → **+ Push Notifications** 추가
  - entitlements에 `aps-environment=development` 자동 주입됨

### 2. Sign in with Apple Capability 누락
- 파일: `MongleFeatures/Sources/MongleFeatures/Presentation/Login/SocialLoginProvider.swift:36-` Apple 로그인 구현은 완성되어 있음
- entitlement에 `com.apple.developer.applesignin`이 없어 **ASAuthorization 호출 시 1000 에러로 즉시 실패**
- 조치: Xcode Capability에서 **+ Sign in with Apple** 추가

### 3. ATT (App Tracking Transparency) 문구 누락
- 파일: `Mongle/Info.plist` — `NSUserTrackingUsageDescription` 키 없음
- `MongleApp.swift:67` `GADMobileAds.sharedInstance().start()` 로 AdMob 사용 중 → IDFA 접근 시 필수
- 누락 시 **심사 리젝트**
- 조치: Info.plist에 추가
  ```xml
  <key>NSUserTrackingUsageDescription</key>
  <string>맞춤형 광고 제공을 위해 사용됩니다.</string>
  ```

---

## 🟠 보안 (코드 작업 필요)

### 4. Apple Sign-In nonce 없음
- 파일: `MongleFeatures/Sources/MongleFeatures/Presentation/Login/SocialLoginProvider.swift:46`
  ```swift
  request.requestedScopes = [.fullName, .email]
  // request.nonce 설정 없음
  ```
- 서버(`MongleServer/src/services/AuthService.ts:10-22`)도 nonce 클레임 검증 없음
- **replay 공격 방지**를 위해 클라이언트에서 `sha256(rawNonce)`를 request에 설정하고 서버에서 ID 토큰의 `nonce` 클레임과 비교해야 함
- `MongleServer/SECURITY_TODO.md:152`에도 동일 항목 기재됨

### 5. credentials.plist / Secrets.swift 평문 저장 — OK
- `credentials.plist`(Google client_id, bundle_id), `Secrets.swift`(Kakao native key, Google client id) 평문
- `.gitignore`에 등록되어 있고 `git ls-files`로 추적 안 됨 확인 완료 (`Secrets.swift.example`만 추적)
- IPA에서 `strings` 추출은 가능하지만 **서버 측 audience(bundle id) 검증이 되어 있으므로 방어됨**
  - Apple: `AuthService.ts:19`
  - Kakao: `AuthService.ts:52`
  - Google: `AuthService.ts:71-75`
- 별도 조치 불필요

### 6. Keychain 토큰 저장 — 양호하나 서비스명 통일 필요
- `MongleData/Sources/MongleData/DataSources/Local/AuthLocalDataSource.swift:15` service: `app.monggle.mongle`
- `MongleData/Sources/MongleData/DataSources/Remote/API/APIClient.swift:60` 별도 `KeychainTokenStorage` 구현 (서비스명 확인 필요)
- access 레벨 `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` 적절
- `SECURITY_TODO.md:154` Phase 2 작업 항목에 포함됨

### 7. 딥링크 페이로드 검증 약함
- `Mongle/MongleApp.swift:73-79` — host로만 분기 (`mongle.app`, `monggle.app`, `monggle://`)
- 초대 코드 payload에 화이트리스트/포맷 검증 추가 권장 (정규식으로 invite code 형식 강제)

### 8. Bundle ID 불일치 리스크
- `credentials.plist:13`: `com.yongheon.Mongle`
- Keychain 서비스명: `app.monggle.mongle`
- URL scheme: `monggle`
- **Apple Developer App ID 등록 전 Bundle ID를 하나로 확정해야 함**
- 결정된 Bundle ID가 다음과 모두 일치해야 함:
  - APNs Auth Key 의 App ID
  - Sign in with Apple Service ID
  - Kakao iOS 플랫폼 Bundle ID
  - Google OAuth iOS 클라이언트 Bundle ID

---

## ✅ 양호한 항목

### 알림 파이프라인 (iOS)
- `MongleApp.swift:22-51` AppDelegate가 device token 수신 → `Root+Reducer.swift:475-479` `userRepository.registerDeviceToken`로 서버 전송
- 포그라운드 표시(banner/sound/badge), 탭 라우팅(`ANSWER_REQUEST`/`MEMBER_ANSWERED`/`NEW_QUESTION`) 처리됨
- 권한 요청 1회만 시도 (`Root+Reducer.swift:206-216` — `mongle.didRequestPushPermission` 플래그)

### 알림 파이프라인 (서버)
- `MongleServer/src/services/PushNotificationService.ts` 토큰 기반 APNs (`.p8` + JWT ES256)
- `NODE_ENV`로 sandbox/prod 분기 (`api.push.apple.com` ↔ `api.sandbox.push.apple.com`)
- 참고: 매 요청마다 `http2.connect`를 새로 여는 구조 — 트래픽 증가 시 connection pool 도입 검토

### 서버 소셜 로그인 검증
- `AuthService.ts`에서 Apple/Kakao/Google 전부 JWKS로 서명 검증 + issuer/audience 검증 정상
- Google 다중 client ID 지원 (`GOOGLE_CLIENT_IDS` 배열)
- Kakao id_token 우선, access_token fallback

### API 클라이언트
- `APIClient.swift` 401 발생 시 refresh token 갱신 재시도 (actor로 동시 갱신 직렬화)
- refresh 요청 시 만료 토큰 미첨부 (`APIClient.swift:214`) — 베스트 프랙티스 준수

---

## 📋 결제 직후 체크리스트

### Apple Developer Console
- [ ] **Bundle ID 확정** 후 App ID 등록
  - Capabilities 활성화: **Push Notifications**, **Sign in with Apple**
- [ ] **APNs Auth Key (.p8)** 생성
  - Key ID, Team ID 메모 → 서버 `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_PRIVATE_KEY` 환경변수 주입
- [ ] **Sign in with Apple** Service ID 구성 (Bundle ID와 페어링)
- [ ] (선택) Associated Domains — `mongle.app` universal link 사용 시

### Xcode Target 설정
- [ ] Signing & Capabilities → **Push Notifications** 추가
- [ ] Signing & Capabilities → **Sign in with Apple** 추가
- [ ] Bundle Identifier를 확정된 값으로 변경
- [ ] Automatically manage signing (개발팀 선택)

### Info.plist 보강
- [ ] `NSUserTrackingUsageDescription` 추가 (AdMob IDFA 용)
- [ ] 알림 자체는 시스템 다이얼로그 — 추가 key 불필요

### 코드 작업
- [ ] Apple Sign-In **nonce 추가** (클라이언트 + 서버)
- [ ] 딥링크 invite code 포맷 검증 강화
- [ ] Keychain 서비스명 통일 (`AuthLocalDataSource` ↔ `KeychainTokenStorage`)

### 서버 (`MongleServer/SECURITY_TODO.md` Phase 0)
- [ ] RDS 비밀번호 회전
- [ ] JWT 시크릿 회전
- [ ] Firebase 키 회전
- [ ] Apple `.pem` 회전 (새 APNs Auth Key 발급 시 자동)
- [ ] AWS Secrets Manager 도입

### App Store Connect 등록 시
- [ ] SKU: 별도 섹션 참조
- [ ] 개인정보 처리방침 URL (AdMob 사용 시 필수)
- [ ] ATT 사용 여부 체크 (Data Types에서 선언)
- [ ] 연령 등급 설문
- [ ] 스크린샷 (6.7", 6.5", 5.5" 각 세트)

---

## 우선순위

1. (1) + (2) entitlements 활성화 — 5분
2. (8) Bundle ID 확정
3. (3) ATT 문구 추가
4. (4) Apple Sign-In nonce 구현
5. (6) Keychain 서비스명 통일
6. (7) 딥링크 검증 강화


STEP 1: App ID 등록
                     
  Bundle ID 정해지면 아래 순서대로 진행:
                                                                                                              
  1. https://developer.apple.com/account 접속 → 로그인                                                        
  2. 좌측 메뉴 Certificates, Identifiers & Profiles 클릭                                                      
  3. Identifiers 탭 → 우상단 + 버튼                                                                           
  4. App IDs 선택 → Continue                                                                                  
  5. App 선택 → Continue                                                                                      
  6. 입력:                                                                                                    
    - Description: Monggle iOS App (자유, 나중에 변경 가능)                                                   
    - Bundle ID: Explicit 선택 후 STEP 0에서 정한 값 입력                                                     
  7. Capabilities 섹션에서 체크:                                                                              
    - ☑ Push Notifications                                                                                    
    - ☑ Sign in with Apple → 옆의 Edit 클릭 → "Enable as a primary App ID" 선택                               
    - ☑ Associated Domains (Universal Link 쓸 거면)                                                           
  8. Continue → Register                                                                                      
                                                                                                              
  ---                                                                                                         
  STEP 2: APNs Auth Key (.p8) 생성                                                                            
                                                                  
  ▎ ⚠️  .p8 파일은 한 번만 다운로드 가능합니다. 반드시 안전한 곳에 보관하세요.
                                                                                                              
  1. 같은 페이지에서 좌측 Keys 탭 클릭                                                                        
  2. 우상단 + 버튼                                                                                            
  3. 입력:                                                                                                    
    - Key Name: Monggle APNs Key                                                                              
    - ☑ Apple Push Notifications service (APNs) 체크
  4. Continue → Register                                                                                      
  5. Download 클릭 → AuthKey_XXXXXXXXXX.p8 파일 다운로드                                                      
  6. 이 페이지에 표시되는 정보 메모 (다시 볼 수 없음):                                                        
    - Key ID: XXXXXXXXXX (10자리)                                                                             
    - Team ID: 우상단 계정 메뉴에서 확인 (10자리)                                                             
                                                                                                              
  메모해야 할 값 3개:                                                                                         
  APNS_KEY_ID=XXXXXXXXXX                                                                                      
  APNS_TEAM_ID=YYYYYYYYYY                                                                                     
  APNS_PRIVATE_KEY=(.p8 파일 내용)                                                                            
                                  
  → 서버 환경변수(MongleServer/.env 또는 AWS Secrets Manager)에 나중에 주입합니다.                            
                                                                                                              
  ---                                                                                                         
  STEP 3: Sign in with Apple — Service ID 필요 여부 확인                                                      
                                                                                                              
  iOS 앱에서만 Apple 로그인 쓰는 경우 → Service ID 불필요. STEP 1에서 App ID에 Sign in with Apple capability를
   enable한 것만으로 충분합니다.                                                                              
                                                                  
  Service ID가 필요한 경우:                                                                                   
  - 웹에서 Apple 로그인 쓸 때 (https://monggle.app/auth/apple 같은 콜백)
  - Android에서 Apple 로그인 쓸 때 (Android는 네이티브 Apple Sign-In이 없어서 웹 플로우 사용)                 
                                                                                             
  Android에서 Apple 로그인도 지원할 건가요? 아니라면 이 스텝 스킵해도 됩니다.                                 
                                                                                                              
  ---                                                                                                         
  STEP 4: Associated Domains (Universal Link)                                                                 
                                                                                                              
  도메인이 monggle.app을 가지고 계시는지 먼저 확인할게요. Associated Domains는 서버에 
  apple-app-site-association 파일을 올려야 동작합니다.                                                        
                                                                  
  - https://monggle.app/.well-known/apple-app-site-association 에 JSON 파일이 이미 있나요?                    
  - 아니면 지금 만들 건가요?                                      
                                                                                                              
  이것도 답변에 따라 진행 여부 정하면 됩니다.     
