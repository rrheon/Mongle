# 작업 보고서 — 공통 컴포넌트 정리 (2026-03-26)

## 작업 내용

### 1. `monggleForMood` 공통 View 추출

**문제:** moodId → MongleMonggle 색상 매핑 switch-case가 여러 화면에 중복 존재
- `MongleCardEditView.swift` — `private var monggleForMood: some View`
- `MongleMoodSelector` (Components.swift) — `private func monggle(for:size:)`
- `ProfileEditView.swift` — `private var monggleColorForMood: Color`

**해결:** `MongleMonggle` extension에 `forMood(_:size:)` 정적 팩토리 메서드 추가

```swift
// Components.swift — MongleMonggle extension에 추가
static func forMood(_ moodId: String?, size: CGFloat = 56) -> MongleMonggle {
    switch moodId {
    case "happy":  return MongleMonggle(color: MongleColor.monggleYellow, size: size)
    case "calm":   return MongleMonggle(color: MongleColor.monggleGreen, size: size)
    case "loved":  return MongleMonggle(color: MongleColor.mongglePink, size: size)
    case "sad":    return MongleMonggle(color: MongleColor.monggleBlue, size: size)
    case "tired":  return MongleMonggle(color: MongleColor.monggleOrange, size: size)
    default:       return MongleMonggle(color: MongleColor.mongglePink, size: size)
    }
}
```

**변경 파일:**

| 파일 | 변경 내용 |
|------|-----------|
| `Design/Components.swift` | `forMood(_:size:)` 추가; `MongleMoodSelector` 내 private 함수 제거 후 호출 교체 |
| `Profile/MongleCardEditView.swift` | `monggleForMood` computed var 제거 → `MongleMonggle.forMood(store.selectedMoodId, size: 80)` |
| `Profile/ProfileEditView.swift` | `monggleColorForMood: Color` 제거 → `MongleMonggle.forMood(store.user?.moodId)` |

---

### 2. 뒤로가기 버튼 UI 통일 (알림설정, 그룹관리 화면)

**문제:** `SupportScreenView`의 toolbar 뒤로가기 버튼에 `.contentShape(Rectangle())`이 없어 탭 영역이 좁았음. 프로필 편집 화면(`MongleCardEditView`)의 뒤로가기 버튼과 UI 불일치.

**해결:** `SupportScreenView.swift` toolbar 버튼 label에 `.contentShape(Rectangle())` 추가

```swift
// 변경 전
.frame(width: 44, height: 44)

// 변경 후
.frame(width: 44, height: 44)
.contentShape(Rectangle())
```

**변경 파일:** `Support/SupportScreenView.swift` (toolbar leading 버튼)
**영향 화면:** 알림설정 화면, 그룹관리 화면, 하트 시스템, 기록 캘린더, 기분 히스토리 등 SupportScreenView를 공유하는 모든 화면
