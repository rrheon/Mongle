# 테스트 구현 작업 보고서

**작업일**: 2026-03-24
**작업자**: Claude

---

## 작업 개요

프로젝트 전반의 테스트 부재 문제를 해결하기 위해, 서버(Node.js/Jest)와 iOS(Swift/TCA) 양쪽에 단위 테스트를 설계하고 구현했습니다.

---

## 1. 서버 테스트 (Jest + ts-jest)

### 구현 결과

| 파일 | 테스트 수 | 상태 |
|------|----------|------|
| `utils/__tests__/inviteCode.test.ts` | 7 | ✅ PASS |
| `utils/__tests__/jwt.test.ts` | 7 | ✅ PASS |
| `services/__tests__/AuthService.test.ts` | 3 | ✅ PASS |
| `services/__tests__/NotificationService.test.ts` | 13 | ✅ PASS |
| `services/__tests__/FamilyService.test.ts` | 10 | ✅ PASS |
| `services/__tests__/QuestionService.test.ts` | 21 | ✅ PASS |
| `services/__tests__/AnswerService.test.ts` | 25 | ✅ PASS |
| **합계** | **86** | **전체 통과** |

### 설정 파일
- `jest.config.js` 신규 생성 (ts-jest preset, testEnvironment: node)

### 주요 테스트 항목

**AuthService**: `refreshToken` — 유효/무효 리프레시 토큰, 삭제된 유저 처리

**FamilyService**: 가족 생성 (초대코드 중복, 3그룹 한도), 가족 참여 (유효성 검사), 가족 탈퇴 (방장/일반 멤버 분기)

**QuestionService**: 오늘의 질문 조회 (기존/신규 배정), 질문 패스 (하트 3개 차감), 나만의 질문 (하트 차감, 중복 방지)

**AnswerService**: 답변 제출/조회/수정/삭제, 첫 답변 시 하트 +1, 중복 제출 방지

**유틸리티**: JWT 서명/검증, 초대코드 생성/검증

### 이슈 및 해결

1. **`NotificationService` prisma mock 방식**: `NotificationService`가 `const prisma = new PrismaClient()`를 모듈 레벨에서 직접 생성하므로, 다른 서비스와 달리 `@prisma/client`를 mock해야 함
2. **`$transaction` 양방향 지원**: 서비스에 따라 콜백형 `async (tx) => ...`과 배열형 `[promise1, promise2]` 두 형태를 모두 사용하므로, mock에서 두 경우 모두 처리
3. **`QuestionService.createCustomQuestion`의 `findUnique` 호출 횟수**: 트랜잭션 후 `toDailyQuestionResponse` 내부에서 추가 `findUnique` 호출이 발생하여 `mockResolvedValueOnce`를 3단계로 설정해야 함
4. **`isValidInviteCode`의 L 허용**: 정규식 `[A-HJ-NP-Z2-9]`에서 J-N 범위에 L이 포함됨. `generateInviteCode`는 L을 생성하지 않지만 `isValidInviteCode`는 허용하는 의도적 차이

---

## 2. iOS 테스트 (XCTest + TCA TestStore)

### 구현 결과

| 파일 | 테스트 수 | 상태 |
|------|----------|------|
| `MongleFeaturesTests/TestHelpers.swift` | - | MockRepository + Factory |
| `MongleFeaturesTests/NotificationFeatureTests.swift` | 13 | ✅ PASS |
| `MongleFeaturesTests/GroupSelectFeatureTests.swift` | 21 | ✅ PASS |
| `DomainTests/DomainTests.swift` | 4개 추가 | ✅ PASS |
| **합계** | **34** | **전체 통과** |

### 설정 변경
- `MongleFeatures/Package.swift`: `MongleFeaturesTests` 테스트 타겟 추가

### 주요 테스트 항목

**NotificationFeatureTests**: onAppear (알림 로드/스킵), refresh, markAsRead (낙관적 업데이트), markAllAsRead, deleteNotification, deleteAll, backTapped→delegate(.close), dismissError, State 계산 프로퍼티(unreadCount, hasUnread), groupedNotifications 날짜/familyId 필터링

**GroupSelectFeatureTests**: onAppear 배지 상태 로드, 액션 시트, Step 전환 (createGroup/joinWithCode), 폼 입력 길이 제한 (그룹명 15자/닉네임 10자), 유효성 검사 에러, 최대 그룹(3개) 제한, 나가기 확인 취소, path push

**DomainTests 추가**: Notification 엔티티 생성, familyId 옵셔널, 동등성, NotificationType 케이스

### 이슈 및 해결

1. **`swift test` UIKit 오류**: KakaoSDK가 UIKit 의존으로 macOS에서 `swift test` 불가. `xcodebuild test -destination 'id=...'`으로 iOS 시뮬레이터 실행
2. **`Action.Delegate`의 CasePathable 부재**: TCA의 `@Reducer`는 `Action` enum에만 CasePathable을 적용하며 중첩 `Delegate` enum에는 미적용. `receive(\.delegate.close)` 대신 `receive(.delegate(.close))` 사용 (Action이 Equatable인 경우) 또는 `receive(\.delegate)` 사용 (Equatable 아닌 경우)
3. **`GroupSelectFeature.Action`이 Equatable 아님**: `Result<[MongleGroup], Error>`가 포함되어 Equatable 불가. key path 기반 `receive(\.case)`와 `store.exhaustivity = .off` 활용
4. **state.errorMessage 직접 설정 불가**: TestStore의 `state`는 read-only. `.setError("...")` 액션 전송으로 초기 상태 설정
5. **`Foundation.Notification` 이름 충돌**: `DomainTests.swift`에서 `Notification(...)` 호출이 `Foundation.Notification`으로 해석됨. `Domain.Notification(...)` 명시적 한정 사용
6. **동일 값 설정 시 "no change occurred"**: `hasUnreadNotifications`가 이미 `false`인데 `false`로 설정하는 블록 제거

---

## 실행 방법

**서버**:
```bash
cd /Users/yong/Desktop/FamTreeServer
npm test
```

**iOS**:
```bash
# Xcode에서 MongleFeatures scheme 선택 후 Cmd+U
# 또는 터미널에서:
cd /Users/yong/Desktop/FamTree/MongleFeatures
xcodebuild test -scheme MongleFeatures -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## 향후 추가 권장 테스트

- **HomeFeature**: `hasUnreadNotifications` 배지 로딩 (RootFeature.refreshHomeData 경로)
- **서버 통합 테스트**: supertest + 실제 DB (테스트용 SQLite/PostgreSQL)
- **Android**: JUnit5 + MockK 기반 ViewModel/UseCase 테스트 (미구현)
