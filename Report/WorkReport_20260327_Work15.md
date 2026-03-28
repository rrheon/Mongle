# 카카오 SNS 로그인 500 오류 수정

**날짜**: 2026-03-27
**작업 범위**: iOS (KakaoLoginCredential, SocialLoginProvider), Server (AuthService)

---

## 원인 분석

### 증상
- 카카오 로그인 시 iOS → 서버 요청에서 500 Internal Server Error 발생
- 카카오 OAuth 토큰 발급 및 iOS 측 user/me 호출은 정상 성공

### 원인 1: 서버에서 카카오 REST API 직접 호출
서버(Lambda)가 `https://kapi.kakao.com/v2/user/me`를 호출하는 방식이었음.
Lambda가 VPC(Private Subnet)에 배치된 경우 NAT Gateway 없이는 외부 인터넷 접근 불가.
호출 실패 시 `new Error('Failed to fetch Kakao user info')` → `ApiError`가 아닌 일반 Error → 전역 에러 핸들러에서 500 반환.

### 원인 2: 카카오 API 응답에 `kakao_account` 없음
iOS 로그 확인 결과, 카카오 앱이 profile/email scope 없이 기본 ID만 반환:
```json
{
    "connected_at": "2026-03-16T06:55:15Z",
    "id": 4799026828
}
```
`kakao_account` 필드 없음 → `email`/`name` 모두 `undefined`.
이 자체는 코드에서 fallback 처리가 되어 있어 직접적 500 원인은 아니나 확인 필요.

### 근본 원인
서버가 iOS와 별도로 카카오 REST API를 다시 호출하는 구조 자체가 문제.
Apple/Google 로그인과 다르게 카카오만 REST API 방식을 사용했음.

---

## 수정 내용

### Apple/Google과 동일하게 id_token(OIDC JWT) 검증 방식으로 변경

**iOS**: `KakaoLoginCredential`에 `idToken` 필드 추가, 서버에 전송
**Server**: Kakao JWKS(`https://kauth.kakao.com/.well-known/jwks.json`)로 JWT 검증

---

## 변경 파일

### 1. iOS - `KakaoLoginCredential.swift`
- `idToken: String?` 필드 추가
- `fields`에 `id_token` 포함

### 2. iOS - `SocialLoginProvider.swift`
- `authenticate()`에서 `token.idToken` 전달

### 3. Server - `AuthService.ts`
- `verifyKakaoIdToken()` 함수 추가 (Apple/Google과 동일한 JWKS 방식)
- Kakao 케이스: `id_token` 우선 처리, `access_token` fallback 유지

```typescript
// 추가된 검증 함수
async function verifyKakaoIdToken(idToken: string): Promise<{ sub: string; email?: string }> {
  const client = jwksClient({ jwksUri: 'https://kauth.kakao.com/.well-known/jwks.json' });
  const decoded = jwt.decode(idToken, { complete: true }) as jwt.Jwt | null;
  if (!decoded?.header?.kid) throw new Error('Invalid Kakao identity token');
  const key = await client.getSigningKey(decoded.header.kid as string);
  const payload = jwt.verify(idToken, key.getPublicKey(), { algorithms: ['RS256'] }) as jwt.JwtPayload;
  return { sub: payload.sub as string, email: payload.email as string | undefined };
}
```

---

## 배포 필요 사항

- `dist/` 재빌드 완료
- 서버 재배포 필요: `npx serverless deploy`
- iOS 앱 재빌드 필요

---

## 참고: 카카오 OIDC 정보

- JWKS 엔드포인트: `https://kauth.kakao.com/.well-known/jwks.json`
- `id_token`의 `sub` 클레임 = 카카오 user ID
- `id_token`은 카카오 로그인 기본 scope(`openid`)에서 발급됨 (로그에서 확인: `scope = openid`)
