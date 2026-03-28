# SupportScreen → 개별 화면 분리 리팩터링 보고서

## 작업일: 2026-03-26

---

## 작업 내용

이전 작업에서 extension으로 분리한 SupportScreenView를
**ProfileEditView 패턴**에 맞게 각 화면을 독립적인 Feature + View로 완전 분리하였음.

---

## 변경 전 구조

```
Support/
  SupportScreenFeature.swift   ← 5개 화면 로직이 한 reducer에 혼재
  SupportScreenView.swift      ← switch로 화면 분기
  SupportScreenView+*.swift    ← extension 방식으로 임시 분리 (이전 작업)
```

ProfileEditFeature → `@Presents var supportScreen: SupportScreenFeature.State?` 하나로 모든 화면 진입

---

## 변경 후 구조

```
Support/
  NotificationSettingsFeature.swift + NotificationSettingsView.swift
  GroupManagementFeature.swift      + GroupManagementView.swift
  MoodHistoryFeature.swift          + MoodHistoryView.swift
  HeartsSystemFeature.swift         + HeartsSystemView.swift
  HistoryCalendarFeature.swift      + HistoryCalendarView.swift
```

ProfileEditFeature → 화면별 독립 `@Presents`:
```swift
@Presents public var notificationSettings: NotificationSettingsFeature.State?
@Presents public var groupManagement: GroupManagementFeature.State?
@Presents public var moodHistory: MoodHistoryFeature.State?
```

ProfileEditView → 화면별 독립 `navigationDestination` 3개

---

## 각 Feature 역할

| Feature | State 주요 항목 | Dependency |
|---------|----------------|------------|
| NotificationSettingsFeature | notificationItems, quietHours | 없음 (UserDefaults) |
| GroupManagementFeature | members, inviteCode, kickTargetMember, transferCandidates | familyRepository |
| MoodHistoryFeature | moodRecords, currentMonth | moodRepository |
| HeartsSystemFeature | heartBalance | 없음 |
| HistoryCalendarFeature | moodCalendar, currentMonth, selectedDate | moodRepository |

---

## 추가 변경 사항

- **MainTab+Modal.swift**: dead code였던 `supportScreen` 케이스 제거
  - Modal enum, Action enum, Scope 모두 제거
  - MainTabView에서 실제로 사용된 적 없던 코드

---

## 이전 SupportScreenFeature 삭제 목록

- `SupportScreenFeature.swift`
- `SupportScreenView.swift`
- `SupportScreenView+Shared.swift`
- `SupportScreenView+HeartsSystem.swift`
- `SupportScreenView+NotificationSettings.swift`
- `SupportScreenView+GroupManagement.swift`
- `SupportScreenView+HistoryCalendar.swift`
- `SupportScreenView+MoodHistory.swift`
