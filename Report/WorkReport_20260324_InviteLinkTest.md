# 작업 보고서 - 초대 링크 테스트 (2026-03-24)

## 작업 배경

초대코드로는 그룹 참여가 가능하지만, 링크(`https://monggle.app/join/{code}`)로는 아직 동작하지 않는다는 보고에 따라 전체 딥링크 흐름을 분석하고 수정.

---

## 발견한 문제

### 1. iOS: Associated Domains 미설정 (심각)

**문제:** `.entitlements` 파일이 아예 없었고, Xcode 프로젝트에 Associated Domains 기능이 설정되지 않았음.

Universal Links(`https://monggle.app/join/...`)가 동작하려면 앱에 `com.apple.developer.associated-domains` 엔타이틀먼트가 필요함. 이게 없으면 iOS는 해당 URL을 Universal Link로 인식하지 않고 Safari에서 열려버림.

**수정:**
- `Mongle/Mongle.entitlements` 신규 생성
- `Mongle.xcodeproj/project.pbxproj` Debug/Release 빌드 설정에 `CODE_SIGN_ENTITLEMENTS` 추가

### 2. 서버: `apple-app-site-association` 파일 없음 (심각)

**문제:** iOS Universal Links는 앱이 설치된 후 시스템이 `https://monggle.app/.well-known/apple-app-site-association` 파일을 주기적으로 다운로드해서 어떤 경로를 앱이 처리하는지 검증함. 이 파일이 없으면 iOS가 Universal Link를 인식하지 못하고 Safari로 넘어감.

**수정:**
- `public/.well-known/apple-app-site-association` 생성
  ```json
  {
    "applinks": {
      "apps": [],
      "details": [{
        "appID": "YQC68LN7U3.com.yongheon.Mongle",
        "paths": ["/join/*"]
      }]
    }
  }
  ```
- `src/app.ts`에 `express.static('public')` 미들웨어 추가

### 3. 서버: `assetlinks.json` 파일 없음 (Android App Links 검증 실패)

**문제:** Android는 `android:autoVerify="true"` 인텐트 필터가 있을 때 `https://monggle.app/.well-known/assetlinks.json`에서 서명 인증서를 검증함. 이 파일이 없으면 검증에 실패하고, 링크를 브라우저에서 열거나 앱 선택 다이얼로그를 띄움 (기기/버전마다 다름).

**수정:**
- `public/.well-known/assetlinks.json` 템플릿 생성
  ```json
  [{
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.mongle.android",
      "sha256_cert_fingerprints": ["REPLACE_WITH_RELEASE_SHA256_FINGERPRINT"]
    }
  }]
  ```
- **⚠️ 추가 작업 필요**: 릴리스 서명 인증서의 SHA-256 지문을 채워야 함
  - 키스토어에서 추출: `keytool -list -v -keystore release.keystore -alias [key-alias]`
  - 또는 Google Play Console > 설정 > 앱 무결성 > 앱 서명 키 인증서 SHA-256

### 4. 서버: 초대 링크 랜딩 페이지 없음 (UX 문제)

**문제:** 앱이 설치되지 않은 기기에서 `https://monggle.app/join/ABCDEFGH`를 열면 서버에 해당 경로의 응답이 없어 오류 페이지 또는 빈 페이지가 표시됨.

**수정:**
- `public/join.html` 랜딩 페이지 생성
  - URL에서 초대코드 자동 추출하여 표시
  - "앱에서 열기" 버튼 → `monggle://join/{code}` 커스텀 스킴으로 앱 실행 시도
  - 앱 미설치 시 앱스토어 유도 안내 문구 표시
- `src/app.ts`에 `GET /join/:code` 라우트 추가 → `join.html` 서빙

---

## 코드 로직 검증 결과

### iOS (RootView.swift) — 정상
```swift
// monggle://join/ABCDEFGH → "ABCDEFGH" ✅
if url.scheme == "monggle", url.host == "join" {
    return url.pathComponents.dropFirst().first?.uppercased()
}
// https://monggle.app/join/ABCDEFGH → "ABCDEFGH" ✅
if url.host == "monggle.app", url.pathComponents.count >= 3,
   url.pathComponents[1] == "join" {
    return url.pathComponents[2].uppercased()
}
```

### Android (RootViewModel.kt) — 정상
```kotlin
// monggle://join/ABCDEFGH → "ABCDEFGH" ✅
uri.scheme == "monggle" && uri.host == "join" -> uri.pathSegments.firstOrNull()?.uppercase()
// https://monggle.app/join/ABCDEFGH → "ABCDEFGH" ✅
uri.host == "monggle.app" && uri.pathSegments.size >= 2 &&
    uri.pathSegments[0] == "join" -> uri.pathSegments[1].uppercase()
```

두 플랫폼 모두 코드 로직 자체는 정확하게 구현되어 있었음. 문제는 서버와 앱 설정 누락이었음.

---

## URL 포맷 정리

| 포맷 | 설명 | 동작 조건 |
|------|------|----------|
| `monggle://join/ABCDEFGH` | 커스텀 스킴 | 앱 설치 시 항상 동작 (서버 불필요) |
| `https://monggle.app/join/ABCDEFGH` | 웹 URL (Universal/App Link) | 서버 검증 파일 필요 |

---

## 수정된 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `FamTreeServer/src/app.ts` | `express.static('public')` 추가, `GET /join/:code` 라우트 추가 |
| `FamTreeServer/public/.well-known/apple-app-site-association` | 신규 생성 (iOS Universal Links 검증용) |
| `FamTreeServer/public/.well-known/assetlinks.json` | 신규 생성 (Android App Links 검증용, SHA-256 채워야 함) |
| `FamTreeServer/public/join.html` | 신규 생성 (앱 미설치 시 랜딩 페이지) |
| `Mongle/Mongle.entitlements` | 신규 생성 (Associated Domains: `applinks:monggle.app`) |
| `Mongle.xcodeproj/project.pbxproj` | Debug/Release 빌드 설정에 `CODE_SIGN_ENTITLEMENTS` 추가 |

---

## 배포 전 필수 체크리스트

- [ ] `assetlinks.json`에 릴리스 서명 인증서 SHA-256 지문 입력
- [ ] 서버를 `monggle.app` 도메인에 배포 (HTTPS 필수)
- [ ] iOS 앱 재빌드 (entitlements 변경 사항 적용)
- [ ] Android 앱 재빌드 + 기기에서 App Links 검증 확인 (`adb shell pm verify-app-links --re-verify com.mongle.android`)
- [ ] 실기기에서 `https://monggle.app/join/{code}` 링크 탭하여 앱 정상 실행 확인

---

## 커스텀 스킴 (`monggle://`) 현황

현재도 `monggle://join/{code}` 형태의 커스텀 스킴 링크는 **이미 정상 동작**함:
- iOS: Info.plist에 `monggle` 스킴 등록 ✅
- Android: AndroidManifest.xml에 `monggle://join` 등록 ✅
- 두 플랫폼 모두 코드 추출 및 GroupSelect 자동이동 로직 정상 ✅

단, 카카오톡/메시지 앱 등 일부 링크 프리뷰에서 커스텀 스킴(`monggle://`)은 클릭 가능한 링크로 인식되지 않을 수 있으므로, 웹 URL(`https://`) 방식이 UX 측면에서 더 권장됨.
