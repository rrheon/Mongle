# 작업 보고서 - 하트 부족 시 광고 보상 기능 (2026-03-24)

## 작업 배경

하트를 소모하는 행위(질문 넘기기, 직접 질문 작성하기, 재촉하기) 시 하트가 부족할 경우, 광고를 시청하면 해당 기능을 수행할 수 있도록 개선.

---

## 발견한 버그

### HeartCostPopupFeature.State에 실제 하트 수 미전달 (기존 버그)

**파일:** `MainTab+Reducer.swift` (lines 176-181)

기존 코드에서 HeartCostPopup을 표시할 때 실제 보유 하트를 전달하지 않아
항상 기본값 5개로 표시되고 있었음. 결과적으로 `hasEnoughHearts`가 항상 `true`가 되어
"하트가 부족해요" 메시지와 광고 버튼이 절대 표시되지 않는 버그.

```swift
// 기존 (버그): 하트 기본값 5 사용
state.modal = .heartCostPopup(HeartCostPopupFeature.State(costType: .writeQuestion))

// 수정: 실제 보유 하트 전달
state.modal = .heartCostPopup(HeartCostPopupFeature.State(costType: .writeQuestion, hearts: state.home.hearts))
```

---

## 구현 내용

### 1. 서버: 광고 보상 하트 지급 API 추가

**배경:** 기존 광고 시청 후 클라이언트에서 로컬로 하트 +1만 적용했으나,
서버에서도 하트를 실제로 지급하지 않으면 이후 API 호출 시 서버가 하트 부족으로 거부함.

#### `FamTreeServer/src/models/index.ts`

```typescript
export interface AdHeartRewardRequest {
  amount: number;
}

export interface HeartRewardResponse {
  heartsRemaining: number;
}
```

#### `FamTreeServer/src/services/UserService.ts`

```typescript
async grantAdHearts(userId: string, amount: number): Promise<number> {
  if (!Number.isInteger(amount) || amount < 1 || amount > 5) {
    throw Errors.badRequest('하트 지급 수량은 1~5 사이여야 합니다.');
  }
  const user = await prisma.user.findUnique({ where: { userId } });
  if (!user) throw Errors.notFound('사용자');
  if (!user.familyId) throw Errors.badRequest('활성 가족이 없습니다.');

  const updated = await prisma.familyMembership.update({
    where: { userId_familyId: { userId: user.id, familyId: user.familyId } },
    data: { hearts: { increment: amount } },
  });

  return updated.hearts;
}
```

#### `FamTreeServer/src/controllers/UserController.ts`

```typescript
@Post('me/hearts/ad-reward')
@Security('jwt')
@SuccessResponse(200, '성공')
public async grantAdHearts(
  @Request() req: AuthRequest,
  @Body() body: AdHeartRewardRequest
): Promise<HeartRewardResponse> {
  const heartsRemaining = await this.userService.grantAdHearts(req.user.userId, body.amount);
  return { heartsRemaining };
}
```

`routes.ts`는 tsoa 자동 생성 파일이므로 새 엔드포인트가 직접 추가됨.

---

### 2. iOS: Domain & Data Layer

#### `Domain/Sources/Domain/Repositories/UserRepositoryProtocol.swift`

```swift
func grantAdHearts(amount: Int) async throws -> Int
```

#### `MongleData/.../DataSources/Remote/API/APIEndpoint.swift`

```swift
case adHeartReward(amount: Int)
// path: "/users/me/hearts/ad-reward", method: .post
// body: ["amount": amount]
```

#### `MongleData/.../Repositories/UserRepository.swift`

```swift
func grantAdHearts(amount: Int) async throws -> Int {
    struct Response: Decodable { let heartsRemaining: Int }
    let response: Response = try await apiClient.request(UserEndpoint.adHeartReward(amount: amount))
    return response.heartsRemaining
}
```

---

### 3. iOS: HeartCostPopupFeature — CostType에 cost 속성 추가

**파일:** `MongleFeatures/.../Common/HeartCostPopupFeature.swift`

```swift
public enum CostType: Equatable, Sendable {
    case writeQuestion
    case refreshQuestion

    public var cost: Int { 3 }
}
```

`.run` 클로저 내에서 State에 접근할 수 없으므로, CostType에서 직접 cost를 알 수 있도록 추가.

---

### 4. iOS: MainTab+Reducer — 광고 보상 흐름 개선

**파일:** `MongleFeatures/.../MainTab/Ext/MainTab+Reducer.swift`
**파일:** `MongleFeatures/.../MainTab/Ext/MainTab+Action.swift`

#### Action 변경

```swift
// 기존
case adRewardEarned(HeartCostPopupFeature.CostType)

// 변경
case adRewardEarned(HeartCostPopupFeature.CostType, heartsRemaining: Int)
```

#### 광고 시청 흐름

```swift
case .modal(.presented(.heartCostPopup(.delegate(.watchAdRequested(let costType))))):
    state.modal = nil
    let cost = costType.cost
    return .run { [costType, cost] send in
        let earned = await adClient.showRewardedAd()
        guard earned else { return }
        do {
            let heartsRemaining = try await userRepository.grantAdHearts(amount: cost)
            await send(.adRewardEarned(costType, heartsRemaining: heartsRemaining))
        } catch {
            // 서버 지급 실패 시 로컬에서 임시 추가 (fallback)
            await send(.adRewardEarned(costType, heartsRemaining: -1))
        }
    }

case .adRewardEarned(let costType, let heartsRemaining):
    if heartsRemaining >= 0 {
        state.home.hearts = heartsRemaining
    } else {
        state.home.hearts += costType.cost
    }
    switch costType {
    case .writeQuestion:
        state.path.append(.writeQuestion(WriteQuestionFeature.State()))
        return .none
    case .refreshQuestion:
        return .run { [questionRepository] send in ... }
    }
```

---

### 5. iOS: PeerNudgeFeature — 광고 지원 추가

**파일:** `MongleFeatures/.../Peer/PeerNudgeFeature.swift`

```swift
// State 추가
public var isWatchingAd: Bool = false

// Action 추가
case watchAdTapped
case adWatchCompleted(Bool)

// Dependency 추가
@Dependency(\.userRepository) var userRepository
@Dependency(\.adClient) var adClient

// Reducer
case .watchAdTapped:
    guard !state.isWatchingAd, !state.isSent else { return .none }
    state.isWatchingAd = true
    return .run { send in
        let earned = await adClient.showRewardedAd()
        await send(.adWatchCompleted(earned))
    }

case .adWatchCompleted(let earned):
    state.isWatchingAd = false
    guard earned, !state.isSent, !state.isLoading else { return .none }
    state.isLoading = true
    return .run { [nudgeRepository, userRepository] send in
        do {
            _ = try await userRepository.grantAdHearts(amount: 1)
            let heartsRemaining = try await nudgeRepository.sendNudge(targetUserId: targetUserId)
            await send(.nudgeResponse(.success(heartsRemaining)))
        } catch {
            await send(.nudgeResponse(.failure(AppError.from(error))))
        }
    }
```

---

### 6. iOS: PeerNudgeView — 하트 부족 시 광고 버튼 표시

**파일:** `MongleFeatures/.../Peer/PeerNudgeView.swift`

하트가 0이고 아직 전송 전일 때:
- "하트가 부족해요." 메시지 표시
- "광고 보고 재촉하기 💚" 버튼 표시
- 광고 시청 중에는 ProgressView 표시 + 버튼 비활성화

---

## 광고 길이 정책

| 기능 | 하트 비용 | 광고 단위 |
|------|----------|----------|
| 재촉하기 | 1개 | 보상형 광고 (동일 단위) |
| 질문 넘기기 | 3개 | 보상형 광고 (동일 단위) |
| 직접 질문 작성하기 | 3개 | 보상형 광고 (동일 단위) |

현재는 단일 보상형 광고 단위(`ca-app-pub-4718464707406824/2869316545`)를 모든 기능에 사용.
향후 AdMob에서 1하트용 짧은 광고(Rewarded Interstitial)와 3하트용 긴 광고(Rewarded)를
별도 단위로 설정하면 더 세밀한 광고 길이 조정 가능.

---

## 수정된 파일

| 파일 | 변경 내용 |
|------|----------|
| `FamTreeServer/src/models/index.ts` | `AdHeartRewardRequest`, `HeartRewardResponse` 추가 |
| `FamTreeServer/src/services/UserService.ts` | `grantAdHearts()` 메서드 추가 |
| `FamTreeServer/src/controllers/UserController.ts` | `POST /users/me/hearts/ad-reward` 엔드포인트 추가 |
| `FamTreeServer/src/routes/routes.ts` | 새 라우트 자동 등록 |
| `Domain/.../UserRepositoryProtocol.swift` | `grantAdHearts(amount:)` 프로토콜 추가 |
| `MongleData/.../APIEndpoint.swift` | `UserEndpoint.adHeartReward(amount:)` 추가 |
| `MongleData/.../UserRepository.swift` | `grantAdHearts(amount:)` 구현 |
| `MongleFeatures/.../HeartCostPopupFeature.swift` | `CostType.cost` 속성 추가 |
| `MongleFeatures/.../MainTab+Action.swift` | `adRewardEarned` 시그니처 변경 |
| `MongleFeatures/.../MainTab+Reducer.swift` | 버그 수정 + 광고 보상 흐름 개선 |
| `MongleFeatures/.../PeerNudgeFeature.swift` | 광고 시청 액션/상태 추가 |
| `MongleFeatures/.../PeerNudgeView.swift` | 하트 부족 시 광고 버튼 UI 추가 |

---

## Android 현황

Android 프로젝트에는 재촉하기(nudge), 질문 넘기기, 직접 질문 작성하기 UI가 아직 구현되지 않았고
AdMob SDK도 미통합 상태. 해당 기능 UI 구현 시 아래 순서로 진행:

1. `libs.versions.toml`에 Google Mobile Ads SDK 의존성 추가
2. `AndroidManifest.xml`에 AdMob App ID(`ca-app-pub-4718464707406824~8995741193`) 등록
3. 보상형 광고 단위(`ca-app-pub-4718464707406824/9365243021`)로 RewardedAd 구현
4. 각 하트 소모 기능 UI에 하트 부족 시 광고 버튼 추가
