# 작업 보고서 - MongleNavigationHeader 추가 적용

**날짜:** 2026-03-26

---

## 작업 내용

`NotificationSettingsView`, `GroupManagementView`를 `MongleNavigationHeader` 공통 컴포넌트로 전환.

---

## 수정된 파일 (2개)

### `Support/NotificationSettingsView.swift`
- 기존: `MongleNavigationHeader(title:left:right:)` 플레이스홀더가 잘못 삽입된 상태 + `ScrollView` 단독
- 변경: `VStack(spacing: 0)` 으로 감싸고 `MongleNavigationHeader` + `ScrollView` 구조로 정리
- `.navigationTitle`, `.toolbar`, `.navigationBarBackButtonHidden` 제거
- `.toolbar(.hidden, for: .navigationBar)` 추가

### `Support/GroupManagementView.swift`
- 기존: `ScrollView` 단독 + `.navigationTitle`, `.toolbar`, `.navigationBarBackButtonHidden`
- 변경: `VStack(spacing: 0)` 으로 감싸고 `MongleNavigationHeader` + `ScrollView` 구조
- `.toolbar(.hidden, for: .navigationBar)` 추가
- `alert`, `sheet` 모디파이어는 `VStack` 최상위로 이동

---

## 이슈

- `NotificationSettingsView`에 이전 작업 중 남겨진 `MongleNavigationHeader(title:left:right:)` 플레이스홀더(Xcode 자동완성 템플릿 잔재)가 있었음 → 이번에 정식 구현으로 교체
