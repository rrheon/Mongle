# Universal Link & Apple Sign-In 다음 단계

> 작성일: 2026-04-07
> 전제: Apple Developer App ID 등록 완료 (`com.yongheon.Mongle`), APNs Auth Key 생성 완료

---

## 0. 이미 완료된 것 (코드 수정 반영)

### A. iOS `Mongle.entitlements` 복원 ✅
빈 `<dict/>` 상태였던 entitlements에 3종 키 추가:
- `aps-environment = development` (Push Notification)
- `com.apple.developer.applesignin = Default` (Sign in with Apple)
- `com.apple.developer.associated-domains = applinks:monggle.app` (Universal Link)

**배포 전**: TestFlight/App Store 빌드 시 `aps-environment`를 `production`으로 바꾸는 것은 Xcode가 Archive 빌드에서 자동으로 처리하지 않으므로, 필요시 Release 스킴에서 별도 파일 사용하거나 Capability UI로 관리.

### B. `AppConfig.inviteLink` URL 수정 ✅
```swift
// Before: "\(apiBaseURL)/invite/\(code)"  ← AWS API Gateway + 잘못된 path
// After:  "https://monggle.app/join/\(code)"  ← AASA + 서버 /join 라우트 일치
```

이제 iOS가 생성하는 초대링크가 Universal Link로 동작할 수 있음 (단, D 완료 후).

---

## 1. 지금 해야 할 것 — 사용자 수동 작업

### C. 서버에 Apple 로그인 콜백 엔드포인트 구현 ⚠️
**이유**: Android Apple 로그인(`SocialLoginHelper.kt:157-170`)이 이미 `${BASE_URL}auth/apple/callback`을 redirect_uri로 쓰고 있는데, 서버에는 해당 라우트가 없음.

**플로우**:
```
Android 앱
  → Custom Tab으로 appleid.apple.com/auth/authorize?...&response_mode=form_post
    → 사용자 Apple 로그인
      → Apple이 POST form_post로 {BASE_URL}/auth/apple/callback 호출
        → 서버: id_token/code/user 수신
          → 서버: monggle://apple-callback?id_token=...&code=...&name=...&email= 로 302 redirect
            → Android 딥링크 처리(AndroidManifest.xml의 monggle://apple-callback)
              → handleAppleCallback(uri) → AuthService socialLogin
```

**필요한 서버 작업** (`MongleServer/src/`):
1. `POST /auth/apple/callback` 라우트 추가 (body에 `id_token`, `code`, `user` JSON string)
2. 응답: 302 redirect to `monggle://apple-callback?id_token=...&code=...&name=...&email=...`
3. `user` 필드는 최초 로그인 시에만 옴 — parse해서 name/email 추출
4. form_post는 POST인데 딥링크 응답이 GET이어야 함 → HTML intermediate page 사용 (auto-submit form 또는 JavaScript location.href)

**주의**: 이 단계에서는 **토큰 검증/DB 저장을 하지 않고** 그대로 앱으로 pass-through. 이유:
- 이미 `AuthService.socialLogin('apple', ...)`이 identity_token을 서버에서 검증함
- Android는 딥링크로 돌아와서 일반 소셜 로그인 API를 호출하므로 경로가 통일됨
- 서버는 Apple 콜백을 **중계만** 하는 역할

### D. `monggle.app` 도메인 배포 ⚠️ **가장 중요**
AASA 파일이 실제로 `https://monggle.app/.well-known/apple-app-site-association`에서 응답하지 않으면 Universal Link는 절대 동작하지 않음.

**확인 필요**:
- [ ] `monggle.app` 도메인 구매 상태?
- [ ] DNS 어디? (Route53? Cloudflare? 가비아?)
- [ ] HTTPS 인증서? (ACM? Let's Encrypt?)

**선택지 (결정 필요)**:
1. **API Gateway Custom Domain** — serverless.yml에 `customDomain` 추가 + ACM 인증서 + Route53 A 레코드
2. **CloudFront 앞에 두기** — S3/Lambda 오리진으로 CDN
3. **별도 정적 호스팅 + API는 서브도메인** — `monggle.app`(Vercel) + `api.monggle.app`(AWS)

**제 추천**: **1번** (API Gateway Custom Domain). 이유:
- 서버 `public/.well-known/` 정적 파일과 `/join/:code` 라우트가 이미 Express로 서빙되므로 API Gateway → Lambda(Express) 플로우 그대로 둘 수 있음
- 추가 인프라 불필요
- AASA와 assetlinks 모두 Lambda에서 응답

**단계**:
```
1. AWS ACM (us-east-1 불필요, ap-northeast-2 OK)에서 monggle.app 인증서 발급
2. Route53 또는 DNS 제공업체에서 ACM 검증 CNAME 추가
3. API Gateway → Custom domain names → 도메인 추가 → 인증서 연결
4. API mapping: monggle.app → 해당 API 스테이지
5. Route53 A 레코드 (Alias to API Gateway)
6. serverless.yml에 customDomain 플러그인 또는 수동 설정
```

### E. Apple Services ID 등록 (Apple Developer Console)
Android가 Apple OAuth URL을 호출할 때 `client_id=com.mongle.app.signin`을 쓰는데(`Mongle-Android/app/build.gradle.kts:27`), 이 Services ID가 Apple Console에 존재하지 않으면 Apple 로그인 화면이 뜨지 않음.

**Apple Developer Console → Identifiers → + → Services IDs**:
```
Description:  Monggle Web Auth (Android)
Identifier:   com.mongle.app.signin    ← Android BuildConfig와 정확히 일치
```

등록 후 해당 Services ID 클릭 → ☑ Sign in with Apple → **Configure**:
```
Primary App ID:           com.yongheon.Mongle  (STEP 1에서 등록한 App ID)
Domains and Subdomains:   monggle.app
Return URLs:              https://monggle.app/auth/apple/callback
```

⚠️ **도메인 검증 필요**: Apple이 `.well-known/apple-developer-domain-association.txt` 파일을 요구함. Apple Console이 생성한 파일을 다운로드 → `MongleServer/public/.well-known/`에 저장 → 배포 → Apple Console에서 "Verify" 클릭.

⚠️ **D 단계 (도메인 배포) 먼저 완료되어야 E의 도메인 검증이 가능함.**

### F. Apple Sign-In Client Secret 생성 (서버용)
Services ID로 Apple 토큰 교환하려면 **client_secret JWT**가 필요. 이건 STEP 2에서 만든 `.p8` 파일로 서명.

**현재 상태**: `MongleServer/Mongle.pem`이 존재 — 기존 키가 있는 듯. STEP 2에서 받은 새 키와 **같은 키**인지 확인 필요.
- 이전 Apple Sign-In용 키가 있었다면 그대로 쓸 수 있음
- 새 APNs Key로 통합하거나 별도 Apple Sign-In 전용 키 만들어도 됨 (Apple은 key의 역할을 Key 생성 시 선택)

**권장**: Apple Sign-In 전용 키를 따로 만들기
- Apple Console → Keys → + → **Sign in with Apple** 선택 → Primary App ID = `com.yongheon.Mongle`
- 발급된 `.p8` → `MongleServer`에 `APPLE_SIGNIN_P8` 환경변수로 주입
- 서버는 런타임에 client_secret JWT 생성

### G. assetlinks.json SHA-256 채우기
Google Play Console 배포 시점에:
- Play Console → 앱 → 설정 → 앱 서명 → "앱 서명 키 인증서 SHA-256" 복사
- `MongleServer/public/.well-known/assetlinks.json:8`에 붙여넣기
- 서버 재배포

(로컬 빌드 SHA-256과는 다르니 주의 — Play App Signing을 쓰면 Google이 관리하는 키 사용)

### H. Team ID 확인
`MongleServer/public/.well-known/apple-app-site-association:6`이 `YQC68LN7U3.com.yongheon.Mongle`로 하드코딩되어 있음. Apple Developer Console → Membership의 **Team ID**와 일치하는지 확인.
- 일치하면 OK
- 다르면 AASA 파일 수정 후 재배포

---

## 2. 우선순위 (실행 순서)

| 순서 | 작업 | 담당 | 블로킹 여부 |
|---|---|---|---|
| 1 | **D**: `monggle.app` 도메인 배포 | 사용자 (AWS/DNS) | Universal Link, Apple Sign-In, AASA 전부 블로킹 |
| 2 | **H**: Team ID 확인 | 사용자 (Apple Console 조회) | 즉시 |
| 3 | **E**: Services ID 등록 | 사용자 (Apple Console) | D 완료 후 도메인 검증 |
| 4 | **C**: 서버 Apple 콜백 라우트 구현 | 코드 작업 | Android Apple 로그인 블로킹 |
| 5 | **F**: Apple Sign-In 키 생성 + 서버 주입 | 사용자 + 환경변수 | C 동작에 필요 |
| 6 | **G**: assetlinks SHA-256 | 사용자 (Play Console) | Android 배포 시점 |

---

## 3. 이번 세션에서 사용자가 답해야 할 것

1. **`monggle.app` 도메인 소유 상태?** (구매했음 / 아직 안 함)
2. **DNS 제공자?** (Route53 / Cloudflare / 가비아 / 기타)
3. **Team ID 확인**: Apple Console Membership 페이지에서 Team ID가 `YQC68LN7U3`인가?
4. **APNs Key와 Apple Sign-In 키를 같은 키로 쓸지, 분리할지?**
5. **Android Apple 로그인 구현을 iOS 출시 전에 할지, 후로 미룰지?**
   - 미루면: 서버 C 작업 + F 작업 생략 가능, iOS 먼저 출시
   - 같이: C + F 작업 진행

---

## 4. 참고: 관련 기존 문서

- `Report/WorkReport_20260324_InviteLinkTest.md` — 초대 링크 문제 분석 및 1차 수정 (일부 복구 필요)
- `Report/SecurityCheck_PreApplePayment.md` — 보안 점검 전체
- `MongleServer/SECURITY_TODO.md` — 서버 시크릿 회전 체크리스트
