# 작업 보고서 - 그룹 해제 24시간 제한 (2026-03-24)

## 작업 배경

그룹을 반복적으로 생성하고 즉시 해제하는 행위를 방지하기 위해,
그룹 해제(나가기)는 그룹 생성 후 **24시간이 경과한 뒤에만** 가능하도록 제한.

---

## 수정 내용

### 1. 서버: `FamilyService.ts` — `leaveFamily()` 24시간 체크 추가

```typescript
// 그룹 생성 후 24시간 이내에는 해제 불가 (반복 생성/삭제 방지)
const hoursSinceCreation = (Date.now() - family.createdAt.getTime()) / (1000 * 60 * 60);
if (hoursSinceCreation < 24) {
  const hoursLeft = Math.ceil(24 - hoursSinceCreation);
  throw Errors.forbidden(`그룹 생성 후 24시간이 지나야 그룹을 해제할 수 있습니다. (${hoursLeft}시간 후 가능)`);
}
```

- `family.createdAt`은 Prisma 스키마의 `@default(now())` 값
- `Errors.forbidden` (HTTP 403) 반환
- 방장 단독 해제(그룹 삭제)와 일반 멤버 나가기 모두에 적용 (check 위치가 분기 이전)

### 2. iOS: `GroupSelectFeature.swift`

**State 추가:**
```swift
public var showLeaveTooSoonAlert: Bool = false
public var leaveTooSoonMessage: String = ""
```

**Action 추가:**
```swift
case dismissLeaveTooSoonAlert
```

**`leaveGroupTapped` 수정:**
```swift
case .leaveGroupTapped(let group):
    let hoursSinceCreation = Date().timeIntervalSince(group.createdAt) / 3600
    if hoursSinceCreation < 24 {
        let hoursLeft = Int(ceil(24 - hoursSinceCreation))
        state.leaveTooSoonMessage = "그룹 생성 후 24시간이 지나야 해제할 수 있어요.\n\(hoursLeft)시간 후에 다시 시도해 주세요."
        state.showLeaveTooSoonAlert = true
        return .none
    }
    // 기존 방장/일반멤버 분기 처리...
```

### 3. iOS: `GroupSelectView+Select.swift` — 안내 알림 추가

```swift
.alert("그룹 해제 불가", isPresented: Binding(
  get: { store.showLeaveTooSoonAlert },
  set: { if !$0 { store.send(.dismissLeaveTooSoonAlert) } }
)) {
  Button("확인", role: .cancel) { store.send(.dismissLeaveTooSoonAlert) }
} message: {
  Text(store.leaveTooSoonMessage)  // "그룹 생성 후 24시간이 지나야 해제할 수 있어요. N시간 후에 다시 시도해 주세요."
}
```

---

## 수정된 파일

| 파일 | 변경 내용 |
|------|-----------|
| `FamTreeServer/src/services/FamilyService.ts` | `leaveFamily()`에 24시간 체크 |
| `MongleFeatures/.../Group/GroupSelectFeature.swift` | State/Action/Reducer 수정 |
| `MongleFeatures/.../Group/GroupSelectView+Select.swift` | 24시간 미경과 알림 추가 |

---

## 동일 패턴 적용 가능한 다른 기능 (파악)

아래 기능들도 쿨다운 또는 시간 제한을 적용하면 남용 방지 효과를 기대할 수 있습니다.

### 우선순위 높음

| 기능 | 현재 상태 | 제안 제한 | 근거 |
|------|-----------|-----------|------|
| **초대 코드 재발급** | 제한 없음 | 1시간마다 1회 | 코드를 자주 바꾸면 공유 링크가 무효화됨 |
| **그룹 이름 변경** | 제한 없음 | 24시간마다 1회 | 잦은 변경으로 멤버 혼란 방지 |
| **방장 위임 후 재위임** | 제한 없음 | 위임 후 1시간 이내 재위임 불가 | 권한 남용 방지 |

### 우선순위 낮음

| 기능 | 현재 상태 | 제안 제한 | 근거 |
|------|-----------|-----------|------|
| **그룹 생성 쿨다운** | `MAX_GROUPS=3` 제한 | 그룹 해제 후 1시간 이내 신규 생성 불가 | 탈퇴-재가입 루프 방지 |
| **하트 사용 (질문 스킵/교체)** | 제한 없음 (하트 차감만) | 변경 없음 (하트 자체가 제한) | 현재 하트 시스템으로 충분 |
| **닉네임 변경** | 제한 없음 | 7일마다 1회 | 빈번한 닉네임 변경 혼란 방지 |

### 구현 시 참고

- 서버에서 `FamilyMembership.joinedAt` 또는 `Family.createdAt` 등 기존 타임스탬프 활용 가능
- iOS에서는 `MongleGroup.createdAt`, `User.createdAt` 등 도메인 엔티티에 이미 시간 필드 존재
- 클라이언트에서 1차 차단 → 서버에서 2차 검증하는 이중 방어 구조 권장
