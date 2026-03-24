# 작업 결과 보고

## 작업 일자
2026-03-21

---

## 재촉하기 알림 수신 불가 (2차 수정)

### 원인
`NotificationRepository.swift`의 `toDomain()` 메서드에서
`ISO8601DateFormatter()` 기본 설정으로 날짜를 파싱하면
TypeScript `Date.toISOString()`이 반환하는 밀리초 포함 형식
`"2025-03-21T12:00:00.000Z"`를 파싱하지 못해 `nil` 반환.

`compactMap`으로 호출하므로 파싱 실패한 알림이 **무음으로 전부 제거**됨.

- 1차 수정(NotificationService userId 불일치 수정) 이후에는 서버가 정상적으로 알림을 반환하지만, iOS 클라이언트에서 모두 drop → 화면에 표시 안 됨
- `AnswerMapper.swift`는 이미 `.withFractionalSeconds` 옵션을 사용하고 있었으나, NotificationRepository에는 누락됨

### 수정 내용
**파일**: `MongleData/Sources/MongleData/Repositories/NotificationRepository.swift`

```swift
// Before
guard let id = UUID(uuidString: self.id),
      let userId = UUID(uuidString: self.userId),
      let notifType = mapType(type),
      let date = ISO8601DateFormatter().date(from: createdAt)
else { return nil }

// After
let formatter = ISO8601DateFormatter()
formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
guard let id = UUID(uuidString: self.id),
      let userId = UUID(uuidString: self.userId),
      let notifType = mapType(type),
      let date = formatter.date(from: createdAt)
else { return nil }
```

### 빌드 확인
- iOS: `xcodebuild` BUILD SUCCEEDED
