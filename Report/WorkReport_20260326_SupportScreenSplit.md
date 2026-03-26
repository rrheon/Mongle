# SupportScreenView 화면 분리 작업 보고서

## 작업일: 2026-03-26

---

## 확인 결과

Work.md에서 요청한 4개 화면의 존재 여부:

| 화면 | SupportScreenView 내 존재 여부 |
|------|-------------------------------|
| 프로필편집 | ✗ 없음 |
| 알림설정 (notificationSettings) | ✓ 존재 |
| 그룹관리 (groupManagement) | ✓ 존재 |
| 계정관리 | ✗ 없음 |

추가로 아래 화면도 동일 파일 내에 존재하였음:
- heartsSystem (하트 시스템)
- historyCalendar (히스토리 달력)
- moodHistory (기분 히스토리)

---

## 분리 작업 내용

기존 `SupportScreenView.swift` 1개 파일(약 953줄)을 7개 파일로 분리:

### 분리된 파일 목록

| 파일명 | 담당 화면 / 역할 |
|--------|----------------|
| `SupportScreenView.swift` | 라우터 (switch 분기, alert, sheet, navigation) |
| `SupportScreenView+HeartsSystem.swift` | 하트 시스템 화면 |
| `SupportScreenView+HistoryCalendar.swift` | 히스토리 달력 화면 |
| `SupportScreenView+NotificationSettings.swift` | 알림 설정 화면 |
| `SupportScreenView+GroupManagement.swift` | 그룹 관리 화면 + 방장 위임 시트 |
| `SupportScreenView+MoodHistory.swift` | 기분 히스토리 화면 |
| `SupportScreenView+Shared.swift` | 공통 헬퍼 (sectionTitle, infoStrip, invitePill, monggleColor, moodName, colorForMoodID, monggleColorForLabel) |

### 아키텍처 방식
- Swift Extension 분리 방식 사용 (SupportScreenView의 extension을 파일별로 분산)
- SupportScreenFeature (TCA Reducer)는 변경 없음
- 공용 헬퍼는 `+Shared` 파일에 internal 접근 수준으로 분리하여 모든 extension에서 공유

---

## 미구현 항목

- **프로필편집 화면**: SupportScreenView에 없음. 별도 구현 필요
- **계정관리 화면**: SupportScreenView에 없음. 별도 구현 필요

두 화면은 SupportScreenFeature의 `Screen` enum에도 포함되어 있지 않음.
향후 추가 시 Feature와 View 모두 작업이 필요함.
